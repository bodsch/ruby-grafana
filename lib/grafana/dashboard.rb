
module Grafana

  # http://docs.grafana.org/http_api/dashboard/
  #
  module Dashboard


    # Get dashboard
    #
    # @example
    #    dashboard('dashboard for many foo')
    #
    # @return [String]
    #
    def dashboard( name )

      raise ArgumentError.new(format('wrong type. \'name\' must be an String, given \'%s\'', name.class.to_s)) unless( name.is_a?(String) )
      raise ArgumentError.new('missing name') if( name.size.zero? )

      endpoint = format( '/api/dashboards/db/%s', slug(name) )

      @logger.debug( "Attempting to get dashboard (GET /api/dashboards/db/#{name})" ) if @debug

      get( endpoint )
    end

    # Create / Update dashboard
    #
    # @param [Hash] params
    # @option params [Hash] dashboard
    # @option params [Boolean] overwrite (true)
    #
    # @example
    #    params = {
    #      dashboard: {
    #        id: null,
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
    #      overwrite: false
    #    }
    #    create_dashboard( params )
    #
    # @return [Hash]
    #
    # POST /api/dashboards/db
    def create_dashboard( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      dashboard = validate( params, required: true, var: 'dashboard', type: Hash )
      overwrite = validate( params, required: false, var: 'overwrite', type: Boolean ) || true

      dashboard = regenerate_template_ids( dashboard )

      db = JSON.parse( dashboard ) if( dashboard.is_a?(String) )
      title = db.dig('dashboard','title')

      endpoint = '/api/dashboards/db'

      payload = {
        dashboard: db.dig('dashboard'),
        overwrite: overwrite
      }
      payload.reject!{ |_k, v| v.nil? }

      @logger.debug("Creating dashboard: #{title} (POST /api/dashboards/db)") if @debug

      post( endpoint, payload.to_json )
    end

    # Delete dashboard
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
