module Halo
  class Map 
    # game types
    SINGLE_PLAYER = 1
    MULTI_PLAYER = 2
    UI = 3

    attr_reader :magic, :version, :length, :zeros, :offset, :metadata_length, :offset_24, :name, :build, :type
    def initialize( data, opts = {})
      @opts = {}
      @data = data
    end

    def magic
      raise 'Bad magic' unless @data[:magic] == 'head'.reverse
      @data[:magic]
    end

    def version
      case @data[:version]
      when 5
        version = 'xbox'
      when 6
        version = 'trial'
      when 7
        version = 'full'
      when 609
        version = 'ce'
      else
        raise "Unknown version: #{@data[:version]}"
      end
      version
    end

    def build
      case @data[:build]
      when '01.00.00.0564'
        'PC'
      when '01.00.00.0609'
        'CE'
      else
        nil
      end
    end

    def type
      case @data[:type]
      when 0
        SINGLE_PLAYER
      when 1
        MULTI_PLAYER
      when 2
        UI
      else
        raise "Unknown map type: #{@data[:type]}"
      end
    end

    def self.parse(path, opts = {})
      buffer = nil
      File.open(path,'rb'){ |f| buffer = FileBuffer.new(f.read) }
      
      data = {
        magic:   buffer.read_str(4),
        version: buffer.read_int32,
        length:  buffer.read_int32,
        zeros:   buffer.read_str(4),
        index_offset:  buffer.read_int32,
        metadata_length: buffer.read_int32,
        offset_24: buffer.read_str(8),
        name: buffer.read_str(32).delete("\x0"),
        build: buffer.read_str(32).delete("\x0"),
        type: buffer.read_str(1).unpack('c').first,
        unknown: buffer.read_str(1947),
        signature: buffer.read_str(4),
      }

      raise "Error processing file with head: #{data[:magic]}" unless data[:magic] == 'head'.reverse 
      raise "Error processing file with footer: #{data[:signature]}" unless data[:signature] == 'foot'.reverse

      Map.new(data, opts)
    end
  end
end