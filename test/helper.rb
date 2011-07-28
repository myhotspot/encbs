$LOAD_PATH.unshift(File.expand_path("../../lib/", __FILE__))

require 'rubygems'
require 'yaml'
require 'digest'
require 'fileutils'
require 'openssl'
require 'socket'
require 'progressbar'
require 'test/unit'
require 'base64'
require 'lzoruby'
require 'zlib'

require 'fog'
require 'backup'
require 'encbsconfig'
require 'helpers'

def puts_fail msg
  raise msg
end
