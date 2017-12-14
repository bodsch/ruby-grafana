
module Grafana

  # You can use the Alerting API to get information about alerts and their states but this API cannot be used to modify the alert. To create new alerts or modify them you need to update the dashboard json that contains the alerts.
  #
  # This API can also be used to create, update and delete alert notifications.
  #
  # original API Documentation can be found under: http://docs.grafana.org/http_api/alerting/
  #
  module Alerts

    # Get alerts
    #
    # These parameters are used as querystring parameters. For example:
    #
    # @param [Hash] params
    # @option params [Mixed] dashboard_id alerts for a specified dashboard.
    # @option params [Integer] panel_id alerts for a specified panel on a dashboard.
    # @option params [Integer] limit (10) response to x number of alerts.
    # @option params [Integer] state (ALL,no_data, paused, alerting, ok, pending)
    # @option params [Array] alerts with one or more of the following alert states: 'ALL', 'no_data', 'paused', 'alerting', 'ok', 'pending'.
    ## To specify multiple states use the following format: ?state=paused&state=alerting
    #
    # @return [Array]
    # GET /api/alerts/
    # curl -H 'Content-Type: application/json;charset=UTF-8' 'http://admin:admin@127.0.0.1:3030/api/alerts'
    #
    def alerts( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
#       raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      dashboard_id = validate( params, required: false, var: 'dashboard_id' )
      panel_id     = validate( params, required: false, var: 'panel_id', type: Integer )
      limit        = validate( params, required: false, var: 'limit', type: Integer )
      alert_array  = validate( params, required: false, var: 'alerts', type: Array )
      valid_alerts = %w[ALL no_data paused alerting ok pending].sort

      unless( alert_array.nil? )
        alert_array  = alert_array.sort
        valid   = alert_array & valid_alerts
        invalid = alert_array - valid_alerts

        raise ArgumentError.new(format('wrong alerts type. only %s allowed, given \'%s\'', valid_alerts.join(', '), alert_array.join(', '))) if( invalid.count != 0 )
      end

      if( dashboard_id.is_a?(String) )

        dashboard = search_dashboards( query: dashboard_id )

        return { 'status' => 404, 'message' => format( 'No Dashboard \'%s\' found', dashboard_id) } if( dashboard.nil? || dashboard.dig('status').to_i != 200 )

        dashboard = dashboard.dig('message').first unless( dashboard.nil? && dashboard.dig('status').to_i == 200 )
        dashboard_id = dashboard.dig('id') unless( dashboard.nil? )

        return { 'status' => 404, 'message' => format( 'No Dashboard \'%s\' found', dashboard_id) } if( dashboard_id.nil? )
      end

      api     = []
      api << format( 'dashboardId=%s', dashboard_id ) unless( dashboard_id.nil? )
      api << format( 'panelId=%s', panel_id ) unless( panel_id.nil? )
      api << format( 'limit=%s', limit ) unless( limit.nil? )

      unless( alert_array.nil? )
        alert_array = alert_array.join( '&state=' ) if( alert_array.is_a?( Array ) )
        api << format( 'state=%s', alert_array )
      end
      api = api.join( '&' )

      endpoint = format( '/api/alerts/?%s' , api )

      @logger.debug("Attempting to search for alerts (GET #{endpoint})") if @debug

      get( endpoint )
    end

    # Get one alert
    #
    # @param [Mixed] alert_id Alertname (String) or Alertid (Integer)
    #
    # @example
    #    alert( 1 )
    #    alert( 'foo' )
    #
    # @return [Hash]
    #
    # curl -H 'Content-Type: application/json;charset=UTF-8' 'http://admin:admin@127.0.0.1:3030/api/alerts/1'
    #
    def alert( alert_id )

      raise ArgumentError.new(format('wrong type. user \'alert_id\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', alert_id.class.to_s)) if( alert_id.is_a?(String) && alert_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'alert_id\'') if( alert_id.size.zero? )

#       if(alert_id.is_a?(String))
#         data = alerts( alerts: 'all' ).select { |_k,v| v['name'] == alert_id }
#         alert_id = data.keys.first if( data )
#       end

#       puts alert_id
      # GET /api/alerts/:id


      endpoint = format( '/api/alerts/%d' , alert_id )

#       puts endpoint

      @logger.debug("Attempting get alert id #{alert_id} (GET #{endpoint})") if @debug

      get( endpoint )
    end


    # Pause single alert
    #
    # @param [Mixed] alert_id Alertname (String) or Alertid (Integer)
    #
    # @example
    #    alert_pause( 1 )
    #    alert_pause( 'foo' )
    #
    # @return [Hash]
    #
    def alert_pause( alert_id )

      raise ArgumentError.new(format('wrong type. user \'alert_id\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', alert_id.class.to_s)) if( alert_id.is_a?(String) && alert_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'alert_id\'') if( alert_id.size.zero? )

      if(alert_id.is_a?(String))
        data = alerts( alerts: 'all' ).select { |_k,v| v['name'] == alert_id }
        alert_id = data.keys.first if( data )
      end

      # POST /api/alerts/:id/pause
#       puts alert_id
    end

    # Get alert notifications
    #
    # @example
    #    alert_notifications
    #
    # @return [Hash]
    #
    def alert_notifications
      logger.debug('Getting alert notifications') if @debug
      get('/api/alert-notifications')
    end

    # Create alert notification
    #
    # @param [Hash] params
    # @option params [String] name short description - required
    # @option params [String] type ('email') - required
    # @option params [Boolean] default (false)
    # @option params [Hash] settings
    #
    # @example
    #    params = {
    #      name: 'new alert notification',
    #      type:  'email',
    #      default: false,
    #      settings: {
    #        addresses: 'carl@grafana.com;dev@grafana.com'
    #      }
    #    }
    #    create_alert_notification( params )
    #
    # @return [Hash]
    #
    def create_alert_notification( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing params') if( params.size.zero? )

      # TODO
      # type are 'email'
      # and the other possible values?

      name     = validate( params, required: true, var: 'name', type: String )
      type     = validate( params, required: true, var: 'type', type: String ) || 'email'
      default  = validate( params, required: false, var: 'default', type: Boolean ) || false
      settings = validate( params, required: false, var: 'settings', type: Hash )

      # TODO
      # check if the alert 'name' already created
      return { 'status' => 404, 'message' => format( 'alert notification \'%s\' alread exists', name) } if( alert_notification?(name) )

#       data = alert_notifications
#       data = data.dig('message').first unless( data.nil? && data.dig('status').to_i == 200 )
#       data = data.select { |k| k['name'] == name }
#       return { 'status' => 404, 'message' => format( 'alert notification \'%s\' alread exists', name) } if( data )

      payload = {
        name: name,
        type: type,
        isDefault: default,
        settings: settings
      }
      payload.reject!{ |_k, v| v.nil? }

      endpoint = '/api/alert-notifications'

#       puts endpoint
#       puts payload

      post(endpoint, payload.to_json)
    end

    # Update alert notification
    #
    # @param [Hash] params
    # @param [Mixed] alert_id Alertname (String) or Alertid (Integer) to change
    # @option params [String] name short description - required
    # @option params [String] type ('email') - required
    # @option params [Boolean] default (false)
    # @option params [Hash] settings
    #
    # @example
    #    params = {
    #      alert_id: 1
    #      name: 'new alert notification',
    #      type:  'email',
    #      default: false,
    #      settings: {
    #        addresses: 'carl@grafana.com;dev@grafana.com'
    #      }
    #    }
    #    update_alert_notification( params )
    #
    #    params = {
    #      alert_id: 'new alert notification'
    #      name: 'new alert notification',
    #      type:  'email',
    #      default: false,
    #      settings: {
    #       addresses: 'carl@grafana.com;dev@grafana.com'
    #      }
    #    }
    #    update_alert_notification( params )
    #
    # @return [Hash]
    #
    def update_alert_notification( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing params') if( params.size.zero? )

      # TODO
      # type are 'email'
      # and the other possible values?
      alert_id = validate( params, required: true, var: 'alert_id' )
      name     = validate( params, required: true, var: 'name', type: String )
      type     = validate( params, required: true, var: 'type', type: String ) || 'email'
      default  = validate( params, required: false, var: 'default', type: Boolean ) || false
      settings = validate( params, required: false, var: 'settings', type: Hash )

      raise ArgumentError.new(format('wrong type. user \'alert_id\' must be an String (for an Alertname) or an Integer (for an Alertid), given \'%s\'', alert_id.class.to_s)) if( alert_id.is_a?(String) && alert_id.is_a?(Integer) )

      alert_id = alert_notification_id(alert_id)
      return { 'status' => 404, 'message' => format( 'alert notification \'%s\' not exists', name) } if( alert_id.nil? )

      payload = {
        id: alert_id,
        name: name,
        type: type,
        isDefault: default,
        settings: settings
      }
      payload.reject!{ |_k, v| v.nil? }

      endpoint = format( '/api/alert-notifications/%d', alert_id )

      put(endpoint, payload.to_json)
    end

    # Delete alert notification
    #
    # @param [Mixed] alert_id Alertname (String) or Alertid (Integer)
    #
    # @example
    #    delete_alert_notification( 1 )
    #    delete_alert_notification( 'foo' )
    #
    # @return [Hash]
    #
    def delete_alert_notification( alert_id )

      raise ArgumentError.new(format('wrong type. user \'alert_id\' must be an String (for an Alert name) or an Integer (for an Alertid), given \'%s\'', alert_id.class.to_s)) if( alert_id.is_a?(String) && alert_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'alert_id\'') if( alert_id.size.zero? )

      id = alert_notification_id(alert_id)
      return { 'status' => 404, 'message' => format( 'alert notification \'%s\' not exists', alert_id) } if( id.nil? )

      endpoint = format('/api/alert-notifications/%d', alert_id )
      logger.debug( "Deleting alert id #{alert_id} (DELETE #{endpoint})" ) if @debug

      delete( endpoint )
    end


    private
    def alert_notification?( alert_id )

      id = alert_notification_id(alert_id)

      return true unless( id.nil? )

      false
    end

    def alert_notification_id( alert_id )

      data = alert_notifications
      data = data.dig('message') unless( data.nil? && data.dig('status').to_i == 200 )

      map = {}
      data.each do |d|
        map[d.dig('id')] = d.dig('name').downcase.split.join('_')
      end

      id = map.select { |key,value| key == alert_id } if( map && alert_id.is_a?(Integer) )
      id = map.select { |key,value| value == alert_id.downcase.split.join('_') } if( map && alert_id.is_a?(String) )

      id = id.keys.first unless(id.nil?)

      return id if( id.is_a?(Integer) )

      nil
    end

  end

end

