class GeneratedSchema < SchemaModel
  enum an_enum: {sym1: 'sym1', sym2: 'sym2'}

  # @override
  def schema
    'com.my-namespace.Generated'
  end
end
