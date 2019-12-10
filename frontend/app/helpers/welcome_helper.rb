module WelcomeHelper
  def database_warning(info = {})
    if session['user']
      flash[:warning] = I18n.t('database_warning.message') if info.has_key?('databaseProductName') && info['databaseProductName'].include?('Derby')
    end
  end

  def no_repo_message
    if session[:user] && @repositories.length === 0
      flash.now[:info] = if user_can?('create_repository')
                           I18n.t('repository._frontend.messages.create_first_repository')
                         else
                           I18n.t('repository._frontend.messages.no_access_to_repositories')
                         end
    end
  end

  def welcome_message
    if session['user']
      "<p>#{I18n.t 'welcome.message_logged_in'}</p>".html_safe
    else
      "<p>#{I18n.t 'welcome.message'}</p>".html_safe
    end
  end
end
