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

  def self.create_backup_files(path, files, key = nil)
    FileUtils.mkdir_p(path) unless Dir.exists?(path)

    files.each {|file| Backup::copy_file_to_backup(path, file, key)}
  end

  def self.create_backup(path, hash_files, key = nil)
    FileUtils.mkdir_p(path) unless Dir.exists?(path)

    Backup::create_backup_index(path, hash_files)

    hash_files.each_key {|file| Backup::copy_file_to_backup(path, file, key)}
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

    File.open("#{jar_path}/jar", "w").puts Backup::semantic_path(path)
  end

  def self.fetch_jars(path)
    Dir["#{path}/*"].map do |backup|
      backup.match(/[0-9a-z]{32}$/)[0] if backup.match(/[0-9a-z]{32}$/)
    end.compact.sort
  end

  def self.semantic_path(path)
    if Dir.exists? path
      path += '/'
    else
      path
    end
  end

  def self.parse_version_to_time(version, last = false)
    puts_fail "Invalid date format: #{version}" if version.length < 6

    year, month, day, hour, min, sec = version.split(/([0-9]{2})/).map do |date|
      date.to_i unless date.empty?
    end.compact

    hour = 23 if last and hour.nil?
    min = 59 if last and min.nil?
    sec = 59 if last and sec.nil?

    time = Time.new(year + 2000, month, day, hour, min, sec, 0)
  end

  def self.aes(command, key, data)
    (aes = OpenSSL::Cipher::Cipher.new('aes-256-cbc').send(command)).key = key
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
end
