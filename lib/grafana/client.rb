
require 'ruby_dig' if RUBY_VERSION < '2.3'

require 'rest-client'
require 'json'
require 'timeout'
require 'logger'

require_relative 'version'
require_relative 'login'
require_relative 'network'
# require_relative 'admin'
# require_relative 'organization'
require_relative 'organizations'

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
#     include Grafana::Admin
#     include Grafana::Organization
    include Grafana::Organizations

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


    def login( params )

      user                = params.dig(:user)
      password            = params.dig(:password)

      raise ArgumentError.new('wrong type. user must be an String') if( user.nil? )
      raise ArgumentError.new('wrong type. password must be an String') if( password.nil? )

      begin

        @logger.info("Initializing API client #{@url}") if @debug
        @logger.info("Headers: #{@http_headers}") if @debug
        @logger.info( sprintf( 'try to connect our grafana endpoint ... ' ) )  if @debug

        @api_instance = RestClient::Resource.new(
          @url,
          timeout: @timeout.to_i,
          open_timeout: @open_timeout.to_i,
          headers: @http_headers,
          verify_ssl: false,
          log: @logger
        )
      rescue => e

        @logger.error( e )
        @logger.debug( e.backtrace.join("\n") )
        false
      end

      request_data = {
        'User'     => user,
        'Password' => password
      }

      if( @api_instance )

#         @logger.debug( @api_instance.inspect ) if @debug

        retried ||= 0
        max_retries = 2

        response_cookies  = ''
        response_code     = 0
        response_body     = ''
        response_header   = ''
        @headers          = {}

        begin

          @logger.info("Attempting to establish user session") if @debug

          response = @api_instance['/login'].post(
            request_data.to_json,
            :content_type => 'application/json; charset=UTF-8'
          )

          response_cookies  = response.cookies
          response_code     = response.code.to_i
          response_body     = response.body
          response_header   = response.headers

          if( response_code == 200 )

            @headers = {
              content_type: 'application/json',
              accept: 'application/json',
              cookies: response_cookies
            }
          end

        rescue RestClient::Unauthorized => e

          @logger.debug( request_data.to_json )
          raise format( 'Not authorized to connect \'%s\' - wrong username or password?', @url )

        rescue Errno::ECONNREFUSED => e

          if( retried < max_retries )
            retried += 1
            @logger.debug( format( 'cannot login, connection refused (retry %d / %d)', retried, max_retries ) )
            sleep( 5 )
            retry
          else

            raise format( 'Maximum retries (%d) against \'%s/login\' reached. Giving up ...', max_retries, @url )
          end

        rescue Errno::EHOSTUNREACH => e

          if( retried < max_retries )
            retried += 1
            @logger.debug( format( 'cannot login, host unreachable (retry %d / %d)', retried, max_retries ) )
            sleep( 5 )
            retry
          else

            raise format( 'Maximum retries (%d) against \'%s/login\' reached. Giving up ...', max_retries, @url )
          end
        end

        @logger.info("User session initiated") if @debug

#         if( @debug )
#           @logger.debug(@headers)
#           @logger.debug( response_code )
#           @logger.debug( response_body )
#           @logger.debug( response_header )
#         end

        return true
      end

      return false
    end

  end

end
