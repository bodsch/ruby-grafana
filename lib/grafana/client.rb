
require 'ruby_dig' if RUBY_VERSION < '2.3'

require 'rest-client'
require 'json'
require 'timeout'

require_relative 'version'
require_relative 'login'
require_relative 'network'
require_relative 'tools'
require_relative 'admin'
require_relative 'user'
require_relative 'users'
require_relative 'datasource'
require_relative 'organization'
require_relative 'organizations'
require_relative 'dashboard'
require_relative 'snapshot'
# -------------------------------------------------------------------------------------------------------------------
#
# @abstract # Namespace for classes and modules that handle all Grafana API calls
#
# @author Bodo Schulz <bodo@boone-schulz.de>
#
#
module Grafana

  # Abstract base class for the API calls.
  # Provides some helper methods
  #
  # @author Bodo Schulz
  #
  class Client

    include Logging

    include Grafana::Version
    include Grafana::Login
    include Grafana::Network
    include Grafana::Tools
    include Grafana::Admin
    include Grafana::User
    include Grafana::Users
    include Grafana::Datasource
    include Grafana::Organization
    include Grafana::Organizations
    include Grafana::Dashboard
    include Grafana::Snapshot

    attr_accessor :debug

    # Create a new instance of Class
    #
    # @param [Hash, #read] settings the settings for Grafana
    # @option settings [String] :host ('localhost') the Grafana Hostname
    # @option settings [Integer] :port (3000) the Grafana HTTP Port
    # @option settings [String] :url_path ('')
    # @option settings [Bool] :ssl (false)
    # @option settings [Integer] :timeout (5)
    # @option settings [Integer] :open_timeout (5)
    # @option settings [Hash] :http_headers ({})
    # @option settings [Bool] :debug (false)
    #
    # @example to create an new Instance
    #    config = {
    #      grafana: {
    #        host: '192.168.33.5',
    #        port: 3000,
    #        url_path: '/grafana',
    #        ssl: false,
    #        timeout: 10,
    #        open_timeout: 10,
    #        debug: true
    #    }
    #
    #    @grafana = Grafana::Client.new(config)
    #
    #
    def initialize( settings )

      raise ArgumentError.new('only Hash are allowed') unless( settings.is_a?(Hash) )
      raise ArgumentError.new('missing settings') if( settings.size.zero? )

      host                = settings.dig(:grafana, :host)          || 'localhost'
      port                = settings.dig(:grafana, :port)          || 3000
      url_path            = settings.dig(:grafana, :url_path)      || ''
      ssl                 = settings.dig(:grafana, :ssl)           || false
      @timeout            = settings.dig(:grafana, :timeout)       || 5
      @open_timeout       = settings.dig(:grafana, :open_timeout)  || 5
      @http_headers       = settings.dig(:grafana, :http_headers)  || {}
      @debug              = settings.dig(:debug)                   || false

      protocoll           = ssl == true ? 'https' : 'http'

      @url = format( '%s://%s:%d%s', protocoll, host, port, url_path )

      raise ArgumentError.new('missing hostname') if( host.nil? )
      raise ArgumentError.new('wrong type. port must be an Integer') unless( port.is_a?(Integer) )
      raise ArgumentError.new('wrong type. url_path must be an String') unless( url_path.is_a?(String) )
      raise ArgumentError.new('wrong type. ssl must be an Boolean') unless( ssl.is_a?(TrueClass) || ssl.is_a?(FalseClass) )
      raise ArgumentError.new("wrong protocoll type. only 'http' or 'https' allowed ('#{protocoll}' giving)") if( %w[http https].include?(protocoll.downcase) == false )
      raise ArgumentError.new('wrong type. timeout must be an Integer') unless( @timeout.is_a?(Integer) )
      raise ArgumentError.new('wrong type. open_timeout must be an Integer') unless( @open_timeout.is_a?(Integer) )

    end

    def self.logger
      @@logger ||= defined?(Logging) ? Logging.logger : Logger.new(STDOUT)
    end

    def self.logger=(logger)
      @@logger = logger
    end

  end

end

