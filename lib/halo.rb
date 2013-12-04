require 'ffi'
require 'crypt_tea'
require 'halo/version'
require 'halo/util'
require 'halo/to_ptr'
require 'halo/lib_c'
require 'halo/packet'
require 'halo/client'
require 'halo/file_buffer'
require 'halo/map'
require 'halo/tea'
require 'halo/game_spy'


module Halo
  
  # for running tests in the debugger
  def self.test
    host = '127.0.0.1'
    port = '3400'
    host = '66.225.231.168'
    port = 2306
    client = Halo::Client.new(host,port)
    client.connect
  end
end
