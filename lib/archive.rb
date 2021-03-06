require 'zlib'
require 'lzoruby'

module GZIP
  def self.compress string, level
    z = Zlib::Deflate.new level
    dst = z.deflate string, Zlib::FINISH
    z.close
    dst
  end

  def self.decompress string
    zstream = Zlib::Inflate.new
    buf = zstream.inflate string
    zstream.finish
    zstream.close
    buf
  end
end

class Archive
  attr_reader :type

  def initialize type
    type = type.to_s
    puts_fail "Unsupported type" unless %w[lzo gzip].include? type.downcase
    instance_eval %{@type = #{type.upcase}}
  end

  def method_missing name, *args
    StringIO.new @type.send(name, *args)
  end
end
