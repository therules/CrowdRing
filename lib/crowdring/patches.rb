module Sinatra
  module Helpers
    def login_required
      return true if current_user.class != GuestUser

      if request.xhr?
        redirect 403
      else
        session[:return_to] = request.fullpath 
        redirect '/login'
      end

      false
    end
  end
end

module Sinatra
  module SinatraAuthentication
    class << self
      alias_method :orig_registered, :registered

      def registered(app)
        orig_registered(app)
        
        app.get '/newuser' do
          haml get_view_as_string("newuser.haml"), :layout => use_layout?
        end

        app.post '/newuser' do
          @user = User.set(params[:user])
          if @user.valid && @user.id
            if Rack.const_defined?('Flash')
              flash[:notice] = "Account created."
            end
            redirect '/users'
          else
            if Rack.const_defined?('Flash')
              flash[:errors] = "#{@user.errors}"
            end
            redirect '/newuser?' + hash_to_query_string(params['user'])
          end
        end
      end
    end
  end
end