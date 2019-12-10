require_relative 'utils'

Sequel.migration do
  up do
    warn('*** ADDING SOME ENUMS')
    enum = self[:enumeration].filter(name: 'note_index_item_type').select(:id)
    gf = self[:enumeration_value].filter(value: 'genre_form', enumeration_id: enum).select(:id).all
    if gf.empty?
      warn('*** Genre Form to note_index_item_type  enum list')
      self[:enumeration_value].insert(enumeration_id: enum, value: 'genre_form', readonly: 1)
    end

    [:resource, :archival_object, :digital_object].each do |klass|
      warn("Triggering reindex of #{klass}")
      self[klass].update(system_mtime: Time.now)
    end
  end
end
