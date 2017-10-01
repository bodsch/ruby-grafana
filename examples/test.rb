#!/usr/bin/env ruby
# frozen_string_literal: true
#
# 01.10.2017 - Bodo Schulz
#
#
#

# -----------------------------------------------------------------------------

require_relative '../lib/grafana'

# -----------------------------------------------------------------------------

grafana_host = ENV.fetch( 'GRAFANA_HOST' , 'localhost' )
grafana_port = ENV.fetch( 'GRAFANA_PORT' , 3000 )
grafana_user = 'admin'
grafana_password = 'grafana_admin'

config = {
  debug: true,
  grafana: {
    host: grafana_host,
    port: grafana_port
  }
}

# ---------------------------------------------------------------------------------------

g  = Grafana::Client.new( config )

unless( g.nil? )

  g.login(user: grafana_user, password: grafana_password)

  puts g.admin_settings

  puts g.dashboard_tags

  puts g.current_user

  # puts g.update_current_user_password( old_password: grafana_password, new_password: 'admin' )

end
