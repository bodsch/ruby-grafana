
module Grafana

  # http://docs.grafana.org/http_api/snapshot/
  #
  module Snapshot

    # Get Snapshot by Id
    # GET /api/snapshots/:key
    def snapshot(key)

      raise ArgumentError.new('key must be an String') unless( key.is_a?(String) )

      endpoint = format('/api/snapshot/%s', key)
      @logger.debug("Get Snapshot by Id #{key} (GET #{endpoint})") if @debug

      get(endpoint)
    end

    # Create new snapshot
    # POST /api/snapshots
    def create_snapshot( dashboard = {} )

      raise ArgumentError.new('dashboard must be an Hash') unless( dashboard.is_a?(String) )

      endpoint = '/api/snapshot'
      @logger.debug("Creating dashboard snapshot (POST #{endpoint})") if @debug

      post(endpoint, dashboard)
    end


    # Delete Snapshot by Id
    # GET /api/snapshots-delete/:key
    def delete_snapshot(key)

      raise ArgumentError.new('key must be an String') unless( key.is_a?(String) )

      endpoint = format( '/api/snapshots-delete/%s', key)
      @logger.debug("Deleting snapshot id #{key} (GET #{endpoint})") if @debug

      delete(endpoint)
    end

  end

end
