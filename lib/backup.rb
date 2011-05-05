require './backup/file'
require './backup/timestamp'

module Backup
  def self.create_hash_for_path(path, timestamp)
    files = {}

    if Dir.exists? path
      matches = Dir.glob(File.join(path, "/**/*"), File::FNM_DOTMATCH)

      matches = matches.map do |match|
        match unless match =~ /\/..$/ or match =~ /\/.$/
      end.compact

      matches << path

      matches.each do |match|
        files.merge!(Backup::File.stat(match, timestamp))
      end
    else
      files = Backup::File.stat(path, timestamp)
    end

    files
  end

  def self.restore_backup_to(path, index)
    #FIXME: Restore rights
    #TODO: Returns the number of files processed.
    #TODO: Push files to share directory without split
    files = Backup::fetch_backup_index(index)
    root_path = File.expand_path("../../", index)

    if index.match /\/diff\/[0-9]{12}$/
      diffs = Backup::backup_diff_versions(root_path)
    end

    files.keys.sort.each do |file|
      restore_file = File.join(path, file)

      if files[file][:checksum].nil?
        FileUtils::mkdir_p restore_file

        begin
          File.chmod files[file][:mode], restore_file
          File.chown files[file][:uid], files[file][:gid], restore_file
        rescue Exception => e
          puts_fail e
        end
      else
        FileUtils::mkdir_p(File.dirname restore_file)

        #FIXME: Check for exists
        File.open(restore_file, "w") do |f|
          begin
            f.chmod files[file][:mode]
            f.chown files[file][:uid], files[file][:gid]
          rescue Exception => e
            puts_fail e
          end

          if files[file][:timestamp] == index.match(/[0-9]{12}$/)[0]
            file_path = index
          else
            if index.match /\/#{files[file][:timestamp]}\/diff\/[0-9]{12}$/
              file_path = root_path
            else
              file_path = diffs.find do |diff|
                if diff == files[file][:timestamp]
                  File.expand_path("../#{diff}", index)
                end
              end

              if file_path.nil?
                puts_fail "Invalid timestamp in backup index"
              end
            end
          end

          puts file
          f.puts open(File.join(file_path,
                                Digest::MD5.hexdigest(file))).read
        end
      end
    end
  end

  def self.create_backup_index(path, hash_files)
    FileUtils.mkdir_p(path) unless Dir.exists?(path)

    File.open("#{path}/index.yml", "w").puts hash_files.to_yaml
  end

  def self.create_backup_files(path, files, key = nil)
    FileUtils.mkdir_p(path) unless Dir.exists?(path)

    files.each {|file| Backup::copy_file_to_backup(path, file, key)}
  end

  def self.create_backup(path, hash_files, key = nil)
    FileUtils.mkdir_p(path) unless Dir.exists?(path)

    Backup::create_backup_index(path, hash_files)

    hash_files.each_key {|file| Backup::copy_file_to_backup(path,
                                                            file, key)}
  end

  def self.copy_file_to_backup(path, file, key = nil)
    unless Dir.exists?(file)
      File.open("#{path}/#{Digest::MD5.hexdigest(file)}", "w") do |f|
        data = open(file).read
        data = Backup::encrypt_data(key, data) unless key.nil?

        f.puts data
      end
    end
  end

  def self.fetch_versions_of_backup(path)
    Dir["#{path}/*"].map do |backup|
      backup.match(/[0-9]{12}$/)[0] if backup.match(/[0-9]{12}$/)
    end.compact.sort
  end

  def self.last_backup_path(path)
    Backup::fetch_versions_of_backup(path)[-1]
  end

  def self.backup_diff_versions(path)
    Backup::fetch_versions_of_backup("#{path}/diff")
  end

  def self.backup_diff_present?(path)
    !Backup::backup_diff_versions(path).empty?
  end

  def self.fetch_backup_index(version)
    YAML::load(open("#{version}/index.yml").read)
  end

  def self.create_jar(jar_path, path)
    FileUtils.mkdir_p(jar_path) unless Dir.exists?(jar_path)

    File.open("#{jar_path}/jar", "w").puts Backup::File.semantic_path(path)
  end

  def self.fetch_jars(path)
    Dir["#{path}/*"].map do |backup|
      backup.match(/[0-9a-z]{32}$/)[0] if backup.match(/[0-9a-z]{32}$/)
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

  def self.jar_path(root_path, jar)
    "#{root_path}/#{Digest::MD5.hexdigest(jar)}"
  end

  def self.last_diff_version(jar_path, version, start_date, end_date)
    diff_versions = Backup::backup_diff_versions("#{jar_path}/#{version}")
    Backup::Timestamp.last_version_from_list(diff_versions, end_date,
                                             start_date)
  end
end
