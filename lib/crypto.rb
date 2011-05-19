require 'openssl' 
require 'base64'

module Crypto
  
  def self.create_keys(priv, pub, bits)
    private_key = OpenSSL::PKey::RSA.new(bits)
    File.open(priv, "w+") { |fp| fp << private_key.to_s }
    File.open(pub,  "w+") { |fp| fp << private_key.public_key.to_s }    
    private_key
  end
  
  class Key
    def initialize(data, size)
      @public = (data =~ /^-----BEGIN (RSA|DSA) PRIVATE KEY-----$/).nil?
      @key = OpenSSL::PKey::RSA.new(data)
      @size = (size == 4096 ? 512 : 256)
    end
  
    def self.from_file(filename, size = 4096)
      self.new(File.read(filename), size)
    end

    def encrypt_to_stream(data)
      encrypt_data = StringIO.new
      i = 0
  
      while buf = data[i..(i+=117)] do
        encrypt_data << encrypt(buf)
      end
  
      encrypt_data.seek(0)
      encrypt_data
    end

    def decrypt_from_stream(data)
      encrypt_data = StringIO.new(data.chomp)
      encrypt_data.seek(0)
      decrypt_data = ""
  
      while buf = encrypt_data.read(@size) do
        decrypt_data += decrypt(buf)
      end

      decrypt_data
    end

    def encrypt(text)
      @key.send("#{key_type}_encrypt", text)
    rescue Exception => e
      puts_fail "RSA encrypt error: #{e.message}"
    end
    
    def decrypt(text)
      @key.send("#{key_type}_decrypt", text)
     rescue Exception => e
       puts_fail "RSA decrypt error: #{e.message}"
    end
  
    def private?
      !@public
    end
  
    def public?
      @public
    end
    
    def key_type
      @public ? :public : :private
    end
  end
end