# frozen_string_literal: true

require 'generators/deimos/schema_model_generator'

RSpec.describe Deimos::Generators::SchemaModelGenerator do
  after(:all) do
    # FileUtils.rm_rf('app') if File.exist?('app')
  end

  it 'should generate a schema model class' do
    described_class.start(['com.my-namespace.Generated'])
    files = Dir['app/lib/schema_models/com/my-namespace/*.rb']
    expect(files.length).to eq(1)
    results = <<~CLASS
      module Deimos
        # :nodoc:
        class GeneratedSchema < SchemaModel
          enum an_enum: {sym1: 'sym1', sym2: 'sym2'}

          # @override
          def schema
            'com.my-namespace.Generated'
          end
        end
      end
    CLASS
    expect(File.read(files[0])).to eq(results)
  end

  # it 'should validate a payload.' do
  #   # schema_model =
  #   GeneratedSchema.validate({})
  # end

end
