
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

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

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


    end

    # Restore dashboard
    # http://docs.grafana.org/http_api/dashboard_versions/#restore-dashboard
    # POST /api/dashboards/id/:dashboardId/restore
    def restore_dashboard( params )


    end

    # Compare dashboard versions
    # http://docs.grafana.org/http_api/dashboard_versions/#compare-dashboard-versions
    # POST /api/dashboards/calculate-diff
    def compare_dashboard_version( params )



    end

  end

end
