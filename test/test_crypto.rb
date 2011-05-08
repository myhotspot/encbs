require File.expand_path('../helper', __FILE__)

# text = "I was encrypted but came back!" 
# 
# secret = pub_key.encrypt(text)
# puts priv_key.decrypt(secret)

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

  def test_encrypt
  end

  def test_decrypt
  end

  def test_crypt_text
  end

  def test_time
    create_keys! 512
    load_keys

    secret = ""
    f = open("/tmp/10mb").read

    start_time = Time.now

    i = 0
    while text = f[i..(i+=52)] do
      crypt_text = @pub_key.encrypt(text)
      # crypt_text = text
      secret += crypt_text
    end
    secret_time = Time.now
    # @priv_key.decrypt(secret)

    puts "*"*20
    STDOUT.puts "Start time: #{start_time}\nSecret time: #{secret_time - start_time}\nTotal: #{Time.now - start_time}"
  end
end