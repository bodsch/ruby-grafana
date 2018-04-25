
module Grafana

  # http://docs.grafana.org/http_api/dashboard_permissions/#dashboard-permissions-api
  #
  # This API can be used to update/get the permissions for a dashboard.
  # Permissions with dashboardId=-1 are the default permissions for users with the Viewer and Editor roles.
  # Permissions can be set for a user, a team or a role (Viewer or Editor).
  # Permissions cannot be set for Admins - they always have access to everything.
  #
  # The permission levels for the permission field:
  #
  #  1 = View
  #  2 = Edit
  #  4 = Admin
  #
  module DashboardPermissions

    # http://docs.grafana.org/http_api/dashboard_permissions/#get-permissions-for-a-dashboard
    #
    # GET /api/dashboards/id/:dashboardId/permissions
    #
    # Gets all existing permissions for the dashboard with the given dashboardId.
    #
    def dashboard_permissions(uid)

      if( uid.is_a?(String) && uid.is_a?(Integer) )
        raise ArgumentError.new(format('wrong type. dashboard \'uid\' must be an String (for an title name) or an Integer (for an Datasource Id), given \'%s\'', uid.class.to_s))
      end
      raise ArgumentError.new('missing \'uid\'') if( uid.size.zero? )

      endpoint = format( '/api/dashboards/id/%s/permissions', uid )
      @logger.debug( "Attempting to get dashboard permissions (GET #{endpoint})" ) if @debug

      r = get( endpoint )
      r['message'] = format('dashboard \'%s\' not found', uid) if(r.dig('status') == 404)
      r
    end

    # http://docs.grafana.org/http_api/dashboard_permissions/#update-permissions-for-a-dashboard
    #
    # POST /api/dashboards/id/:dashboardId/permissions
    #
    # Updates permissions for a dashboard.
    # This operation will remove existing permissions if they're not included in the request.
    #
    #
    def update_dashboad_permissions(params)

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

      dashboard_id = validate( params, required: true, var: 'dashboard_id', type: Integer )
      permissions  = validate( params, required: true, var: 'permissions' , type: Hash )

      return { 'status' => 404, 'message' => 'no permissions given' } if( permissions.size.zero? )

      valid_roles = %w[View Edit Admin]

      c_team = permissions.dig('team')
      c_user = permissions.dig('user')
      team   = []
      user   = []

      unless(c_team.nil?)
        check_keys = []

        c_team.uniq.each do |x|
          k = x.keys.first
          v = x.values.first
          r = validate_hash( v, valid_roles )

          f_team = team(k)
          team_id = f_team.dig('id')

          next unless(( f_team.dig('status') == 200) && !check_keys.include?(team_id) && r == true )

          check_keys << team_id

          role_id = valid_roles.index(v)
          role_id += 1
          role_id += 1 if(v == 'Admin')

          team << {
            teamId: team_id,
            permission: role_id
          }
        end
      end

      unless(c_user.nil?)
        check_keys = []

        c_user.uniq.each do |x|
          k = x.keys.first
          v = x.values.first
          r = validate_hash( v, valid_roles )

          f_user = user(k)
          user_id = f_user.dig('id')

          next unless(( f_user.dig('status') == 200) && !check_keys.include?(user_id) && r == true )

          check_keys << user_id

          role_id = valid_roles.index(v)
          role_id += 1
          role_id += 1 if(v == 'Admin')

          user << {
            userId: user_id,
            permission: role_id
          }
        end
      end

      payload = {
        items: team + user
      }
      payload.reject!{ |_, y| y.nil? }


      endpoint = format('/api/dashboards/id/%s/permissions', dashboard_id)
      post(endpoint, payload.to_json)
    end

  end

end
