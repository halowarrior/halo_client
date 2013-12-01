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
      @packet_opts = { send_proc: Proc.new{|data| send(data) } }
    end

    def connect
      @socket.connect(@host, @port)
      @state = :connected
      run while @state != :finished 
    end

    def hash_and_derived_key
      key  = SecureRandom.random_bytes
      hash = Digest::MD5.digest(key)
      # {hash: hash, key: key}
      [hash,key]
    end

    def change_state new_state
      @state = new_state.to_sym
    end

    def decrypt_with_key( key, data )
      Crypt::XXTEA.decrypt(key, data)
    end

    def run
      case @state
      when :connected
        # send challenge
        @hash           = FFI::MemoryPointer.new(:uint8, 200)
        @encryption_key = FFI::MemoryPointer.new(:uint8, 200)
        @decryption_key = FFI::MemoryPointer.new(:uint8, 200)
        @challenge      = GameSpy.challenge
        packet = Packet.new({function: 1, number: @packet_number }, @packet_opts)
        packet.message = @challenge
        packet.send
        change_state(:process_challenge)
      when :process_challenge
        # send back challenge (calculated from server response), encryption key, version
        if server_packet = next_packet
          if server_packet.function == 2
            @challenge = GameSpy.challenge(server_packet.message[32..-1])
            Tea.generate_keys(@hash, nil, @encryption_key)
            packet = Packet.new({function: 3 }, @packet_opts)
            packet.message = @challenge + @encryption_key.read_string(16) +  "\x40\x66\x09\x00" #@encryption_key.read_string(16) #encode_version(VERSION)
            raise_parse_error(packet.message) unless packet.message.length + 7 == 59
            packet.send
            change_state(:generate_keys)
          end
        end
      when :generate_keys
        if server_packet = next_packet
          if server_packet.function == 4
            Tea.generate_keys(@hash, server_packet.message, @decryption_key)
            change_state(:get_server_keys)
          end
        end
      when :get_server_keys
        if server_packet = next_packet

          message = server_packet.message[0..-5].clone

          message_ptr = message.to_ptr

          Tea.halo_tea_decrypt(message_ptr, message.length, @decryption_key )

          message_ptr2 = message.to_ptr
          Tea.halo_tea_decrypt(message_ptr, message.length, @encryption_key )


          debugger
          puts message_ptr.read_string(message.length)

          #change_state(:process)
        end
      when :process
        if server_packet = next_packet

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

      def next_packet
        read
        if packet = @buffer.shift
          Packet.new(packet,@packet_opts)
        end
      end

      def send data
        @socket.send( data, 0)
      end
  end
end