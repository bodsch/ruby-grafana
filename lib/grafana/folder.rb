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
    def folder( folder_uid )

      raise ArgumentError.new(format('wrong type. user \'folder_uid\' must be an String (for an Folder Uid) or an Integer (for an Folder Id), given \'%s\'', folder_uid.class.to_s)) if( folder_uid.is_a?(String) && folder_uid.is_a?(Integer) )
      raise ArgumentError.new('missing \'folder_uid\'') if( folder_uid.size.zero? )

      if(folder_uid.is_a?(Integer))
        folder_map = {}

        usrs  = folders
        usrs  = JSON.parse(usrs) if(usrs.is_a?(String))
        status = usrs.dig('status')

        return usrs if( status != 200 )

        usrs = usrs.dig('message').detect {|f| f['id'] == folder_uid }

        return { 'status' => 404, 'message' => format( 'No Folder \'%s\' found', folder_uid) } if( folder_uid.nil? )

        folder_uid = usrs.dig('uid') unless(usrs.nil?)

        return { 'status' => 404, 'message' => format( 'No Folder \'%s\' found', folder_uid) } if( folder_uid.is_a?(Integer) )
      end

      return { 'status' => 404, 'message' => format( 'No Folder \'%s\' found', folder_uid) } if( folder_uid.nil? )

      endpoint = format( '/api/folders/%s', folder_uid )

      @logger.debug("Getting folder by Id #{folder_uid} (GET #{endpoint})") if @debug
      get(endpoint)
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
    # Deletes an existing folder identified by uid together with all dashboards stored in the folder, if any.
    # This operation cannot be reverted.
    def delete_folder( folder_uid )

      raise ArgumentError.new(format('wrong type. user \'folder_uid\' must be an String (for an Folder Uid) or an Integer (for an Folder Id), given \'%s\'', folder_uid.class.to_s)) if( folder_uid.is_a?(String) && folder_uid.is_a?(Integer) )
      raise ArgumentError.new('missing \'folder_uid\'') if( folder_uid.size.zero? )

      if(folder_uid.is_a?(Integer))

        fldrs  = folders

        fldrs  = JSON.parse(fldrs) if(fldrs.is_a?(String))
        status = fldrs.dig('status')

        return fldrs if( status != 200 )

        fldrs.dig('message').each do |d|
          folder_uid = d.dig('uid').to_s
        end
      end

      return { 'status' => 404, 'message' => format( 'No User \'%s\' found', folder_uid) } if( folder_uid.nil? )

      endpoint = format( '/api/folders/%s', folder_uid )

      @logger.debug("deleting folder by uid #{folder_uid} (GET #{endpoint})") if @debug
      delete(endpoint)


    end







  end
end

