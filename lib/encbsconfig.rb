class EncbsConfig
  attr_reader :paths, :bucket, :colorize, :compression, :hostname, :increment,
              :key, :purge, :secret, :size, :token, :timeout, :verbose

  def initialize
    @paths = ""
  end

  def load(path)
    [:bucket, :colorize, :compression, :hostname, :increment, :key, :secret,
      :size, :token, :timeout, :verbose].each {|attr| eval "@#{attr} = nil"}

    @paths = ""

    instance_eval "#{open(path).read}"
  end

  def use_hostname attr
    @hostname = attr
  end

  def add(attr)
    @paths += " #{attr}"
  end

  def colorize!
    @colorize = true
  end

  def public_key attr
    @token = attr
  end

  def increment!
    @increment = true
  end

  def use_compression attr
    @compression = attr
  end

  def aws_key attr
    @key = attr
  end

  def aws_secret attr
    @secret = attr
  end

  def aws_bucket attr
    @bucket = attr
  end

  def key_size attr
    @size = attr
  end

  def verbose!
    @verbose = true
  end

  def set_timeout attr
    @timeout = attr
  end

  def purge!
    @purge = true unless @increment
  end
end
