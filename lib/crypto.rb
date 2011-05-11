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
    def initialize(data)
      @public = (data =~ /^-----BEGIN (RSA|DSA) PRIVATE KEY-----$/).nil?
      @key = OpenSSL::PKey::RSA.new(data)
    end
  
    def self.from_file(filename)    
      self.new File.read( filename )
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
      encrypt_data = StringIO.new data
      decrypt_data = ""
  
      while buf = encrypt_data.read(256) do
        decrypt_data += decrypt(buf)
      end

      decrypt_data
    end

    def encrypt(text)
      @key.send("#{key_type}_encrypt", text)
    end
    
    def decrypt(text)
      @key.send("#{key_type}_decrypt", text)
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