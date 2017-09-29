
module Grafana

  module Datasource

    # Getting data source namespaces (POST /api/datasources/proxy/#{datasource_id})
#     def namespaces(datasource_id)
#
#       endpoint = "/api/datasources/proxy/#{datasource_id}"
#       return postRequest( endpoint, { "action" => "__GetNamespaces" }.to_json )
#     end


    def dataSources

      endpoint = '/api/datasources'
      logger.debug("Attempting to get existing data sources (GET #{endpoint})")

      data_sources = getRequest( endpoint )

      return false unless  data_sources 

      data_source_map = {}
      data_sources.each do |ds|
        data_source_map[ds['id']] = ds
      end

      data_source_map
    end


    def dataSource(id)
      endpoint = "/api/datasources/#{id}"
      logger.debug("Attempting to get existing data source ID #{id}")
      getRequest(endpoint)
    end


    def updateDataSource( id, ds = {} )
      existing_ds = dataSource(id)
      ds = existing_ds.merge(ds)
      endpoint = "/api/datasources/#{id}"
      logger.debug("Updating data source ID #{id}")
      putRequest(endpoint, ds.to_json)
    end


    def createDataSource( ds = {} )
      if ds == {} || !ds.key?('name') || !ds.key?('database')
        logger.error("Error: missing 'name' and 'database' values!")
        return false
      end
      endpoint = '/api/datasources'
      logger.debug("Creating data source: #{ds['name']} (database: #{ds['database']})")
      postRequest(endpoint, ds.to_json)
    end


    def deleteDataSource(id)
      endpoint = "/api/datasources/#{id}"
      logger.debug("Deleting data source #{id} (DELETE #{endpoint})")
      deleteRequest(endpoint)
    end


    def availableDataSourceTypes
      endpoint = '/api/datasources'
      logger.debug("Attempting to get existing data source types (GET #{endpoint})")
      getRequest(endpoint)
    end

  end

end
