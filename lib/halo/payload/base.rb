module Halo
  class Payload
    def initialize(data, _opts = {})
      @data = data
    end

    def encrypt(data)
      fail 'Encryption key not set' unless @opts[:encryption_key]
      encrypted = HaloTea::Crypto.encrypt(data, @opts[:encryption_key])
      encrypted += crc32_bytes(encrypted)
      encrypted
    end

    def decrypt(data)
      fail 'Decryption key not set' unless @opts[:decryption_key]
      decrypted = HaloTea::Crypto.decrypt(data, @opts[:decryption_key])
      checksum = decrypted.slice!(-4, 4).unpack('L<').first
      if HaloTea::Crypto.crc32(decrypted) != checksum
        fail "Message validation failed: #{m.inspect}"
      end
      decrypted
    end

    def as_bytes(opts = {})
      opts[:encrypt]
    end

    private

    def crc32_bytes
      [HaloTea::Crypto.crc32(encrypted)].pack('L<')
    end
  end
end
