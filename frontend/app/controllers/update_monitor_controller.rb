class UpdateMonitorController < ApplicationController
  set_access_control public: [:poll]

  # Turn off CSRF checking for this endpoint since we won't send through a
  # token, and the failed check blats out the session, which we need.
  skip_before_action :verify_authenticity_token, only: [:poll]

  def poll
    uri = params[:uri]
    lock_version = params[:lock_version].to_i

    raise AccessDeniedException unless session[:user]

    if uri =~ %r{/repositories/([0-9]+)} && session[:repo_id] != Regexp.last_match(1).to_i
      render json: { status: 'repository_changed' }
    else
      render json: EditMediator.record(session[:user], uri, lock_version, Time.now)
    end
  end
end
