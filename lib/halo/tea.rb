require 'ffi'

module Halo
  class Tea
    extend FFI::Library
    ffi_lib File.expand_path('../../halo_tea.bundle', __FILE__)

    attach_function :halo_generate_keys, [:pointer, :pointer, :pointer], :void
    attach_function :halo_create_key, [:pointer, :pointer, :pointer, :pointer], :void
    attach_function :halo_tea_decrypt, [:pointer, :int, :pointer], :void
    attach_function :halo_tea_encrypt, [:pointer, :int, :pointer], :void

    def initialize(encryption_key, decryption_key, hash, opts = {})
      @encryption_key = encryption_key
      @decryption_key = decryption_key
      @hash = hash
      @opts = {}
    end

    def encrypt(data)
      data_ptr = FFI::MemoryPointer(:char, data.length + 1)
      data_ptr.write_string(data)
      halo_tea_encrypt(data_ptr, data.length, key_ptr)
      data_ptr.read_string_to_null
    end

    def decrypt(data)
      data_ptr = FFI::MemoryPointer(:char, data.length + 1)
      data_ptr.write_string(data)
      halo_tea_decrypt(data_ptr, data.length, key_ptr)
      data_ptr.read_string_to_null
    end

    def self.generate_key(hash, source, encryption_key)
      halo_generate_keys(hash, source, encryption_key)
    end
  end
end