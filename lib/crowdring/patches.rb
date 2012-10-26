require 'net/smtp'
require 'utils/smtp-tls'

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

   def send_password_email(to, created_by, password)
      message = <<MESSAGE_END
To: <#{to}>
Subject: Welcome to Crowdring!

Hello #{to},

#{created_by} created a Crowdring account for you. Login at https://campaign.crowdring.org 

Your username is #{to}
Your password is #{password}

Happy campaigning!
The Crowdring Team
MESSAGE_END

      Net::SMTP.start(ENV["SMTP_HOST"], ENV["SMTP_PORT"],
          ENV["SMTP_DOMAIN"], ENV["SMTP_USER"], ENV["SMTP_PASSWORD"], :login) do |smtp|
        smtp.send_message message, ENV["SMTP_USER"], to
      end
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
          haml get_view_as_string("newuser.haml"), layout: use_layout?
        end

        app.post '/newuser' do
          if params[:email] != params[:email_confirmation]
            flash[:errors] = "Email and confirmation email do not match."
            redirect '/newuser?' + hash_to_query_string(params)
          else
            password = PasswordGenerator.generate
            @user = User.set(email: params[:email], password: password, password_confirmation: password)
            if @user.valid && @user.id
              send_password_email(params[:email], current_user.email, password)
              flash[:notice] = "Account created."
              redirect '/users'
            else
              flash[:errors] = "#{@user.errors}"
              redirect '/newuser?' + hash_to_query_string(params)
            end
          end
        end

        app.get '/changepassword' do
          haml get_view_as_string("change_password.haml"), layout: use_layout?
        end

        app.post '/changepassword' do
          user = current_user
          if User.authenticate(user.email, params[:current_password])
            if user.update(params[:user])
              flash[:notice] = "Password successfully updated."
              redirect to('/')
            else
              flash[:errors] = "#{user.errors}"
              redirect '/changepassword'
            end
          else
            flash[:errors] = "Original password is incorrect."
            redirect '/changepassword'
          end
        end
      end
      
    end
  end
end