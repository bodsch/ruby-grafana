
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

        return { 'status' => 404, 'message' => format( 'No Playlist \'%s\' found', playlist_id) } if( data.size == 0 )

        if( data.size != 0 )

          _d = []
          data.each do |k,v|
            _d << playlist( k['id'] )
          end
          return { 'status' => status, 'playlists' => _d }
        end
#        return { 'status' => 200, 'message' => data } if( data.size != 0 )
      end

      raise format('playlist id can not be 0') if( playlist_id.zero? )

      endpoint = format('/api/playlists/%d', playlist_id )

#      puts endpoint

      @logger.debug("Attempting to get existing playlist id #{playlist_id} (GET #{endpoint})") if  @debug

      result = get(endpoint)
#      puts result

      return { 'status' => 404, 'message' => 'playlist is empty', 'items' => [] } if( result.dig('status') == 404 )

      return result
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

      _playlists = playlists

      begin
        status  = _playlists.dig('status')
        message = _playlists.dig('message')

        if( status == 200 )

          data = message.select { |k| k['id'] == playlist_id } if( playlist_id.is_a?(Integer) )
          data = message.select { |k| k['name'] == playlist_id } if( playlist_id.is_a?(String) )

          return { 'status' => 404, 'message' => 'No Playlist found' } if( !data.is_a?(Array) || data.count == 0 || status.to_i != 200 )
          return { 'status' => 404, 'message' => format('found %d playlists with name %s', data.count, playlist_id ) } if( data.count > 1 && multi_result == false )

          id = data.first.dig('id')
        else
          return _playlists
        end
      rescue
        return { 'status' => 404, 'message' => 'No Playlists found' } if( playlists.nil? || playlists == false || playlists.dig('status').to_i != 200 )
      end

      endpoint = "/api/playlists/#{id}/items"

      result = get( endpoint )

      return { 'status' => 404, 'message' => 'playlist is empty' } if( result.dig('status') == 404 )

      return result
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
#      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

      name     = validate( params, required: true , var: 'name'      , type: String )
      interval = validate( params, required: true , var: 'interval'  , type: String )
      items    = validate( params, required: true , var: 'items'     , type: Array )

      return { 'status' => 404, 'message' => 'There are no elements for a playlist' } if(items.count == 0)

      _items   = []

      items.each do |r|
        _element = {}

        if( r['name'] )

          _name = search_dashboards( query: r['name'] )
          _name_status = _name.dig('status')

          next unless( _name_status == 200 )

          _name = _name.dig('message')
          _name_id = _name.first.dig('id')
          _name_title = _name.first.dig('title')

          _element[:type]  = 'dashboard_by_id'
          _element[:value] = _name_id.to_s
          _element[:title] = _name_title

        elsif( r['id'] )

          _uid = dashboard_by_uid(r['id'])
          _uid_status = _uid.dig('status')

          next unless( _uid_status == 200 )

          _element[:type]  = 'dashboard_by_id'
          _element[:value] = r['id']

        elsif( r['tag'] )

          _tags = search_dashboards( tags: r['tag'] )
          _tags_status = _tags.dig('status')

          next unless( _tags_status == 200 )

          _element[:type]  = 'dashboard_by_tag'
          _element[:value] = r['tag']
          _element[:title] = r['tag']

        else
          next
        end

        _element[:order] = r['order'] if(r['order'])

        _items << _element if(_element.count == 4)
      end


      payload = {
        'name'=> name,
        'interval'=> interval,
        'items' => _items
      }
      payload.reject!{ |_k, v| v.nil? }

#       p "payload: #{payload.to_json} (#{payload.class})"

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

    def update_playlist() ; end


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

      _playlists = playlists

      data = []

      begin
        status  = _playlists.dig('status')
        message = _playlists.dig('message')

        if( status == 200 )

          data = message.select { |k| k['id'] == playlist_id } if( playlist_id.is_a?(Integer) )
          data = message.select { |k| k['name'] == playlist_id } if( playlist_id.is_a?(String) )

          return { 'status' => 404, 'message' => 'no playlist found' } if( !data.is_a?(Array) || data.count == 0 || status.to_i != 200 )
          return { 'status' => 404, 'message' => format('found %d playlists with name %s', data.count, playlist_id ) } if( data.count > 1 && multi_result == false )

#           puts data.count
#           puts "data: #{data} (#{data.class})"
        else
          return _playlists
        end
      rescue
        return { 'status' => 404, 'message' => 'no playlists found' } if( playlists.nil? || playlists == false || playlists.dig('status').to_i != 200 )
      end

      if( multi_result == true )

        result = { 'status' => 0, 'message' => 'under development' }
        data.each do |x|

          endpoint = format( '/api/playlists/%d', x.dig('id') )

          begin
#             puts endpoint
            result = delete( endpoint )
#             puts result
          rescue => error
            puts "error: #{error}"
          end
        end

        return result
        # { 'status' => 0, 'message' => 'under development' }
      else

        playlist_id = data.first.dig('id')

        endpoint = format( '/api/playlists/%d', playlist_id )
#         puts endpoint

        result = delete( endpoint )

#         puts result

        if(result.dig('status').to_i == 500)

          # check if the playlist exists
          r = playlist( playlist_id )
          return { 'status' => 200, 'message' => 'playlist deleted' } if(r.dig('status').to_i == 404)
#          return { 'status' => 0, 'message' => 'under development' }
        end

        return result
      end

    end

  end
end
