class EmailOverrides
  def self.delivering_email(mail)
    mail.to = AppConfig['pui_email_override'] if AppConfig.has_key?('pui_email_override')
  end
end

ActionMailer::Base.register_interceptor(EmailOverrides)
