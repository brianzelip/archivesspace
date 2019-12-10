module PrefixHelper
  def self.app_prefix(path)
    AppConfig[:public_proxy_prefix].gsub(%r{/?$}, '') + (path.start_with?('/') ? path : "/#{path}")
  end

  def self.app_prefix_js
    prefix = AppConfig[:public_proxy_prefix].gsub(%r{/?$}, '')

    "'#{prefix}' +"
  end

  def app_prefix(path)
    PrefixHelper.app_prefix(path)
  end

  def app_prefix_js
    PrefixHelper.app_prefix_js
  end
end
