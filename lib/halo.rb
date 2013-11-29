require 'ffi'
require 'crypt_tea'
require 'halo/version'
require 'halo/util'
require 'halo/packet'
require 'halo/client'
require 'halo/file_buffer'
require 'halo/map'
require 'halo/tea'
require 'halo/tea_2'
require 'halo/game_spy'


module Halo
  # Your code goes here...

  def self.test
    host = '127.0.0.1'
    port = '3400'
    host = '66.225.231.168'
    port = 2306
    client = Halo::Client.new(host,port)
    client.connect

  end
end
