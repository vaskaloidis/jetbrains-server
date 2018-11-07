require 'jetbrains/version'

require 'openssl'
require 'sinatra/base'
require 'trollop'
require 'logger'
require 'ngrok/tunnel'
require 'colorize'

require_relative 'jetbrains/license_signer'
require_relative 'jetbrains/product_identifier'
require_relative 'jetbrains/license_server'

VERSION = '2016-08-31_08:23'.freeze

module Jetbrains
end
