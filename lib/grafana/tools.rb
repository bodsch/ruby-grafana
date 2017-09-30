
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
