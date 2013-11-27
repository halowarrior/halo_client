require 'ffi'
require 'securerandom'
require 'micromachine'
require 'crypt_tea'



module Halo
  class Client
    #extend Inliner
    #inline File.read('ext/halo_pck_algo.h')

    CHALLENGE_HEADERS = [ "\xFE\xFE\x01\x00\x00\x00\x00", 
                          "\xFE\xFE\x02\x00\x00\x00\x01",
                          "\xFE\xFE\x03\x00\x01\x00\x01",
                        ]

    def initialize(host, port, opts = {})
      # arguments
      @host = host
      @port = port
      @opts = opts
      @state = :connecting
      
      # tea encryption
      @enc_key1 =  LibC.malloc(16)
      @enc_key2 =  LibC.malloc(16)
      @dec_key1 =  LibC.malloc(16)
      @dec_key2 =  LibC.malloc(16)
      @base_key1 = LibC.malloc(17)
      @base_key2 = LibC.malloc(17)
      @hash1      = LibC.malloc(17)
      @hash2      = LibC.malloc(17)

      @cryptor = Halo::Tea.new

      @buffer = []
      @socket = UDPSocket.new(Socket::AF_INET)
    end

    def connect
      @socket.connect(@host, @port)
      @state = :connected
      execute_state while @state!= :finished 
    end

    def execute_state
      case @state
      when :connected
        @cryptor.genkeys(@hash1, @hash2, nil, nil, @base_key1, @base_key2)
        message = "#{CHALLENGE_HEADERS[0]}#{@hash1.read_string_to_null}#{@hash2.read_string_to_null}"
        @socket.send(message,0)
        @state = :process_challenge
      when :process_challenge
        read
        if packet = @buffer.shift        
          packet.slice!(CHALLENGE_HEADERS[1])
          report_parse_error(packet) unless packet.length == 64
          @cryptor.genkeys( @hash1, @hash2, packet[32..-1], packet[32..-1], @base_key1, @base_key2)
          debugger


          @state = :finished
        end


        # # response_to_client_challenge = packet[0..31]
        # # server_key = packet[32..-2]
        # random_number = packet[0..63]

        # debugger
        # raise_parse_error(server_challenge) unless server_challenge.length == 32
        # client_response = "#{CHALLENGE_HEADERS[2]}#{Halo::GameSpy.challenge(server_challenge)}"
        # @socket.send(client_response)
        # debugger
        # puts 1



      when :our_challenge_response

      end
    end

    private

    def raise_parse_error(data)
      raise "Error: Could not parse packet #{data} for state #{@state}"
    end

    def read
      bytes = @socket.recvfrom_nonblock(1024) rescue ['']
      @buffer << bytes.first if bytes.first.length > 0
    end

    def remove_bytes_from_buffer( length )
      bytes = @buffer[0..length-1]
      @buffer = @buffer[length..-1]
      bytes
    end
  end
end