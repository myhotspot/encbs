module Backup
  class Jar
    def initialize(root_path, local_path)
      @root_path = root_path
      @local_path = local_path
      @timestamp = Backup::Timestamp.create
    end

    def jar_hash
      Digest::MD5.hexdigest(@local_path)
    end

    def save
      @local_files ||= hash_local_files

      FileItem.create_directory_once meta_jars_path, meta_jar_path, jar_data_path
      FileItem.create_file_once "#{meta_jars_path}/#{jar_hash}",
                                FileItem.semantic_path(@local_path)
      FileItem.create_file_once "#{meta_jar_path}/#{@timestamp}.yml",
      													@local_files.to_yaml

      @local_files.keys.each do |file|
        unless Dir.exists?(file)
          FileItem.create_file_once "#{jar_data_path}/#{FileItem.file_hash file}",
                                    open(file).read
        end
      end
    end

    def hash_local_files
      files = {}

      puts_verbose "Create index for #{@local_path}"

      if Dir.exists? @local_path
        matches = Dir.glob(File.join(@local_path, "/**/*"), File::FNM_DOTMATCH)

        matches = matches.select do |match|
          match[/\/..$/].nil? and match[/\/.$/].nil?
        end

        matches << @local_path

        matches.each do |match|
          files.merge!(FileItem.stat(match, @timestamp))
        end
      else
        files = FileItem.stat(@local_path, @timestamp)
      end

      files
    end

    class << self
      def hash_to_path(root_path, hash)
        FileItem.read_file("#{root_path}/meta/jars/#{hash}").chomp
      rescue Errno::ENOENT
        ""
      end

      def all(root_path)
        hashes = FileItem.dir("#{root_path}/meta/jars").map do |backup|
          backup[/[0-9a-z]{32}$/]
        end.compact.sort

        result = {}

        hashes.each do |hash|
          jar_local_path = Jar.hash_to_path(root_path, hash)
          result[jar_local_path] = hash unless jar_local_path.empty?
        end

        result
      end

      def jar_versions(root_path, jar, hash = false)
        jar = Digest::MD5.hexdigest(jar) unless hash
        meta_jar_path = "#{root_path}/meta/#{jar}"

        FileItem.dir(meta_jar_path, "*.yml").map do |file|
          file.match(/\/([0-9]{12}).yml$/)[1]
        end.sort
      end

      def fetch_index_for(root_path, hash, timestamp)
        YAML::load(FileItem.read_file "#{root_path}/meta/#{hash}/#{timestamp}.yml")
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
