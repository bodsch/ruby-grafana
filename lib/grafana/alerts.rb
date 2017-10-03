
module Grafana

  # http://docs.grafana.org/http_api/alerting/
  #
  module Alerts

    # Get alerts
    # GET /api/alerts/
    #
    # Get one alert
    # GET /api/alerts/:id
    #
    def alerts( id = nil ); end

    # Pause alert
    # POST /api/alerts/:id/pause
    def alert_pause( id ); end

    # Get alert notifications
    # GET /api/alert-notifications
    def alert_notifications; end

    # Create alert notification
    # POST /api/alert-notifications
    def create_alert_notification( oarams ); end

    # Update alert notification
    # PUT /api/alert-notifications/1
    def update_alert_notification( params ); end

    # Delete alert notification
    # DELETE /api/alert-notifications/:notificationId
    def delete_alert_notification( id ); end

  end

end
