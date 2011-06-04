require File.expand_path('../helper', __FILE__)

class TestConfig < Test::Unit::TestCase
  def setup
    @config = EncbsConfig.new
    @config.load File.expand_path('../fixtures/Encbsfile.example', __FILE__)
  end

  def test_load
    assert @config.colorize
    assert @config.increment
    assert @config.paths.include?('~/.oh-my-zsh')
    assert @config.paths.include?('~/.zshrc')
    assert @config.verbose

    assert_nil @config.purge

    assert_equal @config.bucket, 'encbs'
    assert_equal @config.compression, 'gzip'
    assert_equal @config.hostname, 'Yeah'
    assert_equal @config.key, 'AWS_KEY'
    assert_equal @config.secret, 'AWS_SECRET'
    assert_equal @config.size, 2048
    assert_equal @config.timeout, 1000
    assert_equal @config.token, '~/rsa_key.pub'
  end
end
