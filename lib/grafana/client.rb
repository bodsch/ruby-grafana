
require 'ruby_dig' if RUBY_VERSION < '2.3'

require 'rest-client'
require 'json'
require 'timeout'
require 'logger'

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

module Grafana
  # Abstract base class for the API calls.
  # Provides some helper methods
  #
  # @author Bodo Schulz
  #
  class Client

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

      protocoll               = ssl == true ? 'https' : 'http'

      @url = format( '%s://%s:%d%s', protocoll, host, port, url_path )

      @logger = Logger.new(STDOUT)

      raise ArgumentError.new('missing hostname') if( host.nil? )
      raise ArgumentError.new('wrong type. port must be an Integer') unless( port.is_a?(Integer) )
      raise ArgumentError.new('wrong type. url_path must be an String') unless( url_path.is_a?(String) )
      raise ArgumentError.new('wrong type. ssl must be an Boolean') unless( ssl.is_a?(TrueClass) || ssl.is_a?(FalseClass) )
      raise ArgumentError.new("wrong protocoll type. only 'http' or 'https' allowed ('#{protocoll}' giving)") if( %w[http https].include?(protocoll.downcase) == false )
      raise ArgumentError.new('wrong type. timeout must be an Integer') unless( @timeout.is_a?(Integer) )
      raise ArgumentError.new('wrong type. open_timeout must be an Integer') unless( @open_timeout.is_a?(Integer) )

    end


  end

end

