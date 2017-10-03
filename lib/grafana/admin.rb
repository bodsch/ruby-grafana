
module Grafana

  # http://docs.grafana.org/http_api/admin/
  #



  module Admin

    # Settings
    # GET /api/admin/settings
    def admin_settings
      @logger.info('Getting admin settings') if @debug
      get('/api/admin/settings')
    end

    # Grafana Stats
    # GET /api/admin/stats
    def admin_stats
      @logger.info('Getting admin statistics') if @debug
      get('/api/admin/stats')
    end

    # Permissions
    # PUT /api/admin/users/:id/permissions
    def update_user_permissions( id, perm )

      valid_perms = ['Viewer','Editor','Read Only Editor','Admin']

      if( perm.is_a?( String ) && !valid_perms.include?(perm) )
        logger.warn("Basic user permissions include: #{valid_perms.join(',')}")
        return false
      elsif( perm.is_a?( Hash ) &&
        ( !perm.key?('isGrafanaAdmin') || ![true,false].include?(perm['isGrafanaAdmin']) ) )

        logger.warn('Grafana admin permission must be either true or false')

        return false
      end

      logger.info("Updating user id #{id} permissions")

      if( perm.is_a?( Hash ) )

        endpoint = "/api/admin/users/#{id}/permissions"
        logger.info("Updating user id #{id} permissions (PUT #{endpoint})")

        return putRequest(endpoint, {'isGrafanaAdmin' => perm['isGrafanaAdmin']}.to_json)
      else
        org = current_org
        endpoint = "/api/orgs/#{org['id']}/users/#{id}"
        logger.info("Updating user id #{id} permissions (PUT #{endpoint})")
        user = {
          'name' => org['name'],
          'orgId' => org['id'],
          'role' => perm.downcase.capitalize
        }
        return patchRequest(endpoint, user.to_json)
      end
    end

    # Delete global User
    # DELETE /api/admin/users/:id
    def deleteUser(user_id)
      if user_id == 1
        logger.warn("Can't delete user id #{user_id} (admin user)")
        return false
      end
      endpoint = "/api/admin/users/#{user_id}"
      logger.info("Deleting user id #{user_id} (DELETE #{endpoint})")
      deleteRequest(endpoint)
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

      return {
        'status' => 404,
        'id' => usr.dig('id'),
        'email' => usr.dig('email'),
        'name' => usr.dig('name'),
        'login' => usr.dig('login'),
        'message' => format( 'user \'%s\' with email \'%s\' exists', user_name, email )
      } if( usr.nil? || usr.dig('status').to_i == 200 )

#      puts usr
#      raise format( 'user \'%s\' with email \'%s\' exists', user_name, email ) if( user_by_name(email) )

      endpoint = '/api/admin/users'
      @logger.info("Create user #{user_name} (PUT #{endpoint})") if @debug
      @logger.info( format( 'Data: %s', params.to_s ) ) if @debug
      post( endpoint, params.to_json)
    end


    def delete_user()

      # path=/api/org/users/:id
    end

    # Password for User
    # PUT /api/admin/users/:id/password
    def updateUserPass(user_id,password)

      endpoint = " /api/admin/users/#{user_id}/#{password}"
      logger.info("Updating password for user id #{user_id} (PUT #{endpoint})")
      putRequest(endpoint,properties)
    end

    # Pause all alerts
    # POST /api/admin/pause-all-alerts






#     def add_user( params = {} )
#
#       user_name = params.dig(:user_name)
#       email = params.dig(:email)
#       login_name = params.dig(:login_name) || user_name
#       password = params.dig(:password)
#
#       raise ArgumentError.new('missing user_name') if( user_name.nil? )
#       raise ArgumentError.new('missing email') if( email.nil? )
#       raise ArgumentError.new('missing login_name') if( login_name.nil? )
#       raise ArgumentError.new('missing password') if( password.nil? )
#
#       raise format( 'user \'%s\' with email \'%s\' exists', user_name, email ) if( user(email) )
#
# #      { \"name\": \"${user}\", \"email\": \"${email}\", \"login\": \"${user}\", \"password\": \"${password}\" }
#
#       endpoint = '/api/admin/users'
#       @logger.info("Creating user: #{params.dig('name')}")
#       @logger.info("Data: #{params}")
#
#       post( endpoint, params.to_json)
#     end
#
#     def delete_user()
#
#       # path=/api/org/users/:id
#     end


  end

end
