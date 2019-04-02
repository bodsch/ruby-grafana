
module Grafana

  # http://docs.grafana.org/http_api/dashboard_versions
  #
  module DashboardVersions

    # Get all dashboard versions
    # http://docs.grafana.org/http_api/dashboard_versions/#get-all-dashboard-versions
    # GET /api/dashboards/id/:dashboardId/versions
    #
    #
    #
    #
    #
    #
    def dashboard_all_versions( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

#      v, mv = version.values
#      return { 'status' => 404, 'message' => format( 'dashboard has been supported in Grafana since version 5. you use version %s', v) } if(mv < 5)

      dashboard_id  = validate( params, required: true , var: 'dashboard_id', type: Integer )
      start         = validate( params, required: false, var: 'start'       , type: Integer )
      limit         = validate( params, required: false, var: 'limit'       , type: Integer )

      api     = []
      api << format( 'start=%s', start ) unless( start.nil? )
      api << format( 'limit=%s', limit ) unless( limit.nil? )
      api = api.join( '&' )

      endpoint = format('/api/dashboards/id/%s/versions?%s', dashboard_id, api)
      get(endpoint)
    end

    # Get dashboard version
    # http://docs.grafana.org/http_api/dashboard_versions/#get-dashboard-version
    # GET /api/dashboards/id/:dashboardId/versions/:id
    def dashboard_version( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'folder has been supported in Grafana since version 5. you use version %s', v) } if(mv < 5)

      dashboard_id  = validate( params, required: true, var: 'dashboard_id', type: Integer )
      version       = validate( params, required: true, var: 'version'     , type: Integer )

      endpoint = format('/api/dashboards/id/%s/versions/%s', dashboard_id, version)

      r = get(endpoint)

      r['message'] = format('no dashboard version \'%s\' for dashboard \'%s\' found', version, dashboard_id) if(r.dig('status') == 404)
      r['message'] = format('no dashboard version \'%s\' for dashboard \'%s\' found', version, dashboard_id) if(r.dig('status') == 500)
      r
    end

    # Restore dashboard
    # http://docs.grafana.org/http_api/dashboard_versions/#restore-dashboard
    # POST /api/dashboards/id/:dashboardId/restore
    def restore_dashboard( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

#      v, mv = version.values
#      return { 'status' => 404, 'message' => format( 'folder has been supported in Grafana since version 5. you use version %s', v) } if(mv < 5)

      dashboard_id  = validate( params, required: true, var: 'dashboard_id', type: Integer )
      version       = validate( params, required: true, var: 'version'    , type: Integer )

      endpoint = format('/api/dashboards/id/%s/restore', dashboard_id)

      payload = {
        version: version
      }

      post(endpoint, payload.to_json)
    end

    # Compare dashboard versions
    # http://docs.grafana.org/http_api/dashboard_versions/#compare-dashboard-versions
    # POST /api/dashboards/calculate-diff
    def compare_dashboard_version( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      base      = validate( params, required: true , var: 'base'     , type: Hash )
      new       = validate( params, required: true , var: 'new'      , type: Hash )
      diff_type = validate( params, required: false, var: 'diff_type', type: String ) || 'json'

      base_dashboard_id      = validate( base, required: true , var: 'dashboard_id', type: Integer )
      base_dashboard_version = validate( base, required: true , var: 'version'     , type: Integer )
      new_dashboard_id       = validate( new , required: true , var: 'dashboard_id', type: Integer )
      new_dashboard_version  = validate( new , required: true , var: 'version'     , type: Integer )

      valid_diff_type = %w[json basic]

      r = validate_hash(diff_type, valid_diff_type)

      return r unless(r == true)

      payload = {
        base: {
          dashboardId: base_dashboard_id,
          version: base_dashboard_version
        },
        new: {
          dashboardId: new_dashboard_id,
          version: new_dashboard_version
        },
        diffType: diff_type
      }

      endpoint = '/api/dashboards/calculate-diff'

      post(endpoint, payload.to_json)
    end

  end

end
