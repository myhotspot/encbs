require 'backup/file_item'
require 'backup/timestamp'
require 'backup/jar'
require 'crypto'

module Backup
  class Instance
    attr_reader :root_path, :timestamp, :hostname, :file_item

    def initialize(root_path, cloud = false, *args)
      #FIXME
      @hostname = Socket.gethostname

      if cloud
        @file_item = Backup::FileItem.for :cloud, :bucket => "palobr",
        																	:secret => "soSAoK/YSBhlWPoZIQorTqPfQvzxBTwf6wMK50LX",
                                          :key => "AKIAJJB6XTJKM2LWOP7Q"
      else
        @file_item = Backup::FileItem.for :local
      end

      @root_path = "#{root_path}/#{@hostname}"
      @timestamp = Backup::Timestamp.create
    end

    def key=(path)
      @key = open(path).read
    end

    def create!(local_path, increment = false)
      jar = Jar.new(@file_item, @root_path, local_path)
      jar.save(increment)
    end

    def jars
      Jar.all(@file_item, @root_path)
    end

    def jar_versions(jar)
      Jar.jar_versions(@file_item, @root_path, jar, !!jar[/^[0-9a-z]{32}$/])
    end

    def restore_jar_to(hash, timestamp, to)
      files = Jar.fetch_index_for(@file_item, @root_path, hash, timestamp)

      files.keys.sort.each do |file|
        restore_file = File.join(to, file)
        current_file = files[file]

        if current_file[:checksum].nil?
          try_create_dir restore_file

          File.chmod current_file[:mode], restore_file
          File.chown current_file[:uid], current_file[:gid], restore_file

          file_ok = @file_item.stat(restore_file)[restore_file]
          
          check_mode(restore_file, file_ok[:mode], current_file[:mode])
          check_rights(restore_file, file_ok[:uid], file_ok[:gid],
          						 current_file[:uid], current_file[:gid])
        else
          try_create_dir(File.dirname restore_file)

          begin
            File.open(restore_file, "w") do |f|
              f.chmod current_file[:mode]
              f.chown current_file[:uid], current_file[:gid]

              remote_path = "#{@root_path}/#{hash}/#{current_file[:timestamp]}"
              remote_path += "/#{@file_item.file_hash file}"

              data = @file_item.read_file remote_path
              f.puts data
            end

            file_ok = @file_item.stat(restore_file)[restore_file]
          
            check_mode(restore_file, file_ok[:mode], current_file[:mode])
            check_rights(restore_file, file_ok[:uid], file_ok[:gid],
                         current_file[:uid], current_file[:gid])
          rescue Errno::EACCES
            puts_fail "Permission denied for #{restore_file.dark_green}"
          end
        end
      end

    end
  end

  def self.fetch_versions_of_backup(path)
    Dir["#{path}/*"].map do |backup|
      backup.match(/[0-9]{12}$/)[0] if backup.match(/[0-9]{12}$/)
    end.compact.sort
  end

  def self.aes(command, key, data)
    aes = OpenSSL::Cipher::Cipher.new('aes-256-cbc').send(command)
    aes.key = key
    aes.update(data) << aes.final
  end

  def self.encrypt_data(key, data)
    Backup::aes(:encrypt, key, data) unless data.empty?
  end

  def self.decrypt_data(key, data)
    Backup::aes(:decrypt, key, data)
  end
end
