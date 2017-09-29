
module Grafana

  module Login

    def ping_session

      endpoint = '/api/login/ping'

      @logger.info( "Pinging current session (GET #{endpoint})" )

      result = getRequest( endpoint )

      @logger.debug( result )

      result
    end
  end

end
