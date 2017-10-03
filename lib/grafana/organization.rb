
module Grafana

  # http://docs.grafana.org/http_api/org/#organisation-api
  #
  module Organization

    # Get current Organisation
    # GET /api/org
    #
    #  -> {"id"=>1, "name"=>"Docker", "address"=>{"address1"=>"", "address2"=>"", "city"=>"", "zipCode"=>"", "state"=>"", "country"=>""}, "status"=>200}
    #
    def current_organization
      endpoint = '/api/org'
      @logger.debug("Get current Organisation (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Update current Organisation
    # PUT /api/org
    #
    #
    #
    def update_current_organization( params = {} )

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )
      name = params.dig(:name)
      raise ArgumentError.new('missing name') if( name.nil? )

      endpoint = '/api/org'
      @logger.debug("Updating current organization (PUT #{endpoint})") if @debug
      put(endpoint, params.to_json)
    end

    # Get all users within the actual organisation
    # GET /api/org/users
    #
    #
    #
    def current_organization_users
      endpoint = '/api/org/users'
      @logger.debug("Getting organization users (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Add a new user to the actual organisation
    # POST /api/org/users
    #
    #
    #
    def add_user_to_current_organization( params = {} )

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )
      login_or_email = params.dig(:loginOrEmail)
      role           = params.dig(:role)
      raise ArgumentError.new('missing loginOrEmail') if( login_or_email.nil? )
      raise ArgumentError.new('missing role') if( role.nil? )
      # Defaults to Viewer, other valid options are Admin and Editor and Read Only Editor
      # valid_perms = ['Viewer','Editor','Read Only Editor','Admin']
      raise ArgumentError.new( format( 'wrong role. only \'Admin\', \'Viewer\' or \'Editor\' allowed (\'%s\' giving)',role)) if( %w[Admin Viewer Editor].include?(role) == false )

      org = current_organization_users
      usr = user_by_name( login_or_email )

      if( org )

        org = org.dig('message')

        if( org.select { |x| x.dig('email') == login_or_email }.count >= 1 )
          return {
            'status' => 404,
            'message' => format('User \'%s\' are already in the organisation', login_or_email)
          }
        end
      end

      if( usr.nil? || usr.dig('status').to_i != 200 )
        return {
          'status' => 404,
          'message' => format('User \'%s\' not found', login_or_email)
        }
      end

      endpoint = '/api/org/users'
      @logger.debug("Adding user to current organization (POST #{endpoint})") if @debug
      post(endpoint, params.to_json)
    end

    # Updates the given user
    # PATCH /api/org/users/:userId


    # Delete user in actual organisation
    # DELETE /api/org/users/:userId


    #

  end

end
