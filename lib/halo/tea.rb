require 'ffi'

module Halo
  class Tea
    extend FFI::Library
    ffi_lib File.expand_path('../../halo_tea.bundle', __FILE__)

    attach_function :halo_generate_keys, [:pointer, :pointer, :pointer], :void
    attach_function :halo_tea_decrypt, [:pointer, :int32, :pointer], :void
    attach_function :halo_tea_encrypt, [:pointer, :int32, :pointer], :void

    def initialize(encryption_key, decryption_key, hash, opts = {})
      @encryption_key = encryption_key
      @decryption_key = decryption_key
      @hash = hash
      @opts = opts
    end

    def encrypt(data)
      data_ptr = FFI::MemoryPointer.new(:int32, data.length + 1)
      data_ptr.write_string(data)
      halo_tea_encrypt(data_ptr, data.length, @decryption_key)
      data_ptr.read_string(data.length)
    end

    def decrypt(data)
      data_ptr = FFI::MemoryPointer.new(:int32, data.length + 1)
      data_ptr.write_string(data)
      halo_tea_decrypt(data_ptr, data.length, @encryption_key)
      data_ptr.read_string(data.length)
    end

    def self.generate_key(hash, source, encryption_key)
      halo_generate_keys(hash, source, encryption_key)
      encryption_key.read_string(16)
    end
  end
end