require 'bindata'
class BitString < BinData::String
  bit_aligned
end
class DecryptedPayload < BinData::Record

  endian :little
  bit11le :len
  bit1le :something
  array :data, :initial_length => Proc.new{ (len * 8 - 12) / 8 }, :type => :bit8le


  # bit_string :data, length: 30

  # array :test, :initial_length => 25, :type => :bit8le
  # string :data, :read_length => 30
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
        @challenge ||= GameSpy::Challenge.generate
        send_message Message.new(type: Message::GTI2MsgClientChallenge,
          data: @challenge,
          sn: @sn,
          esn: @esn
        )
        @sn += 1
        @esn += 1
        change_state(:process_challenge)
      when :process_challenge
        if m = next_message
          if m.type == Message::GTI2MsgServerChallenge
            client_challenge_response =  m.data[0..31]
            server_challenge = m.data[32..63]

            if ! GameSpy::Challenge.check_response(GameSpy::Challenge.get_response(@challenge), client_challenge_response)
              raise "Client challenge response verification failed"
            end
            server_challenge_response = GameSpy::Challenge.get_response(server_challenge)

            m = Message.new({type: Message::GTI2MsgClientResponse,
              sn: @sn,
              esn: @esn,
              data: server_challenge_response + @encryption_key + encode_version(VERSION)
            })
            raise_parse_error(m.data) unless m.data.length + 7 == 59
            send_message(m)
            change_state(:generate_keys)
          end
        end
      when :generate_keys
        if m = next_message
          if m.type == Message::GTI2MsgAccept
            none, @encryption_key2 = HaloTea::Crypto.generate_keys(@random_hash, m.data)
            none, @decryption_key2 = HaloTea::Crypto.generate_keys(@random_hash, m.data)
            change_state(:join)
          end
        end
      when :join
        if m = next_message
          if m.sn == 2 && m.esn == 2
            decrypted = HaloTea::Crypto.decrypt(m.data, @encryption_key2)
            checksum = decrypted.slice!(-4,4).unpack("L<").first
            data = decrypted
            len = BinData::Bit11le.read(decrypted)
            if HaloTea::Crypto.crc32(data) != checksum
              raise "Message validation failed: #{m.inspect}"
            end

          end
        end
        # fe fe 00 00 02 00 02                              .......
        # 0c 02 01 73 63 72 77 73 7a 63 00 01 00 00 00 01   ...scrwszc......
        # 00 00 00 00 69 6d 70 6f 73 69 6e 67 5f 31 00 04   ....imposing_1..
        # 10 6c                                             .l

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

    def change_state new_state
      @state = new_state.to_sym
    end

    def encode_version( version )
      [ version ].pack('L<')
    end

    def raise_parse_error(data)
      raise "Error: Could not parse packet #{data} for state #{@state}"
    end

    def read( length = 20000 )
      bytes = @socket.recvfrom_nonblock(length) rescue ['']
      @buffer << bytes.first if bytes.first.length > 0
    end

    def next_message
      read
      if payload = @buffer.shift
        puts 'HEREEEE'
        puts payload.inspect
        if payload.length >= 7
          m = Message.new(payload)
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