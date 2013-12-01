module Halo
  class GameSpy
    extend FFI::Library
    ffi_lib File.expand_path('../../halo_tea.bundle', __FILE__)
    
    attach_function :gssdkcr, [:pointer, :pointer, :pointer], :void

    def self.challenge( challenge_string = nil)
      challenge =  FFI::MemoryPointer.new(:uint32, 33 * 4)
      result = FFI::MemoryPointer.new(:uint32, 33 * 4)
      if ! challenge_string
        LibC.memset(challenge, 0, 32);
      else
        challenge.write_string challenge_string 
      end

      gssdkcr(result, challenge, nil)
      result.read_string(32)
    end
  end
end