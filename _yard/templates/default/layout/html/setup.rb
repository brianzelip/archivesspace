def menu_lists
  super + [{ type: 'schema', title: 'Schema List', search_title: 'Schema List' }]
end

def layout
  @nav_url = if object.is_a? YARD::CodeObjects::SchemaObject
               'schema_list.html'
             else
               url_for_list(!(defined?(@file) && @file) || options.index ? 'class' : 'file')
             end

  @path =
    if !object || object.is_a?(String)
      nil
    elsif defined?(@file) && @file
      @file.path
    elsif !object.is_a?(YARD::CodeObjects::NamespaceObject)
      object.parent.path
    else
      object.path
    end

  erb(:layout)
end
