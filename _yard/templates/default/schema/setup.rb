include T('default/module')

def init
  sections :schema
end

def schema
  @schema = object

  # Nest the item type inside the "array" string if the
  # property takes an array, e.g., (array (JSONModel(:subject)))
  @schema[:properties].each do |_p, defn|
    next unless defn['type']

    if (defn['type'] == 'array') && (defn['items']['type'] == 'object') && !defn['items']['properties'].nil?
      defn['type'] += " (Object (#{defn['items']['properties'].keys.join(', ')}))"
    elsif (defn['type'] == 'array') && defn['items']['type']
      defn['type'] += " (#{defn['items']['type']})"
    end

    defn['type'] += " (max length: #{defn['maxLength']})" if defn['maxLength']
  end

  erb(:schema)
end
