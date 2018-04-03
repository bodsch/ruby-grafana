module Grafana

  # http://docs.grafana.org/http_api/folder/#folder-api
  #
  module Folder

    # Get all folders
    # GET /api/folders
    # Returns all folders that the authenticated user has permission to view.
    #
    # @example
    #    folders
    #
    # @return [Hash]
    #
    def folders

      status = 200
      folders = []

      endpoint = '/api/folders'
      @logger.debug("Getting all folders (GET #{endpoint})") if @debug
      get(endpoint)

      # { status: status, folders: folders }
    end

    # Get folder by uid
    # GET /api/folders/:uid
    #
    # Will return the folder given the folder uid.
    #
    # Get folder by id
    # GET /api/folders/:id
    #
    # Will return the folder identified by id.
    def folder( folder_id )

      raise ArgumentError.new(format('wrong type. user \'folder_id\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', folder_id.class.to_s)) if( folder_id.is_a?(String) && folder_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'folder_id\'') if( folder_id.size.zero? )

      if(folder_id.is_a?(String))
        user_map = {}

        usrs  = folders
        usrs  = JSON.parse(usrs) if(usrs.is_a?(String))
        status = usrs.dig('status')

        return usrs if( status != 200 )

        usrs.dig('message').each do |d|
          usr_id = d.dig('id').to_i
          user_map[usr_id] = d
        end

        folder_id = user_map.select { |_k,v| v['login'] == folder_id || v['email'] == folder_id || v['name'] == folder_id }.keys.first
      end

      return { 'status' => 404, 'message' => format( 'No User \'%s\' found', folder_id) } if( folder_id.nil? )

      endpoint = format( '/api/folders/%s', folder_id )

      @logger.debug("Getting folder by Id #{folder_id} (GET #{endpoint})") if @debug
      data = get(endpoint)
      data['id'] = folder_id
      data
    end

    # Create folder
    # POST /api/folders
    #
    # Creates a new folder.
    # JSON Body schema:
    #
    #   uid   – Optional unique identifier.
    #   title – The title of the folder.
    def create_folder( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      title = validate( params, required: false, var: 'title' )
      uid   = validate( params, required: true, var: 'uid' )

#      raise ArgumentError.new(format('wrong type. user \'name\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', name.class.to_s)) if( name.is_a?(String) && name.is_a?(Integer) )

      data = {
        uid: uid,
        title: title
      }
      data.reject!{ |_k, v| v.nil? }

      payload = data.deep_string_keys

      endpoint = '/api/folders'

      @logger.debug("create folder#{title} (GET #{endpoint})") if  @debug
      logger.debug(payload.to_json) if(@debug)

      post( endpoint, payload.to_json )
    end

    # Update folder
    # PUT /api/folders/:uid
    #
    # Updates an existing folder identified by uid.
    # JSON Body schema:
    #
    #   - uid – Provide another unique identifier than stored to change the unique identifier.
    #   - title – The title of the folder.
    #   - version – Provide the current version to be able to update the folder. Not needed if overwrite=true.
    #   - overwrite – Set to true if you want to overwrite existing folder with newer version.
    def update_folder(); end


    # Delete folder
    # DELETE /api/folders/:uid
    #
    # Deletes an existing folder identified by uid together with all dashboards stored in the folder, if any. This operation cannot be reverted.
    def delete_folder(); end







  end
end

