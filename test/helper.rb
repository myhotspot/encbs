$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib/palobr/')

require 'rubygems'
require 'test/unit'
require 'yaml'
require 'digest'
require 'fileutils'
require 'openssl'

require 'backup'
require 'crypto'

def puts_fail msg
  raise msg
end
