require 'jsonmodel'
require 'memoryleak'
require 'client_enum_source'

unless ENV['DISABLE_STARTUP']
  loop do
    begin
      JSONModel.init(client_mode: true,
                     priority: :high,
                     enum_source: ClientEnumSource.new,
                     url: AppConfig[:backend_url])
      break
    rescue StandardError
      warn 'Connection to backend failed.  Retrying...'
      sleep(5)
    end
  end

  MemoryLeak::Resources.define(:repository, proc { JSONModel(:repository).all }, 60)

  JSONModel::Notification.add_notification_handler('REPOSITORY_CHANGED') do |_msg, _params|
    MemoryLeak::Resources.refresh(:repository)
  end

  JSONModel::Notification.start_background_thread

  JSONModel.add_error_handler do |error|
    raise ArchivesSpacePublic::SessionGone, 'Your backend session was not found' if error['code'] == 'SESSION_GONE'
    raise ArchivesSpacePublic::SessionExpired, 'Your session expired due to inactivity. Please sign in again.' if error['code'] == 'SESSION_EXPIRED'
  end

end

include JSONModel
