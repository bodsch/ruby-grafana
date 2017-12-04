
module Grafana

  # http://docs.grafana.org/http_api/data_source/
  #
  module Datasource

    # Get all datasources
    # GET /api/datasources
    def data_sources

      endpoint = '/api/datasources'

      @logger.debug("Attempting to get all existing data sources (GET #{endpoint})") if @debug

      data_sources = get( endpoint )

      if  data_sources.nil? || data_sources.dig('status').to_i != 200
        return {
          'status' => 404,
          'message' => 'No Datasources found'
        }
      end

      data_sources = data_sources.dig('message')

      data_source_map = {}
      data_sources.each do |ds|
        data_source_map[ds['id']] = ds
      end

      data_source_map
    end

    # Get a single data sources by Id
    # GET /api/datasources/:datasourceId
    def data_source( id )

      if( id.is_a?(String) && id.is_a?(Integer) )
        raise ArgumentError.new('data source id must be an String (for an Data Source name) or an Integer (for an Data Source Id)')
      end

      data_source_id = id if(id.is_a?(Integer))

      if(id.is_a?(String))

        data = data_sources.select { |_k,v| v['name'] == id }

        data_source_id = data.keys.first if  data
      end

      if( data_source_id.nil? )
        return {
          'status' => 404,
          'message' => format( 'No Datasource \'%s\' found', id)
        }
      end

      raise format('Data Source Id can not be 0') if( data_source_id.zero? )

      endpoint = format('/api/datasources/%d', data_source_id )
      @logger.debug("Attempting to get existing data source Id #{data_source_id} (GET #{endpoint})") if  @debug

      get(endpoint)
    end

    # Get a single data source by Name
    # GET /api/datasources/name/:name

    # Get data source Id by Name
    # GET /api/datasources/id/:name

    # Update an existing data source
    # PUT /api/datasources/:datasourceId
    def update_datasource( params = {} )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )

      datasource = params.dig(:datasource)
      data       = params.dig(:data)

      if( !datasource.is_a?(String) && !datasource.is_a?(Integer) )
        raise ArgumentError.new('datasource must be an String (for an Data Source name) or an Integer (for an Data Source Id)')
      end

      raise ArgumentError.new('data must be an Hash') unless( data.is_a?(Hash) )

      existing_ds = data_source(datasource)

      existing_ds.reject! { |x| x == 'status' }
      data_source_id = existing_ds.dig('id')

      existing_ds = existing_ds.deep_string_keys
      data        = data.deep_string_keys

      ds = existing_ds.merge(data)

      endpoint = format('/api/datasources/%d', data_source_id )
      @logger.debug("Updating data source Id #{data_source_id} (GET #{endpoint})") if  @debug
      put( endpoint, ds.to_json )
    end

    # Create data source
    # POST /api/datasources
    def create_datasource( params = {} )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )

      type         = params.dig(:type)
      name         = params.dig(:name)
      dba          = params.dig(:database)
      access       = params.dig(:access)
      default      = params.dig(:default)
      user         = params.dig(:user)
      password     = params.dig(:password)
      url          = params.dig(:url)
      json_data    = params.dig(:jsonData)
      json_secure  = params.dig(:secureJsonData)
      ba_user      = params.dig(:basic_auth_user)
      ba_password  = params.dig(:basic_auth_password)

      default      = default.to_s.eql?('true') ? true : false

      raise ArgumentError.new('datasource name must be an String') unless( name.is_a?(String) )
      raise ArgumentError.new('datasource database must be an String') unless( dba.is_a?(String) )
      raise ArgumentError.new('datasource type must be an String') unless( type.is_a?(String) )
      raise ArgumentError.new('datasource access must be an String') unless( access.is_a?(String) )
      raise ArgumentError.new(format('datasource default must be an Boolean give \'%s\' (%s)', default, default.class.to_s) ) unless( default.is_a?(Boolean) )
      raise ArgumentError.new('datasource url must be an String') unless( url.is_a?(String) )

#       raise ArgumentError.new('datasource jsonData must be an String') unless( json_data.is_a?(String) )

      params['isDefault'] = true if( default == true )

      if( !ba_user.nil? && !ba_password.nil? )

        params['basicAuth'] = true
        params['basicAuthUser'] = ba_user
        params['basicAuthPassword'] = ba_password

        params.delete(:basic_auth_user)
        params.delete(:basic_auth_password)
      end

      params.delete('default')

      @logger.debug("Creating data source: #{name} (database: #{dba})")
      @logger.debug( params )

      endpoint = '/api/datasources'
      post(endpoint, params.to_json)
    end

    # Delete an existing data source by id
    # DELETE /api/datasources/:datasourceId
    def delete_datasource(id)

      if( id.is_a?(String) && id.is_a?(Integer) )
        raise ArgumentError.new('data source id must be an String (for an Data Source name) or an Integer (for an Data Source Id)')
      end

      data_source_id = id if(id.is_a?(Integer))

      if(id.is_a?(String))

        data = data_sources.select { |_k,v| v['name'] == id }

        data_source_id = data.keys.first if  data
      end

      if( data_source_id.nil? )
        return {
          'status' => 404,
          'message' => format( 'No Datasource \'%s\' found', id)
        }
      end

      raise format('Data Source Id can not be 0') if( data_source_id.zero? )

      endpoint = format('/api/datasources/%d', data_source_id)
      @logger.debug("Deleting data source Id #{data_source_id} (DELETE #{endpoint})") if @debug

      delete(endpoint)
    end


    # Delete an existing data source by name
    # DELETE /api/datasources/name/:datasourceName

    # Data source proxy calls
    # GET /api/datasources/proxy/:datasourceId/*



  end

end

