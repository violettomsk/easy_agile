class ApplicationController < ActionController::Base
  attr_accessor :google_analytics_disabled

  helper :all # include all helpers, all the time

  layout :decide_layout

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'a06ef3d2087744dfb53f6628410ad34b'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

  before_filter :login_required
  before_filter :select_organisation

  def google_analytics?
    %w(test production).include?(RAILS_ENV) && ! google_analytics_disabled
  end

  protected

  def no_google_analytics
    self.google_analytics_disabled = true
  end

  def decide_layout
    layout = ''
    respond_to do |format|
      format.html do
        layout = 'application'
      end

      format.js do
        layout = 'request'
      end
    end

    layout
  end

  def current_user
    @current_user ||= User.valid.find_by_id(session[:user_id])
  end

  def current_organisation
    @current_organisation ||=
      current_user.organisations.find_by_id(session[:organisation_id])
  end

  def get_project
    @project = current_organisation.projects.find_by_id(params[:project_id])
  end

  def login_required
    if current_user
      true
    else
      session[:redirect_to] = request.request_uri
      redirect_to new_session_url
    end
  end

  def select_organisation
    if session[:organisation_id].nil? && current_user.organisations.size == 1
      session[:organisation_id] = current_user.organisations.first.id
    end

    unless current_organisation
      session[:redirect_to] = request.request_uri
      redirect_to organisations_url
    end
  end

  def set_current_user_on_resource
    resource_name = controller_name.singularize
    resource = instance_variable_get("@#{resource_name}")
    if resource && resource.respond_to?(:current_user=)
      resource.current_user = current_user
    end
  end
end
