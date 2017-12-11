module Grafana

  module Tags

    # expand the Template Tags
    #
    #
    #
    def expand_tags( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      dashboard       = validate( params, required: true, var: 'dashboard', type: Hash )
      additional_tags = validate( params, required: true, var: 'additional_tags', type: Array )

      # add tags
      # dashboard = JSON.parse( dashboard ) if( dashboard.is_a?( String ) )

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
