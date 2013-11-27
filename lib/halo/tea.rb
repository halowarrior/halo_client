require 'ffi'
require 'crypt_tea'
require 'securerandom'

module Halo
  class Tea
    extend FFI::Library
    ffi_lib File.expand_path('../../halo_tea.bundle', __FILE__)

    attach_function :halo_create_randhash, [:pointer], :void
    attach_function :halo_generate_keys, [:pointer, :pointer, :pointer], :void
    attach_function :halo_create_key, [:pointer, :pointer, :pointer, :pointer], :void
    attach_function :halo_tea_decrypt, [:pointer, :int, :pointer], :void
    attach_function :halo_tea_encrypt, [:pointer, :int, :pointer], :void
    attach_function :genkeys, [:pointer, :pointer, :pointer, :pointer, :pointer, :pointer], :void
    attach_function :gssdkcr, [:pointer, :pointer, :pointer], :void


    def initialize(key = nil)
      @key = key
      @hash = nil
    end

    def self.gss
      ptr = FFI::MemoryPointer.new(32)
      #ptr.write_string((1..32).map{"\x00"}.join)
      gssdkcr(ptr,ptr,nil)
      ptr
    end

    def self.randhash
      hash = FFI::MemoryPointer.new(FFI::Type::INT32, 2000)
      halo_create_randhash(hash)
      hash.read_string_to_null
    end

    def generate_key( source_key = nil)
      
      hash = LibC.malloc(17)
      hash.write_string self.class.randhash

      generated_key = LibC.malloc(16)

      if ( source_key )
        skey = LibC.malloc(source_key.length + 1)
        skey.write_string(source_key)
      else
        skey = nil
      end

      halo_generate_keys(hash,skey, generated_key)
      debugger


      {
        hash: hash.read_string(16),
        key: generated_key.read_string(16)
      }
    end

    def gen
      hash1 = FFI::Pointer.new(0)
      hash1.write_string(self.class.generate_random_key)

      hash2 = FFI::Pointer.new(0)
      hash2.write_string(self.class.generate_random_key)

      hash2 = FFI::Pointer.new(0)
      hash2.write_string(self.class.generate_random_key)
     

    end

    def encrypt(s)
      data = LibC.malloc(200)
      kp = LibC.malloc(200)
      kp.write_string(key)
      data.write_string(s)
      halo_tea_encrypt(data, s.length, kp)
      data
    end

    def decrypt(s)
      data = LibC.malloc(200)
      kp = LibC.malloc(200)
      kp.write_string(key)
      data.write_string(s)
      halo_tea_decrypt(data, s.length, kp)
      data
    end

    def saved_hash
      @saved_hash ||= self.class.generate_random_key
    end

    def key
      @key ||= self.class.generate_random_key
    end


    def self.generate_random_key
      SecureRandom.random_bytes
    end

    def self.test
      first = "30 2c 42 5c 4d 38 4d 56 77 62 5d 50 25 29 22 25 4e 54 55 3e 45 4e 69 38 55 66 75 4c 67 66 31 7c"
      parts = hex_to_bin(first)
      parts[0..15]

    end

    def self.hex_to_bin(s)
      #s.scan(/../)
      s.split(' ').map { |x| x.hex.chr }.join
    end


    # def self.generate_key
    #   hash = LibC.malloc(90)
    #   generated_key = LibC.malloc(90)
    #   null = LibC.malloc(50)
    #   hash = LibC.malloc(100)
    #   hash.write_string('3')

    #   ptr = FFI::MemoryPointer.new(:char, 200)
    #   # ptr.write_string('3')

    #   halo_create_randhash(ptr)
    #   #hash.read_string_to_null



    #   p = FFI::Pointer::NULL
    #   #halo_generate_keys(hash,p, generated_key)
    #   # generated_key.read_string_to_null
    # end

    # def self.generate_keys

    # end
    # def self.challenge( challenge_text = nil, key_text = nil)

    #   # where the function stores the result
    #   result_buffer = LibC.malloc(33)

    #   # the string the server sends

    #   challenge_pointer = LibC.malloc(33)
    #   challenge_pointer.write_string(challenge_text||@@challenge_hash)

    #   raise "Error: Challenge must be 32 characters: #{@@challenge_hash}" if @@challenge_hash.length != 32
      
    #   # game specific gamespy key

    #   key = LibC.malloc(33)
    #   key.write_string( key_text || HALO_KEY )

    #   gssdkcr(result_buffer,challenge_pointer,key).read_string_to_null
    # end
  end
end