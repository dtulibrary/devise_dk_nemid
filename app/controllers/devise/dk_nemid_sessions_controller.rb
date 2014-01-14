require 'dk_nemid/models/dk_nemid_logon'

class Devise::DkNemidSessionsController < Devise::SessionsController
  def new
    # Create class which can do nemid stuff
    @nemid = Devise::Models::DkNemidLogon.new
    session[:devise_dk_nemid_challenge] = @nemid.create_challenge
    # Get login_type
    @login_type = params[:login_type] || request.cookies['preferredLogin']
    unless ['otp', 'software', 'digitalsignatur'].include? @login_type
      @login_type = 'otp'
    end
    logger.info "Login type: #{@login_type}"
    @remember = "remember#{@login_type}"
    render :dk_nemid_login
  end

  # We get the result of NemId login posted
  #   signature = XML structure of signature
  #   result = text string of result
  #     ok = all is good. Signature contains data
  #     all other = error text. Signature is empty
  def create
    # Lets devise do its work
    if params[:result].nil?
      data = eval(File.read("applet.dump.local"))
      params[:result] = data['result']
      params[:signature] = data['signature']
      session[:devise_dk_nemid_challenge] =
        "\x91\xC8}\x9C,\x15i\xDA\xEE\xBFq\xB5\x0F!\xFE"
    end
    super
  end

end
