require_relative 'marcxml_converter'

class MarcXMLAccessionConverter < MarcXMLConverter
  def self.import_types(_show_hidden = false)
    [
      {
        name: 'marcxml_accession',
        description: 'Import MARC XML records as Accessions'
      }
    ]
  end

  def self.instance_for(type, input_file)
    new(input_file) if type == 'marcxml_accession'
  end
end

MarcXMLAccessionConverter.configure do |config|
  config['/record'][:obj] = :accession
  config['/record'][:map].delete("//controlfield[@tag='008']")

  config['/record'][:map]['self::record'] = lambda { |accession, _node|
    accession.title = accession['_fallback_titles'].shift if !accession.title && accession['_fallback_titles'] && !accession['_fallback_titles'].empty?

    accession.id_0 = "imported-#{SecureRandom.uuid}" if accession.id_0.nil? || accession.id.empty?

    accession.accession_date = Time.now.to_s.sub(/\s.*/, '')
  }

  # strip mappings that target .notes
  config['/record'][:map].each do |path, defn|
    next unless defn.is_a?(Hash)

    config['/record'][:map].delete(path) if defn[:rel] == :notes
  end

  # strip other mappings that target resource-only properties
  [
    "datafield[@tag='536']" # finding_aid_sponsor
  ].each do |resource_only_path|
    config['/record'][:map].delete(resource_only_path)
  end

  config['/record'][:map]["datafield[@tag='506']"] = lambda { |record, node|
    node.xpath('subfield').each do |sf|
      val = sf.inner_text
      next if val.empty?

      record.access_restrictions_note ||= ''
      record.access_restrictions_note += ' ' unless record.access_restrictions_note.empty?
      record.access_restrictions_note += val
    end

    record.access_restrictions = true if node.attr('ind1') == '1'
  }

  config['/record'][:map]["datafield[@tag='520']"] = lambda { |record, node|
    node.xpath('subfield').each do |sf|
      val = sf.inner_text
      next if val.empty?

      record.content_description ||= ''
      record.content_description += ' ' unless record.content_description.empty?
      record.content_description += val
    end
  }

  config['/record'][:map]["datafield[@tag='540']"] = lambda { |record, node|
    node.xpath('subfield').each do |sf|
      val = sf.inner_text
      next if val.empty?

      record.use_restrictions_note ||= ''
      record.use_restrictions_note += ' ' unless record.use_restrictions_note.empty?
      record.use_restrictions_note += val
    end

    record.use_restrictions = true
  }

  config['/record'][:map]["datafield[@tag='541']"] = lambda { |record, node|
    provenance1 = ''

    node.xpath('subfield').each do |sf|
      val = sf.inner_text

      unless val.empty?
        provenance1 += ' ' unless provenance1.empty?
        provenance1 += val
      end
    end

    if record.provenance
      record.provenance = provenance1 + " #{record.provenance}"
    elsif !provenance1.empty?
      record.provenance = provenance1
    end
  }

  config['/record'][:map]["datafield[@tag='561']"] = lambda { |record, node|
    provenance2 = ''

    node.xpath('subfield').each do |sf|
      val = sf.inner_text

      unless val.empty?
        provenance2 += ' ' unless provenance2.empty?
        provenance2 += val
      end
    end

    if record.provenance
      record.provenance = "#{record.provenance} " + provenance2
    elsif !provenance2.empty?
      record.provenance = provenance2
    end
  }
end
