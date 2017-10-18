
module Grafana

  # http://docs.grafana.org/http_api/dashboard/
  #
  module Dashboard


    # Get dashboard
    # GET /api/dashboards/db/:slug
    def dashboard( name )

      raise ArgumentError.new('name must be an String') unless( name.is_a?(String) )

      endpoint = format( '/api/dashboards/db/%s', slug(name) )

      @logger.debug( "Attempting to get dashboard (GET /api/dashboards/db/#{name})" ) if @debug

      get( endpoint )
    end

    # Create / Update dashboard
    # POST /api/dashboards/db
    def create_dashboard( params )

      raise ArgumentError.new(format('wrong type. params must be an Hash, given %s', params.class.to_s ) ) unless( params.is_a?(Hash) )

      title     = params.dig(:title)
      dashboard = params.dig(:dashboard)

      # raise ArgumentError.new('missing title') if( title.nil? )
      raise ArgumentError.new('missing dashboard') if( dashboard.nil? )
      raise ArgumentError.new(format('wrong type. dashboard must be an Hash, given %s', dashboard.class.to_s ) ) unless( dashboard.is_a?(Hash) )

      endpoint = '/api/dashboards/db'
      # title     = slug(title)

      # dashboard = JSON.parse( dashboard ) if( dashboard.is_a?(String) )
      dashboard = regenerate_template_ids( dashboard )

      if( title.nil? )
        db = JSON.parse( dashboard ) if( dashboard.is_a?(String) )
        title = db.dig('dashboard','title')
      end

      @logger.debug("Creating dashboard: #{title} (POST /api/dashboards/db)") if @debug

      post( endpoint, dashboard )
    end

    # Delete dashboard
    # DELETE /api/dashboards/db/:slug
    def delete_dashboard( name )

      endpoint = format( '/api/dashboards/db/%s', slug(name) )

      @logger.debug("Deleting dashboard #{slug(name)} (DELETE #{endpoint})") if @debug

      delete(endpoint)
    end

    # Gets the home dashboard
    # GET /api/dashboards/home
    def home_dashboard

      endpoint = '/api/dashboards/home'

      @logger.debug("Attempting to get home dashboard (GET #{endpoint})") if @debug

      get(endpoint)
    end

    # Tags for Dashboard
    # GET /api/dashboards/tags
    def dashboard_tags

      endpoint = '/api/dashboards/tags'

      @logger.debug("Attempting to get dashboard tags(GET #{endpoint})") if @debug

      get(endpoint)
    end

    # Search Dashboards
    # GET /api/search/
    #
    #    searchDashboards( { :tags   => host } )
    #    searchDashboards( { :tags   => [ host, 'tag1' ] } )
    #    searchDashboards( { :tags   => [ 'tag2' ] } )
    #    searchDashboards( { :query  => title } )
    #    searchDashboards( { :starred => true } )
    def search_dashboards( params = {} )

      query   = params.dig(:query)
      starred = params.dig(:starred)
      tags    = params.dig(:tags)
      api     = []

      api << format( 'query=%s', CGI.escape( query ) ) unless  query.nil?
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


    def import_dashboards_from_directory( directory )

      raise ArgumentError.new('directory must be an String') unless( directory.is_a?(String) )

      result = {}

      dirs = Dir.glob( format( '%s/**.json', directory ) ).sort

      dirs.each do |f|

        @logger.debug( format( 'import \'%s\'', f ) ) if @debug

        dashboard = File.read( f )
        dashboard = JSON.parse( dashboard )
        title     = dashboard.dig('dashboard','title') || f

        result[f.to_s] ||= {}
        result[f.to_s] = create_dashboard( title: title, dashboard: dashboard )
      end

      result
    end

  end

end
