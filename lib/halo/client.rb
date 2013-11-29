module Halo
  class Client
    extend FFI::Library
    ffi_lib File.expand_path('../../halo_tea.bundle', __FILE__)
    
    VERSION = 616

    CHALLENGE_HEADERS = [ "\xFE\xFE\x01\x00\x00\x00\x00", 
                          "\xFE\xFE\x02\x00\x00\x00\x01",
                          "\xFE\xFE\x03\x00\x01\x00\x01",
                        ]

    def initialize(host, port, opts = {})
      @hash = FFI::MemoryPointer.new(:int32, 17)
      @encryption_key = FFI::MemoryPointer.new(:int32, 17)
      @decryption_key = FFI::MemoryPointer.new(:int32, 17)
      @buffer = []
      @host = host
      @port = port
      @opts = opts
      @state = :connecting
      @socket = UDPSocket.new(Socket::AF_INET)
      @packet_number = 0
    end

    def connect
      @socket.connect(@host, @port)
      @state = :connected
      run while @state != :finished 
    end

    def random_hash
      Digest::MD5.digest(Random.new.rand(9000000000).to_s)
    end

    def run
      read
      case @state
      when :connected
        @hash = random_hash
        packet = Packet.create({function: 1, number: @packet_number, message: GameSpy.challenge }) #CHALLENGE_HEADERS[0] + GameSpy.challenge
        send(packet.build)
        @packet_number += 1
        @state = :process_challenge
        Tea.generate_key(@hash, nil, @encryption_key)
      when :process_challenge
        if server_packet = @buffer.shift
          server_packet = Packet.from_buffer(server_packet)
          client_packet = Packet.create({function: 3, number: @packet_number, unknown_number: "\x01" })


          # possible_key = FFI::MemoryPointer.new(:int32, 900)
          # possible_key.write_string(server_packet.message[0..31])
          # puts server_packet.message[0..31].length
          # Tea.generate_key(@hash, nil, @encryption_key)
          # Tea.generate_key(@hash, possible_key, @encryption_key)
          # Tea.generate_key(@hash, possible_key, @decryption_key)


          client_packet.message = GameSpy.challenge(server_packet.message[32..-1]) + 
                                  @encryption_key.read_string(16) +
                                  encode_version(VERSION)


          raise_parse_error(client_packet.message) unless client_packet.message.length + 7 == 59
          send(client_packet.build)
          @packet_number += 1
          @state = :generate_keys
        end
      when :generate_keys
        if server_packet = @buffer.shift
          server_packet = Packet.from_buffer(server_packet)
          # raise_parse_error(server_packet.message) unless server_packet.message.length == 64

          temp = FFI::MemoryPointer.new(:int32, 900)
          temp.write_string(server_packet.message)
          #server_packet.message

          Tea.generate_key(@hash, temp, @decryption_key)
          Tea.generate_key(@hash, temp, @encryption_key)
          debugger
          @state = :start_encrypted_communication
        end
      when :start_encrypted_communication
        if server_packet = @buffer.shift 
          client_packet = Packet.create({ function: 0, number: @packet_number})
          @tea = Tea.new(@encryption_key, @decryption_key, @hash)
          server_packet = Packet.from_buffer(server_packet, { opts: { cryptor: @tea }})
          puts 1
          @packet_number += 1
        end
      end

    end

    private
      
      def encode_version( version )
        [ version * 1000 ].pack('L')
      end

      def raise_parse_error(data)
        raise "Error: Could not parse packet #{data} for state #{@state}"
      end

      def read( length = 20000 )
        bytes = @socket.recvfrom_nonblock(length) rescue ['']
        @buffer << bytes.first if bytes.first.length > 0
      end

      def send data
        @socket.send( data, 0)
      end

      def remove_bytes_from_buffer( length )
        bytes = @buffer[0..length-1]
        @buffer = @buffer[length..-1]
        bytes
      end
  end
end