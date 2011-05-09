require 'backup/file_item/base'

module Backup
	module FileItem
    class Cloud < Backup::FileItem::Base
      attr_reader :key, :secret, :backet, :provider

      def initialize(args = {})
        puts_fail "Empty hash in Cloud initialize method" if args.empty?

        [:key, :secret, :bucket].each do |arg|
          puts_fail "#{arg} should not be empty" if args[arg].nil?
          instance_eval %{@#{arg} = args[:#{arg}]}
        end

        try_connect_to_cloud
      end

      def create_directory_once(*directories)
        directories.each do |path|
          FileUtils.mkdir_p(path) unless Dir.exists?(path)
        end
      end

      def create_file_once(file, data)
        File.open(file, "w").puts(data) unless File.exists?(file)
      end

      def read_file(file)
        open(file).read if File.exists? file
      end

      def dir(path, mask = "*")
        path.chop! if path =~ /\/$/
        path = path[1, path.length] if path =~ /^\//
        mask = mask.gsub('.', '\.').gsub('*', '[^\/]')

        files = @directory.files.map &:key
        files.map do |item|
          match = item.match(/^#{path}\/([^\/]+#{mask}).*$/)
          match[1] if match
        end.compact.uniq
      end

      private

      def try_connect_to_cloud
        #FIXME: Check for errors
        @connection = ::Fog::Storage.new(
          :provider                 => 'AWS',
          :aws_secret_access_key    => @secret,
          :aws_access_key_id        => @key
        )

        @directory = @connection.directories.get(@bucket)
      end
		end
  end
end