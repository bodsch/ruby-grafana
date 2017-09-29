
module Grafana

  module Tools

    def slug( text )

      if( text =~ /\s/ )

        text = if( text =~ /-/ )
          text.gsub( /\s+/, '' )
        else
          text.gsub( /\s+/, '-' )
        end

        text.downcase
      end

      text
    end

    def regenerate_template_ids( json )

      if( valid_json?( json ) )

        json = JSON.parse( json ) if( json.is_a?(String) )

        rows = json.dig('dashboard','rows')

        if( rows.nil? )

          counter = 1
          idCounter = 10
          rows.each_with_index do |r, counter|

            panel = r.dig('panels')

            next if( panel.nil? )

            panel.each do |p|
              p['id']   = idCounter
              idCounter = idCounter+1 # idCounter +=1 ??
            end
          end
        end

        JSON.generate( json )
      else

        return false
      end

    end


    def valid_json?( json )

#       @logger.debug( json.class.to_s )
#       @logger.debug( json )
      begin
        JSON.parse( json ) if( json.is_a?(String) )
        return true
      rescue JSON::ParserError => e
        @logger.error("json parse error: #{e}") if @debug
        return false
      end

    end

  end

end
