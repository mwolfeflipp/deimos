# frozen_string_literal: true

require 'rails/generators'
require 'rails/version'

module Deimos
  module Generators
    class SchemaModelGenerator < Rails::Generators::Base
      source_root File.expand_path('schema_model/templates', __dir__)

      argument :full_schema, desc: 'The fully qualified schema name.', required: true

      no_commands do

        # @return [String]
        def schema
          last_dot = self.full_schema.rindex('.')
          self.full_schema[last_dot + 1..-1]
        end

        # @return [String]
        def namespace
          last_dot = self.full_schema.rindex('.')
          self.full_schema[0...last_dot]
        end

        # @return [String]
        def namespace_path
          namespace.gsub '.', '/'
        end

        # @return [Deimos::SchemaBackends::Base]
        def schema_base
          @schema_base ||= Deimos.schema_backend_class.new(schema: schema, namespace: namespace)
        end

        # @return [Array<SchemaField>]
        def fields
          schema_base.schema_fields
        end

      end

      desc 'Generate a class based on an existing schema.'
      # :nodoc:
      def generate
        template('schema.rb', "app/lib/schema_models/#{namespace_path}/#{schema.underscore}_schema.rb")
      end
    end
  end
end
