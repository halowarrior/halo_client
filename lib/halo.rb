require 'halo/version'

require 'logger'
require 'byebug'
require 'halo_tea'
require 'game_spy'
require 'micromachine'

require 'halo/util'
require 'halo/message'
require 'halo/payload/base'
require 'halo/client'
require 'halo/file_buffer'
require 'halo/map'

module Halo
  # for running tests in the debugger
  def self.test
    host = '198.58.124.27'
    port = 2330
    client = Halo::Client.new(host, port)
    client.connect
  end
end
