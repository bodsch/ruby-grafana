
module Grafana

  # http://docs.grafana.org/http_api/org/#organisation-api
  #
  module Organization

    # Get current Organisation
    #
    # @example
    #    current_organization
    #
    # @return [Hash]
    #
    def current_organization
      endpoint = '/api/org'
      @logger.debug("Get current Organisation (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Update current Organisation
    #
    # @param [Hash] params
    # @option params [String] name new Organisation Name
    #
    # @example
    #    params = {
    #       name: 'foo'
    #    }
    #    update_current_organization( params )
    #
    # @return [Hash]
    #
    def update_current_organization( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      name         = validate( params, required: true, var: 'name', type: String )

      endpoint = '/api/org'
      payload = {
        name: name
      }

      @logger.debug("Updating current organization (PUT #{endpoint})") if @debug
      put(endpoint, payload.to_json)
    end

    # Get all users within the actual organisation
    #
    # @example
    #    current_organization_users
    #
    # @return [Hash]
    #
    def current_organization_users
      endpoint = '/api/org/users'
      @logger.debug("Getting organization users (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # Add a new user to the actual organisation
    #
    # @param [Hash] params
    # @option params [String] login_or_email Login or email
    # @option params [String] role Name of the Role - only 'Viewer', 'Editor', 'Read Only Editor' or 'Admin' allowed
    #
    # @example
    #    params = {
    #       login_or_email: 'foo',
    #       role: 'Editor'
    #    }
    #    add_user_to_current_organization( params )
    #
    # @return [Hash]
    #
    def add_user_to_current_organization( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      login_or_email = validate( params, required: true, var: 'login_or_email', type: String )
      role           = validate( params, required: true, var: 'role', type: String )
      valid_roles    = ['Viewer', 'Editor', 'Read Only Editor', 'Admin']

      # https://stackoverflow.com/questions/9333952/case-insensitive-arrayinclude?answertab=votes#tab-top
      # Do this once, or each time the array changes
      downcased = Set.new valid_roles.map(&:downcase)
      unless( downcased.include?( role.downcase ) )
        return {
          'status' => 404,
          'login_or_email' => login_or_email,
          'role' => role,
          'message' => format( 'wrong role. Role must be one of %s, given \'%s\'', valid_roles.join(', '), role )
        }
      end

      org = current_organization_users
      usr = user( login_or_email )

      return { 'status' => 404, 'message' => format('User \'%s\' not found', login_or_email) } if( usr.nil? || usr.dig('status').to_i != 200 )

      if( org.is_a?(Hash) && org.dig('status').to_i == 200 )
        org = org.dig('message')
        return { 'status' => 404, 'message' => format('User \'%s\' are already in the organisation', login_or_email) } \
          if( org.select { |x| x.dig('email') == login_or_email || x.dig('login') == login_or_email }.count >= 1 )
      end

      endpoint = '/api/org/users'
      payload = {
        loginOrEmail: login_or_email,
        role: role
      }

      @logger.debug("Adding user to current organization (POST #{endpoint})") if @debug
      post(endpoint, payload.to_json)
    end

    # Updates the given user
    # PATCH /api/org/users/:userId


    # Delete user in actual organisation
    # DELETE /api/org/users/:userId


    #

  end

end
