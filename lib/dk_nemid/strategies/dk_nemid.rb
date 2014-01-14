require 'devise/strategies/authenticatable'
require 'dk_nemid/models/dk_nemid_document'
 
module Devise::Strategies
  class DkNemidAuthenticatable < Authenticatable
    def valid?
      valid_params?
    end
 
    def authenticate!
      result = Base64.decode64(params[:result])
      if result != "ok"
        # Result is an error code from Nemid
        fail(I18n.t(result, :scope => 'devise.dk_nemid'))
      end

      begin
        doc = Devise::Models::DkNemidDocument.new(Base64.decode64(
          params[:signature]))
        unless doc.verify_logon(encode(
            session[:devise_dk_nemid_challenge]))
          logger.info "DkNemid strategy failed with #{doc.error}"
          fail(doc.error)
          return
        end
      rescue StandardError => e
        logger.error "DkNemid strategy failed with '#{doc.error}' and "+
          "'#{e.message}' from "+
          "#{params[:signature]}"
        fail(I18n.t('devise.dk_nemid.failure'))
        return
      end

      resource = mapping.to.where(:identifier => doc.identifier).first
      if resource.nil?
        # TODO: Only use cpr if cpr_service is enabled
        resource = mapping.to.create(
           :identifier => doc.identifier,
           :cpr => doc.cpr,
           :cvr => doc.cvr
        )
      end
      success!(resource)
    end

    private

    def valid_params?
      !(params[:signature].nil? || params[:result].nil?)
    end

    def logger
      Rails.logger
    end

    def encode(param)
      Base64.encode64(param).gsub("\n", "")
    end

  end

end

Warden::Strategies.add(:dk_nemid, Devise::Strategies::DkNemidAuthenticatable)
