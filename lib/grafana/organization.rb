
module Grafana

  # http://docs.grafana.org/http_api/org/#organisation-api
  module Organization

    # Get current Organisation
    # GET /api/org
    #
    #  -> {"id"=>1, "name"=>"Docker", "address"=>{"address1"=>"", "address2"=>"", "city"=>"", "zipCode"=>"", "state"=>"", "country"=>""}, "status"=>200}
    #
    def current_organization
      endpoint = '/api/org'
      @logger.info("Get current Organisation (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Update current Organisation
    # PUT /api/org
    #
    #
    #
    def update_current_organization(properties={})
      endpoint = '/api/org'
      @logger.info("Updating current organization (PUT #{endpoint})") if @debug
      putRequest(endpoint, properties)
    end

    # Get all users within the actual organisation
    # GET /api/org/users
    #
    #
    #
    def current_organization_users
      endpoint = '/api/org/users'
      @logger.info("Getting organization users (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Add a new user to the actual organisation
    # POST /api/org/users
    #
    #
    #
    def add_user_to_current_organization( properties = {} )
      endpoint = '/api/org/users'
      @logger.info("Adding user to current organization (POST #{endpoint})") if @debug
      post(endpoint, properties)
    end

    # Updates the given user
    # PATCH /api/org/users/:userId


    # Delete user in actual organisation
    # DELETE /api/org/users/:userId


    #

  end

end
