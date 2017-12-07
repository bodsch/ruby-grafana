
module Grafana

  # http://docs.grafana.org/http_api/annotations/
  #
  module DashboardVersions

    # Get all dashboard versions
    # http://docs.grafana.org/http_api/dashboard_versions/#get-all-dashboard-versions
    # GET /api/dashboards/id/:dashboardId/versions
    def dashboard_all_versions( params ); end

    # Get dashboard version
    # http://docs.grafana.org/http_api/dashboard_versions/#get-dashboard-version
    # GET /api/dashboards/id/:dashboardId/versions/:id
    def dashboard_version( params ); end

    # Restore dashboard
    # http://docs.grafana.org/http_api/dashboard_versions/#restore-dashboard
    # POST /api/dashboards/id/:dashboardId/restore
    def restore_dashboard( params ); end

    # Compare dashboard versions
    # http://docs.grafana.org/http_api/dashboard_versions/#compare-dashboard-versions
    # POST /api/dashboards/calculate-diff
    def compare_dashboard_version( params ); end

  end

end
