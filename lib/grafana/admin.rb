
module Grafana

  module Admin


    def admin_settings
      @logger.info('Getting admin settings')

      get('/api/admin/settings')
    end


    def updateUserPermissions(id, perm)

      valid_perms = ['Viewer','Editor','Read Only Editor','Admin']

      if( perm.is_a?( String ) && !valid_perms.include?(perm) )
        logger.warn("Basic user permissions include: #{valid_perms.join(',')}")
        return false
      elsif( perm.is_a?( Hash ) &&
        ( !perm.key?('isGrafanaAdmin') || ![true,false].include?(perm['isGrafanaAdmin']) ) )

        logger.warn('Grafana admin permission must be either true or false')

        return false
      end

      logger.info("Updating user ID #{id} permissions")

      if( perm.is_a?( Hash ) )

        endpoint = "/api/admin/users/#{id}/permissions"
        logger.info("Updating user ID #{id} permissions (PUT #{endpoint})")

        return putRequest(endpoint, {'isGrafanaAdmin' => perm['isGrafanaAdmin']}.to_json)
      else
        org = current_org
        endpoint = "/api/orgs/#{org['id']}/users/#{id}"
        logger.info("Updating user ID #{id} permissions (PUT #{endpoint})")
        user = {
          'name' => org['name'],
          'orgId' => org['id'],
          'role' => perm.downcase.capitalize
        }
        return patchRequest(endpoint, user.to_json)
      end
    end


    def deleteUser(user_id)
      if user_id == 1
        logger.warn("Can't delete user ID #{user_id} (admin user)")
        return false
      end
      endpoint = "/api/admin/users/#{user_id}"
      logger.info("Deleting user ID #{user_id} (DELETE #{endpoint})")
      deleteRequest(endpoint)
    end


    # return given user
    #
    def user( user_name )

      # /api/users/lookup?loginOrEmail=user@mygraf.com
      raise ArgumentError.new('missing user_name') if( user_name.nil? )

      get( format('/api/users/lookup?loginOrEmail=%s', user_name ) )

      # result: {"id"=>2, "email"=>"foo@foo-bar.tld", "name"=>"foo", "login"=>"foo", "theme"=>"", "orgId"=>1, "isGrafanaAdmin"=>true, "status"=>200}
    end


    def add_user( params = {} )

      user_name = params.dig(:user_name)
      email = params.dig(:email)
      login_name = params.dig(:login_name) || user_name
      password = params.dig(:password)

      raise ArgumentError.new('missing user_name') if( user_name.nil? )
      raise ArgumentError.new('missing email') if( email.nil? )
      raise ArgumentError.new('missing login_name') if( login_name.nil? )
      raise ArgumentError.new('missing password') if( password.nil? )

      raise format( 'user \'%s\' with email \'%s\' exists', user_name, email ) if( user(email) )

#      { \"name\": \"${user}\", \"email\": \"${email}\", \"login\": \"${user}\", \"password\": \"${password}\" }

      endpoint = '/api/admin/users'
      @logger.info("Creating user: #{params.dig('name')}")
      @logger.info("Data: #{params}")

      post( endpoint, params.to_json)
    end


    def delete_user()

      # path=/api/org/users/:id
    end


    def updateUserPass(user_id,password)

      endpoint = " /api/admin/users/#{user_id}/#{password}"
      logger.info("Updating password for user ID #{user_id} (PUT #{endpoint})")
      putRequest(endpoint,properties)
    end


  end

end
