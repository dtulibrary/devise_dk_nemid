require 'nokogiri'
require 'xmldsig'
require 'dk_nemid/models/dk_nemid_properties'
require 'dk_nemid/savon_ssl'
require 'dk_nemid/test' if Rails.env.development?

module Devise::Models
  class DkNemidDocument < Xmldsig::SignedDocument
    NAMESPACEURI_OPENOCES_R1 = 'http://www.openoces.org/2003/10/signature#'
    NAMESPACEURI_OPENOCES_R2 = 'http://www.openoces.org/2006/07/signature#'
    NAMESPACES = {
      'ds' => 'http://www.w3.org/2000/09/xmldsig#',
      'openoces' => 'http://www.openoces.org/2006/07/signature#',
    }

    def verify_logon(challenge, logonto = nil)
      @error = nil
      @cert = nil
      get_signature_properties
      if @signature_properties.length == 0
        @error = I18n.t('devise.dk_nemid.no_signature_properties')
        logger.info "No signature properties"
        return false 
      end

      if validate_signature_parameters(challenge, logonto)
        get_signing_certificate
        if (@cert)
          get_certificate_data
          if Devise.dk_nemid_cpr_service != :none
            if @dk_nemid_cpr_service == :private and @cpr.nil?
              redirect :get_cpr_path
            end
            @identifier.match(/PID:([0-9-]+)/)
            pid = $1
            @identifier.match(/RID:([0-9-]+)/)
            rid = $1
            logger.info "PID: #{pid}, RID: #{rid}"
            if pid
              get_pid_cpr(pid)
            elsif rid
              get_rid_cpr(rid)
            else
              logger.warn "Missing PID or RID for cpr lookup"
            end
          end
        end
      end
      @error.nil?
    end

    def validate_signature_parameters(challenge, logonto)
      unless @signature_properties['challenge'] == challenge
        @error = I18n.t('devise.dk_nemid.challenge_incorrect')
        logger.info("Challenge failed. Expected #{challenge}, "+
          "got #{@signature_properties['challenge']}")
        return false
      end
      unless logonto.nil?
        validate_logon_to(logonto)
      end
      true
    end

    def validate_logon_to(logonto)
      true
    end

    def get_signature_properties
      @signature_properties = Hash.new
      case document.namespaces['xmlns:openoces']
      when NAMESPACEURI_OPENOCES_R1
        return get_properties_r1
      when NAMESPACEURI_OPENOCES_R2
        return get_properties_r2
      end
    end

    def get_properties_r1
      if (signed_nodes.count != 1)
        @error = I18n.t('devise.dk_nemid.wrong_content_length',
          :count => signed_nodes.count)
        return
      end

      # TODO: This is untested. If year is correct no signature of this
      #       kind should be valid anymore.
      extract_properties_from_nodes(signed_nodes.children, "Name", "Value")
    end

    def get_properties_r2
      signed_nodes.each do |node|
        if node.attr('Id') == "ToBeSigned"
          extract_properties_from_nodes(
            node.xpath("//ds:SignatureProperty", NAMESPACES),
            "openoces:Name", "openoces:Value")
        end
      end
    end

    def extract_properties_from_nodes(nodes, name_xpath, value_xpath)
      nodes.each do |node|
        name = node.xpath(name_xpath, NAMESPACES).text
        value_node = node.xpath(value_xpath, NAMESPACES)
        value = value_node.text
        encoding = value_node.attr("Encoding").text
        value = Base64.decode64(value) if encoding == 'base64'
        @signature_properties[name] = value
      end
    end

    def get_signing_certificate
      props = DkNemidProperties.instance
      danid_certs = props.danid_certs
      cert = get_user_certificate
      if danid_certs.verify(cert)
        @chain = danid_certs.chain
        # TODO: Verify cert through ocsp lookup
        # if certs.ocsp_verify(cert, @chain)
          @cert = cert
          @cert_base64 = props.clean_base64(cert)
        # end
      else
        @error = I18n.t('devise.dk_nemid.cert_verify_failed',
           :code => danid_certs.error,
           :reason => danid_certs.error_string)
      end
    end

    def get_user_certificate
      # Find the user certificate
      document.xpath('//ds:KeyInfo/ds:X509Data/ds:X509Certificate',
        Xmldsig::NAMESPACES).each do |base64_cert|
        cert = OpenSSL::X509::Certificate.new "-----BEGIN CERTIFICATE-----" +
          base64_cert.text + "-----END CERTIFICATE-----"
        cert.extensions.each do |ext|
          if ext.oid == 'keyUsage' && !(ext.value =~ /CRL Sign/)
            return cert
          end
        end
      end
      logger.error "Did not find user certificate"
    end

    def get_certificate_data
      subject_serial = @cert.subject.to_a.assoc("serialNumber")[1]
      if subject_serial =~ /^(PID:[0-9-]+)/
        @identifier = $1
      elsif subject_serial =~ /^CVR:([0-9]+)-(.+)/
        @cvr = $1
        @identifier = $2
      else
        @error = I18n.t('devise.dk_nemid.wrong_cert_type')
      end
    end

    def error
      @error
    end

    def cvr
      @cvr
    end

    def cpr
      @cpr
    end

    def identifier
      @identifier
    end

    def logger
      Rails.logger
    end

    protected

    def get_pid_cpr(pid)
      @cpr ||= nil
      props = DkNemidProperties.instance
      response = props.pid_soap_client.call(:pid,
        message: {
          :pIDRequests => {
            :PIDRequest => {
              PID: pid, CPR: @cpr,
              serviceId: Devise.dk_nemid_cpr_pid_spid,
              b64Cert: @cert_base64,
              id: nil
            }
          }
        }
      )
      result = response.to_hash[:pid_response][:result][:pid_reply]
      if result[:status_code].to_i == 0 && result[:pid] == pid
        @cpr = result[:cpr]
      else
        logger.warn "PID lookup failed with #{result[:status_text_uk]} for #{pid}"
        @cpr = nil
      end
    end

    def get_rid_cpr(rid)
      logger.error "RID lookup not implemented"
      @cpr = nil
    end

  end
end
