require "halo/version"
require 'halo/file_buffer'
require 'halo/lib_c'
require 'halo/map'
require 'halo/client'
require 'halo/tea'

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
