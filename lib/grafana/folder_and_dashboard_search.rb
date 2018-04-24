module Grafana

  # http://docs.grafana.org/http_api/folder_dashboard_search/#folder-dashboard-search-api
  #
  module FolderSearch

    # Search folders and dashboards
    # GET /api/search/
    #
    # Query parameters:
    #
    #  - query - Search Query
    #  - tag - List of tags to search for
    #  - type - Type to search for, dash-folder or dash-db
    #  - dashboardIds - List of dashboard id's to search for
    #  - folderIds - List of folder id's to search in for dashboards
    #  - starred - Flag indicating if only starred Dashboards should be returned
    #  - limit - Limit the number of returned results
    def folder_and_dashboard_search(params)

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has team support. you use version %s', v) } if(mv != 5)

      query         = validate( params, required: false, var: 'query'       , type: String )
      tag           = validate( params, required: false, var: 'tag '        , type: String )
      type          = validate( params, required: false, var: 'type'        , type: String )
      dashboard_id  = validate( params, required: false, var: 'dashboardIds', type: Integer )
      folder_id     = validate( params, required: false, var: 'folderIds'   , type: Integer )
      starred       = validate( params, required: false, var: 'starred'     , type: Boolean )
      limit         = validate( params, required: false, var: 'limit'       , type: Integer )

      unless(type.nil?)
        valid_types   = ['dash-folder', 'dash-db']
        downcased = Set.new valid_types.map(&:downcase)
        return { 'status' => 404, 'message' => format( 'wrong type. Must be one of %s, given \'%s\'', valid_types.join(', '), type ) } unless( downcased.include?( type.downcase ) )
      end

      api     = []
      api << format( 'query=%s', CGI.escape( query ) ) unless( query.nil? )
      api << format( 'tags=%s', tag ) unless( tag.nil? )
      api << format( 'type=%s', type ) unless( type.nil? )
      api << format( 'dashboardId=%s', dashboard_id ) unless( dashboard_id.nil? )
      api << format( 'folderId=%s', folder_id ) unless( folder_id.nil? )
      api << format( 'starred=%s', starred ) unless( starred.nil? )
      api << format( 'limit=%s', limit ) unless( limit.nil? )

      api = api.join( '&' )

      endpoint = format('/api/search?%s', api)
      get(endpoint)
    end

  end
end

