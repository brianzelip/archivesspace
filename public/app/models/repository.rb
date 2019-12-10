class Repository < Struct.new(:code, :name, :uri, :display_name, :parent, :parent_url)
  @@AllRepos = {}
  def self.get_repos
    @@AllRepos = ArchivesSpaceClient.new.list_repositories if @@AllRepos.blank?
    @@AllRepos
  end

  def self.set_repos(repos)
    @@AllRepos = repos
  end

  # determine which badges to display
  def self.badge_list(repo_code)
    list = []
    [:resource, :record, :digital_object, :accession, :subject, :agent, :classification].each do |sym|
      badge = "#{sym}_badge".to_sym
      list.push(sym.to_s) unless AppConfig[:pui_repos].dig(repo_code, :hide, badge).nil? ? AppConfig[:pui_hide][badge] : AppConfig[:pui_repos][repo_code][:hide][badge]
    end
    list
  end

  def initialize(code, name, uri, display_name, parent, parent_url = '')
    self.code = code
    self.name = name
    self.uri = uri
    self.display_name = display_name
    self.parent = parent
    self.parent_url = parent_url if !parent_url.blank? && !parent_url.end_with?("url\.unspecified")
  end

  def self.from_json(json)
    new(json['repo_code'], json['name'], json['uri'], json['display_string'], json['parent_institution_name'], json['url'])
  end
end
