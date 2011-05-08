#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/palobr/')

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
  on :colorize, "Colorize print to console."
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
$COLORIZE = true

if opts.generate?
  puts "Generate 4096 bits RSA keys"
  Crypto::create_keys(File.join(Dir.getwd, "rsa_key"),
  										File.join(Dir.getwd, "rsa_key.pub"))
  puts "Done!"

  exit
end

@backup = Backup::Instance.new "backup"

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
  @start_date = nil
  @end_date = Time.now.utc
end

if opts.jar?
  versions = @backup.jar_versions(opts[:jar])

  unless versions.empty?
    puts "Versions of backup: #{opts[:jar]}"

    versions.each do |version|
      puts "    #{version}: #{Backup::Timestamp.to_str(version)}"
    end
  else
    puts "Versions doesn't exists for jar: #{opts[:jar]}"
  end

  exit
end

#TODO: Support rescue option as hash
if opts.rescue?
  paths = opts[:rescue].split(" ")
  jars_list = @backup.jars

  include_path = lambda {|path| jars_list.keys.include? path}
  
  jars_hashes = paths.map do |path|
    path = File.expand_path path

    unless include_path[path] or include_path["#{path}/"]
      puts_fail "Jar \"#{path}\" not exists." 
    end

    jars_list[path] || jars_list["#{path}/"]
  end

  if opts.to?
    @to = File.expand_path opts[:to]
    try_create_dir @to
  else
    @to = "/"
  end

  #TODO: Confirm flag
  #TODO: fetch last diff index or root index. And add files to array that fetch these after
  #TODO: Empty destination directory

  @index = {}

  jars_hashes.each do |hash|
    versions = @backup.jar_versions(hash)
    puts "Versions: #{versions}" #FIXME

    last_version = Backup::Timestamp.last_from(versions, @end_date, @start_date)

    unless last_version.nil?
      @index[hash] = last_version
    else
      error_path = "#{Backup::Jar.hash_to_path(@backup.root_path, hash)}"
      start_date = Backup::Timestamp.to_s(@start_date)
      end_date = Backup::Timestamp.to_s(@end_date)

      unless @end_date == @start_date
        puts_fail "Nothing found for #{error_path}, between date: #{start_date} - #{end_date}"
      else
        puts_fail "Nothing found for #{error_path}, for date: #{end_date}"
      end
    end
  end

  @index.each do |hash, timestamp|
    puts "#{hash}: #{timestamp}" #FIXME
    @backup.restore_jar_to(hash, timestamp, @to)
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
    unless opts.increment?
      @backup.create! path
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
