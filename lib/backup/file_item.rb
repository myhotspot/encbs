module Backup
  class FileItem
    def self.semantic_path(path)
      if Dir.exists? path
        path += '/'
      else
        path
      end
    end

    def self.stat(file, timestamp = nil)
      files = {}

      stat = File.new(file).stat
      files[file] = {
        :uid => stat.uid,
        :gid => stat.gid,
        :mode => stat.mode
      }
      files[file][:timestamp] = timestamp if timestamp

      unless Dir.exists?(file)
        files[file][:checksum] = Digest::MD5.hexdigest(File.open(file).read)
      end

      files
    rescue Exception => e
      STDERR.puts e
    end

    def self.create_directory_once(*directories)
      directories.each do |path|
        FileUtils.mkdir_p(path) unless Dir.exists?(path)
      end
    end

    def self.create_file_once(file, data)
      File.open(file, "w").puts(data) unless File.exists?(file)
    end

    def self.file_hash(file)
      Digest::MD5.hexdigest file
    end

    def self.read_file(file)
      open(file).read if File.exists? file
    end

    def self.dir(path, mask = "*")
      Dir["#{path}/#{mask}"]
    end
  end
end
