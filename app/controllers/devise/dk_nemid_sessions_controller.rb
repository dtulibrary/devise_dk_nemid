require 'dk_nemid/models/dk_nemid_logon'

class Devise::DkNemidSessionsController < Devise::SessionsController
  SESSION_CHALLENGE_NAME = 'devise_dk_nemid_challenge'
  def new
    if Devise.dk_nemid_test_mode
      logger.info "DkNemid in test mode. Bypassing Nemid login."
      render :dk_nemid_login_test_mode and return
    end

    # Create class which can do nemid stuff
    @nemid = Devise::Models::DkNemidLogon.new
    session[SESSION_CHALLENGE_NAME] = @nemid.create_challenge
    # Get login_type
    @login_type = params[:login_type] || request.cookies['preferredLogin']
    unless Devise.dk_nemid_allowed.include? @login_type
      @login_type = Devise.dk_nemid_allowed.first
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
    params[:challenge] = session[SESSION_CHALLENGE_NAME]
    super
  end

end
