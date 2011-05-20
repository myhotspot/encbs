require 'backup/file_item/base'

module Backup
  module FileItem
    class Local < Backup::FileItem::Base
      attr_reader :timeout
      
      def initialize
        @timeout = 0
      end

      def create_directory_once(*directories)
        directories.each do |path|
          FileUtils.mkdir_p(path) unless Dir.exists?(path)
        end
      end

      def create_file_once(file, data)
        data = data.read if data.is_a? File or data.is_a? StringIO
        File.open(file, "wb").puts(data) unless File.exists?(file)
      end

      def read_file(file)
        File.open(file, 'rb').read if File.exists? file
      end
      
      def timeout=(time)
      end

      def dir(path, mask = "*")
        r_mask = mask.gsub('.', '\.').gsub('*', '[^\/]')

        Dir["#{path}/#{mask}"].map do |item|
          match = item.match(/^#{path}\/([^\/]+#{r_mask}).*$/)
          match[1] if match
        end.compact.uniq
      end
    end
  end
end