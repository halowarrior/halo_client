module Halo
  class Client
    extend FFI::Library
    ffi_lib File.expand_path('../../halo_tea.bundle', __FILE__)
    
    VERSION = 616

    def initialize(host, port, opts = {})
      @buffer = []
      @host = host
      @port = port
      @opts = opts
      @state = :connecting
      @socket = UDPSocket.new(Socket::AF_INET)
      @packet_number = 0
      @data_log = File.open('data.log','w')
      @packet_opts = { send_proc: Proc.new{|data| send(data) } }
    end

    def connect
      @socket.connect(@host, @port)
      @state = :connected
      run while @state != :finished 
    end

    def run
      case @state
      when :connected
        @hash           = FFI::MemoryPointer.new(:uint, 17)
        @encryption_key = FFI::MemoryPointer.new(:uint8, 16)
        @decryption_key = FFI::MemoryPointer.new(:uint8, 16)
        @hash.order(:network)
        @encryption_key.order(:network)
        @decryption_key.order(:network)

        @main_hash  = SecureRandom.random_bytes
        # @crypt  = Crypt::TEA.new(@hash)

        # generate initial hash and encryption key 
        Tea.generate_keys(@hash, nil, @encryption_key)

        packet = Packet.new({function: 1, number: @packet_number, message: GameSpy.challenge }, @packet_opts)
        packet.send
        change_state(:process_challenge)
      when :process_challenge
        # send back challenge (calculated from server response), our encryption key, version
        if server_packet = next_packet
          if server_packet.function == 2
            packet = Packet.new({function: 3 }, @packet_opts)
            packet.message = GameSpy.challenge(server_packet.message[32..-1]) + @encryption_key.read_string(16) +  "\x40\x66\x09\x00" #@encryption_key.read_string(16) #encode_version(VERSION)
            raise_parse_error(packet.message) unless packet.message.length + 7 == 59
            packet.send
            change_state(:generate_keys)
          end
        end
      when :generate_keys
        if server_packet = next_packet
          if server_packet.function == 4
            @server_key = server_packet.message.unpack("L>*")
            @m = FFI::MemoryPointer.new(:uint8, 16)
            @m.write_array_of_uint8( @server_key )
            Tea.generate_keys(@hash, server_packet.message.to_ptr, @encryption_key)
            change_state(:get_server_keys)
          end
        end
      when :get_server_keys
        if server_packet = next_packet
          if server_packet.function == 0 
            # decrypt stream
            message = server_packet.message
            length = message.length
            message_ptr = message.to_ptr(:uint8)
            Tea.halo_tea_decrypt(message_ptr, length, @encryption_key)
            debugger
            @data_log.write(message_ptr)
            @data_log.flush
          end
        end
      when :process
        if server_packet = next_packet
        end
      end

    end

    private
      
      def change_state new_state
        @state = new_state.to_sym
      end
      
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

      def next_packet
        read
        if packet = @buffer.shift
          Packet.new(packet,@packet_opts) if packet.length >= 7
        end
      end

      def send data
        @socket.send( data, 0)
      end

      def format_message( message )
        message.unpack("h*").first.scan(/../).map{|byte| byte.hex.chr }.join
      end
  end
end