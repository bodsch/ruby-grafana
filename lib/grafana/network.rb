
module Grafana

  module Network

    def get( endpoint )

      request( 'GET', endpoint )
    end

    def post( endpoint, data )

      request( 'POST', endpoint, data )
    end

    def put( endpoint, data )

      request( 'PUT', endpoint, data )
    end

    def patch( endpoint, data )

      request( 'PATCH', endpoint, data )
    end

    def delete( endpoint )

      request( 'DELETE', endpoint )
    end

    def request( method_type = 'GET', endpoint = '/', data = {} )

#       @logger.debug( "request( #{method_type}, #{endpoint}, data )" )
#       @logger.debug( "#{@headers}" )

      if( @api_instance.nil? )
        raise 'try first login()'
      end

      result_codes = {
        200 => 'created',
        400 => 'Errors (invalid json, missing or invalid fields, etc)',
        401 => 'Unauthorized',
        403 => 'Forbidden',
        412 => 'Precondition failed'
      }

      response             = nil
      response_code        = 404
      response_body        = ''
      response_headers     = ''
      response_raw_headers = ''

      begin

        case method_type.upcase
        when 'GET'
          response = @api_instance[endpoint].get( @headers )
        when 'POST'
          response = @api_instance[endpoint].post( data, @headers )
        when 'PATCH'
          response = @api_instance[endpoint].patch( data, @headers )
        when 'PUT'
          response = @api_instance[endpoint].put( data, @headers )
        when 'DELETE'
          response = @api_instance[endpoint].delete( @headers )
        else
          @logger.error( "Error: #{__method__} is not a valid request method." )
          return false
        end

        response_code    = response.code.to_i
        response_body    = response.body
        response_headers = response.headers

#         @logger.debug( response.inspect )
#        @logger.debug( response_code )
#        @logger.debug( response_body )
#        @logger.debug( JSON.pretty_generate( response_headers ) )

        if( ( response_code >= 200 && response_code <= 299 ) || ( response_code >= 400 && response_code <= 499 ) )

          result = JSON.parse( response_body )

#           @logger.debug( JSON.pretty_generate( result ) )

          if( result.is_a?(Array) )

            r_result= {
              'status' => response_code,
              'message' => result
            }

            return r_result
          end

          result_status = result.dig('status') if( result.is_a?( Hash ) )

          result['message'] = result_status if( result_status != nil )
          result['status']  = response_code

          return result
        else

          @logger.error( "#{__method__} #{method_type.upcase} on #{endpoint} failed: HTTP #{response.code} - #{response_body}" )
          @logger.error( @headers )
          @logger.error( JSON.pretty_generate( response_headers ) )

          return JSON.parse( response_body )
        end

      rescue RestClient::Unauthorized => e

        @logger.error( 'Not authorized to connect \'%s/%s\' - wrong username or password?', @url, endpoint )

        return false

      rescue RestClient::NotFound => e

        return {
          status: 404,
          message: 'not found'
        }

      rescue RestClient::Conflict => e

        return {
          status: 409,
          message: 'Conflict'
        }

      rescue RestClient::PreconditionFailed => e

        return {
          status: 412,
          message: 'Precondition failed. the dashboard probably already exists.'
        }

      rescue RestClient::Exception => e

        @logger.error( "Error: #2 #{__method__} #{method_type.upcase} on #{endpoint} error: '#{e}'" )
        @logger.error( e.to_s )
        @logger.error( data )
        @logger.error( @headers )
        @logger.error( JSON.pretty_generate( response_headers ) )

        return false

      rescue RestClient::ExceptionWithResponse => e

        @logger.error( "Error: #{__method__} #{method_type.upcase} on #{endpoint} error: '#{e}'" )
        @logger.error( data )
        @logger.error( @headers )
        @logger.error( JSON.pretty_generate( response_headers ) )

        return false

      end

    end

  end

end
