require 'backup/file_item/base'

module Backup
	module FileItem
    class Cloud < Backup::FileItem::Base
      attr_reader :key, :secret, :backet, :provider

      def initialize(args = {})
        puts_fail "Empty hash in Cloud initialize method" if args.empty?

        [:key, :secret, :bucket].each do |arg|
          puts_fail "'#{arg.to_s.green}' should not be empty" if args[arg].nil?
          instance_eval %{@#{arg} = args[:#{arg}]}
        end

       try_to_connect_with_cloud 
      end

      def create_directory_once(*directories)
        # Nothing happen
      end

      def create_file_once(file, data)
        try_to_work_with_cloud do
          @directory.files.create(
            :key => delete_slashes(file),
            :body => data
          )
        end
      end

      def read_file(file)
        try_to_work_with_cloud do
          file = delete_slashes(file)
          remote_file = @directory.files.get(file)
          remote_file.body if remote_file
       	end
      end

      def dir(path, mask = "*")
        path = delete_slashes(path)
        mask = mask.gsub('.', '\.').gsub('*', '[^\/]')

        files = @directory.files.all(
          :prefix => path,
          :max_keys => 30_000 #TODO: Fix or use it?
        ).map &:key
        
        files.map do |item|
          match = item.match(/^#{path}\/([^\/]+#{mask}).*$/)
          match[1] if match
        end.compact.uniq
      end

      private

      def delete_slashes(str)
        str.chop! if str =~ /\/$/
        str = str[1, str.length] if str =~ /^\//
        str
      end

      def try_to_work_with_cloud(&block)
        begin
          yield
        rescue Exception => e
          try_to_connect_with_cloud 

          yield
        end
      end

      def try_to_connect_with_cloud
        begin
          @connection = ::Fog::Storage.new(
            :provider => 'AWS',
            :aws_secret_access_key => @secret,
            :aws_access_key_id => @key
          )

          @directory = @connection.directories.get(@bucket)
        rescue Exception => e
          puts_verbose e.message
          puts_fail "403 Forbidden"
        end

        puts_fail "Bucket '#{@bucket}' is not exists." if @directory.nil?
      end
		end
  end
end