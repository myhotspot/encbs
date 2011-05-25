module Backup
	module FileItem
  	class Base
      def semantic_path(path)
        if File.directory? path
          path += '/'
        else
          path
        end
      end

      def stat(file)
        files = {}

        stat = File.new(file).stat
        files[file] = {
          :uid => stat.uid,
          :gid => stat.gid,
          :mode => stat.mode
        }
        unless File.directory? file
          files[file][:checksum] = Digest::MD5.hexdigest File.open(file, 'rb').read
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
