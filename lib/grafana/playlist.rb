
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
    def playlists() ; end

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

    def playlist( params ) ; end

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

    def playlist_items() ; end

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

    def playlist_dashboards(); end

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

    def delete_playlist(); end

  end
end
