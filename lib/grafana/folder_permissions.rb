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
      return { 'status' => 404, 'message' => format( 'folder has been supported in Grafana since version 5. you use version %s', v) } if(mv < 5)

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
    # This operation will remove existing permissions if they're not included in the request.
    #
    # JSON body schema:
    #
    # items - The permission items to add/update. Items that are omitted from the list will be removed.
    #
    def update_folder_permissions( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      v, mv = version.values
      return { 'status' => 404, 'message' => format( 'folder has been supported in Grafana since version 5. you use version %s', v) } if(mv < 5)

      folder      = validate( params, required: true, var: 'folder'     , type: String )
      permissions = validate( params, required: true, var: 'permissions', type: Hash )

      return { 'status' => 404, 'message' => 'no permissions given' } if( permissions.size.zero? )

      f_folder = folder(folder)
      return { 'status' => 404, 'message' => format( 'No Folder \'%s\' found', folder) } if( f_folder.dig('status') != 200 )

      folder_uid = f_folder.dig('uid')

      valid_roles = %w[View Edit Admin]
#       valid_keys  = %w[role permission teamId userId]

      c_team = permissions.dig('team')
      c_user = permissions.dig('user')
      team   = []
      user   = []

      unless(c_team.nil?)
        check_keys = []

        c_team.uniq.each do |x|
          k = x.keys.first
          v = x.values.first
          r = validate_hash( v, valid_roles )

          f_team = team(k)
          team_id = f_team.dig('id')

          next unless(( f_team.dig('status') == 200) && !check_keys.include?(team_id) && r == true )

          check_keys << team_id

          role_id = valid_roles.index(v)
          role_id += 1
          role_id += 1 if(v == 'Admin')

          team << {
            teamId: team_id,
            permission: role_id
          }
        end
      end

      unless(c_user.nil?)
        check_keys = []

        c_user.uniq.each do |x|
          k = x.keys.first
          v = x.values.first
          r = validate_hash( v, valid_roles )

          f_user = user(k)
          user_id = f_user.dig('id')

          next unless(( f_user.dig('status') == 200) && !check_keys.include?(user_id) && r == true )

          check_keys << user_id

          role_id = valid_roles.index(v)
          role_id += 1
          role_id += 1 if(v == 'Admin')

          user << {
            userId: user_id,
            permission: role_id
          }
        end
      end

      payload = {
        items: team + user
      }
      payload.reject!{ |_, y| y.nil? }

      endpoint = format( '/api/folders/%s/permissions', folder_uid )

      post(endpoint, payload.to_json)
    end


#    private
#    def validate_hash( value, valid_params )
#
#      downcased = Set.new valid_params.map(&:downcase)
#
#      unless( downcased.include?( value.downcase ) )
#        return {
#          'status' => 404,
#          'message' => format( 'wrong permissions. Must be one of %s, given \'%s\'', valid_params.join(', '), value )
#        }
#      end
#      true
#    end

  end
end

