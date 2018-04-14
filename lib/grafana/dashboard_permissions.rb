
module Grafana

  # http://docs.grafana.org/http_api/dashboard_permissions/#dashboard-permissions-api
  #
  # This API can be used to update/get the permissions for a dashboard.
  # Permissions with dashboardId=-1 are the default permissions for users with the Viewer and Editor roles. Permissions can be set for a user, a team or a role (Viewer or Editor). Permissions cannot be set for Admins - they always have access to everything.
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


    # http://docs.grafana.org/http_api/dashboard_permissions/#update-permissions-for-a-dashboard
    #
    # POST /api/dashboards/id/:dashboardId/permissions
    #
    # Updates permissions for a dashboard. This operation will remove existing permissions if they’re not included in the request.
    #
    #


  end

end
