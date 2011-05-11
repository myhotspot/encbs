$LOAD_PATH.unshift(File.expand_path("../../lib/", __FILE__))

require 'rubygems'
require 'yaml'
require 'digest'
require 'fileutils'
require 'openssl'
require 'socket'
require 'helpers'
require 'progressbar'
require 'test/unit'

require 'backup'

def puts_fail msg
  raise msg
end
