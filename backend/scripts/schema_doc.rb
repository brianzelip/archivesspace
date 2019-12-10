require 'main'
require 'json'
require 'fileutils'
include JSONModel

FileUtils.mkdir_p File.join('..', 'schema_docs')

File.open(File.join('..', 'schema_docs', 'models.json'), 'w') { |f| f << JSONModel.models.to_json }

JSONModel.models.each_pair do |k, v|
  File.open(File.join('..', 'schema_docs', "#{k}.json"), 'w') do |file|
    json = v.send(:schema)

    json['required'] = []
    json['properties'].each_pair do |k, v|
      json['required'] << k if v.has_key?('ifmissing')
    end

    json['title'] = k
    file << JSON.pretty_generate(json)
  end
end
