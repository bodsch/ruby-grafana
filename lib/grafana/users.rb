
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


    def user( user_id )

      raise ArgumentError.new(format('wrong type. user \'user_id\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', user_id.class.to_s)) if( user_id.is_a?(String) && user_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'user_id\'') if( user_id.size.zero? )

      if(user_id.is_a?(String))
        user_map = {}
        users.dig('message').each do |d|
#           puts d
          usr_id = d.dig('id').to_i
          user_map[usr_id] = d
        end

#         puts user_map
        user_id = user_map.select { |_k,v| v['login'] == user_id || v['email'] == user_id || v['name'] == user_id }.keys.first
      end

      return { 'status' => 404, 'message' => format( 'No User \'%s\' found', user_id) } if( user_id.nil? )

      endpoint = format( '/api/users/%s', user_id )

#       puts endpoint

      @logger.debug("Getting user by Id #{user_id} (GET #{endpoint})") if @debug
      data = get(endpoint)
      data['id'] = user_id
      data
    end

#     # Get single user by Id
#     # GET /api/users/:id
#     def user_by_id(id)
#
#       raise ArgumentError.new('id must be an Integer') unless( id.is_a?(Integer) )
#
#       endpoint = format( '/api/users/%d', id )
#       @logger.debug("Getting user by Id #{id} (GET #{endpoint})") if @debug
#       get(endpoint)
#     end
#
#     # Get single user by Username(login) or Email
#     # GET /api/users/lookup?loginOrEmail=user@mygraf.com
#     def user( name )
#
#       endpoint = format( '/api/users/lookup?loginOrEmail=%s', URI.escape( name ) )
#       @logger.debug("Get User by Name (GET #{endpoint})") if @debug
#       get( endpoint )
#     end

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
    # PUT /api/users/:id
    def update_user( params = {} )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )

      user_name   = params.dig(:user_name)

      raise ArgumentError.new('missing \'user_name\'') if( user_name.nil? )

      if( !user_name.is_a?(String) && !user_name.is_a?(Integer) )
        raise ArgumentError.new('user_name must be an String (for an Username) or an Integer (for an User Id)')
      end

      usr = user(user_name)

      if  usr.nil? || usr.dig('status').to_i != 200
        return {
          'status' => 404,
          'message' => format('User \'%s\' not found', user_name)
        }
      end

      user_id = usr.dig('id')

      endpoint = format( '/api/users/%d', user_id )

      @logger.debug("Updating user with Id #{user_id}") if @debug

      usr    = usr.deep_string_keys
      params = params.deep_string_keys

      params = usr.merge(params)

      put( endpoint, params.to_json )
    end

    # Get Organisations for user
    # GET /api/users/:id/orgs
    def user_organizations(user)

      if( !user.is_a?(String) && !user.is_a?(Integer) )
        raise ArgumentError.new('user must be an String (for an Dashboard name) or an Integer (for an Dashboard ID)')
      end

      usr = user(user)

      if  usr.nil? || usr.dig('status').to_i != 200
        return {
          'status' => 404,
          'message' => format('User \'%s\' not found', user)
        }
      end

      user_id = usr.dig('id')

      endpoint = format('/api/users/%d/orgs', user_id )
      @logger.debug("Getting organizations for User #{user} (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Switch user context for a specified user
    # POST /api/users/:userId/using/:organizationId

  end
end
