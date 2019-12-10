class DCModel < ASpaceExport::ExportModel
  model_for :dc

  include JSONModel

  attr_accessor :title
  attr_accessor :identifier
  attr_accessor :creators
  attr_accessor :subjects
  attr_accessor :dates
  attr_accessor :type
  attr_accessor :lang_materials

  @archival_object_map = {
    title: :title=,
    dates: :handle_date,
    lang_materials: :handle_langmaterials,
    linked_agents: :handle_agents,
    subjects: :handle_subjects
  }

  @digital_object_map = {}

  def initialize(obj)
    @creators = []
    @subjects = []
    @sources = []
    @dates = []
    @lang_materials = []
    @rights = []
    @json = obj
  end

  def self.from_archival_object(obj)
    dc = new(obj)

    dc.apply_map(obj, @archival_object_map)

    dc
  end

  def self.from_digital_object(obj)
    dc = from_archival_object(obj)

    dc.apply_map(obj, @digital_object_map)

    dc.identifier = "#{AppConfig[:backend_url]}#{obj.uri}" if obj.respond_to?('uri')

    dc.type = obj.digital_object_type if obj.respond_to?('digital_object_type')

    dc
  end

  def self.DESCRIPTIVE_NOTE_TYPES
    @descriptive_note_type ||= ['bioghist', 'prefercite']
    @descriptive_note_type
  end

  def self.RIGHTS_NOTE_TYPES
    @rights_note_type ||= ['accessrestrict', 'userestrict']
    @rights_note_type
  end

  def self.FORMAT_NOTE_TYPES
    @format_note_type ||= ['dimensions', 'physdesc']
    @format_note_type
  end

  def self.SOURCE_NOTE_TYPES
    @source_note_type ||= ['originalsloc']
    @source_note_type
  end

  def self.RELATION_NOTE_TYPES
    @relation_note_type ||= ['relatedmaterial']
    @relation_note_type
  end

  def each_description
    if @json.respond_to?('notes')
      @json.notes.each do |note|
        yield extract_note_content(note) if self.class.DESCRIPTIVE_NOTE_TYPES.include? note['type']
      end

      repo = @json.repository['_resolved']
      repo_info = "Digital object made available by #{repo['name']}"
      repo_info << " (#{repo['url']})" if repo['url']

      yield repo_info
    end
  end

  def each_rights
    if @json.respond_to?('notes')
      @json.notes.each do |note|
        yield extract_note_content(note) if self.class.RIGHTS_NOTE_TYPES.include? note['type']
      end
    end
  end

  def each_format
    if @json.respond_to?('notes')
      @json.notes.each do |note|
        yield extract_note_content(note) if self.class.FORMAT_NOTE_TYPES.include? note['type']
      end
    end
  end

  def each_source
    if @json.respond_to?('notes')
      @json.notes.each do |note|
        yield extract_note_content(note) if self.class.SOURCE_NOTE_TYPES.include? note['type']
      end
    end
  end

  def each_relation
    if @json.respond_to?('notes')
      @json.notes.each do |note|
        yield extract_note_content(note) if self.class.RELATION_NOTE_TYPES.include? note['type']
      end
    end
  end

  def handle_agents(linked_agents)
    linked_agents.each do |link|
      role = link['role']
      agent = link['_resolved']

      case role
      when 'creator'
        agent['names'].each { |n| creators << n['sort_name'] }
      when 'subject'
        agent['names'].each { |n| subjects << n['sort_name'] }
      end
    end
  end

  def handle_langmaterials(lang_materials)
    language_vals = lang_materials.map { |l| l['language_and_script'] }.compact
    unless language_vals.empty?
      language_vals.each do |language|
        self.lang_materials << language['language']
        self.lang_materials << language['script'] if language['script']
      end
    end

    language_notes = lang_materials.map { |l| l['notes'] }.compact.reject { |e| e == [] }.flatten
    unless language_notes.empty?
      language_notes.each do |note|
        self.lang_materials << extract_note_content(note)
      end
    end
  end

  def handle_date(dates)
    dates.each do |date|
      self.dates << extract_date_string(date)
    end
  end

  def handle_rights(rights_statements)
    rights_statements.each do |rs|
      case rs['rights_type']

      when 'license'
        self['rights'] << "License: #{rs.license_identifier_terms}"
      end

      self['rights'] << "Permissions: #{rs.permissions}" if rs['permissions']

      self['rights'] << "Restriction: #{rs.restrictions}" if rs['restrictions']
    end
  end

  def handle_subjects(subjects)
    subjects.map { |s| s['_resolved'] }.each do |subject|
      self.subjects << subject['terms'].map { |t| t['term'] }.join('--')
    end
  end
end
