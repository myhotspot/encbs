def puts_fail(msg)
  STDERR.puts "#{"Error! ".red}#{msg}"

  exit msg.length
end

def puts_verbose(msg)
  puts msg if $PRINT_VERBOSE
end

def print_verbose(msg)
  print msg if $PRINT_VERBOSE
end

def try_create_dir(dir)
  begin
    FileUtils.mkdir_p dir unless Dir.exists? dir
  rescue Errno::EACCES
    puts_fail "Permission denied for #{dir.dark_green}"
  end
end

def check_mode(file, first, second)
  unless first == second
    puts_fail "Permission wasn't changed for #{file.dark_green}"
  end
end

def check_rights(file, first_uid, first_gid, second_uid, second_gid)
  unless first_uid == second_uid and first_gid == second_gid
    puts_fail "Group and user wasn't change for #{file.dark_green}"
  end
end

def create_lock
  open("/tmp/encbs.lock", "w") do |f|
    f.puts Process.pid
  end
end

def remove_lock
  FileUtils.rm "/tmp/encbs.lock" if File.exists? "/tmp/encbs.lock"
end

def lock_exists?
  File.exists? "/tmp/encbs.lock"
end

class String
  def red
    colorize(self, "\e[1m\e[31m")
  end

  def green
    colorize(self, "\e[1m\e[32m")
  end

  def dark_green
    colorize(self, "\e[32m")
  end

  def yellow
    colorize(self, "\e[1m\e[33m")
  end

  def blue
    colorize(self, "\e[1m\e[34m")
  end

  def dark_blue
    colorize(self, "\e[34m")
  end

  def pur
    colorize(self, "\e[1m\e[35m")
  end

  def colorize(text, color_code)
    if $COLORIZE
      "#{color_code}#{text}\e[0m"
    else
      text
    end
  end
end
