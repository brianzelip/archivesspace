require_relative 'utils'

Sequel.migration do
  up do
    range = self[:enumeration_value].filter(value: 'range').get(:id)
    bulk_date = self[:enumeration_value].filter(value: 'bulk').get(:id)
    inclusive_date = self[:enumeration_value].filter(value: 'inclusive').get(:id)

    # Changing all event dates that are bulk dates to ranges
    self[:date].exclude(event_id: nil).filter(date_type_id: bulk_date).update(date_type_id: range) if bulk_date && range

    # Changing all event dates that are inclusive dates to ranges
    self[:date].exclude(event_id: nil).filter(date_type_id: inclusive_date).update(date_type_id: range) if inclusive_date && range
  end
end
