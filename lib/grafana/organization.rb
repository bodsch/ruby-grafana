
module Grafana

  # http://docs.grafana.org/http_api/org/
  module Organization

    # result
    #   {"id"=>1, "name"=>"Docker", "address"=>{"address1"=>"", "address2"=>"", "city"=>"", "zipCode"=>"", "state"=>"", "country"=>""}, "status"=>200}
    #
    def current_organization
      endpoint = '/api/org'
      @logger.info("Get current Organisation (GET #{endpoint})") if @debug
      get(endpoint)
    end


    def update_current_organization(properties={})
      endpoint = '/api/org'
      @logger.info("Updating current organization (PUT #{endpoint})") if @debug
      putRequest(endpoint, properties)
    end


    def current_organization_users
      endpoint = '/api/org/users'
      @logger.info("Getting organization users (GET #{endpoint})") if @debug
      get(endpoint)
    end


    def add_user_to_current_organization( properties = {} )
      endpoint = '/api/org/users'
      @logger.info("Adding user to current organization (POST #{endpoint})") if @debug
      post(endpoint, properties)
    end


  end

end
