
module Grafana

  # All Admin API Calls found under http://docs.grafana.org/http_api/admin/
  #
  # The Admin HTTP API does not currently work with an API Token.
  # API Tokens are currently only linked to an organization and an organization role.
  #
  # They cannot be given the permission of server admin, only users can be given that permission.
  # So in order to use these API calls you will have to use Basic Auth and the Grafana user must
  # have the Grafana Admin permission.
  #
  # (The default admin user is called admin and has permission to use this API.)
  #
  module Admin

    # get all admin settings
    #
    # @example
    #    admin_settings
    #
    # @return [Hash]
    #
    def admin_settings
      logger.debug('Getting admin settings') if @debug
      get('/api/admin/settings')
    end

    # get all grafana statistics
    #
    # @example
    #    admin_stats
    #
    # @return [Hash]
    #
    def admin_stats
      logger.debug('Getting admin statistics') if @debug
      get('/api/admin/stats')
    end

    # set User Permissions
    #
    # Only works with Basic Authentication (username and password).
    #
    # @param [Hash] params
    # @option params [String] name login or email for user
    # @option params [Mixed] permissions string or hash to change permissions
    #  [String] only 'Viewer', 'Editor', 'Read Only Editor' or 'Admin' allowed
    #  [Hash] grafana_admin: true or false
    #
    # @example
    #    update_user_permissions( user_name: 'admin', permissions: 'Viewer' )
    #    update_user_permissions( user_name: 'admin', permissions: { grafana_admin: true } )
    #
    # @return [Hash]
    #
    def update_user_permissions( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing params') if( params.size.zero? )

      user_name   = validate( params, required: true, var: 'user_name', type: String )
      permissions = validate( params, required: true, var: 'permissions' )
      raise ArgumentError.new(format('wrong type. \'permissions\' must be an String or Hash, given %s', permissions.class.to_s ) ) unless( permissions.is_a?(String) || permissions.is_a?(Hash) )
      valid_roles    = ['Viewer', 'Editor', 'Read Only Editor', 'Admin']

      downcased = Set.new valid_roles.map(&:downcase)

      if( permissions.is_a?(String) )
        unless( downcased.include?( permissions.downcase ) )
          message = format( 'wrong permissions. Must be one of %s, given \'%s\'', valid_roles.join(', '), permissions )
          return {
            'status' => 404,
            'name' => user_name,
            'permissions' => permissions,
            'message' => message
          }
        end
      end

      if( permissions.is_a?(Hash) && !permissions.dig(:grafana_admin).nil? )
        grafana_admin = permissions.dig(:grafana_admin)
        unless( grafana_admin.is_a?(Boolean) )
          message = 'Grafana admin permission must be either \'true\' or \'false\''
          return {
            'status' => 404,
            'name' => user_name,
            'permissions' => permissions,
            'message' => message
          }
        end
      end

      usr = user(user_name)

      if( usr.nil? || usr.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => format('User \'%s\' not found', user_name)
        }
      end

      user_id = usr.dig('id')

      if( permissions.is_a?(Hash) )

        endpoint = format( '/api/admin/users/%s/permissions', user_id )
        payload = {
          isGrafanaAdmin: grafana_admin
        }

        logger.debug("Updating user id #{user_id} permissions (PUT #{endpoint})") if @debug
        logger.debug(payload.to_json) if(@debug)

        return put(endpoint, payload.to_json )
      end

      org = current_organization

      if( org.nil? || org.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => 'No current Organization found'
        }
      end

      endpoint = format( '/api/orgs/%s/users/%s', org.dig('id'), user_id )
      logger.debug( format( 'Updating user id %s permissions', user_id ) ) if @debug

      payload = {
        name: org.dig('name'),
        orgId: org.dig('id'),
        role: permissions.downcase.capitalize
      }

      logger.debug("Updating user id #{user_id} permissions (PATCH #{endpoint})") if @debug
      logger.debug(payload.to_json) if(@debug)

      patch( endpoint, payload.to_json )
    end

    # Delete an Global User
    #
    # Only works with Basic Authentication (username and password).
    #
    # @param [Mixed] user_id Username (String) or Userid (Integer) for delete User
    #   The Admin User can't be delete!
    #
    # @example
    #    delete_user( 1 )
    #    delete_user( 'foo' )
    #
    # @return [Hash]
    #
    def delete_user( user_id )

      raise ArgumentError.new(format('wrong type. user \'user_id\' must be an String (for an User name) or an Integer (for an User Id), given \'%s\'', user_id.class.to_s)) if( user_id.is_a?(String) && user_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'user_id\'') if( user_id.size.zero? )

      if(user_id.is_a?(String))
        usr = user(user_id)
        user_id = usr.dig('id')
      end

      if( user_id.nil? )
        return {
          'status' => 404,
          'message' => format( 'No User \'%s\' found', user_id)
        }
      end

      if( user_id.is_a?(Integer) && user_id.to_i.zero? )
        return {
          'status' => 403,
          'message' => format( 'Can\'t delete user id %d (admin user)', user_id )
        }
      end

      endpoint = format('/api/admin/users/%d', user_id )
      logger.debug( "Deleting user id #{user_id} (DELETE #{endpoint})" ) if @debug

      delete( endpoint )
    end

    # Create new user
    #
    # Only works with Basic Authentication (username and password).
    #
    # @param [Hash] params
    # @option params [String] user_name name for user (required)
    # @option params [String] email email for user (required)
    # @option params [String] login_name login name for user (optional)  - if 'login_name' is not set, 'name' is used
    # @option params [String] password password (required)
    #
    # @example
    #    params = {
    #      user_name: 'foo',
    #      email: 'foo@bar.com',
    #      password: 'pass'
    #    }
    #    add_user( params )
    #
    # @return [Hash|FalseClass]
    #
    def add_user( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing params') if( params.size.zero? )

      user_name = validate( params, required: true, var: 'user_name', type: String )
      email = validate( params, required: true, var: 'email', type: String )
      login_name = validate( params, required: false, var: 'login_name', type: String ) || user_name
      password = validate( params, required: true, var: 'password', type: String )

      usr = user(user_name)

      if( usr.nil? || usr.dig('status').to_i == 200 )
        return {
          'status' => 404,
          'id' => usr.dig('id'),
          'email' => usr.dig('email'),
          'name' => usr.dig('name'),
          'login' => usr.dig('login'),
          'message' => format( 'user \'%s\' with email \'%s\' exists', user_name, email )
        }
      end

      #
      payload = {
        name: user_name,
        email: email,
        login: login_name,
        password: password
      }
      payload.reject!{ |_k, v| v.nil? }

      endpoint = '/api/admin/users'
      logger.debug("Create user #{user_name} (PUT #{endpoint})") if @debug
      logger.debug(payload.to_json) if(@debug)

      post( endpoint, payload.to_json)
    end

    # Change Password for User
    #
    # Only works with Basic Authentication (username and password).
    # Change password for a specific user.
    #
    # @param [Hash] params
    # @option params [String] user_name user_name for user (required)
    # @option params [String] password password to set (required)
    #
    # @example
    #    params = {
    #      user_name: 'foo',
    #      password: 'bar'
    #    }
    #    update_user_password( params )
    #
    # @return [Hash]
    #
    def update_user_password( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing params') if( params.size.zero? )

      user_name = validate( params, required: true, var: 'user_name', type: String )
      password  = validate( params, required: true, var: 'password', type: String )

      usr = user(user_name)

      return { 'status' => 404, 'message' => format('User \'%s\' not found', user_name) } if( usr.nil? || usr.dig('status').to_i != 200 )

      user_id = usr.dig('id')

      endpoint = format( '/api/admin/users/%d/password', user_id )
      payload = {
        password: password
      }

      logger.debug("Updating password for user id #{user_id} (PUT #{endpoint})") if @debug
      logger.debug(payload.to_json) if(@debug)

      put( endpoint, payload.to_json )
    end

    # Pause all alerts
    #
    # Only works with Basic Authentication (username and password).
    #
    # @example
    #    pause_all_alerts
    #
    # @return [Hash]
    #
    def pause_all_alerts

      endpoint = '/api/admin/pause-all-alerts'
      logger.debug("pause all alerts (POST #{endpoint})") if @debug

      post( endpoint, nil )
    end

  end

end
