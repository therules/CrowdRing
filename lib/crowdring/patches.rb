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