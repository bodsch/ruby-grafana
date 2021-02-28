
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

      if( organisation_id.is_a?(String) && organisation_id.is_a?(Integer))
        raise ArgumentError.new(format('wrong type. \'organisation_id\' must be an String (for an Datasource name) ' \
                                       'or an Integer (for an Datasource Id), given \'%s\'', organisation_id.class.to_s))
      end
      raise ArgumentError.new('missing \'organisation_id\'') if( organisation_id.size.zero? )

      endpoint = format( '/api/orgs/%d', organisation_id ) if(organisation_id.is_a?(Integer))
      endpoint = format( '/api/orgs/name/%s', ERB::Util.url_encode( organisation_id ) ) if(organisation_id.is_a?(String))

      @logger.debug("Attempting to get existing data source Id #{organisation_id} (GET #{endpoint})") if  @debug

      get(endpoint)
    end

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

      organization = validate( params, required: true, var: 'organization', type: String )
      name         = validate( params, required: true, var: 'name', type: String )
      org          = organization( organization )

      return { 'status' => 404, 'message' => format('Organization \'%s\' not found', organization) } if( org.nil? || org.dig('status').to_i != 200 )

      organization_id = org.dig('id')

      endpoint = format( '/api/orgs/%s', organization_id )
      payload = { name: name }

      @logger.debug("Update Organisation id #{organization_id} (PUT #{endpoint})") if @debug

      put( endpoint, payload.to_json )
    end

    # Get Users in Organisation
    #
    # @param [Mixed] organization_id Organistaion Name (String) or Organistaion Id (Integer)
    #
    # @example
    #    organization_users( 1 )
    #    organization_users( 'Foo Bar' )
    #
    # @return [Hash]
    #
    def organization_users( organization_id )

      if( organization_id.is_a?(String) && organization_id.is_a?(Integer))
        raise ArgumentError.new(format('wrong type. \'organization_id\' must be an String (for an Organisation name) '\
                                       'or an Integer (for an Organisation Id), given \'%s\'', organization_id.class.to_s))
      end
      raise ArgumentError.new('missing \'organization_id\'') if( organization_id.size.zero? )

      if(organization_id.is_a?(String))
        org = organization(organization_id)
        return { 'status' => 404, 'message' => format('Organization \'%s\' not found', organization) } if( org.nil? || org.dig('status').to_i != 200 )

        organization_id = org.dig('id')
      end

      endpoint = format( '/api/orgs/%s/users', organization_id )

      @logger.debug("Getting users in Organisation id #{organization_id} (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Add User in Organisation
    #
    # @param [Hash] params
    # @option params [String] organization Organisation name
    # @option params [String] login_or_email Login or email
    # @option params [String] role Name of the Role - only 'Viewer', 'Editor', 'Read Only Editor' or 'Admin' allowed
    #
    # @example
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

      data   = validate_organisation_user( params )
      status = data.dig('status')

      return data if( status.nil? || status.to_i == 404 )

      org = data.dig('organisation')
      usr = data.dig('user')

      organization_id = org.dig('id')
      organization = org.dig('name')
      login_or_email = usr.dig('email')
      role = data.dig('role')

      endpoint = format( '/api/orgs/%d/users', organization_id )
      payload = {
        loginOrEmail: login_or_email,
        role: role
      }

      @logger.debug("Adding user '#{login_or_email}' to organisation '#{organization}' (POST #{endpoint})") if @debug

      post( endpoint, payload.to_json )
    end

    # Update Users in Organisation
    #
    # @param [Hash] params
    # @option params [String] organization Organisation name
    # @option params [String] login_or_email Login or email
    # @option params [String] role Name of the Role - only 'Viewer', 'Editor', 'Read Only Editor' or 'Admin' allowed
    #
    # @example
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

      data   = validate_organisation_user( params )
      status = data.dig('status')

      return data if( status.nil? || status.to_i == 404 )

      org = data.dig('organisation')
      usr = data.dig('user')

      organization_id = org.dig('id')
      organization = org.dig('name')
      usr_id = usr.dig('id')
      login_or_email = usr.dig('name')
      role = data.dig(:role)

      endpoint = format( '/api/orgs/%d/users/%d', organization_id, usr_id )
      payload = {
        role: role
      }

      @logger.debug("Updating user '#{login_or_email}' in organization '#{organization}' (PATCH #{endpoint})") if @debug
      patch( endpoint, payload.to_json )
    end

    # Delete User in Organisation
    #
    # @param [Hash] params
    # @option params [String] organization Organisation name
    # @option params [String] login_or_email Login or email
    #
    # @example
    #    params = {
    #      organization: 'Foo',
    #      login_or_email: 'foo@foo-bar.tld'
    #    }
    #    delete_user_from_organization( params )
    #
    # @return [Hash]
    #
    def delete_user_from_organization( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      organization   = validate( params, required: true, var: 'organization', type: String )
      login_or_email = validate( params, required: true, var: 'login_or_email', type: String )

      org = organization( organization )
      usr = user( login_or_email )

      return { 'status' => 404, 'message' => format('Organization \'%s\' not found', organization) } if( org.nil? || org.dig('status').to_i != 200 )
      return { 'status' => 404, 'message' => format('User \'%s\' not found', login_or_email) } if( usr.nil? || usr.dig('status').to_i != 200 )

      organization_id = org.dig('id')
      usr_id = usr.dig('id')

      endpoint = format( '/api/orgs/%d/users/%d', organization_id, usr_id )

      @logger.debug("Deleting user '#{login_or_email}' in organization '#{organization}' (DELETE #{endpoint})") if @debug
      delete(endpoint)
    end

    # Create Organisation
    #
    # @param [Hash] params
    # @option params [String] organization Organisation name
    #
    # @example
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
      org    = organization( name )

      return { 'status' => 409, 'message' => format('Organisation \'%s\' already exists', name ) } if( org.nil? || org.dig('status').to_i == 200 )

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

      if( organisation_id.is_a?(String) && organisation_id.is_a?(Integer) )
        raise ArgumentError.new(format('wrong type. \'organisation_id\' must be an String (for an Organisation name) ' \
                                       'or an Integer (for an Organisation Id), given \'%s\'', organisation_id.class.to_s))
      end
      raise ArgumentError.new('missing \'organisation_id\'') if( organisation_id.size.zero? )

      if(organisation_id.is_a?(String))
        data = organizations.dig('message')
        organisation_map = {}
        data.each do |d|
          organisation_map[d.dig('id')] = d.dig('name')
        end
        organisation_id = organisation_map.select { |_,y| y == organisation_id }.keys.first if( organisation_map )
      end

      return { 'status' => 404, 'message' => format( 'No Organisation \'%s\' found', organisation_id) } if( organisation_id.nil? )

      endpoint = format( '/api/orgs/%d', organisation_id )
      @logger.debug("Deleting organization #{organisation_id} (DELETE #{endpoint})") if @debug

      delete(endpoint)
    end


    private
    # validate an user for an organisation
    #
    # @example
    #    params = {
    #      organization: 'Foo',
    #      login_or_email: 'foo@foo-bar.tld',
    #      role: 'Viewer'
    #    }
    #    validate_organisation_user( params )
    #
    # @return [Hash]
    #
    def validate_organisation_user( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      organization   = validate( params, required: true, var: 'organization', type: String )
      login_or_email = validate( params, required: true, var: 'login_or_email', type: String )
      role           = validate( params, required: true, var: 'role', type: String )
      valid_roles    = %w[Viewer Editor "Read Only Editor" Admin]

      # https://stackoverflow.com/questions/9333952/case-insensitive-arrayinclude?answertab=votes#tab-top
      # Do this once, or each time the array changes
      downcased = Set.new valid_roles.map(&:downcase)
      unless( downcased.include?( role.downcase ) )
        return {
          'status' => 404,
          'login_or_email' => login_or_email,
          'role' => role,
          'message' => format( 'wrong role. Role must be one of %s, given \'%s\'', valid_roles.join(', '), role )
        }
      end

      org = organization( organization )
      usr = user( login_or_email )

      return { 'status' => 404, 'message' => format('Organization \'%s\' not found', organization) } if( org.nil? || org.dig('status').to_i != 200 )
      return { 'status' => 404, 'message' => format('User \'%s\' not found', login_or_email) } if( usr.nil? || usr.dig('status').to_i != 200 )

      {
        'status' => 200,
        'organisation' => org,
        'user' => usr,
        'role' => role
      }
    end


  end
end
