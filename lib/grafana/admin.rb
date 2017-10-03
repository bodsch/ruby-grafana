
module Grafana

  # http://docs.grafana.org/http_api/admin/
  #
  module Admin

    # Settings
    # GET /api/admin/settings
    def admin_settings
      @logger.debug('Getting admin settings') if @debug
      get('/api/admin/settings')
    end

    # Grafana Stats
    # GET /api/admin/stats
    def admin_stats
      @logger.debug('Getting admin statistics') if @debug
      get('/api/admin/stats')
    end

    # Permissions
    # PUT /api/admin/users/:id/permissions
#     def update_user_permissions( id, perm )
#
#       valid_perms = ['Viewer','Editor','Read Only Editor','Admin']
#
#       if( perm.is_a?( String ) && !valid_perms.include?(perm) )
#         logger.warn("Basic user permissions include: #{valid_perms.join(',')}")
#         return false
#       elsif( perm.is_a?( Hash ) &&
#         ( !perm.key?('isGrafanaAdmin') || ![true,false].include?(perm['isGrafanaAdmin']) ) )
#
#         logger.warn('Grafana admin permission must be either true or false')
#
#         return false
#       end
#
#       logger.info("Updating user id #{id} permissions")
#
#       if( perm.is_a?( Hash ) )
#
#         endpoint = "/api/admin/users/#{id}/permissions"
#         logger.info("Updating user id #{id} permissions (PUT #{endpoint})")
#
#         return putRequest(endpoint, {'isGrafanaAdmin' => perm['isGrafanaAdmin']}.to_json)
#       else
#         org = current_org
#         endpoint = "/api/orgs/#{org['id']}/users/#{id}"
#         logger.info("Updating user id #{id} permissions (PUT #{endpoint})")
#         user = {
#           'name' => org['name'],
#           'orgId' => org['id'],
#           'role' => perm.downcase.capitalize
#         }
#         return patchRequest(endpoint, user.to_json)
#       end
#     end

    # Delete global User
    # DELETE /api/admin/users/:id
    def delete_user( id )

      if( id.is_a?(String) && id.is_a?(Integer) )
        raise ArgumentError.new('user id must be an String (for an User name) or an Integer (for an User Id)')
      end

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


    # Global Users
    # POST /api/admin/users
    def add_user( params = {} )

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )

      user_name = params.dig(:user_name)
      email = params.dig(:email)
      login_name = params.dig(:login_name) || user_name
      password = params.dig(:password)

      raise ArgumentError.new('missing user_name') if( user_name.nil? )
      raise ArgumentError.new('missing email') if( email.nil? )
      raise ArgumentError.new('missing login_name') if( login_name.nil? )
      raise ArgumentError.new('missing password') if( password.nil? )

      usr = user_by_name(email)

      if  usr.nil? || usr.dig('status').to_i == 200
        return {
          'status' => 404,
          'id' => usr.dig('id'),
          'email' => usr.dig('email'),
          'name' => usr.dig('name'),
          'login' => usr.dig('login'),
          'message' => format( 'user \'%s\' with email \'%s\' exists', user_name, email )
        }
      end

#      puts usr
#      raise format( 'user \'%s\' with email \'%s\' exists', user_name, email ) if( user_by_name(email) )

      endpoint = '/api/admin/users'
      @logger.debug("Create user #{user_name} (PUT #{endpoint})") if @debug
      @logger.debug( format( 'Data: %s', params.to_s ) ) if @debug
      post( endpoint, params.to_json)
    end


    # Password for User
    # PUT /api/admin/users/:id/password
    def update_user_password( params ) #user_id,password)

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )

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
