
module Grafana

  # http://docs.grafana.org/http_api/dashboard/

  # The identifier (id) of a dashboard is an auto-incrementing numeric value and is only unique per Grafana install.
  #
  # The unique identifier (uid) of a dashboard can be used for uniquely identify a dashboard between multiple Grafana installs.
  # It's automatically generated if not provided when creating a dashboard. The uid allows having consistent URL's for
  # accessing dashboards and when syncing dashboards between multiple Grafana installs, see dashboard provisioning for
  # more information. This means that changing the title of a dashboard will not break any bookmarked links to that dashboard.
  #
  # The uid can have a maximum length of 40 characters.
  #
  # Deprecated resources
  #  Please note that these resource have been deprecated and will be removed in a future release.
  #
  #  - Get dashboard by slug
  #  - Delete dashboard by slug
  #
  #
  #
  module Dashboard

    # http://docs.grafana.org/http_api/dashboard/#get-dashboard-by-slug
    #  - Deprecated starting from Grafana v5.0.
    #    Please update to use the new Get dashboard by uid resource instead
    #
    # Get dashboard
    #
    # Will return the dashboard given the dashboard slug.
    # Slug is the url friendly version of the dashboard title.
    # If there exists multiple dashboards with the same slug, one of them will be returned in the response.
    #
    # @example
    #    dashboard('dashboard for many foo')
    #
    # @return [String]
    #
    def dashboard( name )

      raise ArgumentError.new(format('wrong type. \'name\' must be an String, given \'%s\'', name.class.to_s)) unless( name.is_a?(String) )
      raise ArgumentError.new('missing name') if( name.size.zero? )

#       v, mv = version.values
#
#       if( mv == 5)
#         puts 'DEPRICATION WARNING'
#         puts 'Grafana v5.0 use a new interal id/uid handling'
#         puts 'This function works well with Grafana v4.x'
#       end

      endpoint = format( '/api/dashboards/db/%s', slug(name) )
      @logger.debug( "Attempting to get dashboard (GET #{endpoint})" ) if @debug

      get( endpoint )
    end

    # http://docs.grafana.org/http_api/dashboard/#get-dashboard-by-uid
    #
    # GET /api/dashboards/uid/:uid
    # Will return the dashboard given the dashboard unique identifier (uid).
    #
    # Get dashboard
    #
    # Will return the dashboard given the dashboard unique identifier (uid).
    #
    # @example
    #    dashboard('L42r6NWiz')
    #
    # @return [String]
    #
    def dashboard_by_uid( uid )

      if( uid.is_a?(String) && uid.is_a?(Integer) )
        raise ArgumentError.new(format('wrong type. dashboard \'uid\' must be an String (for an title name) or an Integer (for an Datasource Id), given \'%s\'', uid.class.to_s))
      end
      raise ArgumentError.new('missing \'uid\'') if( uid.size.zero? )

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has uid support. you use version %s', v) } if(mv != 5)

      return { 'status' => 404, 'message' => format( 'The uid can have a maximum length of 40 characters. \'%s\' given', uid.length) } if( uid.length > 40 )

      endpoint = format( '/api/dashboards/uid/%s', uid )
      @logger.debug( "Attempting to get dashboard (GET #{endpoint})" ) if @debug

      get( endpoint )
    end


    # Create / Update dashboard
    #
    # Creates a new dashboard or updates an existing dashboard.
    #
    # @param [Hash] params
    # @option params [Hash] dashboard The complete dashboard model
    #  - dashboard.id - id = null to create a new dashboard.
    #  - dashboard.uid - Optional unique identifier when creating a dashboard. uid = null will generate a new uid.
    #  - folderId - The id of the folder to save the dashboard in.
    #  - overwrite - Set to true if you want to overwrite existing dashboard with newer version, same dashboard title in folder or same dashboard uid.
    #  - message - Set a commit message for the version history.
    # @option params [Boolean] overwrite (true)
    #
    # @example
    #    params = {
    #      dashboard: {
    #        id: null,
    #        uid: null,
    #        title: 'Production Overview',
    #        tags: [ 'templated' ],
    #        timezone": 'browser',
    #        rows: [
    #          {
    #          }
    #        ],
    #        'schemaVersion': 6,
    #        'version': 0
    #      },
    #      folderId: 0,
    #      overwrite: false,
    #      message: 'created by foo'
    #    }
    #    create_dashboard( params )
    #
    # @return [Hash]
    #
    # POST /api/dashboards/db
    def create_dashboard( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      dashboard = validate( params, required: true , var: 'dashboard', type: Hash )
      overwrite = validate( params, required: false, var: 'overwrite', type: Boolean ) || true
      folder_id = validate( params, required: false, var: 'folderId' )
      message   = validate( params, required: false, var: 'message', type: String )

      dashboard = regenerate_template_ids( dashboard )

      unless(folder_id.nil?)
        f_folder = folder(folder_id)
        return { 'status' => 404, 'message' => format( 'No Folder \'%s\' found', folder_id) } if( f_folder.dig('status') != 200 )

        folder_id = f_folder.dig('id')
      end

      db = JSON.parse( dashboard ) if( dashboard.is_a?(String) )
      title = db.dig('dashboard','title')

      endpoint = '/api/dashboards/db'

      payload = {
        dashboard: db.dig('dashboard'),
        overwrite: overwrite,
        folderId: folder_id,
        message: message
      }
      payload.reject!{ |_k, v| v.nil? }

      @logger.debug("Creating dashboard: #{title} (POST /api/dashboards/db)") if @debug

      post( endpoint, payload.to_json )
    end

    # http://docs.grafana.org/http_api/dashboard/#delete-dashboard-by-slug
    #  - Deprecated starting from Grafana v5.0.
    #    Please update to use the new Get dashboard by uid resource instead
    #
    # Delete dashboard
    # Will delete the dashboard given the specified slug. Slug is the url friendly version of the dashboard title.
    #
    # @example
    #    delete_dashboard('dashboard for many foo')
    #
    # @return [Hash]
    #
    def delete_dashboard( name )

      raise ArgumentError.new(format('wrong type. \'name\' must be an String, given \'%s\'', name.class.to_s)) unless( name.is_a?(String) )
      raise ArgumentError.new('missing name') if( name.size.zero? )

      endpoint = format( '/api/dashboards/db/%s', slug(name) )

      @logger.debug("Deleting dashboard #{slug(name)} (DELETE #{endpoint})") if @debug

      delete(endpoint)
    end

    # Gets the home dashboard
    #
    # @example
    #    home_dashboard
    #
    # @return [Hash]
    #
    def home_dashboard

      endpoint = '/api/dashboards/home'

      @logger.debug("Attempting to get home dashboard (GET #{endpoint})") if @debug

      get(endpoint)
    end

    # Tags for Dashboard
    #
    # @example
    #    dashboard_tags
    #
    # @return [Hash]
    #
    def dashboard_tags

      endpoint = '/api/dashboards/tags'

      @logger.debug("Attempting to get dashboard tags(GET #{endpoint})") if @debug

      get(endpoint)
    end

    # Search Dashboards
    #
    # @example
    #    searchDashboards( tags: host )
    #    searchDashboards( tags: [ host, 'tag1' ] )
    #    searchDashboards( tags: [ 'tag2' ] )
    #    searchDashboards( query: title )
    #    searchDashboards( starred: true )
    #
    # @return [Hash]
    #
    def search_dashboards( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )

      query   = validate( params, required: false, var: 'query', type: String )
      starred = validate( params, required: false, var: 'starred', type: Boolean )
      tags    = validate( params, required: false, var: 'tags' )

      api     = []
      api << format( 'query=%s', CGI.escape( query ) ) unless( query.nil? )
      api << format( 'starred=%s', starred ? 'true' : 'false' ) unless( starred.nil? )

      unless( tags.nil? )
        tags = tags.join( '&tag=' ) if( tags.is_a?( Array ) )
        api << format( 'tag=%s', tags )
      end

      api = api.join( '&' )

      endpoint = format( '/api/search/?%s' , api )

      @logger.debug("Attempting to search for dashboards (GET #{endpoint})") if @debug

      get( endpoint )
    end

    # import Dashboards from directory
    #
    # @example
    #    import_dashboards_from_directory( '/tmp/dashboards' )
    #
    # @return [Hash]
    #
    def import_dashboards_from_directory( directory )

      raise ArgumentError.new('directory must be an String') unless( directory.is_a?(String) )

      result = {}

      dirs = Dir.glob( format( '%s/**.json', directory ) ).sort

      dirs.each do |f|

        @logger.debug( format( 'import \'%s\'', f ) ) if @debug

        dashboard = File.read( f )
        dashboard = JSON.parse( dashboard )

        result[f.to_s] ||= {}
        result[f.to_s] = create_dashboard( dashboard: dashboard )
      end

      result
    end

  end

end
