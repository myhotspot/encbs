require File.expand_path('../helper', __FILE__)

class TestCrypto < Test::Unit::TestCase
  def fixtures
    File.expand_path('../fixtures/rsa_keys', __FILE__)
	end

  def create_keys!(bits = 4096)
    Crypto.create_keys("#{fixtures}/rsa_key", "#{fixtures}/rsa_key.pub", bits)
  end

  def load_keys
    @priv_key = Crypto::Key.from_file("#{fixtures}/rsa_key")
    @pub_key =  Crypto::Key.from_file("#{fixtures}/rsa_key.pub")
	end

  def test_create_keys
    create_keys!

    assert_not_nil File.open("#{fixtures}/rsa_key").read
    assert_not_nil File.open("#{fixtures}/rsa_key.pub").read
  end
end