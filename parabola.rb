#!/usr/bin/env ruby
require 'rubygems'
require 'yaml'
require 'digest'
require 'socket'
require 'fileutils'
require 'openssl'

def puts_fail(msg)
  STDERR.puts "Error: #{msg}"

  exit msg.length
end

begin
  require 'slop'
  # require 'fog'
rescue Exception => e
  puts_fail %Q{This script use these gems: fog, slop.
    Make sure that you have them all.
    If you don't have, you may install them: $ gem install fog slop
  }
end

require './lib/backup.rb'

opts = Slop.parse :help => true do
  on :a, :add, "Add path to backup", true
  on :c, :config, "Use config file to upload backup", true
  on :d, :date, "Date for return to back up", true
  on :f, :find, "Find file or directory in backups"
  on :g, :generate, "Generate key", true
  on :i, :increment, "Use increment mode for backup (default: false)"
  on :j, :jar, "Versions of jar (option: hash or path)", true
  on :k, :key, "Key to encrypt/decrypt backup", true
  on :l, :list, "List of jars"
  on :r, :rescue, "What rescue from backup (default: all)", true
  on :t, :to, "Recovery to path (default: absolute path)"
  on :v, :verbose, "Verbose mode"

  banner "Usage:\n    $ parabola [options]\n\nOptions:"
end

if ARGV.empty?
  puts opts.help
  exit
end

@timestamp = Time.now.utc.strftime "%y%m%d%H%M%S"
@hostname = Socket.gethostname
@root_path = "backup/#{@hostname}"

if opts.list?
  puts "List of jars:\n"

  Backup::fetch_jars(@root_path).each do |jar|
    puts "    #{jar}: #{open("#{@root_path}/#{jar}/jar").readlines[0].chomp}"
  end

  exit
end

if opts.key?
  @key = open(opts[:key]).read
end

if opts.generate?
  File.open(opts[:generate], "w") do |f|
    10.times {f.puts Digest::SHA512.digest "#{rand}#{Time.now}"}
  end

  exit
end

if opts.date?
  date = opts[:date].gsub(".", "").gsub(" ", "").gsub(":", "").split("-")

  unless date.length == 1
    start_date = Backup::parse_version_to_time date[0]
    end_date = Backup::parse_version_to_time date[1], true

    puts_fail "Last date less than start date" if start_date > end_date
    puts start_date, end_date
  else
    puts Backup::parse_version_to_time date[0]
  end

  exit
end

if opts.jar?
  jar_path = Backup::jar_path(@root_path, File.expand_path(opts[:jar]))

  versions = Backup::fetch_versions_of_backup jar_path

  unless versions.empty?
    puts "Versions of backup: #{opts[:jar]}"
    versions.each do |version|
      puts "    #{Backup::parse_version_to_time version}"

      Backup::backup_diff_versions("#{jar_path}/#{version}").each do |diff|
        puts "      diff: #{Backup::parse_version_to_time diff}"
      end
    end
  else
    puts "Versions doesn't exists for backup: #{opts[:jar]}"
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
    @files = Backup::create_hash_for_path(path, @timestamp)
    @jar_path = "#{@root_path}/#{Digest::MD5.hexdigest(path)}"

    unless opts.increment?
      current_path = "#{@jar_path}/#{@timestamp}"

      unless @files.empty?
        Backup::create_jar(@jar_path, path)
        Backup::create_backup(current_path, @files, @key)
      else
        puts_fail "Nothing to backup"
      end
    else
      puts_fail "Before create incremental backup, you need to create a full backup." if Backup::last_backup_path(@jar_path).nil?

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

          if current_file == previous_file
            @files[file][:timestamp] = previous_index[file][:timestamp]
          else
            new_files << file
          end
        else
          new_files << file
        end
      end

      if @files.length > 1
        diff_path = "#{current_path}/diff/#{@timestamp}"
      else
        diff_path = current_path
      end

      unless new_files.empty?
        Backup::create_backup_index(diff_path, @files)
        Backup::create_backup_files(diff_path, new_files, @key)
      else
        puts "Nothing to backup: #{Backup::semantic_path(path)}"
      end
    end
  end
else
  puts_fail "Before create backup, you must add path." if opts.increment?
end
