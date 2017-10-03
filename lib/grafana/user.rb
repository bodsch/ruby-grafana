
module Grafana

  # http://docs.grafana.org/http_api/user/
  #
  module User

    # Actual User
    # GET /api/user
    def current_user
      endpoint = '/api/user'
      @logger.info("Getting user current user (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Change Password
    # PUT /api/user/password
    def update_current_user_password( params )

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )

      old_password = params.dig(:old_password)
      new_password = params.dig(:new_password)

      raise ArgumentError.new('missing old_password for update') if( old_password.nil? )
      raise ArgumentError.new('missing new_password for update') if( new_password.nil? )

      endpoint = '/api/user/password'
      @logger.info("Updating current user password (PUT #{endpoint})") if @debug
      put( endpoint, { oldPassword: old_password, newPassword: new_password, confirmNew: new_password }.to_json )
    end

    # Switch user context for signed in user
    # POST /api/user/using/:organizationId
    def switch_current_user_organization( organization )

      raise ArgumentError.new('organization must be an String') unless( params.is_a?(String) )

      org = organization_by_name( organization )

      return {
        'status' => 404,
        'message' => format('Organization \'%s\' not found', organization)
      } if( org.nil? || org.dig('status').to_i != 200 )

      org_id = org.dig('id')

      endpoint = format( '/api/user/using/%d', org_id )
      @logger.info("Switching current user to Organization #{organization} (GET #{endpoint})") if @debug

      post( endpoint, {} )
    end

    # Organisations of the actual User
    # GET /api/user/orgs
    def current_user_oganizations

      endpoint = '/api/user/orgs'
      @logger.info("Getting current user organizations (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Star a dashboard
    # POST /api/user/stars/dashboard/:dashboardId
    def add_dashboard_star( dashboard )

      if( !dashboard.is_a?(String) && !dashboard.is_a?(Integer) )
        raise ArgumentError.new('dashboard must be an String (for an Dashboard name) or an Integer (for an Dashboard ID)')
      end

      dashboard_id = dashboard if(dashboard.is_a?(Integer))

      if(dashboard.is_a?(String))

        search = { :query => dashboard }
        r = search_dashboards( search )
        message = r.dig('message')
        dashboard_id = message.first.dig('id')
      end

      if( dashboard_id == 0 )
        raise RuntimeError, format('Dashboard id can not be 0')
      end

      endpoint = format( '/api/user/stars/dashboard/%d', dashboard_id )
      @logger.info("Adding star to dashboard id #{dashboard_id} (GET #{endpoint})") if @debug
      post(endpoint, {}.to_json)
    end

    # Unstar a dashboard
    # DELETE /api/user/stars/dashboard/:dashboardId
    def remove_dashboard_star( dashboard )

      if( !dashboard.is_a?(String) && !dashboard.is_a?(Integer) )
        raise ArgumentError.new('dashboard must be an String (for an Dashboard name) or an Integer (for an Dashboard ID)')
      end

      dashboard_id = dashboard if(dashboard.is_a?(Integer))

      if(dashboard.is_a?(String))

        search = { :query => dashboard }
        r = search_dashboards( search )
        message = r.dig('message')
        dashboard_id = message.first.dig('id')
      end

      if( dashboard_id == 0 )
        raise RuntimeError, format('Dashboard Id can not be 0')
      end

      endpoint = format( '/api/user/stars/dashboard/%d', dashboard_id )
      @logger.info("Deleting star on dashboard id #{dashboard_id} (GET #{endpoint})") if @debug
      delete( endpoint )
    end

  end

end
