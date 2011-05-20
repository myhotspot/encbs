module Backup
  class Jar
    def initialize(file_item, root_path, local_path, key = nil)
      @root_path = root_path
      @local_path = local_path
      @timestamp = Backup::Timestamp.create
      @file_item = file_item
      @key = key
    end

    def jar_hash
      Digest::MD5.hexdigest(@local_path)
    end

    def save(increment = false)
      @meta_index = {}
      @local_files = hash_local_files

      if increment
        last_timestamp = Jar.jar_versions(@file_item, @root_path, jar_hash, true).last

        if last_timestamp.nil?
          puts_fail "First you must create a full backup for #{@local_path.dark_green}"
        end

        @last_index = Jar.fetch_index_for(@file_item, @root_path, jar_hash, last_timestamp)

        @local_files.keys.each do |file|
          current = @local_files[file].dup
          current.delete(:timestamp)
        
          unless @last_index[file].nil?
            backup = @last_index[file].dup
            backup.delete(:timestamp)
        
            if (current == backup) or
               (!current[:checksum].nil? and current[:checksum] == backup[:checksum])
        
              @meta_index[file] = @local_files[file]
              @meta_index[file][:timestamp] = @last_index[file][:timestamp]
            end
          end
        end
      end

      unless @key.nil?
        @meta_index.merge!({
          :checksum => Base64.encode64(@key.encrypt(@timestamp))
        })
      end
      @file_item.create_directory_once meta_jars_path, meta_jar_path, jar_data_path
      @file_item.create_file_once(
        "#{meta_jars_path}/#{jar_hash}",
        @file_item.semantic_path(@local_path)
      )

      if @file_item.is_a? Backup::FileItem::Cloud
        pbar = ProgressBar.new(
          "Uploading",
          @local_files.keys.count
        )
      else
        pbar = ProgressBar.new(
          "Copying",
          @local_files.keys.count
        )
      end
      
      pbar.bar_mark = '*'

      #@local_files = @meta_index.select {|k, v| v[:timestamp] == @timestamp if v.is_a? Hash}
      
      begin
        @local_files.keys.each do |file|
          if @meta_index[file].nil?
            unless Dir.exists?(file)
              data = StringIO.new File.open(file, 'rb').read
              checksum = Digest::MD5.hexdigest(data.read)
          
              data.seek 0
              data = @key.encrypt_to_stream(data) if @key
              
              #FIXME
              #puts_fail "Error on #{file}" if (1..50).to_a.shuffle[0] == 1

              @file_item.create_file_once(
                "#{jar_data_path}/#{@file_item.file_hash file}",
                data
              )
          
              pbar.inc
            end
        
            @meta_index[file] = @local_files[file]
            @meta_index[file][:checksum] = checksum
            @meta_index[file][:timestamp] = @timestamp
          end
        end
      rescue Exception => e
        File.open("/var/tmp/encbs.swap", "w") do |f|
          f.puts @meta_index.to_yaml
        end
        
        puts
        puts_fail "Index file has been saved that to allow upload into cloud in next run."
      else
        @file_item.create_file_once(
          "#{meta_jar_path}/#{@timestamp}.yml",
          @meta_index.to_yaml
        )
      end

      pbar.finish
    end

    def hash_local_files
      files = {}

      if Dir.exists? @local_path
        matches = Dir.glob(File.join(@local_path, "/**/*"), File::FNM_DOTMATCH)

        matches = matches.select do |match|
          match[/\/..$/].nil? and match[/\/.$/].nil?
        end

        matches << @local_path

        matches.each do |match|
          files.merge!(@file_item.stat match)
        end
      else
        files = @file_item.stat @local_path
      end

      files
    end

    class << self
      def hash_to_path(file_item, root_path, hash)
        file_item.read_file("#{root_path}/meta/jars/#{hash}").chomp
      rescue Errno::ENOENT
        ""
      end

      def all(file_item, root_path)
        hashes = file_item.dir("#{root_path}/meta/jars").map do |backup|
          backup[/[0-9a-z]{32}$/]
        end.compact.sort

        result = {}

        hashes.each do |hash|
          jar_local_path = Jar.hash_to_path(file_item, root_path, hash)
          result[jar_local_path] = hash unless jar_local_path.empty?
        end

        result
      end

      def jar_versions(file_item, root_path, jar, hash = false)
        jar = jar.chop if jar =~ /\/$/
        jar = Digest::MD5.hexdigest(jar) unless hash

        meta_jar_path = "#{root_path}/meta/#{jar}"

        file_item.dir(meta_jar_path, "*.yml").map do |file|
          match = file.match(/^\/?([0-9]{12}).yml$/)
          match[1] if match
        end.compact.sort
      end

      def fetch_index_for(file_item, root_path, hash, timestamp)
        index = file_item.read_file "#{root_path}/meta/#{hash}/#{timestamp}.yml"
        YAML::load(index) unless index.nil?
      end
    end

    private

    def meta_jars_path
      "#{@root_path}/meta/jars"
    end

    def meta_jar_path
      "#{@root_path}/meta/#{jar_hash}"
    end

    def jar_data_path
      "#{@root_path}/#{jar_hash}/#{@timestamp}"
    end
  end
end
