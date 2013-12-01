module Halo
  class OTEA

    def self.generate_key( password)
      Digest::MD5.digest(pass_phrase).unpack('L*')
    end
    # key is 4, int32s, i.e. [4, 4, 4, 4]
    def self.encrypt(key, text)
      v0,v1, = key
    end

    def self.decrypt(key, text)

    end
  end
end