class EnumerationValue < Sequel::Model(:enumeration_value)
  include ASModel
  corresponds_to JSONModel(:enumeration_value)
  set_model_scope :global

  many_to_one :enumeration

  enable_suppression

  def before_create
    # bit clunky but this allows us to make sure that bulk updates are
    # positioned correctly
    unless position
      self.position = rand(1_000_000..1_000_099) # lets just give it a randomly high number
    end
    obj = super
    # now let's set it in the list
    100.times do
      DB.attempt {
        sibling = self.class.dataset.filter(enumeration_id: enumeration_id).order(:position).last
        if sibling
          self.class.dataset.db[self.class.table_name].filter(id: id).update(position: sibling[:position] + 1)
        else
          self.class.dataset.db[self.class.table_name].filter(id: id).update(position: 0)
        end
        return
      }.and_if_constraint_fails {
        # another transaction has slipped in...let's try again
      }
    end
    obj
  end

  def update_position_only(target_position)
    # we need to swap places with what we're trying to replace.
    current_position = position
    sibling = self.class.dataset.filter(enumeration_id: enumeration_id, position: target_position).first

    self.class.dataset.filter(enumeration_id: enumeration_id, position: target_position).update(position: Sequel.lit('position + 9999')) if sibling

    self.class.dataset.filter(id: id).update(position: target_position)
    self.class.dataset.filter(id: sibling.id).update(position: current_position) if sibling
    enumeration.class.broadcast_changes

    target_position
  end

  def self.handle_suppressed(ids, val)
    obj = super
    Enumeration.broadcast_changes
    obj
  end
end
