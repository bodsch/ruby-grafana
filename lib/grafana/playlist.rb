
module Grafana

  # +++
  # title = "Playlist HTTP API "
  # description = "Playlist Admin HTTP API"
  # keywords = ["grafana", "http", "documentation", "api", "playlist"]
  # aliases = ["/http_api/playlist/"]
  # type = "docs"
  # [menu.docs]
  # name = "Playlist"
  # parent = "http_api"
  # +++

  # https://github.com/grafana/grafana/blob/1165d098b0d0ae705955f9d2ea104beea98ca6eb/pkg/api/dtos/playlist.go

  module Playlist

    ## Playlist API
    #
    ### Search Playlist
    #
    #`GET /api/playlists`
    #
    #Get all existing playlist for the current organization using pagination
    #
    #**Example Request**:
    #
    #```bash
    #GET /api/playlists HTTP/1.1
    #Accept: application/json
    #Authorization: Bearer eyJrIjoiT0tTcG1pUlY2RnVKZTFVaDFsNFZXdE9ZWmNrMkZYbk
    #```
    #
    #  Querystring Parameters:
    #
    #  These parameters are used as querystring parameters.
    #
    #  - **query** - Limit response to playlist having a name like this value.
    #  - **limit** - Limit response to *X* number of playlist.
    #
    #**Example Response**:
    #
    #```json
    #HTTP/1.1 200
    #Content-Type: application/json
    #[
    #  {
    #    "id": 1,
    #    "name": "my playlist",
    #    "interval": "5m"
    #  }
    #]
    #```
    def playlists

      endpoint = '/api/playlists'

      @logger.debug("Attempting to get all existing playlists (GET #{endpoint})") if @debug

      playlists = get( endpoint )

      return { 'status' => 404, 'message' => 'No Playlists found' } if( playlists.nil? || playlists == false || playlists.dig('status').to_i != 200 )

      playlists
    end

    ### Get one playlist
    #
    #`GET /api/playlists/:id`
    #
    #**Example Request**:
    #
    #```bash
    #GET /api/playlists/1 HTTP/1.1
    #Accept: application/json
    #Authorization: Bearer eyJrIjoiT0tTcG1pUlY2RnVKZTFVaDFsNFZXdE9ZWmNrMkZYbk
    #```
    #
    #**Example Response**:
    #
    #```json
    #HTTP/1.1 200
    #Content-Type: application/json
    #{
    #  "id" : 1,
    #  "name": "my playlist",
    #  "interval": "5m",
    #  "orgId": "my org",
    #  "items": [
    #    {
    #      "id": 1,
    #      "playlistId": 1,
    #      "type": "dashboard_by_id",
    #      "value": "3",
    #      "order": 1,
    #      "title":"my third dasboard"
    #    },
    #    {
    #      "id": 2,
    #      "playlistId": 1,
    #      "type": "dashboard_by_tag",
    #      "value": "myTag",
    #      "order": 2,
    #      "title":"my other dasboard"
    #    }
    #  ]
    #}
    #```

    def playlist( playlist_id )

      if( playlist_id.is_a?(String) && playlist_id.is_a?(Integer) )
        raise ArgumentError.new(format('wrong type. \'playlist_id\' must be an String (for an Playlist name) or an Integer (for an Playlist Id), given \'%s\'', playlist_id.class.to_s))
      end
      raise ArgumentError.new('missing \'playlist_id\'') if( playlist_id.size.zero? )

      if(playlist_id.is_a?(String))

        data = playlists
        status = data.dig('status')
        d = data.dig('message')
        data = d.select { |k| k['name'] == playlist_id }

        return { 'status' => 404, 'message' => format( 'No Playlist \'%s\' found', playlist_id) } if( data.size.zero? )

        unless( empty? )

          playlist_data = []
          # data.each do |k,_v|
          data.each_key do |k|
            playlist_data << playlist( k['id'] )
          end
          return { 'status' => status, 'playlists' => playlist_data }
        end
#        return { 'status' => 200, 'message' => data } if( data.size != 0 )
      end

      raise format('playlist id can not be 0') if( playlist_id.zero? )

      endpoint = format('/api/playlists/%d', playlist_id )

      @logger.debug("Attempting to get existing playlist id #{playlist_id} (GET #{endpoint})") if  @debug

      result = get(endpoint)

      return { 'status' => 404, 'message' => 'playlist is empty', 'items' => [] } if( result.dig('status') == 404 )

      result
    end

    ### Get Playlist items

    #`GET /api/playlists/:id/items`
    #
    #**Example Request**:
    #
    #```bash
    #GET /api/playlists/1/items HTTP/1.1
    #Accept: application/json
    #Authorization: Bearer eyJrIjoiT0tTcG1pUlY2RnVKZTFVaDFsNFZXdE9ZWmNrMkZYbk
    #```
    #
    #**Example Response**:
    #
    #```json
    #HTTP/1.1 200
    #Content-Type: application/json
    #[
    #  {
    #    "id": 1,
    #    "playlistId": 1,
    #    "type": "dashboard_by_id",
    #    "value": "3",
    #    "order": 1,
    #    "title":"my third dasboard"
    #  },
    #  {
    #    "id": 2,
    #    "playlistId": 1,
    #    "type": "dashboard_by_tag",
    #    "value": "myTag",
    #    "order": 2,
    #    "title":"my other dasboard"
    #  }
    #]
    #```

    def playlist_items( playlist_id, multi_result = false )

      if( playlist_id.is_a?(String) && playlist_id.is_a?(Integer) )
        raise ArgumentError.new(format('wrong type. \'playlist_id\' must be an String (for an playlist name) or an Integer (for an playlist Id), given \'%s\'', playlist_id.class.to_s))
      end
      raise ArgumentError.new('missing \'playlist_id\'') if( playlist_id.size.zero? )

      tmp_playlists = playlists

      begin
        status  = tmp_playlists.dig('status').to_i
        message = tmp_playlists.dig('message')

        return tmp_playlists if( status != 200 )

        data = message.select { |k| k['id'] == playlist_id } if( playlist_id.is_a?(Integer) )
        data = message.select { |k| k['name'] == playlist_id } if( playlist_id.is_a?(String) )

        return { 'status' => 404, 'message' => 'No Playlist found' } if( !data.is_a?(Array) || data.count.zero? || status.to_i != 200 )
        return { 'status' => 404, 'message' => format('found %d playlists with name %s', data.count, playlist_id ) } if( data.count > 1 && multi_result == false )

        id = data.first.dig('id')

      rescue
        return { 'status' => 404, 'message' => 'No Playlists found' } if( playlists.nil? || playlists == false || playlists.dig('status').to_i != 200 )
      end

      endpoint = "/api/playlists/#{id}/items"

      result = get( endpoint )

      return { 'status' => 404, 'message' => 'playlist is empty' } if( result.dig('status') == 404 )

      result
    end

    ### Get Playlist dashboards
    #
    #`GET /api/playlists/:id/dashboards`
    #
    #**Example Request**:
    #
    #```bash
    #GET /api/playlists/1/dashboards HTTP/1.1
    #Accept: application/json
    #Authorization: Bearer eyJrIjoiT0tTcG1pUlY2RnVKZTFVaDFsNFZXdE9ZWmNrMkZYbk
    #```
    #
    #**Example Response**:
    #
    #```json
    #HTTP/1.1 200
    #Content-Type: application/json
    #[
    #  {
    #    "id": 3,
    #    "title": "my third dasboard",
    #    "order": 1,
    #  },
    #  {
    #    "id": 5,
    #    "title":"my other dasboard"
    #    "order": 2,
    #
    #  }
    #]
    #```

    def playlist_dashboards( playlist_id )

      raise ArgumentError.new(format('wrong type. \'playlist_id\' must be an Integer, given \'%s\'', playlist_id.class)) unless( playlist_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'playlist_id\'') if( playlist_id.size.zero? )

      endpoint = format('/api/playlists/%s/dashboards', playlist_id)

      @logger.debug( "Attempting to get playlist (GET #{endpoint})" ) if @debug
      get(endpoint)
    end

    # Create a playlist

    # `POST /api/playlists/`
    #
    #**Example Request**:
    #
    #```bash
    #PUT /api/playlists/1 HTTP/1.1
    #Accept: application/json
    #Content-Type: application/json
    #Authorization: Bearer eyJrIjoiT0tTcG1pUlY2RnVKZTFVaDFsNFZXdE9ZWmNrMkZYbk
    #  {
    #    "name": "my playlist",
    #    "interval": "5m",
    #    "items": [
    #      {
    #        "type": "dashboard_by_id",
    #        "value": "3",
    #        "order": 1,
    #        "title":"my third dasboard"
    #      },
    #      {
    #        "type": "dashboard_by_tag",
    #        "value": "myTag",
    #        "order": 2,
    #        "title":"my other dasboard"
    #      }
    #    ]
    #  }
    #```
    #
    #**Example Response**:
    #
    #```json
    #HTTP/1.1 200
    #Content-Type: application/json
    #  {
    #    "id": 1,
    #    "name": "my playlist",
    #    "interval": "5m"
    #  }
    #```

    def create_playlist( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

#      v, mv = version.values
#      return { 'status' => 404, 'message' => format( 'folder has been supported in Grafana since version 5. you use version %s', v) } if(mv < 5)

      name     = validate( params, required: true , var: 'name'      , type: String )
      interval = validate( params, required: true , var: 'interval'  , type: String )
      items    = validate( params, required: true , var: 'items'     , type: Array )

      return { 'status' => 404, 'message' => 'There are no elements for a playlist' } if(items.count.zero?)

      payload_items = create_playlist_items(items)

      payload = {
        name:     name,
        interval: interval,
        items:    payload_items
      }
      payload.reject!{ |_k, v| v.nil? }

      endpoint = '/api/playlists'

      post(endpoint, payload.to_json)
    end

    ### Update a playlist
    #
    #`PUT /api/playlists/:id`
    #
    #**Example Request**:
    #
    #```bash
    #PUT /api/playlists/1 HTTP/1.1
    #Accept: application/json
    #Content-Type: application/json
    #Authorization: Bearer eyJrIjoiT0tTcG1pUlY2RnVKZTFVaDFsNFZXdE9ZWmNrMkZYbk
    #  {
    #    "name": "my playlist",
    #    "interval": "5m",
    #    "items": [
    #      {
    #        "playlistId": 1,
    #        "type": "dashboard_by_id",
    #        "value": "3",
    #        "order": 1,
    #        "title":"my third dasboard"
    #      },
    #      {
    #        "playlistId": 1,
    #        "type": "dashboard_by_tag",
    #        "value": "myTag",
    #        "order": 2,
    #        "title":"my other dasboard"
    #      }
    #    ]
    #  }
    #```
    #
    #**Example Response**:
    #
    #```json
    #HTTP/1.1 200
    #Content-Type: application/json
    #{
    #  "id" : 1,
    #  "name": "my playlist",
    #  "interval": "5m",
    #  "orgId": "my org",
    #  "items": [
    #    {
    #      "id": 1,
    #      "playlistId": 1,
    #      "type": "dashboard_by_id",
    #      "value": "3",
    #      "order": 1,
    #      "title":"my third dasboard"
    #    },
    #    {
    #      "id": 2,
    #      "playlistId": 1,
    #      "type": "dashboard_by_tag",
    #      "value": "myTag",
    #      "order": 2,
    #      "title":"my other dasboard"
    #    }
    #  ]
    #}
    #```

    def update_playlist( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      playlist_id   = validate( params, required: true , var: 'playlist' )
      name          = validate( params, required: false, var: 'name' )
      interval      = validate( params, required: false, var: 'interval', type: String )
      # organisation = validate( params, required: false, var: 'organisation' )
      items         = validate( params, required: false, var: 'items', type: Array )

      tmp_playlists    = playlists

      data = []

      begin
        status  = tmp_playlists.dig('status').to_i
        message = tmp_playlists.dig('message')

        return tmp_playlists if( status != 200 )

        data = message.select { |k| k['id'] == playlist_id } if( playlist_id.is_a?(Integer) )
        data = message.select { |k| k['name'] == playlist_id } if( playlist_id.is_a?(String) )

        return { 'status' => 404, 'message' => 'no playlist found' } if( !data.is_a?(Array) || data.count.zero? || status.to_i != 200 )
        return { 'status' => 404, 'message' => format('found %d playlists with name %s', data.count, playlist_id ) } if( data.count > 1 && multi_result == false )

      rescue
        return { 'status' => 404, 'message' => 'no playlists found' } if( playlists.nil? || playlists == false || playlists.dig('status').to_i != 200 )
      end

      playlist_id   = data.first.dig('id')
      # playlist_name = data.first.dig('name')
      payload_items = create_playlist_items(items, playlist_id)

      payload = {
        id:       playlist_id,
        name:     name,
        interval: interval,
        items:    payload_items
      }
      payload.reject!{ |_k, v| v.nil? }

      endpoint = format( '/api/playlists/%d', playlist_id )

      put( endpoint, payload.to_json )

    end


    ### Delete a playlist
    #
    #`DELETE /api/playlists/:id`
    #
    #**Example Request**:
    #
    #```bash
    #DELETE /api/playlists/1 HTTP/1.1
    #Accept: application/json
    #Authorization: Bearer eyJrIjoiT0tTcG1pUlY2RnVKZTFVaDFsNFZXdE9ZWmNrMkZYbk
    #```
    #
    #**Example Response**:
    #
    #```json
    #HTTP/1.1 200
    #Content-Type: application/json
    #{}
    #```

    def delete_playlist(playlist_id, multi_result = false )

      if( playlist_id.is_a?(String) && playlist_id.is_a?(Integer) )
        raise ArgumentError.new(format('wrong type. \'playlist_id\' must be an String (for an Playlist name) or an Integer (for an Playlist Id), given \'%s\'', playlist_id.class.to_s))
      end
      raise ArgumentError.new('missing \'playlist_id\'') if( playlist_id.size.zero? )

      tmp_playlists = playlists

      data = []

      begin
        status  = tmp_playlists.dig('status').to_i
        message = tmp_playlists.dig('message')

        return tmp_playlists if( status != 200 )

        data = message.select { |k| k['id'] == playlist_id } if( playlist_id.is_a?(Integer) )
        data = message.select { |k| k['name'] == playlist_id } if( playlist_id.is_a?(String) )

        return { 'status' => 404, 'message' => 'no playlist found' } if( !data.is_a?(Array) || data.count.zero? || status.to_i != 200 )
        return { 'status' => 404, 'message' => format('found %d playlists with name %s', data.count, playlist_id ) } if( data.count > 1 && multi_result == false )

      rescue
        return { 'status' => 404, 'message' => 'no playlists found' } if( playlists.nil? || playlists == false || playlists.dig('status').to_i != 200 )
      end

      if( multi_result == true )

        result = { 'status' => 0, 'message' => 'under development' }
        data.each do |x|

          endpoint = format( '/api/playlists/%d', x.dig('id') )

          begin
            result = delete( endpoint )
          rescue => error
            logger.error( "error: #{error}" )
          end
        end

        # return result
      else

        playlist_id = data.first.dig('id')

        endpoint = format( '/api/playlists/%d', playlist_id )

        result = delete( endpoint )

        if(result.dig('status').to_i == 500)
          # check if the playlist exists
          r = playlist( playlist_id )
          return { 'status' => 200, 'message' => 'playlist deleted' } if(r.dig('status').to_i == 404)
        end

        # return result
      end

      result
    end


    private
    def create_playlist_items( items, playlist_id = nil)

      playlist_items   = []

      items.each do |r|
        playlist_element = {}

        if( r['name'] )

          playlist_name = search_dashboards( query: r['name'] )
          playlist_name_status = playlist_name.dig('status')

          next unless( playlist_name_status == 200 )

          playlist_name       = playlist_name.dig('message')
          playlist_name_id    = playlist_name.first.dig('id')
          playlist_name_title = playlist_name.first.dig('title')

          playlist_element[:type]  = 'dashboard_by_id'
          playlist_element[:value] = playlist_name_id.to_s
          playlist_element[:title] = playlist_name_title
          playlist_element[:playlistId] = playlist_id unless(playlist_id.nil?)

        elsif( r['id'] )

          uid = dashboard_by_uid(r['id'])
          uid_status = uid.dig('status')

          next unless( uid_status == 200 )

          playlist_element[:type]  = 'dashboard_by_id'
          playlist_element[:value] = r['id']
          playlist_element[:playlistId] = playlist_id unless(playlist_id.nil?)

        elsif( r['tag'] )

          tags        = search_dashboards( tags: r['tag'] )
          tags_status = tags.dig('status')

          next unless( tags_status == 200 )

          playlist_element[:type]  = 'dashboard_by_tag'
          playlist_element[:value] = r['tag']
          playlist_element[:title] = r['tag']
          playlist_element[:playlistId] = playlist_id unless(playlist_id.nil?)

        else
          next
        end

        playlist_element[:order] = r['order'] if(r['order'])

        playlist_items << playlist_element if(playlist_element.count >= 4)
      end

      playlist_items
    end

  end
end
