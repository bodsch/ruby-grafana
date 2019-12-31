
require 'ruby_dig' if RUBY_VERSION < '2.3'

require 'rest-client'
require 'json'
require 'timeout'

require_relative 'logging'
require_relative 'version'
require_relative 'auth'
require_relative 'validator'
require_relative 'login'
require_relative 'network'
require_relative 'tools'
require_relative 'admin'
require_relative 'annotations'
require_relative 'preferences'
require_relative 'user'
require_relative 'users'
require_relative 'teams'
require_relative 'datasource'
require_relative 'organization'
require_relative 'organizations'
require_relative 'dashboard'
require_relative 'dashboard_versions'
require_relative 'dashboard_permissions'
require_relative 'snapshot'
require_relative 'alerts'
require_relative 'folder'
require_relative 'folder_permissions'
require_relative 'folder_and_dashboard_search'
require_relative 'playlist'

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
    include Grafana::Auth
    include Grafana::Validator
    include Grafana::Login
    include Grafana::Network
    include Grafana::Tools
    include Grafana::Admin
    include Grafana::Annotations
    include Grafana::Preferences
    include Grafana::User
    include Grafana::Users
    include Grafana::Teams
    include Grafana::Datasource
    include Grafana::Organization
    include Grafana::Organizations
    include Grafana::Dashboard
    include Grafana::DashboardVersions
    include Grafana::DashboardPermissions
    include Grafana::Snapshot
    include Grafana::Alerts
    include Grafana::Folder
    include Grafana::FolderPermissions
    include Grafana::FolderSearch
    include Grafana::Playlist

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
      @api_user           = settings.dig(:grafana, :api, :user)    || 'admin'
      @api_password       = settings.dig(:grafana, :api, :password)
      @http_headers       = settings.dig(:grafana, :http_headers)  || { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
      @debug              = settings.dig(:debug)                   || false

      @debug = true
      @headers            = {}

      # Token Support for Grafana 6
      @api_key            = nil
      @api_token_name     = settings.dig(:grafana, :api, :token, :name ) || (0..10).to_a.map{|_a| rand(16).to_s(16)}.join
      @api_token_lifetime = settings.dig(:grafana, :api, :token, :lifetime ) || 0

      raise ArgumentError.new('missing \'host\'') if( host.nil? )

      raise ArgumentError.new(format('wrong type. \'port\' must be an Integer, given \'%s\'', port.class.to_s)) unless( port.is_a?(Integer) )
      raise ArgumentError.new(format('wrong type. \'url_path\' must be an String, given \'%s\'', url_path.class.to_s)) unless( url_path.is_a?(String) )
      raise ArgumentError.new(format('wrong type. \'ssl\' must be an Boolean, given \'%s\'', ssl.class.to_s)) unless( ssl.is_a?(Boolean) )
      raise ArgumentError.new(format('wrong type. \'timeout\' must be an Integer, given \'%s\'', @timeout.class.to_s)) unless( @timeout.is_a?(Integer) )
      raise ArgumentError.new(format('wrong type. \'open_timeout\' must be an Integer, given \'%s\'', @open_timeout.class.to_s)) unless( @open_timeout.is_a?(Integer) )

      protocoll = ssl == true ? 'https' : 'http'

      @url      = format( '%s://%s:%d%s', protocoll, host, port, url_path )

      @api_instance = create_instance
    end


    def create_instance

#       logger.debug( "create_instance" )
#       logger.debug( "@api_key: #{@api_key} #{@api_key.class}" )

      params = { timeout: @timeout.to_i, open_timeout: @open_timeout.to_i, headers: @http_headers, verify_ssl: false }
      params = { timeout: @timeout.to_i, open_timeout: @open_timeout.to_i, headers: @http_headers, verify_ssl: false, user: @api_user, password: @api_password } if( @api_key.nil? )

#       logger.debug( "params: #{params}" )

      begin
        @api_instance = RestClient::Resource.new( @url, params )
      rescue => error
        logger.error( error ) # if @debug
        logger.debug( e.backtrace.join("\n") ) #if @debug
        false
      end
    end


    # Get Settings
    #
    # http://docs.grafana.org/http_api/other/#get-settings
    #
    def settings
      endpoint = '/api/frontend/settings'
      @logger.debug("Getting all settings (GET #{endpoint})") if @debug
      get(endpoint)
    end


    def version
      s = settings

      status = s.dig('status')
      if( status.to_i == 200 )
        @version =  s.dig('buildInfo','version')
        @major_version = @version.split('.').first.to_i

        { version: @version, major_version: @major_version }
      else
        s
      end
    end


#    def self.logger
#      @@logger ||= defined?(Logging) ? Logging.logger : Logger.new(STDOUT)
#    end
#
#    def self.logger=(logger)
#      @@logger = logger
#    end

  end

end

