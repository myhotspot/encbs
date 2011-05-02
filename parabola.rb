#!/usr/bin/env ruby
require 'rubygems'
require 'yaml'
require 'digest'
require 'socket'
require 'fileutils'

begin
  require 'slop'
  # require 'fog'
rescue Exception => e
  fail %Q{This script use these gems: fog, slop.
    Make sure that you have them all.
    If you don't have, you may install them: $ gem install fog slop
  }
end

require './lib/backup.rb'

opts = Slop.parse :help => true do
  on :a, :add, "Add path to backup", true
  on :i, :increment, "Use increment mode for backup (default: false)"
  on :c, :config, "Use config file to upload backup", true
  on :v, :verbose, "Verbose mode"
  on :k, :key, "Key to encrypt/decrypt backup", true
  on :g, :"generate-key", "Generate key", true
  on :r, :rescue, "What rescue from backup (default: all)", true
  on :d, :date, "Date for return to back up", true
  on :l, :list, "List of full backups"

  banner "Usage:\n    $ parabola [options]\n\nOptions:"
end

if ARGV.empty?
  puts opts.help
  exit
end

@timestamp = Time.now.strftime "%y%m%d%H%M%S"
@hostname = Socket.gethostname
@root_path = "backup/#{@hostname}"

if opts.list?
  puts "List of backups:\n"

  Backup::fetch_versions_of_backups(@root_path).each do |backup|
    puts "    #{backup}"
  end

  exit
end

if opts.add?
  paths = opts[:add].split(" ")

  paths.each do |path|
    fail "Path \"#{path}\" not exists." unless File.exists? path
  end

  @files = {}

  paths.each do |path|
    @files.merge!(Backup::create_hash_for_path(path, @timestamp))
  end

  unless opts.increment?
    current_path = "#{@root_path}/#{@timestamp}"

    Backup::create_backup(current_path, @files)
  else
    fail "Before create incremental backup, you need create full backup." if Backup::last_backup_path(@root_path).nil?

    current_path = "#{@root_path}/#{Backup::last_backup_path(@root_path)}"

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

    diff_path = "#{current_path}/diff/#{@timestamp}"

    unless new_files.empty?
      Backup::create_backup_index(diff_path, @files)
      Backup::create_backup_files(diff_path, new_files)
    else
      puts "Nothing to backup"
    end
  end
else
  fail "Before create backup, you must add path." if opts.increment?
end
