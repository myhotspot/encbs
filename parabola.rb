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
  on :c, :config, "Use config file to upload backup", true
  on :d, :date, "Date for return to back up", true
  on :f, :find, "Find file or directory in backups"
  on :g, :"generate-key", "Generate key", true
  on :i, :increment, "Use increment mode for backup (default: false)"
  on :j, :jar, "Versions of jar (option: hash or path)", true
  on :k, :key, "Key to encrypt/decrypt backup", true
  on :l, :list, "List of jars" # FIXME
  on :r, :rescue, "What rescue from backup (default: all)", true
  on :t, :to, "Recovery to path (default: absolute path)"
  on :v, :verbose, "Verbose mode"

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
  puts "List of jars:\n"

  Backup::fetch_jars(@root_path).each do |jar|
    puts "    #{jar}: #{open("#{@root_path}/#{jar}/jar").readlines[0].chomp}"
  end

  exit
end

if opts.add?
  paths = opts[:add].split(" ")

  paths = paths.map do |path|
    path = File.expand_path path
    fail "Path \"#{path}\" not exists." unless File.exists? path
    path
  end

  paths.each do |path|
    @files = Backup::create_hash_for_path(path, @timestamp)
    @jar_path = "#{@root_path}/#{Digest::MD5.hexdigest(path)}"

    unless opts.increment?
      current_path = "#{@jar_path}/#{@timestamp}"

      unless @files.empty?
        Backup::create_jar(@jar_path, path)
        Backup::create_backup(current_path, @files)
      else
        fail "Nothing to backup"
      end
    else
      fail "Before create incremental backup, you need create full backup." if Backup::last_backup_path(@jar_path).nil?

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

      diff_path = "#{current_path}/diff/#{@timestamp}"

      unless new_files.empty?
        Backup::create_backup_index(diff_path, @files)
        Backup::create_backup_files(diff_path, new_files)
      else
        puts "Nothing to backup"
      end
    end
  end
else
  fail "Before create backup, you must add path." if opts.increment?
end
