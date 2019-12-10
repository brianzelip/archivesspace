require 'digest/sha1'

unless ENV['DISABLE_STARTUP']
  ArchivesSpacePublic::Application.config.secret_token = Digest::SHA1.hexdigest(AppConfig[:public_cookie_secret])
  ArchivesSpacePublic::Application.config.secret_key_base = Digest::SHA1.hexdigest(AppConfig[:public_cookie_secret])
end
