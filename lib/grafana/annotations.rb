
module Grafana

  # This is the API documentation for the new Grafana Annotations feature released in Grafana 4.6.
  # Annotations are saved in the Grafana database (sqlite, mysql or postgres).
  #
  # Annotations can be global annotations that can be shown on any dashboard by configuring an annotation
  # data source - they are filtered by tags.
  #
  # Or they can be tied to a panel on a dashboard and are then only shown on that panel.
  #
  # original API Documentation can be found under: http://docs.grafana.org/http_api/annotations/
  #
  module Annotations

    # Find Annotations
    # http://docs.grafana.org/http_api/annotations/#find-annotations
    #
    # @param [Hash] params
    # @option params [Integer] from: epoch datetime in milliseconds. Optional.
    # @option params [Integer] to: epoch datetime in milliseconds. Optional.
    # @option params [Integer] limit: number. Optional - default is 10. Max limit for results returned.
    # @option params [Integer] alert_id: number. Optional. Find annotations for a specified alert.
    # @option params [Mixed] dashboard: number. Optional. Find annotations that are scoped to a specific dashboard
    # @option params [Integer] panel_id: number. Optional. Find annotations that are scoped to a specific panel
    # @option params [Array] tags: Optional. Use this to filter global annotations.
    #                              Global annotations are annotations from an annotation data source that are not connected specifically to a dashboard or panel.
    #                              To do an "AND" filtering with multiple tags, specify the tags parameter multiple times e.g.
    #
    # @example
    #    params = {
    #      limit: 5,
    #      tags: [ 'spec', 'test' ]
    #    }
    #    find_annotation( params )
    #
    # @return [Array]
    #
    def find_annotation( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      dashboard = validate( params, required: false, var: 'dashboard' )
      from      = validate( params, required: false, var: 'from', type: Integer )
      to        = validate( params, required: false, var: 'to', type: Integer )
      limit     = validate( params, required: false, var: 'limit', type: Integer ) || 10
      alert_id  = validate( params, required: false, var: 'alert_id', type: Integer )
      panel_id  = validate( params, required: false, var: 'panel_id', type: Integer )
      tags      = validate( params, required: false, var: 'tags', type: Array )

      if( dashboard.is_a?(String) )

        dashboard = search_dashboards( query: dashboard )

        return { 'status' => 404, 'message' => format( 'No Dashboard \'%s\' found', dashboard) } if( dashboard.nil? || dashboard.dig('status').to_i != 200 )

        dashboard = dashboard.dig('message').first unless( dashboard.nil? && dashboard.dig('status').to_i == 200 )
        dashboard = dashboard.dig('id') unless( dashboard.nil? )

        return { 'status' => 404, 'message' => format( 'No Dashboard \'%s\' found', dashboard) } if( dashboard.nil? )
      end

      api     = []
      api << format( 'from=%s', from ) unless( from.nil? )
      api << format( 'to=%s', to ) unless( to.nil? )
      api << format( 'limit=%s', limit ) unless( limit.nil? )
      api << format( 'alertId=%s', alert_id ) unless( alert_id.nil? )
      api << format( 'panelId=%s', panel_id ) unless( panel_id.nil? )
      api << format( 'dashboardId=%s', dashboard ) unless( dashboard.nil? )

      unless( tags.nil? )
        tags = tags.join( '&tags=' ) if( tags.is_a?( Array ) )
        api << format( 'tags=%s', tags )
      end
      api = api.join( '&' )

      endpoint = format( '/api/annotations/?%s' , api )

      @logger.debug("Attempting to search for annotations (GET #{endpoint})") if @debug

      get( endpoint )
    end

    # Create Annotation
    #
    # Creates an annotation in the Grafana database.
    # The dashboard_id and panel_id fields are optional.
    # If they are not specified then a global annotation is created and can be queried in any dashboard that adds
    # the Grafana annotations data source.
    #
    # When creating a region annotation the response will include both id and endId, if not only id.
    #
    # http://docs.grafana.org/http_api/annotations/#create-annotation
    # POST /api/annotations
    #
    #
    # @param [Hash] params
    # @option params [Mixed] dashboard
    # @option params [Integer] panel_id
    # @option params [Integer] time:
    # @option params [Integer] time_end:
    # @option params [Boolean] region:
    # @option params [Array] tags:
    # @option params [String] text:
    #
    # @example
    #    params = {
    #      time: Time.now.to_i,
    #      tags: [ 'spec', 'test' ],
    #      text: 'test annotation'
    #    }
    #    create_annotation( params )
    #
    # @return [Hash]
    #
    def create_annotation( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      dashboard = validate( params, required: false, var: 'dashboard' )
      panel_id  = validate( params, required: false, var: 'panel_id', type: Integer )
      time      = validate( params, required: false, var: 'time', type: Integer ) || Time.now.to_i
      time_end  = validate( params, required: false, var: 'time_end', type: Integer )
      region    = validate( params, required: false, var: 'region', type: Boolean )
      tags      = validate( params, required: true , var: 'tags', type: Array )
      text      = validate( params, required: true , var: 'text', type: String )

      if( dashboard.is_a?(String) )

        dashboard = search_dashboards( query: dashboard )

        return { 'status' => 404, 'message' => format( 'No Dashboard \'%s\' found', dashboard) } if( dashboard.nil? || dashboard.dig('status').to_i != 200 )

        dashboard = dashboard.dig('message').first unless( dashboard.nil? && dashboard.dig('status').to_i == 200 )
        dashboard = dashboard.dig('id') unless( dashboard.nil? )

        return { 'status' => 404, 'message' => format( 'No Dashboard \'%s\' found', dashboard) } if( dashboard.nil? )
      end

      unless( time_end.nil? )
        return { 'status' => 404, 'message' => format( '\'end_time\' can\'t be lower then \'time\'' ) } if( time_end < time )
      end

      endpoint = '/api/annotations'
      payload = {
        dashboardId: dashboard,
        panelId: panel_id,
        time: time,
        timeEnd: time_end,
        isRegion: region,
        tags: tags,
        text: text
      }
      payload.reject!{ |_k, v| v.nil? }

      post(endpoint, payload.to_json)
    end

    # Create Annotation in Graphite format
    #
    # Creates an annotation by using Graphite-compatible event format.
    # The when and data fields are optional.
    # If when is not specified then the current time will be used as annotation's timestamp.
    # The tags field can also be in prior to Graphite 0.10.0 format (string with multiple tags being separated by a space).
    #
    # http://docs.grafana.org/http_api/annotations/#create-annotation-in-graphite-format
    # POST /api/annotations/graphite
    #
    # @param [Hash] params
    # @option params [Integer] what
    # @option params [Integer] when
    # @option params [Array] tags
    # @option params [String] data
    #
    # @example
    #    params = {
    #      what: 'spec test graphite annotation',
    #      when: Time.now.to_i,
    #      tags: [ 'spec', 'test' ],
    #      data: 'test annotation'
    #    }
    #    create_annotation_graphite( params )
    #
    # @return [Hash]
    #
    def create_annotation_graphite( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      what      = validate( params, required: true , var: 'what', type: String )
      time_when = validate( params, required: false, var: 'when', type: Integer ) || Time.now.to_i
      tags      = validate( params, required: true , var: 'tags', type: Array )
      data      = validate( params, required: false, var: 'data', type: String )

      endpoint = '/api/annotations/graphite'
      payload = {
        what: what,
        when: time_when,
        tags: tags,
        data: data
      }
      payload.reject!{ |_k, v| v.nil? }

      post(endpoint, payload.to_json)
    end

    # Update Annotation
    #
    # http://docs.grafana.org/http_api/annotations/#update-annotation
    #
    # @param [Hash] params
    # @option params [Integer] annotation
    # @option params [Integer] time
    # @option params [Integer] time_end
    # @option params [Boolean] region
    # @option params [Array] tags
    # @option params [String] text
    #
    # @example
    #    params = {
    #      annotation: 1,
    #      tags: [ 'deployment' ],
    #      text: 'git tag #1234'
    #    }
    #    update_annotation( params )
    #
    # @return [Hash]
    #
    def update_annotation( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      annotation_id = validate( params, required: true, var: 'annotation', type: Integer )
      time      = validate( params, required: false, var: 'time', type: Integer )
      time_end  = validate( params, required: false, var: 'time_end', type: Integer )
      region    = validate( params, required: false, var: 'region', type: Boolean )
      tags      = validate( params, required: false, var: 'tags', type: Array )
      text      = validate( params, required: false, var: 'text', type: String )

      unless( time_end.nil? )
        return { 'status' => 404, 'message' => format( '\'end_time\' can\'t be lower then \'time\'' ) } if( time_end < time )
      end

      endpoint = format( '/api/annotations/%d', annotation_id)
      payload = {
        time: time,
        timeEnd: time_end,
        isRegion: region,
        text: text,
        tags: tags
      }
      payload.reject!{ |_k, v| v.nil? }

      put(endpoint, payload.to_json)
    end

    # Delete Annotation By Id
    #
    # Deletes the annotation that matches the specified id.
    #
    # http://docs.grafana.org/http_api/annotations/#delete-annotation-by-id
    # DELETE /api/annotation/:id
    #
    # @param [Integer] annotation_id
    #
    # @example
    #    delete_annotation( 1 )
    #
    # @return [Hash]
    #
    def delete_annotation( annotation_id )

      raise ArgumentError.new(format('wrong type. user \'annotation_id\' must be an Integer, given \'%s\'', annotation_id.class.to_s)) unless( annotation_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'annotation_id\'') if( annotation_id.size.zero? )
      raise ArgumentError.new('\'annotation_id\' can not be 0') if( annotation_id.zero? )

      endpoint = format( '/api/annotation/%d', annotation_id )

      delete(endpoint)
    end

    # Delete Annotation By RegionId
    #
    # Deletes the annotation that matches the specified region id.
    # A region is an annotation that covers a timerange and has a start and end time.
    # In the Grafana database, this is a stored as two annotations connected by a region id.
    #
    # http://docs.grafana.org/http_api/annotations/#delete-annotation-by-regionid
    # DELETE /api/annotation/region/:id
    #
    # @param [Integer] region_id
    #
    # @example
    #    delete_annotation_by_region( 1 )
    #
    # @return [Hash]
    #
    def delete_annotation_by_region( region_id )

      raise ArgumentError.new(format('wrong type. user \'region_id\' must be an Integer, given \'%s\'', region_id.class.to_s)) unless( region_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'region_id\'') if( region_id.size.zero? )
#       raise ArgumentError.new('\'region_id\' can not be 0') if( region_id.zero? )

      endpoint = format( '/api/annotation/region/%d', region_id )

      delete(endpoint)
    end

  end

end
