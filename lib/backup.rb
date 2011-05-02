module Backup
  def self.file_stat(file, timestamp)
    files = {}

    stat = File.new(file).stat
    files[file] = {
      :uid => stat.uid,
      :gid => stat.gid,
      :mode => stat.mode,
      :timestamp => timestamp
    }

    unless Dir.exists?(file)
      files[file][:checksum] = Digest::MD5.hexdigest(File.open(file).read)
    end

    files
  rescue Exception => e
    STDERR.puts e
  end

  def self.create_hash_for_path(path, timestamp)
    files = {}

    if Dir.exists? path
      matches = Dir.glob(File.join(path, "/**/*"), File::FNM_DOTMATCH)
      matches = matches.map {|match| match unless match =~ /\/..$/ or match =~ /\/.$/ }.compact
      matches << path

      matches.each do |match|
        files.merge!(Backup::file_stat(match, timestamp))
      end
    else
      files = Backup::file_stat(path, timestamp)
    end

    files
  end

  def self.create_backup_index(path, hash_files)
    FileUtils.mkdir_p(path) unless Dir.exists?(path)

    File.open("#{path}/index.yml", "w").puts hash_files.to_yaml
  end

  def self.create_backup_files(path, files)
    FileUtils.mkdir_p(path) unless Dir.exists?(path)

    files.each {|file| Backup::copy_file_to_backup(path, file)}
  end

  def self.create_backup(path, hash_files)
    FileUtils.mkdir_p(path) unless Dir.exists?(path)

    Backup::create_backup_index(path, hash_files)

    hash_files.each_key {|file| Backup::copy_file_to_backup(path, file)}
  end

  def self.copy_file_to_backup(path, file)
    unless Dir.exists?(file)
      File.open("#{path}/#{Digest::MD5.hexdigest(file)}", "w") do |f|
        f.puts open(file).read
      end
    end
  end

  def self.fetch_versions_of_backups(path)
    Dir["#{path}/*"].map {|backup| backup.match(/[0-9]{12}$/)[0]}.compact.sort
  end

  def self.last_backup_path(path)
    Backup::fetch_versions_of_backups(path)[-1]
  end

  def self.backup_diff_versions(path)
    Backup::fetch_versions_of_backups("#{path}/diff")
  end

  def self.backup_diff_present?(path)
    !Backup::backup_diff_versions(path).empty?
  end

  def self.fetch_backup_index(version)
    YAML::load(open("#{version}/index.yml").read)
  end

  def self.create_jar(jar_path, path)
    FileUtils.mkdir_p(jar_path) unless Dir.exists?(jar_path)

    File.open("#{jar_path}/jar", "w").puts path
  end
end
