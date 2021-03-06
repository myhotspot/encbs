require 'stringio'

require 'backup/file_item'
require 'backup/timestamp'
require 'backup/jar'
require 'archive'
require 'crypto'

module Backup
  class Instance
    attr_reader :root_path, :timestamp, :hostname, :file_item, :compression

    def initialize(root_path, cloud = false, *args)
      if cloud
        @file_item = Backup::FileItem.for :cloud, *args
      else
        @file_item = Backup::FileItem.for :local
      end

      @hostname = Socket.gethostname
      @_root_path = @root_path
      @root_path = "#{root_path}/#{@hostname}"
      @timestamp = Backup::Timestamp.create
    end

    def compression= type
      @compression = Archive.new type.to_sym
    end

    def hostname= host
      @hostname = host
      @root_path = "#{@_root_path}/#{@hostname}"
    end

    def rsa_key path, size
      if File.exists? path
        @key = Crypto::Key.from_file(path, size)
      else
        @key = nil
      end
    end

    def create! local_path, increment = false, purge_previous = false
      jar = Jar.new @file_item, @root_path, local_path, @key
      jar.save increment, @compression, purge_previous
    end

    def jars
      Jar.all @file_item, @root_path
    end

    def jar_versions jar
      Jar.jar_versions @file_item, @root_path, jar, !!jar[/^[0-9a-z]{32}$/]
    end

    def restore_jar_to(hash, timestamp, to)
      files = Jar.fetch_index_for(@file_item, @root_path, hash, timestamp)
      puts_fail "Jar doesn't exists" if files.nil?

      unless files[:checksum].nil?
        if @key.nil? or
           @key.decrypt(Base64.decode64(files[:checksum])) != timestamp

          puts_fail "Checksum does not match."
        end
        files.delete :checksum
      end

      unless files[:compression].nil?
        compression = Archive.new files[:compression].to_sym
        files.delete :compression
      else
        compression = nil
      end

      pbar = ProgressBar.new(
        "Restoring",
        files.keys.length
      )
      pbar.bar_mark = '*'

      files.keys.sort.each do |file|
        restore_file = File.join(to, file)
        current_file = files[file]

        if current_file[:checksum].nil?
          try_create_dir restore_file

          File.chmod current_file[:mode], restore_file
          File.chown current_file[:uid], current_file[:gid], restore_file

          file_ok = @file_item.stat(restore_file)[restore_file]

          check_mode(restore_file, file_ok[:mode], current_file[:mode])
          check_rights(
            restore_file,
            file_ok[:uid],
            file_ok[:gid],
            current_file[:uid],
            current_file[:gid]
          )
        else
          try_create_dir(File.dirname restore_file)

          begin
            File.open(restore_file, "wb") do |f|
              f.chmod current_file[:mode]
              f.chown current_file[:uid], current_file[:gid]

              remote_path = "#{@root_path}/#{hash}/#{current_file[:timestamp]}"
              remote_path += "/#{@file_item.file_hash file}"

              data = @file_item.read_file(remote_path)
              data = @key.decrypt_from_stream data if @key

              unless compression.nil?
                data = compression.decompress(data).read
              end

              f.print data
            end

            file_ok = @file_item.stat(restore_file)[restore_file]

            check_mode(restore_file, file_ok[:mode], current_file[:mode])
            check_rights(
              restore_file,
              file_ok[:uid],
              file_ok[:gid],
              current_file[:uid],
              current_file[:gid]
            )
          rescue Errno::EACCES
            puts_fail "Permission denied for #{restore_file.dark_green}"
          end
        end

        pbar.inc
      end

      pbar.finish
    end
  end
end
