require 'rubygems'
require 'bundler/setup'
require 'rack/ssl'
require 'sinatra/auth/github'
require 'rest_client'
require 'json'

module Example
  class BadAuthentication < Sinatra::Base
    get '/unauthenticated' do
      status 403
      <<-EOS
      <h2>Unable to authenticate, sorry</h2>
      <p>#{env['warden'].message}</p>
      EOS
    end
  end

  class SimpleApp < Sinatra::Base
    #set views
    set :views, File.expand_path('../../views', __FILE__)
    @toggle = false

    enable :sessions
    enable :raise_errors
    disable :show_exceptions
    #enable :inline_templates

    set :github_options, {
      :scope => 'user,repo',
      :secret => ENV['GITHUB_CLIENT_SECRET'] || 'test_client_secret',
      :client_id => ENV['GITHUB_CLIENT_ID'] || 'test_client_id'
    }
    register Sinatra::Auth::Github

    get '/' do
      erb :index
    end

    get '/profile' do
      authenticate!
      # flag for show access rights
      @toggle = true
      owner = 'spring-projects'
      repo = 'spring-framework'
      @result = JSON.parse(RestClient.get("https://api.github.com/repos/amedia/hanuman/pulls",
                                           :Authorization => "token #{github_user.token}"))
      erb :index
    end

    get '/login' do
      authenticate!
      user_token = github_user.token
      result = JSON.parse(RestClient.get('https://api.github.com/user',
                                         {:params => {:access_token => user_token},
                                          :accept => :json}))
      redirect '/'
    end

    get '/logout' do
      logout!
      redirect '/'
    end
  end

  def self.app
    @app ||= Rack::Builder.new do
      run SimpleApp
    end
  end
end


