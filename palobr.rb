#!/usr/bin/env ruby
$LOAD_PATH << File.dirname(__FILE__) + '/lib/'

require 'rubygems'
require 'yaml'
require 'digest'
require 'fileutils'
require 'openssl'
require 'helpers'

safe_require do
  require 'slop'
  # require 'fog'
end

require 'backup'
require 'crypto'

opts = Slop.parse :help => true do
  on :a, :add, "Add path to backup", true
  on :c, :config, "Use config file to upload backup", true #TODO
  on :d, :date, "Date for backup restore (default: last)", true
  on :f, :find, "Find file or directory in backups" #TODO
  on :g, :generate, "Generate 4096 bits RSA keys"
  on :h, :hostname, "Set hostname (default: system)", true
  on :i, :increment, "Use increment mode for backup (default: false)"
  on :j, :jar, "Versions of jar (option: hash or path)", true
  on :k, :key, "Key to encrypt/decrypt backup", true
  on :l, :list, "List of jars"
  on :r, :rescue, "Return data from backup (option: jar, path or filter)", true
  on :t, :to, "Path to recovery (default: /)", true
  on :v, :verbose, "Verbose mode" #TODO

  banner "Usage:\n    $ parabola [options]\n\nOptions:"
end

if ARGV.empty?
  puts opts.help

  exit
end

# $VERBOSE = opts.verbose?
$VERBOSE = true

#FIXME: REMOVE!!
require 'socket'
if opts.hostname?
  @hostname = opts[:hostname]
else
  @hostname = Socket.gethostname
end

#FIXME: Add cloud and config paths
@root_path = "backup/#{@hostname}" #TODO: REMOVE!!

if opts.generate?
  puts "Generate 4096 bits RSA keys"
  Crypto::create_keys(File.join(Dir.getwd, "rsa_key"),
  										File.join(Dir.getwd, "rsa_key.pub"))
  puts "Done!"

  exit
end

@backup = Backup::Instance.new @root_path

if opts.list?
  jars_list = @backup.jars

  unless jars_list.empty?
    puts "List of jars:\n"
    jars_list.keys.sort.each do |key|
      puts "    #{key}: #{jars_list[key]}"
    end
  else
    puts "Nothing to listing."
  end

  exit
end

#TODO: AES or RSA
@backup.key = opts[:key] if opts.key?

if opts.date?
  date = opts[:date].split("-")

  unless date.length == 1
    @start_date = Backup::Timestamp.parse_timestamp date[0]
    @end_date = Backup::Timestamp.parse_timestamp date[1], true

    puts_fail "Last date less than start date" if start_date > end_date
  else
    @start_date = Backup::Timestamp.parse_timestamp date[0]
    @end_date = Backup::Timestamp.parse_timestamp date[0], true
  end
else
  @end_date = Time.now.utc
end

if opts.jar?
  #FIXME: Support hash as path too
  #TODO: DSL for that
  jar_path = @backup.jar_path(File.expand_path(opts[:jar]))

  versions = Backup::fetch_versions_of_backup jar_path

  unless versions.empty?
    puts "Versions of backup: #{opts[:jar]}"
    versions.each do |version|
      puts "    #{Backup::Timestamp.parse_timestamp version}"

      Backup::backup_diff_versions("#{jar_path}/#{version}").each do |diff|
        puts "      diff: #{Backup::Timestamp.parse_timestamp diff}"
      end
    end
  else
    puts "Versions doesn't exists for backup: #{opts[:jar]}"
  end

  exit
end

if opts.rescue?
  paths = opts[:rescue].split(" ")
  jars = paths.map do |path|
    path = File.expand_path path
    jar_path = "#{@root_path}/#{Digest::MD5.hexdigest(path)}"

    if Backup::fetch_versions_of_backup(jar_path).empty?
      puts_fail "Jar \"#{path}\" not exists." 
    end

    jar_path
  end

  if opts.to?
    @to = File.expand_path opts[:to]
    FileUtils.mkdir_p @to
  else
    @to = "/"
  end

  #TODO: Confirm flag
  #TODO: Filters for date: < now, or 12.12.03 >
  #TODO: fetch last diff index or root index. And add files to array that fetch these after
  #TODO: Empty destination directory

  @indexes = []

  jars.each do |jar_path|
    versions = Backup::fetch_versions_of_backup jar_path

    #FIXME: Clean code!!!1
    last_version = Backup::Timestamp.last_version_from_list(versions,
                                                            @end_date, @start_date)

    unless last_version.nil?
      last_diff_version = Backup::last_diff_version(jar_path, last_version,
                                                    @start_date, @end_date)

      if last_diff_version.nil?
        @indexes << "#{jar_path}/#{last_version}"
      else
        @indexes << "#{jar_path}/#{last_version}/diff/#{last_diff_version}"
      end
    else
      last_diff_version = versions.reverse.find do |version|
        if last_diff_version = Backup::last_diff_version(jar_path, version,
                                                         @start_date, @end_date)
          "#{jar_path}/#{version}/diff/#{last_diff_version}"
        end
      end

      if last_diff_version
        @indexes << last_diff_version
      else
        #TODO: Add path to message than showing which params is bad
        unless @end_date == @start_date
          puts_fail "Nothing found in date range: #{@start_date} % #{@end_date}"
        else
          puts_fail "Nothing found in date: #{@start_date}"
        end
      end
    end
  end

  @indexes.each do |index|
    Backup::restore_backup_to(@to, index)
  end

  exit
end

if opts.add?
  paths = opts[:add].split(" ")

  paths = paths.map do |path|
    path = File.expand_path path
    puts_fail "Path \"#{path}\" not exists." unless File.exists? path

    path
  end

  paths.each do |path|
    # @files = @backup.create_hash_for_path(path)
    # puts_fail "Nothing to backup" if @files.empty?

    # jar_path = @backup.jar_path path #!!!!!!!!!!!
    # backup/Timothy-Klims-MacBook-Pro.local/c5068b7c2b1707f8939b283a2758a691

    unless opts.increment?
      @backup.create! path
      # @backup.create_jar(path) #!!!!!!
      # @backup.create_backup(path, @files) #!!!!!!!!
    else
      if Backup::last_backup_path(@jar_path).nil?
        puts_fail "Before create incremental backup, you need to create a full backup."
      end

      current_path = "#{@jar_path}/#{Backup::last_backup_path(@jar_path)}"

      unless Backup::backup_diff_present?(current_path)
        previous_index = Backup::fetch_backup_index(current_path)
      else
        last_diff = Backup::backup_diff_versions(current_path)[-1]
        previous_index = Backup::fetch_backup_index("#{current_path}/diff/#{last_diff}")
      end

      new_files = []

      @files.each_key do |file|
        current_file = @files[file].dup
        current_file.delete(:timestamp)

        unless previous_index[file].nil?
          previous_file = previous_index[file].dup
          previous_file.delete(:timestamp)

          if (current_file == previous_file) or (current_file[:checksum] ==
                                                 previous_file[:checksum])
            @files[file][:timestamp] = previous_index[file][:timestamp]
          else
            new_files << file
          end
        else
          #TODO: If file has renamed, find it and change path, without upload
          new_files << file
        end
      end

      if @files.length > 1
        diff_path = "#{current_path}/diff/#{@timestamp}"
      else
        diff_path = current_path
      end

      unless @files == previous_index
        Backup::create_backup_index(diff_path, @files)
        Backup::create_backup_files(diff_path, new_files, @key) unless new_files.empty?
      else
        puts "Nothing to backup: #{Backup::FileItem.semantic_path(path)}"
      end
    end
  end
else
  puts_fail "Before create backup, you must add path." if opts.increment?
end
