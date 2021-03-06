class GemifierController < ApplicationController

  def index
    render "no_sessions_index" if !session[:token] 
    @file = File.new("app/views/layouts/application.html.erb")
  end

  def create_iframe
    @iframe_file = Concerns::IframeContentCreator.new(params)
    @iframe_file.create_iframe_file

    respond_to do |f|
      f.html {render :page}
      f.js
    end
  end

  def create_side_column
    respond_to do |f|
      f.js
    end
  end

  def create
    @client = Octokit::Client.new(:access_token => session[:token])
    raise "error" if @client.repository?(params[:repo_name])
    @gemifier = Gemifier.new(@client, params)
    @gemifier.scaffold

    reset_session

    respond_to do |f|
      f.html {render :success_modal}
      f.js
    end
  end

  def omniauth
    session[:token] = env["omniauth.auth"]["credentials"]["token"]
    redirect_to "/"
  end

end
