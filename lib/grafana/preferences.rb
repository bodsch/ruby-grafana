module Grafana

  #
  #
  #
  #
  #
  # original API Documentation can be found under: http://docs.grafana.org/http_api/preferences/#user-and-org-preferences-api
  #
  module Preferences

    # Get Current User Prefs
    # GET /api/user/preferences
    def user_preferences()

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

      endpoint = '/api/user/preferences'
      @logger.debug("Getting current user preferences (GET #{endpoint})") if @debug
      get(endpoint)
    end


    # Update Current User Prefs
    # PUT /api/user/preferences
    #
    # theme - One of: light, dark, or an empty string for the default theme
    # homeDashboardId - The numerical :id of a favorited dashboard, default: 0
    # timezone - One of: utc, browser, or an empty string for the default
    #
    def update_user_preferences(params)

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      endpoint = '/api/user/preferences'
      @logger.debug("update current user preferences (GET #{endpoint})") if @debug

      update_preferences( endpoint, params )
    end


    # Get Current Org Prefs
    # GET /api/org/preferences
    def org_preferences()

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

      endpoint = '/api/org/preferences'
      @logger.debug("Getting current organisation preferences (GET #{endpoint})") if @debug
      get(endpoint)
    end



    # Update Current Org Prefs
    # PUT /api/org/preferences
    #
    # theme - One of: light, dark, or an empty string for the default theme
    # homeDashboardId - The numerical :id of a favorited dashboard, default: 0
    # timezone - One of: utc, browser, or an empty string for the default
    #
    def update_org_preferences(params)

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      endpoint = '/api/org/preferences'
      @logger.debug("update current organisation preferences (GET #{endpoint})") if @debug

      update_preferences( endpoint, params )
    end


    private
    def update_preferences( endpoint, params )

      theme          = validate( params, required: false, var: 'theme'         , type: String )
      timezone       = validate( params, required: false, var: 'timezone'      , type: String )
      home_dashboard = validate( params, required: false, var: 'home_dashboard')

      valid_theme    = %w[light dark]
      valid_timezone = %w[utc browser]

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

      unless(theme.nil?)
        v_theme = validate_hash( theme, valid_theme )
        return v_theme unless( v_theme == true )
      end

      unless(timezone.nil?)
        v_timez = validate_hash( timezone, valid_timezone )
        return v_timez unless( v_timez == true )
      end

      unless(home_dashboard.nil?)
        v_dashboard = dashboard(home_dashboard)
        return { 'status' => 404, 'message' => format('dashboard \'%s\' not found',home_dashboard) }\
            unless(v_dashboard.dig('status') == 200)

        dashboard_id = v_dashboard.dig('dashboard','id')
      end

      payload = {
        theme: theme,
        homeDashboardId: dashboard_id,
        timezone: timezone
      }
      payload.reject!{ |_, y| y.nil? }

#      endpoint = '/api/user/preferences'
#      @logger.debug("update current preferences (GET #{endpoint})") if @debug

      put(endpoint, payload.to_json)
    end

  end
end
