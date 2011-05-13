class EncbsConfig
  attr_reader :paths, :bucket, :colorize, :hostname, :increment, :key,
              :secret, :token, :verbose

  def initialize
    @paths = ""
  end

  def load(path)
    eval "#{open(path).read}"
  end

  def use_hostname(attr)
    @hostname = attr
  end

  def add(attr)
    @paths += " #{attr}"
  end

  def colorize!
    @colorize = true
  end

  def public_key(attr)
    @token = attr
  end

  def increment!
    @increment = true
  end

  def aws_key(attr)
    @key = attr
  end

  def aws_secret(attr)
    @secret = attr
  end

  def aws_bucket(attr)
    @bucket = attr
  end

  def verbose!
    @verbose = true
  end
end
