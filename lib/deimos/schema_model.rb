# frozen_string_literal: true

require 'avro'

module Deimos
  # base class of the schema classes generated from Avro Schemas
  class SchemaModel
    # @param payload [Hash] Decoded payload.
    def self.initialize(payload)
      @payload = payload
    end

    # Returns the schema name of the inheriting class.
    # @return [String]
    def schema
      raise NotImplementedError
    end

    # @param payload [Hash] Decoded payload.
    def validate(payload)
      Avro::SchemaValidator.validate!(avro_schema(schema), payload,
                                      recursive: true,
                                      fail_on_extra_fields: true)
    end

  end
end
