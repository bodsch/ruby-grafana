
module Grafana

  # namespace for validate options
  module Validator

    # validate some parameters
    #
    # @param params [Hash]
    # @param options [Hash]
    # @option options [Boolean] required
    # @option options [String] var
    # @option options [Class] type
    #
    # @example
    #    default = validate( params, required: false, var: 'default', type: Boolean )
    #    name    = validate( params, required: true, var: 'name', type: String )
    #
    # @return [Mixed]
    #
    def validate( params, options )
      required = options.dig(:required) || false
      var      = options.dig(:var)
      type     = options.dig(:type)

      params   = params.deep_symbolize_keys
      variable = params.dig(var.to_sym)

      raise ArgumentError.new(format('\'%s\' is required and missing!', var)) if(variable.nil? && required == true )

      unless( type.nil? )
        clazz = Object.const_get(type.to_s)
        raise ArgumentError.new(format('wrong type. \'%s\' must be an %s, given \'%s\'', var, type, variable.class.to_s)) unless( variable.nil? || variable.is_a?(clazz) )
      end

      variable
    end

    # validate an value with an array of values
    #
    #
    # @return [Mixed]
    #
    def validate_hash( value, valid_params )

#       puts "validate_hash( #{value}, #{valid_params} )"

      unless( valid_params.collect { |r| r.downcase }.include?(value.downcase) )
#         puts "NOOO : #{value}"
        return {
          'status' => 404,
          'message' => format( 'wrong value. \'%s\' must be one of \'%s\'', value, valid_params.join('\', \''))
        }
      end
#      puts "result: #{result} #{result.class}"
#
#
#      downcased = Set.new valid_params.map(&:downcase)
#
#      puts "downcased: #{downcased}"
#
#      unless( downcased.include?( value.downcase ) )
#        return {
#          'status' => 404,
#          'message' => format( 'wrong value. \'%s\' must be one of \'%s\'', value, valid_params.join('\', \''))
#        }
#      end
      true
    end

  end
end

