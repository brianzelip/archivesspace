class DigitalObjectComponentChildren < DigitalRecordChildren
  def self.uri_and_remaining_options_for(_id = nil, opts = {})
    substitute_parameters('/repositories/:repo_id/digital_object_components/:digital_object_component_id/children', opts)
  end
end
