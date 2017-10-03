
module Grafana

  module Tools

    def slug( text )

      raise ArgumentError.new('text must be an String') unless( text.is_a?(String) )

      if( text =~ /\s/ )

        text = if( text =~ /-/ )
          text.gsub( /\s+/, '' )
        else
          text.gsub( /\s+/, '-' )
        end

        return text.downcase
      end

      text
    end


    def regenerate_template_ids( json )

      raise ArgumentError.new('json must be an Hash') unless( json.is_a?(Hash) )

      rows = json.dig('dashboard','rows')

      if( rows.nil? )

        # counter = 1
        id_counter = 10
        rows.each_with_index do |r, _counter|

          panel = r.dig('panels')

          next if( panel.nil? )

          panel.each do |p|
            p['id']   = id_counter
            id_counter = id_counter +=1 # id_counter+1 # id_counter +=1 ??
          end
        end
      end

      JSON.generate( json )

    end


    def valid_json?( json )

        JSON.parse( json ) if( json.is_a?(String) )
        return true
      rescue JSON::ParserError => e
        @logger.error("json parse error: #{e}") if @debug
        return false

    end

  end

end
