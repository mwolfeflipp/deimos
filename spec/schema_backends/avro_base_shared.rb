# frozen_string_literal: true

require 'deimos/schema_backends/avro_base'

RSpec.shared_examples_for('an Avro backend') do
  let(:backend) { described_class.new(schema: 'MySchema', namespace: 'com.my-namespace') }

  let(:full_schema) do
    {
      'type' => 'record',
      'name' => 'schema1',
      'namespace' => 'com.my-namespace',
      'fields' => [
        {
          'name' => 'int-field',
          'type' => 'int'
        },
        {
          'name' => 'long-field',
          'type' => 'long'
        },
        {
          'name' => 'float-field',
          'type' => 'float'
        },
        {
          'name' => 'double-field',
          'type' => 'double'
        },
        {
          'name' => 'string-field',
          'type' => 'string'
        },
        {
          'name' => 'boolean-field',
          'type' => 'boolean'
        },
        {
          'name' => 'union-field',
          'type' => %w(null string)
        },
        {
          'name' => 'union-int-field',
          'type' => %w(null int)
        }
      ]
    }
  end

  specify('#encode_key') do
    expect(backend).to receive(:encode).
      with({ 'test_id' => 1 }, { schema: 'MySchema_key', topic: 'topic' }).and_return('itsme')
    expect(backend.encode_key('test_id', 1, topic: 'topic')).to eq('itsme')
    expect(backend.schema_store.find('MySchema_key', 'com.my-namespace').to_avro).
      to eq(
        'doc' => 'Key for com.my-namespace.MySchema',
        'fields' => [
          { 'name' => 'test_id', 'type' => 'string' }
        ],
        'name' => 'MySchema_key',
        'namespace' => 'com.my-namespace',
        'type' => 'record'
      )
  end

  specify('#decode_key') do
    expect(backend).to receive(:decode).
      with('payload', schema: 'MySchema_key').
      and_return('test_id' => 1)
    expect(backend.decode_key('payload', 'test_id')).to eq(1)
  end

  describe('#validate') do
    it 'should pass valid schemas' do
      expect {
        backend.validate({ 'test_id' => 'hi', 'some_int' => 4 }, { schema: 'MySchema' })
      }.not_to raise_error
    end

    it 'should fail invalid schemas' do
      expect {
        backend.validate({ 'test_id2' => 'hi', 'some_int' => 4 }, { schema: 'MySchema' })
      }.to raise_error(Avro::SchemaValidator::ValidationError)
    end

  end

  describe '#coerce' do
    let(:payload) do
      {
        'int-field' => 1,
        'long-field' => 11_111_111_111_111_111_111,
        'float-field' => 1.0,
        'double-field' => 2.0,
        'string-field' => 'hi mom',
        'boolean-field' => true,
        'union-field' => nil,
        'union-int-field' => nil
      }
    end

    before(:each) do
      backend.schema_store.add_schema(full_schema)
      backend.schema = 'schema1'
    end

    it 'should leave numbers as is' do
      result = backend.coerce(payload)
      expect(result['int-field']).to eq(1)
      expect(result['long-field']).to eq(11_111_111_111_111_111_111)
      expect(result['float-field']).to eq(1.0)
      expect(result['double-field']).to eq(2.0)
      expect(result['boolean-field']).to eq(true)
      expect(result['union-field']).to eq(nil)
    end

    it 'should coerce strings to numbers' do
      result = backend.coerce(payload.merge(
                                'int-field' => '1',
                                'long-field' => '123',
                                'float-field' => '1.1',
                                'double-field' => '2.1'
                              ))
      expect(result['int-field']).to eq(1)
      expect(result['long-field']).to eq(123)
      expect(result['float-field']).to eq(1.1)
      expect(result['double-field']).to eq(2.1)
    end

    it 'should coerce Time to number' do
      result = backend.coerce(payload.merge('int-field' => Time.find_zone('UTC').local(2019, 5, 5)))
      expect(result['int-field']).to eq(1_557_014_400)
    end

    it 'should coerce symbols to string' do
      result = backend.coerce(payload.merge('string-field' => :itsme))
      expect(result['string-field']).to eq('itsme')
    end

    it 'should convert string-like things to string' do
      stringy = Class.new do
        # :nodoc:
        def initialize(str)
          @st = str
        end

        # :nodoc:
        def to_s
          @st
        end

        # :nodoc:
        def to_str
          @st
        end
      end
      stub_const('Stringy', stringy)
      result = backend.coerce(payload.merge('string-field' => Stringy.new('itsyou')))
      expect(result['string-field']).to eq('itsyou')
    end

    it 'should convert null to false' do
      result = backend.coerce(payload.merge('boolean-field' => nil))
      expect(result['boolean-field']).to eq(false)
    end

    it 'should convert unions' do
      result = backend.coerce(payload.merge('union-field' => :itsme))
      expect(result['union-field']).to eq('itsme')
    end

  end

end
