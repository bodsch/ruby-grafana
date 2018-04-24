
module Grafana

  module Network

    # GET request
    #
    # @param endpoint [String]
    #
    def get( endpoint )
      request( 'GET', endpoint )
    end

    # POST request
    #
    # @param endpoint [String]
    # @param data [Hash]
    #
    def post( endpoint, data )
      request( 'POST', endpoint, data )
    end

    # PUT request
    #
    # @param endpoint [String]
    # @param data [Hash]
    #
    def put( endpoint, data )
      request( 'PUT', endpoint, data )
    end

    # PATCH request
    #
    # @param endpoint [String]
    # @param data [Hash]
    #
    def patch( endpoint, data )
      request( 'PATCH', endpoint, data )
    end

    # DELETE request
    #
    # @param endpoint [String]
    #
    def delete( endpoint )
      request( 'DELETE', endpoint )
    end


    private
    # helper function for all request methods
    #
    # @param method_type [String]
    # @param endpoint [String]
    # @param data [Hash]
    #
    # @example
    #
    #
    # @return [Hash]
    #
    def request( method_type = 'GET', endpoint = '/', data = {} )
#       logger.debug( "request( #{method_type}, #{endpoint}, data )" )
      raise 'try first login()' if @api_instance.nil?

      login( username: @username, password: @password )

      response             = nil
      response_code        = 404
      response_body        = ''

      begin
        case method_type.upcase
        when 'GET'
          response = @api_instance[endpoint].get( headers )
        when 'POST'
          response = @api_instance[endpoint].post( data, headers )
        when 'PATCH'
          response = @api_instance[endpoint].patch( data, headers )
        when 'PUT'
          # response = @api_instance[endpoint].put( data, headers )
          @api_instance[endpoint].put( data, headers ) do |resp, _request, _result|
            response_body = resp.body
            response_code = resp.code.to_i
            response_body = JSON.parse(response_body) if response_body.is_a?(String)

            case response_code
            when 200
              return { 'status' => response_code, 'message' => response_body.dig('message').nil? ? 'Successful' : response_body.dig('message') }
            when 400
              raise RestClient::BadRequest
            when 412
              status  = response_body.dig('status')
              message = response_body.dig('message')
              message += " (#{status})"  unless(status.nil?)
              return { 'status'  => response_code, 'message' => message }
            when 422
              raise RestClient::UnprocessableEntity
            else
#               logger.error( response_code )
#               logger.error( response_body )
              return { 'status' => response_code, 'message' => response_body.dig('message') }
              # response.return! # (request, result)
            end
          end

        when 'DELETE'
          response = @api_instance[endpoint].delete( headers )
        else
          @logger.error( "Error: #{__method__} is not a valid request method." )
          return false
        end

        response_code    = response.code.to_i
        response_body    = response.body
        response_headers = response.headers

#         if( @debug )
#           logger.debug("response_code : #{response_code}" )
#           logger.debug("response_body : #{response_body}" )
#           logger.debug("response_headers : #{response_headers}" )
#         end

        if( ( response_code >= 200 && response_code <= 299 ) || ( response_code >= 400 && response_code <= 499 ) )

          result = JSON.parse( response_body )
          return { 'status' => response_code, 'message' => result } if( result.is_a?(Array) )

          result_status     = result.dig('status') if( result.is_a?( Hash ) )
          result['message'] = result_status unless( result_status.nil? )
          result['status']  = response_code

          return result
        else
          @logger.error( "#{__method__} #{method_type.upcase} on #{endpoint} failed: HTTP #{response.code} - #{response_body}" )
          @logger.error( headers )
          @logger.error( JSON.pretty_generate( response_headers ) )

          return JSON.parse( response_body )
        end

      rescue RestClient::BadRequest
        response_body = JSON.parse(response_body) if response_body.is_a?(String)
        return { 'status' => 400, 'message' => response_body.dig('message').nil? ? 'Bad Request' : response_body.dig('message') }
      rescue RestClient::Unauthorized
        return { 'status' => 401, 'message' => format('Not authorized to connect \'%s/%s\' - wrong username or password?', @url, endpoint) }
      rescue RestClient::Forbidden
        return { 'status' => 403, 'message' => format('The operation is forbidden \'%s/%s\'', @url, endpoint) }
      rescue RestClient::NotFound
        return { 'status' => 404, 'message' => 'Not Found' }
      rescue RestClient::Conflict
        return { 'status' => 409, 'message' => 'Conflict with the current state of the target resource' }
      rescue RestClient::PreconditionFailed
        return { 'status' => 412, 'message' => 'Precondition failed. The Object probably already exists.' }
      rescue RestClient::PreconditionFailed
        return { 'status' => 412, 'message' => 'Precondition failed. The Object probably already exists.' }
      rescue RestClient::ExceptionWithResponse => error
#        logger.error( "Error: #{__method__} #{method_type.upcase} on #{endpoint} error: '#{error}'" )
#        logger.error( "query: #{data}" )
        return { 'status' => 500, 'message' => "Internal Server Error: #{error}" }
      rescue => error
#        logger.error( "Error: #{__method__} #{method_type.upcase} on #{endpoint} error: '#{error}'" )
#        logger.error( "query: #{data}" )
        return { 'status' => 500, 'message' => "Internal Server Error: #{error}" }
      end
    end
  end
end
