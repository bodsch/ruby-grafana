
module Grafana

  # Abstract base class for Login.
  #
  module Login

    # Login into Grafana
    #
    # @param [Hash] params
    # @option params [String] username username for the login
    # @option params [String] password password for the login
    # @option params [Integer] max_retries (2) maximum retries
    # @option params [Integer] sleep_between_retries (5) sleep seconds between retries
    #
    # @example
    #    login( username: 'admin', password: 'admin' )
    #    login( username: 'admin', password: 'admin', max_retries: 10, sleep_between_retries: 8 )
    #
    # @return [Hash]
    #
    def login( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing params') if( params.size.zero? )

      username = validate( params, required: true, var: 'username', type: String )
      password = validate( params, required: true, var: 'password', type: String )
      max_retries = validate( params, required: false, var: 'max_retries', type: Integer ) || 2
      sleep_between_retries = validate( params, required: false, var: 'sleep_between_retries', type: Integer ) || 5

      begin
        @api_instance = RestClient::Resource.new(
          @url,
          timeout: @timeout.to_i,
          open_timeout: @open_timeout.to_i,
          headers: @http_headers,
          verify_ssl: false
        )
      rescue => e
        logger.error( e ) if @debug
        logger.debug( e.backtrace.join("\n") ) if @debug
        false
      end

      request_data = { 'User' => username, 'Password' => password }

      if( @api_instance )
        retried ||= 0
        response_cookies  = ''
        @headers          = {}

        begin
          logger.debug('Attempting to establish user session') if @debug

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
            @username = username
            @password = password
          end

        rescue SocketError
          raise format( 'Maximum retries (%d) against \'%s/login\' reached. Giving up ...', max_retries, @url ) unless( retried < max_retries )

          retried += 1
          logger.debug( format( 'cannot login, socket error (retry %d / %d)', retried, max_retries ) ) if @debug
          sleep( sleep_between_retries )
          retry

        rescue RestClient::Unauthorized
          logger.debug( request_data.to_json ) if @debug
          raise format( 'Not authorized to connect \'%s\' - wrong username or password?', @url )

        rescue RestClient::BadGateway
          raise format( 'Maximum retries (%d) against \'%s/login\' reached. Giving up ...', max_retries, @url ) unless( retried < max_retries )

          retried += 1
          logger.debug( format( 'cannot login, connection refused (retry %d / %d)', retried, max_retries ) ) if @debug
          sleep( sleep_between_retries )
          retry

        rescue Errno::ECONNREFUSED
          raise format( 'Maximum retries (%d) against \'%s/login\' reached. Giving up ...', max_retries, @url ) unless( retried < max_retries )

          retried += 1
          logger.debug( format( 'cannot login, connection refused (retry %d / %d)', retried, max_retries ) ) if @debug
          sleep( sleep_between_retries )
          retry

        rescue Errno::EHOSTUNREACH
          raise format( 'Maximum retries (%d) against \'%s/login\' reached. Giving up ...', max_retries, @url ) unless( retried < max_retries )

          retried += 1
          logger.debug( format( 'cannot login, host unreachable (retry %d / %d)', retried, max_retries ) ) if @debug
          sleep( sleep_between_retries )
          retry

        rescue => error
          raise format( 'Maximum retries (%d) against \'%s/login\' reached. Giving up ...', max_retries, @url ) unless( retried < max_retries )

          retried += 1
          logger.error( error )
          logger.debug( format( 'cannot login (retry %d / %d)', retried, max_retries ) ) if @debug
          sleep( sleep_between_retries )
          retry
        end

        logger.debug('User session initiated') if @debug
        return true
      end
      false
    end

    # Renew session based on remember cookie
    #
    # @example
    #    ping_session
    #
    # @return [Hash]
    #
    def ping_session
      logger.debug( "Pinging current session (GET #{endpoint})" ) if @debug
      endpoint = '/api/login/ping'
      get( endpoint )
    end


    def headers
      @headers
    end
  end

end
