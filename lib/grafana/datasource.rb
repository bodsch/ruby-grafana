
module Grafana

  # http://docs.grafana.org/http_api/datasource/
  #
  module Datasource

    # Get all datasources
    #
    # @example
    #    datasources
    #
    # @return [Hash]
    #
    def datasources

      endpoint = '/api/datasources'

      @logger.debug("Attempting to get all existing data sources (GET #{endpoint})") if @debug

      datasources = get( endpoint )

      return { 'status' => 404, 'message' => 'No Datasources found' } if( datasources.nil? || datasources == false || datasources.dig('status').to_i != 200 )

      datasources = datasources.dig('message')

      datasource_map = {}
      datasources.each do |ds|
        datasource_map[ds['id']] = ds
      end

      datasource_map
    end

    # Get a single datasources by Id or Name
    #
    # @param [Mixed] datasource_id Datasource Name (String) or Datasource Id (Integer)
    #
    # @example
    #    datasource( 1 )
    #    datasource( 'foo' )
    #
    # @return [Hash]
    #
    def datasource( datasource_id )

      raise ArgumentError.new(format('wrong type. user \'datasource_id\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', datasource_id.class.to_s)) if( datasource_id.is_a?(String) && datasource_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'datasource_id\'') if( datasource_id.size.zero? )

      if(datasource_id.is_a?(String))
        data = datasources.select { |_k,v| v['name'] == datasource_id }
        datasource_id = data.keys.first if( data )
      end

      return { 'status' => 404, 'message' => format( 'No Datasource \'%s\' found', datasource_id) } if( datasource_id.nil? )

      raise format('DataSource Id can not be 0') if( datasource_id.zero? )

      endpoint = format('/api/datasources/%d', datasource_id )

      @logger.debug("Attempting to get existing data source Id #{datasource_id} (GET #{endpoint})") if  @debug

      get(endpoint)
    end

    # Get a single data source by Name
    # GET /api/datasources/name/:name

    # Get data source Id by Name
    # GET /api/datasources/id/:name

    # Update an existing data source
    #
    # merge an current existing datasource configuration with the new values
    #
    # @param [Hash] params
    # @option params [Mixed] name Name or Id of the current existing Datasource (required)
    # @option params [Mixed] organisation Name or Id of an existing Organisation
    # @option params [String] type Datasource Type - (required) (grafana graphite cloudwatch elasticsearch prometheus influxdb mysql opentsdb postgres)
    # @option params [String] new_name  New Datasource Name
    # @option params [String] database  Datasource Database
    # @option params [String] access (proxy) Acess Type
    # @option params [Boolean] default (false)
    # @option params [String] user
    # @option params [String] password
    # @option params [String] url Datasource URL
    # @option params [Hash] json_data
    # @option params [String] basic_user
    # @option params [String] basic_password
    #
    # @example
    #    params = {
    #      name: 'graphite',
    #      new_name: 'influx',
    #      organisation: 'Main Org.',
    #      type: 'influxdb',
    #      url: 'http://localhost:8090'
    #    }
    #    update_datasource( params )
    #
    # @return [Hash]
    #
    def update_datasource( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      name = validate( params, required: true, var: 'name' )
      organisation  = validate( params, required: false, var: 'organisation' )
      type          = validate( params, required: false, var: 'type', type: String )
      new_name      = validate( params, required: false, var: 'new_name', type: String )
      database    = validate( params, required: false, var: 'database', type: String )
      access      = validate( params, required: false, var: 'access', type: String ) || 'proxy'
      default     = validate( params, required: false, var: 'default', type: Boolean ) || false
      user        = validate( params, required: false, var: 'user', type: String )
      password    = validate( params, required: false, var: 'password', type: String )
      url         = validate( params, required: false, var: 'url', type: String )
      json_data   = validate( params, required: false, var: 'json_data', type: Hash )
      ba_user     = validate( params, required: false, var: 'basic_user', type: String )
      ba_password = validate( params, required: false, var: 'basic_password', type: String )
      basic_auth  = false
      basic_auth  = true unless( ba_user.nil? && ba_password.nil? )
      org_id      = nil

      raise ArgumentError.new(format('wrong type. user \'name\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', name.class.to_s)) if( name.is_a?(String) && name.is_a?(Integer) )

      if( organisation )
        raise ArgumentError.new(format('wrong type. user \'organisation\' must be an String (for an Organisation name) or an Integer (for an Organisation Id), given \'%s\'', organisation.class.to_s)) if( organisation.is_a?(String) && organisation.is_a?(Integer) )
        org    = organization( organisation )
        org_id = org.dig('id')

        return { 'status' => 404, 'message' => format('Organization \'%s\' not found', organization) } if( org.nil? || org.dig('status').to_i != 200 )
      end

      existing_ds = datasource(name)
      existing_ds.reject! { |x| x == 'status' }
      existing_ds = existing_ds.deep_string_keys
      datasource_id = existing_ds.dig('id')

      return { 'status' => 404, 'message' => format('No Datasource \'%s\' found', name) } if( datasource_id.nil? )

      raise format('Data Source Id can not be 0') if( datasource_id.zero? )

      unless( type.nil? )
        valid_types = %w[grafana graphite cloudwatch elasticsearch prometheus influxdb mysql opentsdb postgres]
        raise ArgumentError.new(format('wrong datasource type. only %s allowed, given \%s\'', valid_types.join(', '), type)) if( valid_types.include?(type.downcase) == false )
      end

      data = {
        id: datasource_id,
        orgId: org_id,
        name: new_name,
        type: type,
        access: access,
        url: url,
        password: password,
        user: user,
        database: database,
        basicAuth: basic_auth,
        basicAuthUser: ba_user,
        basicAuthPassword: ba_user,
        isDefault: default,
        jsonData: json_data
      }
      data.reject!{ |_k, v| v.nil? }

      payload = data.deep_string_keys
      payload = existing_ds.merge(payload).deep_symbolize_keys

      endpoint = format('/api/datasources/%d', datasource_id )

      @logger.debug("Updating data source Id #{datasource_id} (GET #{endpoint})") if  @debug
      logger.debug(payload.to_json) if(@debug)

      put( endpoint, payload.to_json )
    end

    # Create data source
    #
    # @param [Hash] params
    # @option params [String] type Datasource Type - (required) (grafana graphite cloudwatch elasticsearch prometheus influxdb mysql opentsdb postgres)
    # @option params [String] name  Datasource Name - (required)
    # @option params [String] database  Datasource Database - (required)
    # @option params [String] access (proxy) Acess Type - (required) (proxy or direct)
    # @option params [Boolean] default (false)
    # @option params [String] password
    # @option params [String] url Datasource URL - (required)
    # @option params [Hash] json_data
    # @option params [Hash] json_secure
    # @option params [String] basic_user
    # @option params [String] basic_password
    #
    # @example
    #    params = {
    #      name: 'graphite',
    #      type: 'graphite',
    #      database: 'graphite',
    #      url: 'http://localhost:8080'
    #    }
    #    create_datasource(params)
    #
    #    params = {
    #      name: 'graphite',
    #      type: 'graphite',
    #      database: 'graphite',
    #      default: true,
    #      url: 'http://localhost:8080',
    #      json_data: { graphiteVersion: '1.1' }
    #    }
    #    create_datasource(params)
    #
    #    params = {
    #      name: 'test_datasource',
    #      type: 'cloudwatch',
    #      url: 'http://monitoring.us-west-1.amazonaws.com',
    #      json_data: {
    #        authType: 'keys',
    #        defaultRegion: 'us-west-1'
    #      },
    #      json_secure: {
    #        accessKey: 'Ol4pIDpeKSA6XikgOl4p',
    #        secretKey: 'dGVzdCBrZXkgYmxlYXNlIGRvbid0IHN0ZWFs'
    #      }
    #    }
    #    create_datasource(params)
    #
    # @return [Hash]
    #
    def create_datasource( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      type        = validate( params, required: true, var: 'type', type: String )
      name        = validate( params, required: true, var: 'name', type: String )
      database    = validate( params, required: true, var: 'database', type: String )
      access      = validate( params, required: false, var: 'access', type: String ) || 'proxy'
      default     = validate( params, required: false, var: 'default', type: Boolean ) || false
      password    = validate( params, required: false, var: 'password', type: String )
      url         = validate( params, required: true, var: 'url', type: String )
      json_data   = validate( params, required: false, var: 'json_data', type: Hash )
      json_secure = validate( params, required: false, var: 'json_secure', type: Hash )
      ba_user     = validate( params, required: false, var: 'basic_user', type: String )
      ba_password = validate( params, required: false, var: 'basic_password', type: String )

      basic_auth  = false
      basic_auth  = true unless( ba_user.nil? && ba_password.nil? )

      valid_types = %w[grafana graphite cloudwatch elasticsearch prometheus influxdb mysql opentsdb postgres]

      raise ArgumentError.new(format('wrong datasource type. only %s allowed, given \%s\'', valid_types.join(', '), type)) if( valid_types.include?(type.downcase) == false )

      payload = {
        isDefault: default,
        basicAuth: basic_auth,
        basicAuthUser: ba_user,
        basicAuthPassword: ba_password,
        name: name,
        type: type,
        url: url,
        access: access,
        jsonData: json_data,
        secureJsonData: json_secure
      }

      payload.reject!{ |_k, v| v.nil? }

      if( @debug )
        logger.debug("Creating data source: #{name} (database: #{database})")
        logger.debug( payload.to_json )
      end

      endpoint = '/api/datasources'
      post(endpoint, payload.to_json)
    end

    # Delete an existing data source by id
    #
    # @param [Mixed] datasource_id Datasource Name (String) or Datasource Id (Integer) for delete Datasource
    #
    # @example
    #    delete_datasource( 1 )
    #    delete_datasource( 'foo' )
    #
    # @return [Hash]
    #
    def delete_datasource( datasource_id )

      raise ArgumentError.new(format('wrong type. user \'datasource_id\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', datasource_id.class.to_s)) if( datasource_id.is_a?(String) && datasource_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'datasource_id\'') if( datasource_id.size.zero? )

      if(datasource_id.is_a?(String))
        data = datasources.select { |_k,v| v['name'] == datasource_id }
        datasource_id = data.keys.first if( data )
      end

      return { 'status' => 404, 'message' => format( 'No Datasource \'%s\' found', datasource_id) } if( datasource_id.nil? )

      raise format('Data Source Id can not be 0') if( datasource_id.zero? )

      endpoint = format('/api/datasources/%d', datasource_id)
      logger.debug("Deleting data source Id #{datasource_id} (DELETE #{endpoint})") if @debug

      delete(endpoint)
    end


    # Delete an existing data source by name
    # DELETE /api/datasources/name/:datasourceName

    # Data source proxy calls
    # GET /api/datasources/proxy/:datasourceId/*



  end

end

