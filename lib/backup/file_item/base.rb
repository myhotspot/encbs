module Backup
	module FileItem
  	class Base
      def semantic_path(path)
        if Dir.exists? path
          path += '/'
        else
          path
        end
      end

      def stat(file, timestamp = nil)
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

      def file_hash(file)
        Digest::MD5.hexdigest file
      end
    end
  end
end
