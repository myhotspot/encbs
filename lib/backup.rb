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

  def self.restore_backup_to(path, index)
    #FIXME: Restore rights
    #TODO: Returns the number of files processed.
    #TODO: Push files to share directory without split
    files = Backup::fetch_backup_index(index)
    root_path = File.expand_path("../../", index)

    files.keys.sort.each do |file|
      restore_file = File.join(path, file)

      if files[file][:checksum].nil?
        FileUtils::mkdir_p restore_file
        #FIXME: Check for ok
        # File.chmod files[file][:mode], restore_file
        # File.chown files[file][:uid], files[file][:gid], restore_file
      else
        FileUtils::mkdir_p(File.dirname restore_file)
        File.open(restore_file, "w") do |f|
          #FIXME: Check for ok
          # f.chmod files[file][:mode]
          # f.chown files[file][:uid], files[file][:gid]

          #FIXME: Use timestamp in path
          if files[file][:timestamp] == index.match(/[0-9]{12}$/)[0]
            file_path = index
          else
            #TODO: check for diff and index to paths
            if index.match /#{files[file][:timestamp]}/
              file_path = root_path
            else
              diffs = Backup::backup_diff_versions(root_path)
              file_path = diffs.select {|diff| diff == files[file][:timestamp]}.first
              file_path = File.expand_path("../#{file_path}", index)

              puts_fail "Invalid timestamp in backup index" if file_path.nil?
            end
          end

          f.puts open(File.join(file_path, Digest::MD5.hexdigest(file))).read
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

    if last
      hour = 23 if hour.nil?
      min = 59 if min.nil?
      sec = 59 if sec.nil?
    end

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

  def self.last_version_from_list(list, end_date, start_date = nil)
    list.reverse.select do |version|
      version = Backup::parse_version_to_time version

      unless start_date.nil?
        version >= start_date and version <= end_date
      else
        version <= end_date
      end
    end.first
  end

  def self.last_diff_version(jar_path, version, start_date, end_date)
    diff_versions = Backup::backup_diff_versions("#{jar_path}/#{version}")
    Backup::last_version_from_list(diff_versions, end_date, start_date)
  end
end
