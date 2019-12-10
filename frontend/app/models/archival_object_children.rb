class ArchivalObjectChildren < ArchivalRecordChildren
  def self.uri_and_remaining_options_for(_id = nil, opts = {})
    substitute_parameters('/repositories/:repo_id/archival_objects/:archival_object_id/children', opts)
  end
end
