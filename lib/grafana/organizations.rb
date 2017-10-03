
module Grafana

  # http://docs.grafana.org/http_api/org/#organisations
  #
  module Organizations

    # Search all Organisations
    # GET /api/orgs
    def all_organizations
      endpoint = '/api/orgs'
      @logger.debug("Getting all organizations (GET #{endpoint})") if @debug
      get( endpoint )
    end

    # Get Organisation by Id
    # GET /api/orgs/:orgId
    def organization_by_id( id )

      raise ArgumentError.new('id must be an Integer') unless( id.is_a?(Integer) )

      endpoint = format( '/api/orgs/%d', id )
      @logger.debug("Get Organisation by Id (GET #{endpoint}})") if @debug
      get( endpoint )
    end

    # Get Organisation by Name
    # GET /api/orgs/name/:orgName
    def organization_by_name( name )
      endpoint = format( '/api/orgs/name/%s', URI.escape( name ) )
      @logger.debug("Get Organisation by Name (GET #{endpoint})") if @debug
      get( endpoint )
    end

    # Update Organisation
    # PUT /api/orgs/:orgId
    # -> Update Organisation, fields Adress 1, Adress 2, City are not implemented yet.
    def update_organization( params )

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )

      organization = params.dig(:organization)
      name     = params.dig(:name)

      raise ArgumentError.new('missing organization for update') if( organization.nil? )
      raise ArgumentError.new('missing name for update') if( name.nil? )

      org = organization_by_name( organization )

      if  org.nil? || org.dig('status').to_i != 200
        return {
          'status' => 404,
          'message' => format('Organization \'%s\' not found', organization)
        }
      end

      org_id = org.dig('id')

      endpoint = format( '/api/orgs/%s', org_id )
      @logger.debug("Update Organisation id #{org_id} (PUT #{endpoint})") if @debug

      put( endpoint, { name: name }.to_json )
    end

    # Get Users in Organisation
    # GET /api/orgs/:orgId/users
    def organization_users( org_id )

      raise ArgumentError.new('missing org_id') if( org_id.nil? )

      endpoint = format( '/api/orgs/%s/users', org_id )

      @logger.debug("Getting users in Organisation id #{org_id} (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Add User in Organisation
    # POST /api/orgs/:orgId/users
    #
    # -> {"message"=>"User added to organization", "status"=>200}
    #
    def add_user_to_organization( params = {} )

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )

      organization   = params.dig(:organization)
      login_or_email = params.dig(:loginOrEmail)
      role           = params.dig(:role)

      raise ArgumentError.new('missing organization') if( organization.nil? )
      raise ArgumentError.new('missing loginOrEmail') if( login_or_email.nil? )
      raise ArgumentError.new('missing role') if( role.nil? )
      # Defaults to Viewer, other valid options are Admin and Editor and Read Only Editor
      raise ArgumentError.new( format( 'wrong role. only \'Admin\', \'Viewer\' or \'Editor\' allowed (\'%s\' giving)',role)) if( %w[Admin Viewer Editor].include?(role) == false )

      org = organization_by_name( organization )
      usr = user_by_name( login_or_email )
#       org_usr = organization_users( organization )

      if( org.nil? || org.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => format('Organization \'%s\' not found', organization)
        }
      end

      if( usr.nil? || usr.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => format('User \'%s\' not found', login_or_email)
        }
      end

      org_id = org.dig('id')

      endpoint = format( '/api/orgs/%d/users', org_id )
      @logger.debug("Adding user '#{login_or_email}' to organisation '#{organization}' (POST #{endpoint})") if @debug

      post( endpoint, { loginOrEmail: login_or_email, role: role }.to_json )
    end

    # Update Users in Organisation
    # PATCH /api/orgs/:orgId/users/:userId
    def update_organization_user( params ) #org_id, user_id, properties={} )

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )

      organization   = params.dig(:organization)
      login_or_email = params.dig(:loginOrEmail)
      role           = params.dig(:role)

      raise ArgumentError.new('missing organization') if( organization.nil? )
      raise ArgumentError.new('missing loginOrEmail') if( login_or_email.nil? )
      raise ArgumentError.new('missing role') if( role.nil? )
      # Defaults to Viewer, other valid options are Admin and Editor and Read Only Editor
      raise ArgumentError.new( format( 'wrong role. only \'Admin\', \'Viewer\' or \'Editor\' allowed (\'%s\' giving)',role)) if( %w[Admin Viewer Editor].include?(role) == false )

      org = organization_by_name( organization )
      usr = user_by_name( login_or_email )

      if( org.nil? || org.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => format('Organization \'%s\' not found', organization)
        }
      end

      if( usr.nil? || usr.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => format('User \'%s\' not found', login_or_email)
        }
      end

      org_id = org.dig('id')
      usr_id = usr.dig('id')

      endpoint = format( '/api/orgs/%d/users/%d', org_id, usr_id )

      @logger.debug("Updating user '#{login_or_email}' in organization '#{organization}' (PATCH #{endpoint})") if @debug
      patch( endpoint, { role: role }.to_json )
    end

    # Delete User in Organisation
    # DELETE /api/orgs/:orgId/users/:userId
    def delete_user_from_organization( params ) # org_id, user_id)

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )

      organization   = params.dig(:organization)
      login_or_email = params.dig(:loginOrEmail)

      raise ArgumentError.new('missing organization') if( organization.nil? )
      raise ArgumentError.new('missing loginOrEmail') if( login_or_email.nil? )

      org = organization_by_name( organization )
      usr = user_by_name( login_or_email )

      if( org.nil? || org.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => format('Organization \'%s\' not found', organization)
        }
      end

      if( usr.nil? || usr.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => format('User \'%s\' not found', login_or_email)
        }
      end

      org_id = org.dig('id')
      usr_id = usr.dig('id')

      endpoint = format( '/api/orgs/%d/users/%d', org_id, usr_id )

      @logger.debug("Deleting user '#{login_or_email}' in organization '#{organization}' (DELETE #{endpoint})") if @debug
      delete(endpoint)
    end

    # Create Organisation
    # POST /api/orgs
    #
    # -> {"message"=>"Organization created", "orgId"=>3, "status"=>200}
    #
    def create_organisation( params )

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )

      name = params.dig(:name)

      raise ArgumentError.new('missing name for Organisation') if( name.nil? )

      org = organization_by_name( name )

      if( org.nil? || org.dig('status').to_i == 200 )
        return {
          'status' => 409,
          'message' => format('Organisation \'%s\' already exists', name )
        }
      end

      endpoint = '/api/orgs'
      @logger.debug("Create Organisation (POST #{endpoint})") if @debug

      post( endpoint, { name: name }.to_json )
    end

    # Delete Organisation
    # DELETE path=/api/orgs/9
    #
    # -> {"message"=>"Organization deleted", "status"=>200}
    #
    def delete_organisation( params )

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )

      name = params.dig(:name)

      raise ArgumentError.new('missing name for Organisation') if( name.nil? )

      org = organization_by_name( name )

      if( org.nil? || org.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => format('Organization \'%s\' not found', organization)
        }
      end

      org_id = org.dig('id')

      endpoint = format( '/api/orgs/%d', org_id )
      @logger.debug("Deleting organization #{org_id} (DELETE #{endpoint})") if @debug

      delete(endpoint)
    end


  end

end
