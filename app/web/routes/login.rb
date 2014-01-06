module Evercam
  class WebApp

    get '/login' do
      rt = params[:rt]
      redirect rt if rt && session[:user]
      erb 'login'.to_sym
    end

    post '/login' do
      user = User.by_login(params[:username])
      unless user && user.password == params[:password]
        session[:user] = nil
        redirect '/login', error: 'Invalid username or email and password combination'
      else
        session[:user] = user.id
        redirect params[:rt] ? params[:rt] : "/users/#{user.username}"
      end
    end

    get '/logout' do
      session[:user] = nil
      redirect '/login'
    end

  end
end

