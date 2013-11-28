require 'ffi'
require 'util'

module Halo
  class GameSpy
    extend FFI::Library
    ffi_lib File.expand_path('../../halo_tea.bundle', __FILE__)
    
    attach_function :gssdkcr, [:pointer, :pointer, :pointer], :void

    def self.challenge( challenge_string = nil)
      challenge_string = Util.zerod_binary_string(32) if challenge_string is nil
      challenge =  FFI::MemoryPointer.new(:char, 33)
      result = FFI::MemoryPointer.new(:char, 33)

      challenge.write_string challenge_string 
      gssdkcr(result, challenge, nil)
      result.read_string_to_null
    end
  end
end