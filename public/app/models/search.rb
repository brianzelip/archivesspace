class Search < Struct.new(:q, :op, :field, :limit, :from_year, :to_year, :filter_fields, :filter_values, :filter_q, :filter_from_year, :filter_to_year, :recordtypes, :dates_searched, :sort, :dates_within, :text_within, :search_statement)
  @@BooleanOpts = []

  def self.get_boolean_opts
    if @@BooleanOpts.empty?
      ['AND', 'OR', 'NOT'].each do |opt|
        @@BooleanOpts.push([I18n.t("advanced_search.operator.#{opt}"), opt])
      end
    end
    @@BooleanOpts
  end

  # we create all the possible sort options here, then refine them according to what's being sorted
  @@SortOpts = {}

  def self.get_sort_opts
    if @@SortOpts.empty?
      @@SortOpts['relevance'] = [I18n.t('search_sorting.relevance'), '']
      # the things we do for I18n!
      ['title_sort', 'year_sort'].each do |type|
        ['asc', 'desc'].each do |dir|
          @@SortOpts["#{type}_#{dir}"] = [I18n.t('search_sorting.sorting', type: I18n.t("search_sorting.#{type}"), direction: I18n.t("search_sorting.#{dir}")), "#{type} #{dir}"]
        end
      end
    end
    @@SortOpts
  end

  # We take params either as a Hash or ActionController::Parameters object
  def initialize(params = {})
    #    Rails.logger.debug("Initializing: #{params}")
    ['q', 'op', 'field', 'from_year', 'to_year', 'filter_fields', 'filter_values', 'filter_q', 'recordtypes'].each do |f|
      self[f.to_sym] = if params.is_a?(Hash)
                         params[f.to_sym] || []
                       else
                         params.fetch(f.to_sym, [])
                       end
    end
    ['limit', 'filter_from_year', 'filter_to_year'].each do |f|
      self[f.to_sym] = if params.is_a?(Hash)
                         params[f.to_sym] || ''
                       else
                         params.fetch(f.to_sym, '')
                       end
    end
    self[:q].each_with_index do |q, i|
      self[:q][i] = '*' if q.blank?
    end
    self[:sort] = params.fetch('sort', nil)
    self[:dates_searched] =  have_contents?(from_year) || have_contents?(to_year)
    self[:dates_within] = self[:text_within] = false
  end

  def filters_blank?
    filter_from_year.blank? && filter_to_year.blank? && filter_q.blank?
  end

  def has_query?
    have_contents?(q)
  end

  def have_contents?(year_array)
    have = false
    year_array.each do |year|
      have = true unless year.strip == ''
    end
    have
  end

  def allow_dates?
    allow = true
    limit.split(',').each do |type|
      allow = false if type == 'subject'
      allow = false if type.start_with?('agent')
    end
    allow
  end

  def search_dates_within?
    dates_within && !dates_searched && filter_from_year.empty? && filter_to_year.empty?
  end

  def get_filter_q_params
    params = ''
    self[:filter_q].each do |v|
      params += "&filter_q[]=#{CGI.escape(v)}"
    end
    params
  end

  def get_filter_q_arr(url = nil)
    fqa = []
    self[:filter_q].each do |v|
      Rails.logger.debug("v: #{v} CGI-escaped: #{CGI.escape(v)}")
      uri = url ? url.sub("&filter_q[]=#{CGI.escape(v)}", '') : ''
      fqa.push('v' => v, 'uri' => uri)
    end
    fqa
  end
end
