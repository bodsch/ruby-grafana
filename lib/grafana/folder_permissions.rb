module Grafana

  # http://docs.grafana.org/http_api/folder_permissions/#folder-permissions-api
  #
  module FolderPermissions

    # Get permissions for a folder
    # GET /api/folders/:uid/permissions
    #
    # Gets all existing permissions for the folder with the given uid.
    def folder_permissions(); end


    # Update permissions for a folder
    # POST /api/folders/:uid/permissions
    #
    # Updates permissions for a folder. This operation will remove existing permissions if they’re not included in the request.
    #
    # JSON body schema:
    #
    # items - The permission items to add/update. Items that are omitted from the list will be removed.
    def update_folder_permissions(); end



























  end
end

