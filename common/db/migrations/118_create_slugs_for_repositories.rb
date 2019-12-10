require_relative 'utils'

Sequel.migration do
  up do
    warn('Creating slugs for repositories')

    self[:repository].all.each do |r|
      # repo_codes are already unique, so no need to de-dupe.

      # remove URL characters from slug
      slug = r[:repo_code].gsub(' ', '_').gsub(%r{[&;?$<>#%{}|\\^~\[\]`/@=:+,!.]}, '')

      slug = slug.prepend('_') if slug.match(/^(\d)+$/)

      self[:repository].where(id: r[:id]).update(slug: slug)
      self[:repository].where(id: r[:id]).update(is_slug_auto: 1)
    end
  end
end
