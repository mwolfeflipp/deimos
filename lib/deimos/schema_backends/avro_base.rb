# frozen_string_literal: true

require_relative 'base'
require 'avro'
require 'avro_turf'
require 'avro_turf/mutable_schema_store'
require_relative 'avro_schema_coercer'

module Deimos
  module SchemaBackends
    # Encode / decode using Avro, either locally or via schema registry.
    class AvroBase < Base
      attr_accessor :schema_store

      # @override
      def initialize(schema:, namespace:)
        super(schema: schema, namespace: namespace)
        @schema_store = AvroTurf::MutableSchemaStore.new(path: Deimos.config.schema.path)
      end

      # @override
      def encode_key(key_id, key, topic: nil)
        @key_schema ||= _generate_key_schema(key_id)
        field_name = _field_name_from_schema(@key_schema)
        payload = { field_name => key }
        encode(payload, schema: @key_schema['name'], topic: topic)
      end

      # @override
      def decode_key(payload, key_id)
        @key_schema ||= _generate_key_schema(key_id)
        field_name = _field_name_from_schema(@key_schema)
        decode(payload, schema: @key_schema['name'])[field_name]
      end

      # @override
      def coerce_field(field, value)
        AvroSchemaCoercer.new(avro_schema).coerce_type(field.type, value)
      end

      # @override
      def schema_fields
        avro_schema.fields.map { |field| SchemaField.new(field.name, field.type) }
      end

      # @override
      def validate(payload, schema:)
        Avro::SchemaValidator.validate!(avro_schema(schema), payload,
                                        recursive: true,
                                        fail_on_extra_fields: true)
      end

      # @override
      def self.mock_backend
        :avro_validation
      end

    private

      # @param schema [String]
      # @return [Avro::Schema]
      def avro_schema(schema=nil)
        schema ||= @schema
        @schema_store.find(schema, @namespace)
      end

      # Generate a key schema from the given value schema and key ID. This
      # is used when encoding or decoding keys from an existing value schema.
      # @param key_id [Symbol]
      # @return [Hash]
      def _generate_key_schema(key_id)
        key_field = avro_schema.fields.find { |f| f.name == key_id.to_s }
        name = _key_schema_name(@schema)
        key_schema = {
          'type' => 'record',
          'name' => name,
          'namespace' => @namespace,
          'doc' => "Key for #{@namespace}.#{@schema}",
          'fields' => [
            {
              'name' => key_id,
              'type' => key_field.type.type_sym.to_s
            }
          ]
        }
        @schema_store.add_schema(key_schema)
        key_schema
      end

      # @param value_schema [Hash]
      # @return [String]
      def _field_name_from_schema(value_schema)
        raise "Schema #{@schema} not found!" if value_schema.nil?
        if value_schema['fields'].nil? || value_schema['fields'].empty?
          raise "Schema #{@schema} has no fields!"
        end

        value_schema['fields'][0]['name']
      end

      # @param schema [String]
      # @return [String]
      def _key_schema_name(schema)
        "#{schema.gsub('-value', '')}_key"
      end
    end
  end
end
