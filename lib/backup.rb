require 'socket'

require 'backup/file_item'
require 'backup/timestamp'
require 'backup/jar'

module Backup
  class Instance
    attr_reader :root_path, :hostname, :timestamp

    def initialize(root_path, hostname = nil, cloud = nil)
      @root_path = root_path
      @hostname = hostname || Socket.gethostname
      @timestamp = Backup::Timestamp.create
    end

    def key=(path)
      @key = open(path).read
    end

    def create!(local_path)
      jar = Jar.new(@root_path, local_path)
      jar.save
    end

    def jars
      Jar.all(@root_path)
    end

    def copy_file_to_backup(path, file)
      unless Dir.exists?(file)
        File.open("#{path}/#{Digest::MD5.hexdigest(file)}", "w") do |f|
          data = open(file).read
          f.puts data
        end
      end
    end

    def jar_versions(jar)
      Jar.jar_versions(root_path, jar, !!jar[/^[0-9a-z]{32}$/])
    end

    def restore_jar_to(hash, timestamp, to)
      #FIXME: Restore rights
      files = Jar.fetch_index_for(root_path, hash, timestamp)

      i=0
      puts files.select {|file| (i+=1) < 10}
      # return

      files.keys.sort.each do |file|
        restore_file = File.join(to, file)
        current_file = files[file]

        if current_file[:checksum].nil?
          try_create_dir restore_file

          File.chmod current_file[:mode], restore_file
          File.chown current_file[:uid], current_file[:gid], restore_file

          file_ok = FileItem.stat(restore_file)[restore_file]
          
          check_mode(restore_file, file_ok[:mode], current_file[:mode])
          check_rights(restore_file, file_ok[:uid], file_ok[:gid],
          						 current_file[:uid], current_file[:gid])
        else
          # FileUtils::mkdir_p(File.dirname restore_file)

          #FIXME: Check for exists
          # File.open(restore_file, "w") do |f|
            # begin
              # f.chmod files[file][:mode]
              # f.chown files[file][:uid], files[file][:gid]
            # rescue Exception => e
              # puts_fail e
            # end

            # puts file
            # f.puts open(File.join(file_path,
                                  # Digest::MD5.hexdigest(file))).read
          # end
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
