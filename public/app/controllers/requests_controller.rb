class RequestsController < ApplicationController
  include PrefixHelper

  # send a request
  def make_request
    @request = RequestItem.new(params)
    errs = @request.validate
    errs << I18n.t('request.failed') if params['comment'].present?
    if errs.blank?
      flash[:notice] = I18n.t('request.submitted')

      RequestMailer.request_received_staff_email(@request).deliver
      RequestMailer.request_received_email(@request).deliver

      redirect_to params.fetch('base_url', app_prefix(request[:request_uri]))
    else
      flash[:error] = errs
      redirect_back(fallback_location: app_prefix(request[:request_uri])) && return
    end
  end
end
