# conversion methods from here: http://anthonylewis.com/2011/02/09/to-hex-and-back-with-ruby/

module Halo
  class Util
    def self.hex_to_bin(s)
      s.split(' ').map { |x| x.hex.chr }.join
    end

    def self.zerod_binary_string(length)
      (1..length).map { "\x00" }.join
    end
  end

  class PackUtil
    def self.bin_to_hex(s)
      s.unpack('H*').first
    end

    def self.hex_to_bin(s)
      s.scan(/../).map(&:hex).pack('c*')
    end
  end
end
