
module Grafana

  # http://docs.grafana.org/http_api/user/
  #
  module Users

    # Search Users
    # GET /api/users
    def all_users
      endpoint = '/api/users'
      @logger.info("Getting all users (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Get single user by Id
    # GET /api/users/:id
    def user_by_id(id)

      raise ArgumentError.new('id must be an Integer') unless( id.is_a?(Integer) )

      endpoint = format( '/api/users/%d', id )
      @logger.info("Getting user by Id #{id} (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Get single user by Username(login) or Email
    # GET /api/users/lookup?loginOrEmail=user@mygraf.com
    def user_by_name( name )

      endpoint = format( '/api/users/lookup?loginOrEmail=%s', URI::escape( name ) )
      @logger.info("Get User by Name (GET #{endpoint})") if @debug
      get( endpoint )
    end

    #
    #
    def search_for_users_by( search = {} )

      raise ArgumentError.new('search must be an Hash') unless( search.is_a?(Hash) )

      all_users = self.all_users()
      key, value = search.first

      @logger.info("Searching for users matching '#{key}' = '#{value}'") if @debug
      users = []

      all_users.dig('message').each do |u|
        users.push(u) if u.select { |k,v| v == value }.count >= 1
      end
      (users.length >= 1 ? users : false)
    end

    # User Update
    # PUT /api/users/:id
    def update_user( params = {} )

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )

      user_name   = params.dig(:user_name)

      if( !user_name.is_a?(String) && !user_name.is_a?(Integer) )
        raise ArgumentError.new('user_name must be an String (for an Dashboard name) or an Integer (for an Dashboard ID)')
      end

      usr = user_by_id(user_name) if(user_name.is_a?(Integer))
      usr = user_by_name(user_name) if(user_name.is_a?(String))

      return {
        'status' => 404,
        'message' => format('User \'%s\' not found', user_name)
      } if( usr.nil? || usr.dig('status').to_i != 200 )

      user_id = usr.dig('id')

      endpoint = format( '/api/users/%d', user_id )

      @logger.info("Updating user with Id #{user_id}") if @debug

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

      usr = user_by_id(user) if(user.is_a?(Integer))
      usr = user_by_name(user) if(user.is_a?(String))

      return {
        'status' => 404,
        'message' => format('User \'%s\' not found', user)
      } if( usr.nil? || usr.dig('status').to_i != 200 )

      user_id = usr.dig('id')

      endpoint = format('/api/users/%d/orgs', user_id )
      @logger.info("Getting organizations for User #{user} (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Switch user context for a specified user
    # POST /api/users/:userId/using/:organizationId

  end
end
