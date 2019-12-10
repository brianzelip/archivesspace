module ASModel
  # Code for moving records between repositories
  module RepositoryTransfers
    def self.included(base)
      base.extend(ClassMethods)
    end

    def transfer_to_repository(target_repository, transfer_group = [])
      if self.class.columns.include?(:repo_id)
        old_uri = uri

        source_repository = Repository[repo_id]

        # Do the update in the cheapest way possible (bypassing save hooks, etc.)
        self.class.filter(id: id).update(repo_id: target_repository.id,
                                         system_mtime: Time.now)

        # Mark the (now changed) URI as deleted
        if old_uri
          Tombstone.create(uri: old_uri)
          DB.after_commit do
            RealtimeIndexing.record_delete(old_uri)
          end

          # Create an event if this is the top-level record being transferred.
          if transfer_group.empty?
            RequestContext.open(repo_id: target_repository.id) do
              Event.for_repository_transfer(source_repository, target_repository, self)
            end
          end
        end
      end

      # Tell any nested records to transfer themselves too
      self.class.nested_records.each do |nested_record_defn|
        association = nested_record_defn[:association][:name]
        association_dataset = send("#{association}_dataset".intern)
        nested_model = Kernel.const_get(nested_record_defn[:association][:class_name])

        association_dataset.select(Sequel.qualify(nested_model.table_name, :id)).all.each do |nested_record|
          nested_record.transfer_to_repository(target_repository, transfer_group + [self])
        end
      end
    end

    module ClassMethods
      def report_incompatible_constraints(source_repository, target_repository)
        problems = {}

        repo_unique_constraints.each do |constraint|
          target_repo_values = filter(repo_id: target_repository.id)
                               .select(constraint[:property])

          overlapping_in_source = filter(:repo_id => source_repository.id,
                                         constraint[:property] => target_repo_values)
                                  .select(:id)

          next unless overlapping_in_source.count > 0

          overlapping_in_source.each do |obj|
            problems[obj.uri] ||= []
            problems[obj.uri] << {
              json_property: constraint[:json_property],
              message: constraint[:message]
            }
          end
        end

        raise TransferConstraintError, problems unless problems.empty?
      end

      def transfer_all(source_repository, target_repository)
        if columns.include?(:repo_id)

          report_incompatible_constraints(source_repository, target_repository)

          # One delete marker per URI
          if has_jsonmodel?
            jsonmodel = my_jsonmodel
            filter(repo_id: source_repository.id).select(:id).each do |row|
              Tombstone.create(uri: jsonmodel.uri_for(row[:id], repo_id: source_repository.id))
            end
          end

          filter(repo_id: source_repository.id)
            .update(repo_id: target_repository.id,
                    system_mtime: Time.now)
        end
      end
    end
  end
end
