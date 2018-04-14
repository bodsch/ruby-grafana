
module Grafana

  # http://docs.grafana.org/http_api/team/
  #
  # This API can be used to create/update/delete Teams and to add/remove users to Teams.
  # All actions require that the user has the Admin role for the organization.
  #
  module Teams

    # http://docs.grafana.org/http_api/team/#team-search-with-paging
    #
    # GET /api/teams/search?perpage=50&page=1&query=mytea
    # or
    # GET /api/teams/search?name=myteam
    #
    # Status Codes:
    #
    # 200 - Ok
    # 401 - Unauthorized
    # 403 - Permission denied
    # 404 - Team not found (if searching by name)
    #
    def search_team()

    end

    # http://docs.grafana.org/http_api/team/#get-team-by-id
    #
    # Get Team By Id
    # GET /api/teams/:id
    #
    #
    def team()


    end

    # http://docs.grafana.org/http_api/team/#add-team
    #
    # The Team name needs to be unique. name is required and email is optional.
    # POST /api/teams
    #
    #
    def add_team()


    end

    # http://docs.grafana.org/http_api/team/#update-team
    #
    # There are two fields that can be updated for a team: name and email.
    # PUT /api/teams/:id
    #
    def update_team()


    end

    # http://docs.grafana.org/http_api/team/#delete-team-by-id
    #
    # DELETE /api/teams/:id
    #
    #
    #
    #
    #
    #
    def delete_team()



    end

    # http://docs.grafana.org/http_api/team/#get-team-members
    #
    # GET /api/teams/:teamId/members
    #
    #
    #
    #
    def team_members()


    end

    # http://docs.grafana.org/http_api/team/#add-team-member
    #
    # POST /api/teams/:teamId/members
    #
    #
    #
    def add_team_member()


    end

    # http://docs.grafana.org/http_api/team/#remove-member-from-team
    #
    # DELETE /api/teams/:teamId/members/:userId
    #
    #
    #
    def remove_team_meber()


    end

  end
end
