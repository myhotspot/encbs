require 'backup/file_item/base'

module Backup
	module FileItem
    class Local < Backup::FileItem::Base
      def create_directory_once(*directories)
        directories.each do |path|
          FileUtils.mkdir_p(path) unless Dir.exists?(path)
        end
      end

      def create_file_once(file, data)
        date = date.read if date.is_a? File
        File.open(file, "w").puts(data) unless File.exists?(file)
      end

      def read_file(file)
        open(file).read if File.exists? file
      end

      def dir(path, mask = "*")
        Dir["#{path}/#{mask}"]
      end
    end
  end
end