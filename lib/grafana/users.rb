
module Grafana

  # http://docs.grafana.org/http_api/user/
  #
  module Users

    # All Users
    #
    # @example
    #    all_users
    #
    # @return [Hash]
    #
    def users
      endpoint = '/api/users'
      @logger.debug("Getting all users (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Get a single user by Id or Name
    #
    # @param [Mixed] user_id Username (String) or Userid (Integer)
    #
    # @example
    #    user( 1 )
    #    user( 'foo' )
    #
    # @return [Hash]
    #
    def user( user_id )

      raise ArgumentError.new(format('wrong type. user \'user_id\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', user_id.class.to_s)) if( user_id.is_a?(String) && user_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'user_id\'') if( user_id.size.zero? )

      if(user_id.is_a?(String))
        user_map = {}
        users.dig('message').each do |d|
          usr_id = d.dig('id').to_i
          user_map[usr_id] = d
        end

        user_id = user_map.select { |_k,v| v['login'] == user_id || v['email'] == user_id || v['name'] == user_id }.keys.first
      end

      return { 'status' => 404, 'message' => format( 'No User \'%s\' found', user_id) } if( user_id.nil? )

      endpoint = format( '/api/users/%s', user_id )

      @logger.debug("Getting user by Id #{user_id} (GET #{endpoint})") if @debug
      data = get(endpoint)
      data['id'] = user_id
      data
    end

    # search users with parameters
    #
    # @example
    #    search_for_users_by( isAdmin: true )
    #    search_for_users_by( login: 'foo' )
    #
    # @return [Array of Hashes] or false
    #
    def search_for_users_by( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      all_users = users
      key, value = params.first

      logger.debug("Searching for users matching '#{key}' = '#{value}'") if @debug
      users = []
      all_users.dig('message').each do |u|
        users.push(u) if u.select { |_k,v| v == value }.count >= 1
      end

      (users.length >= 1 ? users : nil)
    end

    # User Update
    #
    # @param [Hash] params
    # @option params [String] email
    # @option params [String] user_name
    # @option params [String] login_name
    # @option params [String] theme
    #
    # @example
    #    params = {
    #      email:'user@mygraf.com',
    #      user_name:'User2',
    #      login_name:'user',
    #      theme: 'light'
    #    }
    #    update_user( params )
    #
    # @return [Hash]
    #
    # PUT /api/users/:id
    def update_user( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )

      user_name  = validate( params, required: true, var: 'user_name', type: String )
      email      = validate( params, required: true, var: 'email', type: String )
      login_name = validate( params, required: false, var: 'login_name', type: String ) || user_name
      theme      = validate( params, required: false, var: 'theme', type: String )

      usr = user(user_name)

      return { 'status' => 404, 'message' => format('User \'%s\' not found', user_name) } if( usr.nil? || usr.dig('status').to_i != 200 )

      user_id = usr.dig('id')

      endpoint = format( '/api/users/%d', user_id )
      payload = {
        email: email,
        name: user_name,
        login: login_name,
        theme: theme
      }
      payload.reject!{ |_k, v| v.nil? }

      @logger.debug("Updating user with Id #{user_id}") if @debug

      usr     = usr.deep_string_keys
      payload = payload.deep_string_keys

      payload = usr.merge(payload)

      put( endpoint, payload.to_json )
    end

    # Get Organisations for user
    #
    # @param [Mixed] user_id Username (String) or Userid (Integer)
    #
    # @example
    #    user_organizations( 1 )
    #    user_organizations( 'foo' )
    #
    # @return [Hash]
    #
    def user_organizations( user_id )

      raise ArgumentError.new(format('wrong type. user \'user_id\' must be an String (for an Username) or an Integer (for an Userid), given \'%s\'', user_id.class.to_s)) if( user_id.is_a?(String) && user_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'user_id\'') if( user_id.size.zero? )

      usr = user(user_id)

      return { 'status' => 404, 'message' => format('User \'%s\' not found', user_id) } if( usr.nil? || usr.dig('status').to_i != 200 )

      user_id = usr.dig('id')

      endpoint = format('/api/users/%d/orgs', user_id )
      @logger.debug("Getting organizations for User #{user_id} (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Switch user context for a specified user
    # POST /api/users/:userId/using/:organizationId

  end
end
