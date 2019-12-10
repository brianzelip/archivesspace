require 'date'
require 'time'
require 'barcode_check'

module JSONModel::Validations
  extend JSONModel

  def self.check_identifier(hash)
    ids = (0...4).map { |i| hash["id_#{i}"] }

    errors = []

    errors << ['identifier', 'must not contain blank entries'] if ids.reverse.drop_while { |elt| elt.to_s.empty? }.any? { |elt| elt.to_s.empty? }

    errors
  end

  [:archival_object, :accession, :resource].each do |type|
    next unless JSONModel(type)

    JSONModel(type).add_validation("#{type}_check_identifier") do |hash|
      check_identifier(hash)
    end
  end

  # Specification:
  # https://www.pivotaltracker.com/story/show/41430143
  # See also: https://www.pivotaltracker.com/story/show/51373893
  def self.check_source(hash)
    errors = []

    # non-authorized forms don't need source or rules
    return errors unless hash['authorized']

    if hash['source'].nil?
      if hash['rules'].nil?
        errors << ['rules', "is required when 'source' is blank"]
        errors << ['source', "is required when 'rules' is blank"]
      end
    end

    errors
  end

  # https://www.pivotaltracker.com/story/show/51373893
  def self.check_authority_id(hash)
    warnings = []
    warnings << ['source', 'is required if there is an authority id'] if hash['source'].nil? && hash['authority_id']

    warnings
  end

  def self.check_name(hash)
    errors = []
    errors << ['sort_name', 'Property is required but was missing'] if hash['sort_name'].nil? && !hash['sort_name_auto_generate']
    errors
  end

  [:name_person, :name_family, :name_corporate_entity, :name_software].each do |type|
    next unless JSONModel(type)

    JSONModel(type).add_validation("#{type}_check_source") do |hash|
      check_source(hash)
    end
    JSONModel(type).add_validation("#{type}_check_name") do |hash|
      check_name(hash)
    end
    JSONModel(type).add_validation("#{type}_check_authority_id", :warning) do |hash|
      check_authority_id(hash)
    end
  end

  # Take a date like YYYY or YYYY-MM and pad to YYYY-MM-DD
  #
  # Note: this might not yield a valid date.  The only goal is that something
  # valid on the way in remains valid on the way out.
  #
  def self.normalise_date(date)
    negated = date.start_with?('-')

    parts = date.gsub(/^-/, '').split(/-/)

    # Pad out to the right length
    padded = (parts + ['01', '01']).take(3)

    (negated ? '-' : '') + padded.join('-')
  end

  # Returns a valid date or throws if the input is invalid.
  def self.parse_sloppy_date(s)
    Date.strptime(normalise_date(s), '%Y-%m-%d')
  rescue StandardError
    raise ArgumentError, $!
  end

  def self.check_date(hash)
    errors = []

    begin
      begin_date = parse_sloppy_date(hash['begin']) if hash['begin']
    rescue ArgumentError => e
      errors << ['begin', 'not a valid date']
    end

    begin
      if hash['end']
        # If padding our end date with months/days would cause it to fall before
        # the start date (e.g. if the start date was '2000-05' and the end date
        # just '2000'), use the start date in place of end.
        end_s = if begin_date && hash['begin'] && hash['begin'].start_with?(hash['end'])
                  hash['begin']
                else
                  hash['end']
                end

        end_date = parse_sloppy_date(end_s)
      end
    rescue ArgumentError
      errors << ['end', 'not a valid date']
    end

    errors << ['end', 'must not be before begin'] if begin_date && end_date && end_date < begin_date

    if hash['expression'].nil? && hash['begin'].nil? && hash['end'].nil?
      errors << ['expression', 'is required unless a begin or end date is given']
      errors << ['begin', 'is required unless an expression or an end date is given']
      errors << ['end', 'is required unless an expression or a begin date is given']
    end

    errors
  end

  JSONModel(:date)&.add_validation('check_date') do |hash|
    check_date(hash)
  end

  def self.check_language(hash)
    langs = hash['lang_materials'].map { |l| l['language_and_script'] }.compact.reject { |e| e == [] }.flatten

    errors = []

    errors << :must_contain_at_least_one_language if langs == []

    errors
  end

  JSONModel(:resource)&.add_validation('check_language') do |hash|
    check_language(hash)
  end

  def self.check_rights_statement(hash)
    errors = []

    if hash['rights_type'] == 'copyright'
      errors << ['status', 'missing required property'] if hash['status'].nil?
      errors << ['jurisdiction', 'missing required property'] if hash['jurisdiction'].nil?
      errors << ['start_date', 'missing required property'] if hash['start_date'].nil?

    elsif hash['rights_type'] == 'license'
      errors << ['license_terms', 'missing required property'] if hash['license_terms'].nil?
      errors << ['start_date', 'missing required property'] if hash['start_date'].nil?

    elsif hash['rights_type'] == 'statute'
      errors << ['statute_citation', 'missing required property'] if hash['statute_citation'].nil?
      errors << ['jurisdiction', 'missing required property'] if hash['jurisdiction'].nil?
      errors << ['start_date', 'missing required property'] if hash['start_date'].nil?

    elsif hash['rights_type'] == 'other'
      errors << ['other_rights_basis', 'missing required property'] if hash['other_rights_basis'].nil?
      errors << ['start_date', 'missing required property'] if hash['start_date'].nil?
    end

    errors
  end

  JSONModel(:rights_statement)&.add_validation('check_rights_statement') do |hash|
    check_rights_statement(hash)
  end

  def self.check_location(hash)
    errors = []

    # When creating a location, a minimum of one of the following is required:
    #   * Barcode
    #   * Classification
    #   * Coordinate 1 Label AND Coordinate 1 Indicator
    required_location_fields = [['barcode'],
                                ['classification'],
                                ['coordinate_1_indicator', 'coordinate_1_label']]

    errors << :location_fields_error if required_location_fields.none? { |fieldset| fieldset.all? { |field| hash[field] } }

    errors
  end

  JSONModel(:location)&.add_validation('check_location') do |hash|
    check_location(hash)
  end

  def self.check_container_location(hash)
    errors = []

    errors << ['end_date', 'is required if status is previous'] if hash['end_date'].nil? && (hash['status'] == 'previous')

    errors
  end

  JSONModel(:container_location)&.add_validation('check_container_location') do |hash|
    check_container_location(hash)
  end

  def self.check_instance(hash)
    errors = []

    if hash['instance_type'] == 'digital_object'
      errors << ['digital_object', "Can't be empty"] if hash['digital_object'].nil?

    elsif hash['digital_object'] && hash['instance_type'] != 'digital_object'
      errors << ['instance_type', "An instance with a digital object reference must be of type 'digital_object'"]

    elsif hash['instance_type']
      errors << ['sub_container', "Can't be empty"] if hash['sub_container'].nil?
    end

    errors
  end

  JSONModel(:instance)&.add_validation('check_instance') do |hash|
    check_instance(hash)
  end

  def self.check_sub_container(hash)
    errors = []

    errors << ['type_2', 'container 2 requires both a type and indicator'] if (!hash['type_2'].nil? && hash['indicator_2'].nil?) || (hash['type_2'].nil? && !hash['indicator_2'].nil?)

    errors << ['type_2', 'container 2 is required if container 3 is provided'] if hash['type_2'].nil? && hash['indicator_2'].nil? && (!hash['type_3'].nil? || !hash['indicator_3'].nil?)

    errors << ['type_3', 'container 3 requires both a type and indicator'] if (!hash['type_3'].nil? && hash['indicator_3'].nil?) || (hash['type_3'].nil? && !hash['indicator_3'].nil?)

    errors
  end

  JSONModel(:sub_container)&.add_validation('check_sub_container') do |hash|
    check_sub_container(hash)
  end

  def self.check_container_profile(hash)
    errors = []

    # Ensure depth, width and height have no more than 2 decimal places
    ['depth', 'width', 'height'].each do |k|
      errors << [k, 'must be a number with no more than 2 decimal places'] if hash[k] !~ /^\s*(?=.*[0-9])\d*(?:\.\d{1,2})?\s*$/
    end

    # Ensure stacking limit is a positive integer if it has value
    errors << ['stacking_limit', 'must be a positive integer'] if !hash['stacking_limit'].nil? && hash['stacking_limit'] !~ /^\d+$/

    errors
  end

  JSONModel(:container_profile)&.add_validation('check_container_profile') do |hash|
    check_container_profile(hash)
  end

  def self.check_collection_management(hash)
    errors = []

    errors << ['processing_total_extent_type', 'is required if total extent is specified'] if !hash['processing_total_extent'].nil? && hash['processing_total_extent_type'].nil?

    ['processing_hours_per_foot_estimate', 'processing_total_extent', 'processing_hours_total'].each do |k|
      errors << [k, 'must be a number with no more than nine digits and five decimal places'] if !hash[k].nil? && hash[k] !~ /^\-?\d{0,9}(\.\d{1,5})?$/
    end

    errors
  end

  JSONModel(:collection_management)&.add_validation('check_collection_management') do |hash|
    check_collection_management(hash)
  end

  def self.check_user_defined(hash)
    errors = []

    ['integer_1', 'integer_2', 'integer_3'].each do |k|
      errors << [k, 'must be an integer'] if !hash[k].nil? && hash[k] !~ /^\-?\d+$/
    end

    ['real_1', 'real_2', 'real_3'].each do |k|
      errors << [k, 'must be a number with no more than nine digits and five decimal places'] if !hash[k].nil? && hash[k] !~ /^\-?\d{0,9}(\.\d{1,5})?$/
    end

    errors
  end

  JSONModel(:user_defined)&.add_validation('check_user-defined') do |hash|
    check_user_defined(hash)
  end

  JSONModel(:resource)&.add_validation('check_resource_otherlevel', :warning) do |hash|
    check_otherlevel(hash)
  end

  def self.check_otherlevel(hash)
    warnings = []

    if hash['level'] == 'otherlevel'
      warnings << ['other_level', 'is required'] if hash['other_level'].nil?
    end

    warnings
  end

  def self.check_archival_object(hash)
    errors = []

    if (!hash.has_key?('dates') || hash['dates'].empty?) && (!hash.has_key?('title') || hash['title'].empty?)
      errors << ['dates', 'one or more required (or enter a Title)']
      errors << ['title', 'must not be an empty string (or enter a Date)']
    end

    errors
  end

  if JSONModel(:archival_object)
    JSONModel(:archival_object).add_validation('check_archival_object') do |hash|
      check_archival_object(hash)
    end

    JSONModel(:archival_object).add_validation('check_archival_object_otherlevel', :warning) do |hash|
      check_otherlevel(hash)
    end

  end

  def self.check_digital_object_component(hash)
    errors = []

    fields = ['dates', 'title', 'label']

    if fields.all? { |field| !hash.has_key?(field) || hash[field].empty? }
      fields.each do |field|
        errors << [field, 'you must provide a label, title or date']
      end
    end

    errors
  end

  JSONModel(:digital_object_component).add_validation('check_digital_object_component') do |hash|
    check_digital_object_component(hash)
  end

  JSONModel(:event).add_validation('check_event') do |hash|
    errors = []

    if hash.has_key?('date') && hash.has_key?('timestamp')
      errors << ['date', "Can't specify both a date and a timestamp"]
      errors << ['timestamp', "Can't specify both a date and a timestamp"]
    end

    if !hash.has_key?('date') && !hash.has_key?('timestamp')
      errors << ['date', 'Must specify either a date or a timestamp']
      errors << ['timestamp', 'Must specify either a date or a timestamp']
    end

    if hash['timestamp']
      # Make sure we can parse it
      begin
        Time.parse(hash['timestamp'])
      rescue ArgumentError
        errors << ['timestamp', 'Must be an ISO8601-formatted string']
      end
    end

    errors
  end

  [:agent_person, :agent_family, :agent_software, :agent_corporate_entity].each do |agent_type|
    JSONModel(agent_type).add_validation("check_#{agent_type}") do |hash|
      errors = []

      errors << ['dates_of_existence', "Label must be 'existence' in this context"] if hash.has_key?('dates_of_existence') && hash['dates_of_existence'].find { |d| d['label'] != 'existence' }

      errors
    end
  end

  [:note_multipart, :note_bioghist].each do |schema|
    JSONModel(schema).add_validation("#{schema}_check_at_least_one_subnote") do |hash|
      if Array(hash['subnotes']).empty?
        [['subnotes', 'Must contain at least one subnote']]
      else
        []
      end
    end
  end

  JSONModel(:find_and_replace_job).add_validation('only target properties on the target schemas') do |hash|
    target_model = JSONModel(hash['record_type'].intern)
    target_property = hash['property']

    target_model.schema['properties'].has_key?(target_property) ? [] : [['property', "#{target_model} does not have a property named '#{target_property}'"]]
  end

  def self.check_location_profile(hash)
    errors = []

    # Ensure depth, width and height have no more than 2 decimal places
    ['depth', 'width', 'height'].each do |k|
      errors << [k, 'must be a number with no more than 2 decimal places'] if !hash[k].nil? && hash[k] !~ /\A\d+(\.\d\d?)?\Z/
    end

    errors
  end

  JSONModel(:location_profile)&.add_validation('check_location_profile') do |hash|
    check_location_profile(hash)
  end

  def self.check_field_query(hash)
    errors = []

    errors << ['value', "Must specify either a value or use the 'empty' comparator"] if (!hash.has_key?('value') || hash['value'].empty?) && hash['comparator'] != 'empty'

    errors
  end

  JSONModel(:field_query)&.add_validation('check_field_query') do |hash|
    check_field_query(hash)
  end

  def self.check_date_field_query(hash)
    errors = []

    errors << ['value', "Must specify either a value or use the 'empty' comparator"] if (!hash.has_key?('value') || hash['value'].empty?) && hash['comparator'] != 'empty'

    errors
  end

  JSONModel(:date_field_query)&.add_validation('check_date_field_query') do |hash|
    check_field_query(hash)
  end

  def self.check_rights_statement_external_document(hash)
    errors = []

    errors << ['identifier_type', 'missing required property'] if hash['identifier_type'].nil?

    errors
  end

  JSONModel(:rights_statement_external_document)&.add_validation('check_rights_statement_external_document') do |hash|
    check_rights_statement_external_document(hash)
  end

  def self.check_assessment_monetary_value(hash)
    errors = []

    if monetary_value = hash['monetary_value']
      errors << ['monetary_value', 'must be a number with no more than 2 decimal places'] unless monetary_value =~ /\A[0-9]+\z/ || monetary_value =~ /\A[0-9]+\.[0-9]{1,2}\z/
    end

    errors
  end

  JSONModel(:assessment)&.add_validation('check_assessment_monetary_value') do |hash|
    check_assessment_monetary_value(hash)
  end

  def self.check_survey_dates(hash)
    errors = []

    begin
      begin_date = parse_sloppy_date(hash['survey_begin'])
    rescue ArgumentError => e
      errors << ['survey_begin', 'not a valid date']
    end

    begin
      if hash['survey_end']
        # If padding our end date with months/days would cause it to fall before
        # the start date (e.g. if the start date was '2000-05' and the end date
        # just '2000'), use the start date in place of end.
        end_s = if begin_date && hash['survey_begin'] && hash['survey_begin'].start_with?(hash['survey_end'])
                  hash['survey_begin']
                else
                  hash['survey_end']
                end

        end_date = parse_sloppy_date(end_s)
      end
    rescue ArgumentError
      errors << ['survey_end', 'not a valid date']
    end

    errors << ['survey_end', 'must not be before begin'] if begin_date && end_date && end_date < begin_date

    errors
  end

  JSONModel(:assessment)&.add_validation('check_survey_dates') do |hash|
    check_survey_dates(hash)
  end
end
