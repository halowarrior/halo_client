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

  string :data, read_length: 30
end

module Halo
  class Client
    VERSION = 616_000

    def initialize(host, port, opts = {})
      @host = host
      @port = port
      @opts = opts
    end

    def connect
      @socket = UDPSocket.new(Socket::AF_INET)
      @socket.connect(@host, @port)
      @machine = build_state_machine
      @machine.trigger(:connected)
      @random_hash, @encryption_key = HaloTea::Crypto.generate_keys
      run while @machine.state != :finished
    end

    def run
      case @machine.state
      when :send_client_challenge
        send_message build_client_challenge
        @machine.trigger :send_client_challenge
      when :read_client_challenge_response
        if m = next_message
          if m.type == Message::GTI2MsgServerChallenge
            verify_client_challenge_response(m.data)
            send_message build_server_challenge_response(m.data)
            @machine.trigger(:read_client_challenge_response)
          end
        end
      when :generate_keys
        if m = next_message
          if m.type == Message::GTI2MsgAccept
            generate_crypto_keys(m.data)
            @machine.trigger(:generate_keys)
          end
        end
      when :read_server_join
        if m = next_message
          if m.sn == 2 && m.esn == 2
            debugger
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

    def build_state_machine
      @machine = MicroMachine.new(:new)
      @machine.when(:connected, new: :send_client_challenge)
      @machine.when(:send_client_challenge, send_client_challenge: :read_client_challenge_response)
      @machine.when(:read_client_challenge_response, read_client_challenge_response: :generate_keys)
      @machine.when(:generate_keys, generate_keys: :read_server_join)
      @machine
    end

    def generate_crypto_keys(data)
      none, @encryption_key = HaloTea::Crypto.generate_keys(@random_hash, data)
      none, @decryption_key = HaloTea::Crypto.generate_keys(@random_hash, data)
    end

    def verify_client_challenge_response(data)
      client_challenge_response =  data[0..31]
      unless GameSpy::Challenge.check_response(GameSpy::Challenge.get_response(@challenge), client_challenge_response)
        fail 'Client challenge response verification failed'
      end
    end

    def build_server_challenge_response(data)
      server_challenge = data[32..63]
      server_challenge_response = GameSpy::Challenge.get_response(server_challenge)
      Message.new(type: Message::GTI2MsgClientResponse,
                  sn: 1,
                  esn: 1,
                  data: server_challenge_response + @encryption_key + encode_version(VERSION))
    end

    def build_client_challenge
      @challenge ||= GameSpy::Challenge.generate
      Message.new(type: Message::GTI2MsgClientChallenge,
                  data: @challenge,
                  sn: 0,
                  esn: 0
                 )
    end

    def encode_version(version)
      [version].pack('L<')
    end

    def read(len = 20_000)
      bytes = @socket.recvfrom_nonblock(len) rescue ['']
      @buffer ||= []
      @buffer << bytes.first if bytes.first.length > 0
    end

    def next_message
      read
      if payload = @buffer.shift
        if payload.length >= 7
          m = Message.new(payload, decryption_key: @encryption_key)
          logger.info("Reading message from server: #{m.explain}")
          m
        end
      end
    end

    def send_message(m)
      logger.info("Sending message to server: #{m.explain}")
      sent = @socket.send(m.as_bytes, 0)
      logger.info "Bytes sent: #{sent}"
    end

    def logger
      @log_file ||= opts[:log_file]
      @logger ||= Logger.new(@log_file ? File.new(@log_file) : STDOUT)
    end
  end
end
