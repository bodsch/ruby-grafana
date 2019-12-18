
module Grafana

  # abstract base class for authentication API
  #
  # https://grafana.com/docs/grafana/latest/http_api/auth/
  #
  # Token
  #   - Currently you can authenticate via an API Token or via a Session cookie (acquired using regular login or oauth).
  #
  # Basic Auth
  #   - If basic auth is enabled (it is enabled by default) you can authenticate your HTTP request via standard
  #     basic auth. Basic auth will also authenticate LDAP users.
  #
  module Auth

    # Auth HTTP resources / actions
    # Api Keys
    #
    # GET /api/auth/keys
    def api_keys

      endpoint = '/api/auth/keys'

      @logger.debug("Attempting to get all existing api keys (GET #{endpoint})") if @debug

      get( endpoint )
    end


    def api_key( api_id )

      if( api_id.is_a?(String) && api_id.is_a?(Integer) )
        raise ArgumentError.new(format('wrong type. API token \'api_id\' must be an String (for an API name) or an Integer (for an API Id), given \'%s\'', api_id.class.to_s))
      end
      raise ArgumentError.new('missing \'api_id\'') if( api_id.size.zero? )

      if(api_id.is_a?(String))
        keys  = api_keys
        keys  = JSON.parse(keys) if(keys.is_a?(String))

#         logger.debug(keys)

        status = keys.dig('status')
        return keys if( status != 200 )

        u = keys.dig('message').detect { |v| v['id'] == api_id || v['name'] == api_id }

#         logger.debug(u)

        return { 'status' => 404, 'message' => format( 'No API token \'%s\' found', api_id ) } if( u.nil? )

        # api_id = u.dig('id') unless(u.nil?)
      end

      { 'status' => 200, 'message' => u }

    end


    # Create API Key
    #
    # POST /api/auth/keys
    # https://grafana.com/docs/grafana/latest/http_api/auth/#create-api-key
    #
    # @param [Hash] params
    # @option params [String] name The key name   - (required)
    # @option params [String] role  Sets the access level/Grafana Role for the key. Can be one of the following values: Viewer, Editor or Admin.   - (required)
    # @option params [Integer] seconds_to_live  Sets the key expiration in seconds.
    #                          It is optional. If it is a positive number an expiration date for the key is set.
    #                          If it is null, zero or is omitted completely (unless api_key_max_seconds_to_live configuration option is set) the key will never expire.
    #
    #
    # @return [Hash]
    #
    # @example:
    #
    def create_api_key( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      name            = validate( params, required: true, var: 'name' )
      role            = validate( params, required: true, var: 'role' )
      seconds_to_live = validate( params, required: false, var: 'seconds_to_live', type: Integer )

      valid_roles     = %w[Viewer Editor Admin]

      # https://stackoverflow.com/questions/9333952/case-insensitive-arrayinclude?answertab=votes#tab-top
      # Do this once, or each time the array changes
      downcased = Set.new valid_roles.map(&:downcase)
      unless( downcased.include?( role.downcase ) )
        return {
          'status' => 404,
          'login_or_email' => login_or_email,
          'role' => role,
          'message' => format( 'wrong role. Role must be one of %s, given \'%s\'', valid_roles.join(', '), role )
        }
      end

      seconds_to_live = 86_400 if seconds_to_live.nil?

      endpoint = '/api/auth/keys'

      data = {
        name: name,
        role: role,
        secondsToLive: seconds_to_live
      }

      data.reject!{ |_k, v| v.nil? }

      payload = data.deep_string_keys
      # payload = existing_ds.merge(payload).deep_symbolize_keys

      logger.debug(payload.to_json)

      @logger.debug("create API token (POST #{endpoint})") #if @debug
      post(endpoint, payload.to_json)

    end

    # Delete API Key
    #
    # DELETE /api/auth/keys/:id
    def delete_api_key( key_id )

      if( key_id.is_a?(String) && key_id.is_a?(Integer) )
        raise ArgumentError.new(format('wrong type. \'key_id\' must be an String (for an API Key name) or an Integer (for an API Key Id), given \'%s\'', key_id.class.to_s))
      end
      raise ArgumentError.new('missing \'key_id\'') if( key_id.size.zero? )

      if(key_id.is_a?(String))
        data = api_keys.select { |_k,v| v['name'] == key_id }
        key_id = data.keys.first if( data )
      end

      return { 'status' => 404, 'message' => format( 'No API key \'%s\' found', key_id) } if( key_id.nil? )

      raise format('API Key can not be 0') if( key_id.zero? )

      endpoint = format('/api/auth/keys/%d', key_id)
      logger.debug("Deleting API key #{key_id} (DELETE #{endpoint})") if @debug

      delete(endpoint)

    end

  end

end
