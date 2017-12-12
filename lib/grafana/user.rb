
module Grafana

  # http://docs.grafana.org/http_api/user/
  #
  module User

    # Actual User
    #
    # @example
    #    current_user
    #
    # @return [Hash]
    #
    def current_user
      endpoint = '/api/user'
      @logger.debug("Getting user current user (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Change Password
    #
    # @param [Hash] params
    # @option params [String] old_password the old password
    # @option params [String] new_password the new password
    #
    # @example
    #    update_current_user_password( old_password: 'foo', new_password: 'FooBar' )
    #
    # @return [Hash]
    #
    def update_current_user_password( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      old_password   = validate( params, required: true, var: 'old_password', type: String )
      new_password   = validate( params, required: true, var: 'new_password', type: String )

      endpoint = '/api/user/password'
      payload = {
        oldPassword: old_password,
        newPassword: new_password,
        confirmNew: new_password
      }
      @logger.debug("Updating current user password (PUT #{endpoint})") if @debug
      put( endpoint, payload.to_json )
    end

    # Switch user context for signed in user
    #
    # @param organization [String ] organization
    #
    # @example
    #    switch_current_user_organization( 'Main. Org' )
    #
    # @return [Hash]
    #
    def switch_current_user_organization( organization )

      raise ArgumentError.new(format('wrong type. \'organization\' must be an String, given \'%s\'', organization.class.to_s)) unless( organization.is_a?(String) )
      raise ArgumentError.new('missing \'organization\'') if( organization.size.zero? )

      org = organization_by_name( organization )

      return { 'status' => 404, 'message' => format('Organization \'%s\' not found', organization) } if( org.nil? || org.dig('status').to_i != 200 )

      org_id = org.dig('id')

      endpoint = format( '/api/user/using/%d', org_id )
      @logger.debug("Switching current user to Organization #{organization} (GET #{endpoint})") if @debug

      post( endpoint, {} )
    end

    # Organisations of the actual User
    #
    # @example
    #    current_user_oganizations
    #
    # @return [Hash]
    #
    def current_user_oganizations
      endpoint = '/api/user/orgs'
      @logger.debug("Getting current user organizations (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Star a dashboard
    #
    # @param [Mixed] dashboard_id Dashboard Name (String) or Dashboard Id (Integer) for add a star
    #
    # @example
    #    add_dashboard_star( 1 )
    #    add_dashboard_star( 'QA Graphite Carbon Metrics' )
    #
    # @return [Hash]
    #
    def add_dashboard_star( dashboard_id )

      raise ArgumentError.new(format('wrong type. user \'dashboard_id\' must be an String (for an Dashboard name) or an Integer (for an Dashboard Id), given \'%s\'', dashboard_id.class.to_s)) if( dashboard_id.is_a?(String) && dashboard_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'dashboard_id\'') if( dashboard_id.size.zero? )

      dashboard_id = dashboard if(dashboard_id.is_a?(Integer))

      if(dashboard_id.is_a?(String))
        r = search_dashboards( query: dashboard_id )
        message = r.dig('message')
        dashboard_id = message.first.dig('id')
      end

      raise format('Dashboard Id can not be 0') if( dashboard_id.zero? )

      endpoint = format( '/api/user/stars/dashboard/%d', dashboard_id )
      @logger.debug("Adding star to dashboard id #{dashboard_id} (GET #{endpoint})") if @debug
      post( endpoint, {}.to_json )
    end

    # Unstar a dashboard
    #
    # @param [Mixed] dashboard_id Dashboard Name (String) or Dashboard Id (Integer) for delete a star
    #
    # @example
    #    remove_dashboard_star( 1 )
    #    remove_dashboard_star( 'QA Graphite Carbon Metrics' )
    #
    # @return [Hash]
    #
    def remove_dashboard_star( dashboard_id )

      raise ArgumentError.new(format('wrong type. user \'dashboard_id\' must be an String (for an Dashboard name) or an Integer (for an Dashboard Id), given \'%s\'', dashboard_id.class.to_s)) if( dashboard_id.is_a?(String) && dashboard_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'dashboard_id\'') if( dashboard_id.size.zero? )

      dashboard_id = dashboard( dashboard_id ) if(dashboard_id.is_a?(Integer))

      if(dashboard_id.is_a?(String))
        r = search_dashboards( query: dashboard_id )
        message = r.dig('message')
        dashboard_id = message.first.dig('id')
      end

      raise format('Dashboard Id can not be 0') if  dashboard_id.zero?

      endpoint = format( '/api/user/stars/dashboard/%d', dashboard_id )
      @logger.debug("Deleting star on dashboard id #{dashboard_id} (GET #{endpoint})") if @debug
      delete( endpoint )
    end

  end

end
