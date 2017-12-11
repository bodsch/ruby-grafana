
module Grafana

  # http://docs.grafana.org/http_api/org/#organisations
  #
  module Organizations

    # Search all Organisations
    # GET /api/orgs
    def organizations
      endpoint = '/api/orgs'
      @logger.debug("Getting all organizations (GET #{endpoint})") if @debug
      get( endpoint )
    end


    # Get a single data sources by Id or Name
    #
    # @example
    #    organisation( 1 )
    #    organisation( 'foo' )
    #
    # @return [Hash]
    #
    def organization( organisation_id )

      raise ArgumentError.new(format('wrong type. user \'organisation_id\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', organisation_id.class.to_s)) if( organisation_id.is_a?(String) && organisation_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'organisation_id\'') if( organisation_id.size.zero? )

      endpoint = format( '/api/orgs/%d', organisation_id ) if(organisation_id.is_a?(Integer))
      endpoint = format( '/api/orgs/name/%s', URI.escape( organisation_id ) ) if(organisation_id.is_a?(String))

      @logger.debug("Attempting to get existing data source Id #{organisation_id} (GET #{endpoint})") if  @debug

      get(endpoint)
    end

#     # Get Organisation by Id
#     # GET /api/orgs/:orgId
#     def organization_by_id( id )
#
#       raise ArgumentError.new('id must be an Integer') unless( id.is_a?(Integer) )
#
#       endpoint = format( '/api/orgs/%d', id )
#       @logger.debug("Get Organisation by Id (GET #{endpoint}})") if @debug
#       get( endpoint )
#     end
#
#     # Get Organisation by Name
#     # GET /api/orgs/name/:orgName
#     def organization_by_name( name )
#
#       raise ArgumentError.new('name must be an String') unless( name.is_a?(String) )
#
#       endpoint = format( '/api/orgs/name/%s', URI.escape( name ) )
#       @logger.debug("Get Organisation by Name (GET #{endpoint})") if @debug
#       get( endpoint )
#     end

    # Update Organisation
    #
    # fields Adress 1, Adress 2, City are not implemented yet.
    #
    # @param [Hash] params
    # @option params [String] organization name of the Organisation
    # @option params [String] name new name
    # @option params [String] adress_1
    # @option params [String] adress_2
    # @option params [String] city
    #
    # @example
    #    update_organization( organization: 'Main. Org', name: 'Foo+Bar' )
    #
    # @return [Hash]
    #
    def update_organization( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      organization   = validate( params, required: true, var: 'organization', type: String )
      name = validate( params, required: true, var: 'name', type: String )

      org = organization( organization )

      if( org.nil? || org.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => format('Organization \'%s\' not found', organization)
        }
      end
      org_id = org.dig('id')

      payload = { name: name }

      endpoint = format( '/api/orgs/%s', org_id )
      @logger.debug("Update Organisation id #{org_id} (PUT #{endpoint})") if @debug

      put( endpoint, payload.to_json )
    end

    # Get Users in Organisation
    #
    # @param [Mixed] user_id Username (String) or Userid (Integer) for delete User
    #
    # @example
    #    organization_users( 1 )
    #    organization_users( 'Foo Bar' )
    #
    # @return [Hash]
    #
    def organization_users( org_id )

      raise ArgumentError.new(format('wrong type. user \'org_id\' must be an String (for an Organisation name) or an Integer (for an Organisation Id), given \'%s\'', org_id.class.to_s)) if( org_id.is_a?(String) && org_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'org_id\'') if( org_id.size.zero? )

      if(org_id.is_a?(String))
        org = organization(org_id)
        if( org.nil? || org.dig('status').to_i != 200 )
          return {
            'status' => 404,
            'message' => format('Organization \'%s\' not found', organization)
          }
        end
        org_id = org.dig('id')
      end

      endpoint = format( '/api/orgs/%s/users', org_id )

      @logger.debug("Getting users in Organisation id #{org_id} (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Add User in Organisation
    #
    # @param
    # @option params [String] organization Organisation name
    # @option params [String] login_or_email Login or email
    # @option params [String] role Name of the Role - only 'Viewer', 'Editor', 'Read Only Editor' or 'Admin' allowed
    #
    # @examle
    #    params = {
    #      organization: 'Foo',
    #      login_or_email: 'foo@foo-bar.tld',
    #      role: 'Viewer'
    #    }
    #    add_user_to_organization( params )
    #
    # @return [Hash]
    #
    def add_user_to_organization( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      organization   = validate( params, required: true, var: 'organization', type: String )
      login_or_email = validate( params, required: true, var: 'login_or_email', type: String )
      role           = validate( params, required: true, var: 'role', type: String )
      valid_roles    = ['Viewer', 'Editor', 'Read Only Editor', 'Admin']

      # https://stackoverflow.com/questions/9333952/case-insensitive-arrayinclude?answertab=votes#tab-top
      # Do this once, or each time the array changes
      downcased = Set.new valid_roles.map(&:downcase)
      unless( downcased.include?( role.downcase ) )

        message = format( 'wrong role. Role must be one of %s, given \'%s\'', valid_roles.join(', '), role )

        return {
          'status' => 404,
          'login_or_email' => login_or_email,
          'role' => role,
          'message' => message
        }
      end

      org = organization( organization )
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

      payload = {
        loginOrEmail: login_or_email,
        role: role
      }

      endpoint = format( '/api/orgs/%d/users', org_id )
      @logger.debug("Adding user '#{login_or_email}' to organisation '#{organization}' (POST #{endpoint})") if @debug

      post( endpoint, payload.to_json )
    end

    # Update Users in Organisation
    #
    # @param
    # @option params [String] organization Organisation name
    # @option params [String] login_or_email Login or email
    # @option params [String] role Name of the Role - only 'Viewer', 'Editor', 'Read Only Editor' or 'Admin' allowed
    #
    # @examle
    #    params = {
    #      organization: 'Foo',
    #      login_or_email: 'foo@foo-bar.tld',
    #      role: 'Viewer'
    #    }
    #    update_organization_user( params )
    #
    # @return [Hash]
    #
    def update_organization_user( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      organization   = validate( params, required: true, var: 'organization', type: String )
      login_or_email = validate( params, required: true, var: 'login_or_email', type: String )
      role           = validate( params, required: true, var: 'role', type: String )
      valid_roles    = ['Viewer', 'Editor', 'Read Only Editor', 'Admin']

      # https://stackoverflow.com/questions/9333952/case-insensitive-arrayinclude?answertab=votes#tab-top
      # Do this once, or each time the array changes
      downcased = Set.new valid_roles.map(&:downcase)
      unless( downcased.include?( role.downcase ) )

        message = format( 'wrong role. Role must be one of %s, given \'%s\'', valid_roles.join(', '), role )

        return {
          'status' => 404,
          'login_or_email' => login_or_email,
          'role' => role,
          'message' => message
        }
      end

      org = organization( organization )
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

      payload = {
        role: role
      }

      endpoint = format( '/api/orgs/%d/users/%d', org_id, usr_id )

      @logger.debug("Updating user '#{login_or_email}' in organization '#{organization}' (PATCH #{endpoint})") if @debug
      patch( endpoint, payload.to_json )
    end

    # Delete User in Organisation
    #
    # @param
    # @option params [String] organization Organisation name
    # @option params [String] login_or_email Login or email
    # @option params [String] role Name of the Role - only 'Viewer', 'Editor', 'Read Only Editor' or 'Admin' allowed
    #
    # @examle
    #    params = {
    #      organization: 'Foo',
    #      login_or_email: 'foo@foo-bar.tld'
    #    }
    #    delete_user_from_organization( params )
    #
    # @return [Hash]
    #
    # DELETE /api/orgs/:orgId/users/:userId
    def delete_user_from_organization( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      organization   = validate( params, required: true, var: 'organization', type: String )
      login_or_email = validate( params, required: true, var: 'login_or_email', type: String )

      org = organization( organization )
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
    #
    # @param
    # @option params [String] organization Organisation name
    #
    # @examle
    #    params = {
    #      name: 'Foo'
    #    }
    #    create_organisation( params )
    #
    # @return [Hash]
    #
    def create_organisation( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      name   = validate( params, required: true, var: 'name', type: String )

      org = organization( name )

      if( org.nil? || org.dig('status').to_i == 200 )
        return {
          'status' => 409,
          'message' => format('Organisation \'%s\' already exists', name )
        }
      end

      endpoint = '/api/orgs'
      payload = {
        name: name
      }
      @logger.debug("Create Organisation (POST #{endpoint})") if @debug

      post( endpoint, payload.to_json )
    end

    # Delete Organisation
    #
    # @param [Mixed] organisation_id Organisation Name (String) or Organisation Id (Integer) for delete Organisation
    #
    # @example
    #    delete_organisation( 1 )
    #    delete_organisation( 'Foo' )
    #
    # @return [Hash]
    #
    def delete_organisation( organisation_id )

      raise ArgumentError.new(format('wrong type. user \'organisation_id\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', organisation_id.class.to_s)) if( organisation_id.is_a?(String) && organisation_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'organisation_id\'') if( organisation_id.size.zero? )

      if(organisation_id.is_a?(String))
        data = organizations.dig('message')
        organisation_map = {}
        data.each do |ds|
          organisation_map[ds['id']] = ds
        end
        organisation_map.select { |_k,v| v['name'] == organisation_id }
        organisation_id = organisation_map.keys.first if( data )
      end

      if( organisation_id.nil? )
        return {
          'status' => 404,
          'message' => format( 'No Organisation \'%s\' found', organisation_id)
        }
      end

      endpoint = format( '/api/orgs/%d', organisation_id )
      @logger.debug("Deleting organization #{organisation_id} (DELETE #{endpoint})") if @debug

      delete(endpoint)
    end

  end
end
