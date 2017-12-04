
module Grafana

  # All Admin API Calls found under http://docs.grafana.org/http_api/admin/
  #
  # The Admin HTTP API does not currently work with an API Token.
  # API Tokens are currently only linked to an organization and an organization role.
  # They cannot be given the permission of server admin, only users can be given that permission.
  # So in order to use these API calls you will have to use Basic Auth and the Grafana user must
  # have the Grafana Admin permission.
  # (The default admin user is called admin and has permission to use this API.)
  #
  module Admin

    # get all admin settings
    #
    # @return [Hash]
    #
    def admin_settings
      @logger.debug('Getting admin settings') if @debug
      get('/api/admin/settings')
    end

    # get all grafana statistics
    #
    # @return [Hash]
    #
    def admin_stats
      @logger.debug('Getting admin statistics') if @debug
      get('/api/admin/stats')
    end

    # change user permissions
    #
    # @param [Hash] params
    # @option params [String] :name login or email for user
    # @option params [Mixed] :permissions string or hash to change permissions
    #  [String] only 'Viewer', 'Editor', 'Read Only Editor' or 'Admin' allowed
    #  [Hash] grafana_admin: true or false
    #
    # @example
    #    update_user_permissions( name: 'admin', permissions: 'Viewer' )
    #    update_user_permissions( name: 'admin', permissions: { grafana_admin: true } )
    #
    # @return [Hash]
    #
    def update_user_permissions( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )

      name  = params.dig(:name)
      permissions  = params.dig(:permissions)

      raise ArgumentError.new('missing \'name\'') if( name.nil? )
      raise ArgumentError.new(format('wrong type. \'permissions\' must be an String or Hash, given %s', permissions.class.to_s ) ) unless( permissions.is_a?(String) || permissions.is_a?(Hash) )

      valid_perms = ['Viewer','Editor','Read Only Editor','Admin']

      if( permissions.is_a?( String ) && !valid_perms.include?(permissions) )

        message = format( 'user permissions must be one of %s, given \'%s\'', valid_perms.join(', '), permissions )
        logger.warn( message )

        return {
          'status' => 404,
          'name' => name,
          'permissions' => permissions,
          'message' => message
        }

      elsif( permissions.is_a?(Hash) && !permissions.dig(:grafana_admin).nil? )

        grafana_admin = permissions.dig(:grafana_admin)

        unless( grafana_admin.is_a?(Boolean) )

          message = 'Grafana admin permission must be either true or false'
          logger.warn( message )

          return {
            'status' => 404,
            'name' => name,
            'permissions' => permissions,
            'message' => message
          }
        end
      end

      usr = user_by_name(name)

      if( usr.nil? || usr.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => format('User \'%s\' not found', name)
        }
      end

      user_id = usr.dig('id')

      if( permissions.is_a?(Hash) )

        endpoint = format( '/api/admin/users/%s/permissions', user_id )

        logger.debug("Updating user id #{user_id} permissions (PUT #{endpoint})") if @debug

        grafana_admin = permissions.dig(:grafana_admin)

        return put(endpoint, { 'isGrafanaAdmin' => grafana_admin }.to_json )
      else

        org = current_organization

        endpoint = format( '/api/orgs/%s/users/%s', org['id'], user_id )
        logger.debug( format( 'Updating user id %s permissions', user_id ) ) if @debug

        user = {
          'name' => org.dig('name'),
          'orgId' => org.dig('id'),
          'role' => permissions.downcase.capitalize
        }

        logger.debug("Updating user id #{user_id} permissions (PATCH #{endpoint})") if @debug

        return patch( endpoint, user.to_json )
      end
    end

    # delete an global user
    #
    # @param [Mixed] id Username or Userid for delete User
    #   The Admin User can't be delete!
    #
    # @example
    #    delete_user( 1 )
    #    delete_user( 'foo' )
    #
    # @return [Hash]
    #
    def delete_user( id )

      raise ArgumentError.new('user id must be an String (for an User name) or an Integer (for an User Id)') if( id.is_a?(String) && id.is_a?(Integer) )

      if(id.is_a?(Integer))
        user_id = id if user_by_id(id).size >= 0
      end

      if(id.is_a?(String))
        usr = user_by_name(id)
        user_id = usr.dig('id')
      end

      if( user_id.nil? )
        return {
          'status' => 404,
          'message' => format( 'No User \'%s\' found', id)
        }
      end

      if( id.is_a?(Integer) && id.to_i.zero? )
        return {
          'status' => 403,
          'message' => format( 'Can\'t delete user id %d (admin user)', id )
        }
      end

      endpoint = format('/api/admin/users/%d', user_id )
      @logger.debug( "Deleting user id #{user_id} (DELETE #{endpoint})" ) if @debug

      delete( endpoint )
    end

    # add an global user
    #
    # @param [Hash] params
    # @option params [String] :name login or email for user
    # @option params [String] :email
    # @option params [String] :login
    # @option params [String] :password
    #
    # @example
    #
    #
    #
    # @return [Hash]
    #
    def add_user( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )

      name       = params.dig(:name)
      email      = params.dig(:email)
      login_name = params.dig(:login) || name
      password   = params.dig(:password)

#       name    = validate( params, required: true, var: 'name', type: String )
#       email    = validate( params, required: true, var: 'email', type: String )
#       login_name    = validate( params, required: true, var: 'login_name', type: String ) || name
#       password    = validate( params, required: true, var: 'password', type: String )

      raise ArgumentError.new('missing name')     if( name.nil? )
      raise ArgumentError.new('missing email')    if( email.nil? )
      raise ArgumentError.new('missing login')    if( login_name.nil? )
      raise ArgumentError.new('missing password') if( password.nil? )

      usr = user_by_name(name)

      if( usr.nil? || usr.dig('status').to_i == 200 )
        return {
          'status' => 404,
          'id' => usr.dig('id'),
          'email' => usr.dig('email'),
          'name' => usr.dig('name'),
          'login' => usr.dig('login'),
          'message' => format( 'user \'%s\' with email \'%s\' exists', name, email )
        }
      end

      endpoint = '/api/admin/users'
      @logger.debug("Create user #{name} (PUT #{endpoint})") if @debug
      @logger.debug( format( 'Data: %s', params.to_s ) ) if @debug
      post( endpoint, params.to_json)
    end


    # Password for User
    # PUT /api/admin/users/:id/password
    def update_user_password( params ) #user_id,password)

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )

      user_name = params.dig(:user_name)
      password  = params.dig(:password)

      raise ArgumentError.new('missing user_name') if( user_name.nil? )
      raise ArgumentError.new('missing password') if( password.nil? )

      usr = user_by_name(user_name)

      if  usr.nil? || usr.dig('status').to_i != 200
        return {
          'status' => 404,
          'message' => format('User \'%s\' not found', user_name)
        }
      end

      user_id = usr.dig('id')

      endpoint = format( '/api/admin/users/%d/password', user_id )
      @logger.debug("Updating password for user id #{user_id} (PUT #{endpoint})") if @debug

      put( endpoint, { password: password }.to_json )
    end

    # Pause all alerts
    # POST /api/admin/pause-all-alerts

  end

end
