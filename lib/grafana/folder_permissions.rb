module Grafana

  # http://docs.grafana.org/http_api/folder_permissions/#folder-permissions-api
  #
  # This API can be used to update/get the permissions for a folder.
  #
  # Permissions with folderId=-1 are the default permissions for users with the Viewer and Editor roles.
  # Permissions can be set for a user, a team or a role (Viewer or Editor).
  # Permissions cannot be set for Admins - they always have access to everything.
  #
  # The permission levels for the permission field:
  #
  # 1 = View
  # 2 = Edit
  # 4 = Admin
  #
  module FolderPermissions

    # Get permissions for a folder
    # GET /api/folders/:uid/permissions
    #
    # Gets all existing permissions for the folder with the given uid.
    def folder_permissions( folder_id )

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)

      f = folder( folder_id )

      status = f.dig('status')
      return f if( status != 200 )

      endpoint = format('/api/folders/%s/permissions', f.dig('uid') )

      @logger.debug("Getting all folders (GET #{endpoint})") if @debug
      get(endpoint)
    end


    # Update permissions for a folder
    # POST /api/folders/:uid/permissions
    #
    # Updates permissions for a folder.
    # This operation will remove existing permissions if they’re not included in the request.
    #
    # JSON body schema:
    #
    # items - The permission items to add/update. Items that are omitted from the list will be removed.
    #
    def update_folder_permissions( params )

#       raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
#       raise ArgumentError.new('missing \'params\'') if( params.size.zero? )
#
#       v, mv = version.values
#       return { 'status' => 404, 'message' => format( 'only Grafana 5 has folder support. you use version %s', v) } if(mv != 5)
#
#       folder      = validate( params, required: true, var: 'folder'    , type: String )
#       permissions = validate( params, required: true, var: 'permission', type: Hash )
#
#       valid_roles = ['View', 'Edit', 'Admin']
#       valid_keys  = ['role','permission','teamId','userId']
#
#         grafana_admin = permissions.dig(:grafana_admin)
#         unless( grafana_admin.is_a?(Boolean) )
#           return {
#             'status' => 404,
#             'name' => user_name,
#             'permissions' => permissions,
#             'message' => 'Grafana admin permission must be either \'true\' or \'false\''
#           }
#         end
#
#       role
#       permission
#       teamId
#       userId
#
#
#       #hasAcl"=>false,
#       #"canSave"=>true,
#       #"canEdit"=>true,
#       #"canAdmin"=>true
    end

  end
end

