
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

    def request(method_type='GET',endpoint='/',data={})

      raise 'try first login()' if  @api_instance.nil?

      response             = nil
      response_code        = 404
      response_body        = ''

      begin

        case method_type.upcase
        when 'GET'
          response = @api_instance[endpoint].get( @headers )
        when 'POST'
          response = @api_instance[endpoint].post( data, @headers )
        when 'PATCH'
          response = @api_instance[endpoint].patch( data, @headers )
        when 'PUT'
          # response = @api_instance[endpoint].put( data, @headers )
          @api_instance[endpoint].put( data, @headers ) do |response, request, result|

            case response.code
            when 200
              response_body = response.body
              response_code = response.code.to_i
              response_body = JSON.parse(response_body) if response_body.is_a?(String)

              return {
                'status' => response_code,
                'message' => response_body.dig('message').nil? ? 'Successful' : response_body.dig('message')
              }
            when 400
              response_body = response.body
              response_code = response.code.to_i
              raise RestClient::BadRequest
            else
              response.return!(request, result)
            end
          end

        when 'DELETE'
          response = @api_instance[endpoint].delete( @headers )
        else
          @logger.error( "Error: #{__method__} is not a valid request method." )
          return false
        end

        response_code    = response.code.to_i
        response_body    = response.body
        response_headers = response.headers

        if( ( response_code >= 200 && response_code <= 299 ) || ( response_code >= 400 && response_code <= 499 ) )

          result = JSON.parse( response_body )

          if( result.is_a?(Array) )
            r_result= {
              'status' => response_code,
              'message' => result
            }
            return r_result
          end

          result_status = result.dig('status') if( result.is_a?( Hash ) )

          result['message'] = result_status unless( result_status.nil? )
          result['status']  = response_code

          return result
        else

          @logger.error( "#{__method__} #{method_type.upcase} on #{endpoint} failed: HTTP #{response.code} - #{response_body}" )
          @logger.error( @headers )
          @logger.error( JSON.pretty_generate( response_headers ) )

          return JSON.parse( response_body )
        end

      rescue RestClient::BadRequest

        response_body = JSON.parse(response_body) if response_body.is_a?(String)

        return {
          'status' => 400,
          'message' => response_body.dig('message').nil? ? 'Bad Request' : response_body.dig('message')
        }

      rescue RestClient::Unauthorized

        return {
          'status' => 401,
          'message' => format('Not authorized to connect \'%s/%s\' - wrong username or password?', @url, endpoint)
        }

      rescue RestClient::NotFound

        return {
          'status' => 404,
          'message' => 'Not Found'
        }

      rescue RestClient::Conflict

        return {
          'status' => 409,
          'message' => 'Conflict with the current state of the target resource'
        }

      rescue RestClient::PreconditionFailed

        return {
          'status' => 412,
          'message' => 'Precondition failed. The Object probably already exists.'
        }

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
