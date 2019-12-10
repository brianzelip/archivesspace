class Vocabulary < Sequel::Model(:vocabulary)
  include ASModel
  corresponds_to JSONModel(:vocabulary)

  set_model_scope :global

  one_to_many :subject

  def self.set(params)
    where(params)
  end
end
