module Grafana

  # http://docs.grafana.org/http_api/folder_dashboard_search/#folder-dashboard-search-api
  #
  module FolderSearch

    # Search folders and dashboards
    # GET /api/search/
    #
    # Query parameters:
    #
    #  - query – Search Query
    #  - tag – List of tags to search for
    #  - type – Type to search for, dash-folder or dash-db
    #  - dashboardIds – List of dashboard id’s to search for
    #  - folderIds – List of folder id’s to search in for dashboards
    #  - starred – Flag indicating if only starred Dashboards should be returned
    #  - limit – Limit the number of returned results
    def folder_and_dashboard_search(); end

  end
end

