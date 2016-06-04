module Halo
  class FileBuffer
    def initialize(contents, _opts = {})
      @contents = contents
      @opts = {}
      @position = 0
    end

    def read_str(length, _opts = {})
      read(length)
    end

    def read_int32
      read(4).unpack('I')[0]
    end

    def read_long
      read(4).unpack('L')[0]
    end

    def read_char
      read(1).unpack('c')
    end

    def seek(position)
      @position = position
    end

    def current_position
      @position
    end

    private

    def read(length)
      contents = @contents.byteslice(@position, length)
      @position += length
      contents.dup
    end
  end
end
