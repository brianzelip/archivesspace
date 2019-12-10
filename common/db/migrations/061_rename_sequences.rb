require_relative 'utils'

Sequel.migration do
  # dedupe and rename existing sequences see:
  # https://archivesspace.atlassian.net/browse/AR-1326

  up do
    puts 'Renaming all sequences, this may take a while...'

    start_time = Time.now

    count = self[:sequence].count
    i = 0

    self[:sequence].order(:value).each do |row|
      i += 1

      puts "#{i} rows / #{((i.to_f / count) * 100).round(2)}% complete" if i % 1000 == 0

      name = row[:sequence_name]
      value = row[:value]

      # Fix sequence names for children of the root record
      self[:sequence].filter(sequence_name: name).update(sequence_name: name.sub(/__/, '_')) if name.match(/__/)

      next unless name.match(%r{/repositories/(\d)+/(resource|digital_object|classification)s/(\d+)_/repositories/\d+/(archival_object|digital_object_component|classification_term)s/(\d+)_children_position})

      repo_id = Regexp.last_match(1)
      root_record_type = Regexp.last_match(2)
      root_id = Regexp.last_match(3)
      record_type = Regexp.last_match(4)
      tree_node_id = Regexp.last_match(5)

      all_sequences = self[:sequence].where("value >= #{value}").where(Sequel.like(:sequence_name, "%\_/repositories/#{repo_id}/#{record_type}s/#{tree_node_id}\_children\_position"))

      next unless all_sequences.count > 0 # already gone
      next unless all_sequences.select(:sequence_name).first[:sequence_name] == name

      sequence_val = if all_sequences.count > 1
                       puts "Merging duplicates for sequence: #{name}"
                       # reset the sequence value if there are multiple versions
                       children = self[record_type.intern].filter(parent_id: tree_node_id)
                       if children.count == 0
                         0
                       else
                         self[record_type.intern].filter(parent_id: tree_node_id).order(:position).select(:position).last[:position]
                       end
                     else
                       row[:value]
                     end

      # delete old sequences
      all_sequences.delete

      # update the name and value
      new_name = "/repositories/#{repo_id}/#{record_type}s/#{tree_node_id}_children_position"

      self[:sequence].insert(sequence_name: new_name, value: sequence_val)
    end

    end_time = Time.now

    puts "Total time to rename sequences: #{end_time - start_time}"
  end

  down do
  end
end
