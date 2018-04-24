
module Grafana

  # namespace for validate options
  module Validator

    # validate some parameters
    #
    # @param params [Hash]
    # @param options [Hash]
    # @option options [Boolean] requiered
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

      raise ArgumentError.new(format('\'%s\' is requiered and missing!', var)) if(variable.nil? && required == true )

      unless( type.nil? )
        clazz = Object.const_get(type.to_s)
        raise ArgumentError.new(format('wrong type. \'%s\' must be an %s, given \'%s\'', var, type, variable.class.to_s)) unless( variable.nil? || variable.is_a?(clazz) )
      end

      variable
    end

  end
end

