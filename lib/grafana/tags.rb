module Grafana

  module Tags

    # expand the Template Tags
    #
    #
    #
    def expand_tags( params = {} )

      raise ArgumentError.new('params must be an Hash') unless( params.is_a?(Hash) )

      dashboard        = params.dig(:dashboard)
      additional_tags  = params.dig(:additional_tags) || []

      raise ArgumentError.new('dashboard must be am Hash') unless( dashboard.is_a?(Hash) )
      raise ArgumentError.new('additional_tags must be an Array') unless( additional_tags.is_a?(Array) )

      # add tags
      dashboard = JSON.parse( dashboard ) if( dashboard.is_a?( String ) )

      additional_tags = additional_tags.values if( additional_tags.is_a?( Hash ) )

      current_tags = dashboard.dig( 'dashboard', 'tags' )

      if( !current_tags.nil? && additional_tags.count > 0 )

        current_tags << additional_tags

        current_tags.flatten!
        current_tags.sort!

        dashboard['dashboard']['tags'] = current_tags
      end

      JSON.generate( dashboard ) if( dashboard.is_a?( Hash ) )
    end

  end

end
