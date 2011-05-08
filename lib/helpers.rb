def puts_fail(msg)
  STDERR.puts "Error: #{msg}"

  exit msg.length
end

def puts_verbose(msg)
  puts msg if $VERBOSE
end

def safe_require(&block)
  yield
rescue Exception => e
  puts_fail %Q{This script use these gems: fog, slop.
    Make sure that you have them all.
    If you don't have, you may install them: $ gem install fog slop
  }
end
