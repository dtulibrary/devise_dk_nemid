require 'devise/strategies/authenticatable'
require 'dk_nemid/models/dk_nemid_document'
require 'uuidtools'

module Devise::Strategies
  class DkNemidAuthenticatable < Authenticatable
    def valid?
      Devise.dk_nemid_test_mode || valid_params?
    end

    def authenticate!
      #if Devise.dk_nemid_test_mode
      #  return test_mode_resource
      #end

      #response = Base64.decode64(params[:response])
      #if !response.start_with? '<?xml'
      #  # Result is an error code from Nemid
      #  fail(I18n.t(response, :scope => 'devise.dk_nemid'))
      #end

      #begin
      #  doc = Devise::Models::DkNemidDocument.new(response)
      #  unless doc.verify_logon(encode("#{params[:challenge]}"))
      #    logger.info "DkNemid strategy failed with #{doc.error}"
      #    fail(doc.error)
      #    return
      #  end
      #rescue StandardError => e
      #  logger.error "DkNemid strategy failed with '#{doc.error}' and "+
      #    "'#{e.message}' from "+
      #    "#{params[:response]}"
      #  logger.info "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
      #  fail(I18n.t('devise.dk_nemid.failure'))
      #  return
      #end

      logger.debug "Params: #{params}"

      resource = mapping.to.where(:cpr => cpr).first
      if resource.nil?
        # TODO: Only use cpr if cpr_service is enabled
        resource = mapping.to.create(
           :identifier => "N/A #{UUIDTools::UUID.timestamp_create}",
           :cpr        => cpr,
        )
      end
      success!(resource)
    end

    private

    def cpr
      params['cpr1'].gsub(/\D/, '')
    end

    def valid_params?
      #!(params[:response].nil?)
      cprs_valid? 
    end

    def cprs_valid?
      params['cpr1'] && params['cpr1'].match(/^\d{6}-?\d{4}$/) && params['cpr1'] == params['cpr2']
    end 

    def logger
      Rails.logger
    end

    def encode(param)
      Base64.encode64(param).gsub("\n", "")
    end

    def test_mode_resource
      resource = mapping.to.where(:identifier => Devise.dk_nemid_test_pid ).first
      if resource.nil?
        # TODO: Only use cpr if cpr_service is enabled
        resource = mapping.to.create(
          :identifier => Devise.dk_nemid_test_pid,
          :cpr => Devise.dk_nemid_test_cpr,
          :cvr => nil
        )
      end
      logger.info "DkNemid in test mode. Returning resource #{resource.inspect}"
      success!(resource)
    end

  end

end

Warden::Strategies.add(:dk_nemid, Devise::Strategies::DkNemidAuthenticatable)
