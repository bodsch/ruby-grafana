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

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

      endpoint = '/api/folders'
      @logger.debug("Getting all folders (GET #{endpoint})") if @debug
      get(endpoint)
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

      raise ArgumentError.new(format('wrong type. user \'folder_uid\' must be an String (for an Folder Uid) or an Integer (for an Folder Id), given \'%s\'', folder_uid.class.to_s)) \
          if( folder_uid.is_a?(String) && folder_uid.is_a?(Integer) )
      raise ArgumentError.new('missing \'folder_uid\'') if( folder_uid.size.zero? )

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

      if(folder_uid.is_a?(Integer))

        f  = folders
        f  = JSON.parse(f) if(f.is_a?(String))

        status = f.dig('status')
        return f if( status != 200 )

        f = f.dig('message').detect {|x| x['id'] == folder_uid }

        return { 'status' => 404, 'message' => format( 'No Folder \'%s\' found', folder_uid) } if( folder_uid.nil? )

        folder_uid = f.dig('uid') unless(f.nil?)

        return { 'status' => 404, 'message' => format( 'No Folder \'%s\' found', folder_uid) } if( folder_uid.is_a?(Integer) )
      end

      return { 'status' => 404, 'message' => format( 'The uid can have a maximum length of 40 characters. \'%s\' given', folder_uid.length) } \
          if( folder_uid.is_a?(String) && folder_uid.length > 40 )
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
    #   uid   - Optional unique identifier.
    #   title - The title of the folder.
    def create_folder( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

      title = validate( params, required: false, var: 'title', type: String )
      uid   = validate( params, required: true , var: 'uid'  , type: String )

      return { 'status' => 404, 'message' => format( 'The uid can have a maximum length of 40 characters. \'%s\' given', uid.length) } if( uid.length > 40 )

      data = {
        uid: uid,
        title: title
      }
      data.reject!{ |_, y| y.nil? }

      payload = data.deep_string_keys

      endpoint = '/api/folders'

      @logger.debug("create folder#{title} (GET #{endpoint})") if  @debug
      logger.debug(payload.to_json) if(@debug)

      post( endpoint, payload.to_json )
    end

    # Update folder
    # PUT /api/folders/:uid
    #
    # schould be fail, when the version are not incremented
    # overwrite helps
    #
    # Updates an existing folder identified by uid.
    # JSON Body schema:
    #
    #   - uid - Provide another unique identifier than stored to change the unique identifier.
    #   - title - The title of the folder.
    #   - version - Provide the current version to be able to update the folder. Not needed if overwrite=true.
    #   - overwrite - Set to true if you want to overwrite existing folder with newer version.
    def update_folder( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

      uid       = validate( params, required: true , var: 'uid'      , type: String )
      title     = validate( params, required: true , var: 'title'    , type: String )
      new_uid   = validate( params, required: false, var: 'new_uid'  , type: String )
      version   = validate( params, required: false, var: 'version'  , type: Integer )
      overwrite = validate( params, required: false, var: 'overwrite', type: Boolean ) || false

      existing_folder = folder( uid )
      return { 'status' => 404, 'message' => format( 'No Folder \'%s\' found', uid) } if( existing_folder.dig('status') != 200 )

      unless( new_uid.nil? )
        existing_folder = folder( new_uid )
        return { 'status' => 404, 'message' => format( 'Folder \'%s\' found', uid) } if( existing_folder.dig('status') == 200 )
      end

      payload = {
        title: title,
        uid: new_uid,
        version: version,
        overwrite: overwrite
      }
      payload.reject!{ |_, y| y.nil? }

      @logger.debug("Updating folder with Uid #{uid}") if @debug

      endpoint = format( '/api/folders/%s', uid )

      put( endpoint, payload.to_json )
    end


    # Delete folder
    # DELETE /api/folders/:uid
    #
    # Deletes an existing folder identified by uid together with all dashboards stored in the folder, if any.
    # This operation cannot be reverted.
    def delete_folder( folder_uid )

      raise ArgumentError.new(format('wrong type. user \'folder_uid\' must be an String (for an Folder Uid) or an Integer (for an Folder Id), given \'%s\'', folder_uid.class.to_s)) \
          if( folder_uid.is_a?(String) && folder_uid.is_a?(Integer) )
      raise ArgumentError.new('missing \'folder_uid\'') if( folder_uid.size.zero? )

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

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

