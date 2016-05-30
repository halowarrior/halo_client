require 'bindata'

class DecryptedPayload < BinData::Record
  endian :little
  bit11le :len
  bit1le :mode
  bit7le :type
  # array :data, :initial_length => Proc.new{ (len * 8 - 12) / 8 }, :type => :bit8le

end

class DecryptedPayload2 < BinData::Record
  # bit_aligned
  endian :little
  bit11le :len
  bit1le :something

  string :data, :read_length => 30
end

module Halo
  class Client
    VERSION = 616000

    def initialize(host, port, opts = {})
      @buffer = []
      @host = host
      @port = port
      @opts = opts

      @sn = 0
      @esn = 0
      @state = :connecting
      @socket = UDPSocket.new(Socket::AF_INET)
      @log_file = opts[:log_file]
      @challenge = nil
      @random_hash, @encryption_key = HaloTea::Crypto.generate_keys
      @decryption_key = nil
    end

    def connect
      @socket.connect(@host, @port)
      @state = :connected
      run while @state != :finished
    end

    def run
      case @state
      when :connected
        send_message build_client_challenge
        @sn += 1
        @esn += 1
        change_state(:server_challenge_response)
      when :server_challenge_response
        if m = next_message
          if m.type == Message::GTI2MsgServerChallenge
            verify_client_challenge_response(m.data)
            send_message build_server_challenge_response(m.data)
            change_state(:generate_keys)
          end
        end
      when :generate_keys
        if m = next_message
          if m.type == Message::GTI2MsgAccept
            generate_crypto_keys
            change_state(:join)
          end
        end
      when :join
        if m = next_message
          if m.sn == 2 && m.esn == 2
            len = BinData::Bit11le.read(decrypted)

          end
        end
      when :get_server_keys
        if server_packet = next_message
          if server_packet.function == 0

          end
        end
      when :process
        if server_packet = next_message
        end
      end
    end

    private

    def generate_crypto_keys
      none, @encryption_key = HaloTea::Crypto.generate_keys(@random_hash, m.data)
      none, @decryption_key = HaloTea::Crypto.generate_keys(@random_hash, m.data)
    end

    def verify_client_challenge_response( data )
      client_challenge_response =  data[0..31]
      if ! GameSpy::Challenge.check_response(GameSpy::Challenge.get_response(@challenge), client_challenge_response)
        raise "Client challenge response verification failed"
      end
    end

    def build_server_challenge_response( data )
      server_challenge = data[32..63]
      server_challenge_response = GameSpy::Challenge.get_response(server_challenge)
      Message.new({type: Message::GTI2MsgClientResponse,
        sn: @sn,
        esn: @esn,
        data: server_challenge_response + @encryption_key + encode_version(VERSION)
      })
    end

    def build_client_challenge
      @challenge ||= GameSpy::Challenge.generate
      Message.new(type: Message::GTI2MsgClientChallenge,
        data: @challenge,
        sn: @sn,
        esn: @esn
      )
    end

    def change_state new_state
      @state = new_state.to_sym
    end

    def encode_version( version )
      [ version ].pack('L<')
    end

    def raise_parse_error(data)
      raise "Error: Could not parse packet #{data} for state #{@state}"
    end

    def read( len = 20000 )
      bytes = @socket.recvfrom_nonblock(len) rescue ['']
      @buffer << bytes.first if bytes.first.length > 0
    end

    def next_message
      read
      if payload = @buffer.shift
        if payload.length >= 7
          m = Message.new(payload, { decryption_key: @encryption_key2 })
          logger.info("Reading message from server: #{m.explain}")
          m
        end
      end
    end

    def send_message( m )
      logger.info("Sending message to server: #{m.explain}")
      sent = @socket.send(m.as_bytes, 0)
      logger.info "Bytes sent: #{sent}"
    end

    def format_message( message )
      message.unpack("h*").first.scan(/../).map{|byte| byte.hex.chr }.join
    end

    def logger
      @logger ||= Logger.new(@log_file ? File.new(@log_file) : STDOUT)
    end
  end
end