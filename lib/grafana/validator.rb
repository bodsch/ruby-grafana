
module Grafana

  # namespace for validate options
  module Validator

    # validate( params, { required: true, var: name, type: String } )
    def validate( params, options )
      required = options.dig(:required) || false
      var      = options.dig(:var)
      type     = options.dig(:type)

      params   = params.deep_symbolize_keys
      variable = params.dig(var.to_sym)

      raise ArgumentError.new(format('\'%s\' is requiered and missing!', var)) if(variable.nil?) if(required == true )

      unless( type.nil? )
        clazz = Object.const_get(type.to_s)
        raise ArgumentError.new(format('wrong type. \'%s\' must be an %s, given \'%s\'', var, type, variable.class.to_s)) unless( variable.nil? || variable.is_a?(clazz) )
      end

      variable
    end

  end
end

