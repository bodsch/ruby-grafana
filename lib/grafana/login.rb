
module Grafana

  module Login

    def login( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing params') if( params.size.zero? )

      @logger.debug( "Grafana::Login.login( #{params} )" ) if( @debug )

      user                = params.dig(:user)
      password            = params.dig(:password)
      max_retries         = params.dig(:max_retries) || 2
      sleep_between_retries = params.dig(:sleep_between_retries) || 5

      raise ArgumentError.new('wrong type. user must be an String') if( user.nil? )
      raise ArgumentError.new('wrong type. password must be an String') if( password.nil? )

      begin
        if( @debug )
          @logger.debug("Initializing API client #{@url}")
          @logger.debug("Headers: #{@http_headers}")
          @logger.info( sprintf( 'try to connect our grafana endpoint ... ' ) )
        end

        @api_instance = RestClient::Resource.new(
          @url,
          timeout: @timeout.to_i,
          open_timeout: @open_timeout.to_i,
          headers: @http_headers,
          verify_ssl: false
        )
      rescue => e
        @logger.error( e ) if @debug
        @logger.debug( e.backtrace.join("\n") ) if @debug
        false
      end

      request_data = {
        'User'     => user,
        'Password' => password
      }

      if( @api_instance )
        retried ||= 0
        response_cookies  = ''
        @headers          = {}

        begin
          @logger.debug('Attempting to establish user session') if @debug

          response = @api_instance['/login'].post(
            request_data.to_json,
            content_type: 'application/json; charset=UTF-8'
          )

          response_cookies  = response.cookies
          response_code     = response.code.to_i

          if( response_code == 200 )

            @headers = {
              content_type: 'application/json',
              accept: 'application/json',
              cookies: response_cookies
            }
          end

        rescue SocketError
          if( retried < max_retries )
            retried += 1
            @logger.debug( format( 'cannot login, socket error (retry %d / %d)', retried, max_retries ) ) if @debug
            sleep( sleep_between_retries )
            retry
          else
            raise format( 'Maximum retries (%d) against \'%s/login\' reached. Giving up ...', max_retries, @url )
          end

        rescue RestClient::Unauthorized
          @logger.debug( request_data.to_json ) if @debug
          raise format( 'Not authorized to connect \'%s\' - wrong username or password?', @url )

        rescue RestClient::BadGateway
          if( retried < max_retries )
            retried += 1
            @logger.debug( format( 'cannot login, connection refused (retry %d / %d)', retried, max_retries ) ) if @debug
            sleep( sleep_between_retries )
            retry
          else
            raise format( 'Maximum retries (%d) against \'%s/login\' reached. Giving up ...', max_retries, @url )
          end

        rescue Errno::ECONNREFUSED
          if( retried < max_retries )
            retried += 1
            @logger.debug( format( 'cannot login, connection refused (retry %d / %d)', retried, max_retries ) ) if @debug
            sleep( sleep_between_retries )
            retry
          else
            raise format( 'Maximum retries (%d) against \'%s/login\' reached. Giving up ...', max_retries, @url )
          end

        rescue Errno::EHOSTUNREACH
          if( retried < max_retries )
            retried += 1
            @logger.debug( format( 'cannot login, host unreachable (retry %d / %d)', retried, max_retries ) ) if @debug
            sleep( sleep_between_retries )
            retry
          else
            raise format( 'Maximum retries (%d) against \'%s/login\' reached. Giving up ...', max_retries, @url )
          end
        end

        @logger.debug('User session initiated') if @debug

        return true
      end

      false
    end


    def ping_session

      endpoint = '/api/login/ping'

      @logger.debug( "Pinging current session (GET #{endpoint})" ) if @debug

      result = get( endpoint )

      @logger.debug( result ) if @debug

      result
    end
  end

end
