require 'base64'
require 'openssl'
require 'dk_nemid/models/dk_nemid_properties'

module Devise
  module Models
    class DkNemidLogon
      OTP_APPLET = "DANID_DIGITAL_SIGNATUR"
      OTP_CODE_CLASS = 'dk.pbs.applet.bootstrap.BootApplet'
      SOFTWARE_APPLET = 'applet'
      SOFTWARE_CODE_CLASS = 
        'org.openoces.opensign.client.applet.bootstrap.BootApplet'

      def initialize
        super
        @challenge = nil
        @log_level = nil
      end

      def generate_logon_applet_element(login_type)
        @props ||= DkNemidProperties.instance
        file = File.expand_path("nemid/#{Devise.dk_nemid_environment}.p12",
          Rails.root)
        @signer = @props.my_cert
        @signkey = @props.my_key

        # Make sure we have a challenge
        create_challenge

        # signedParamters Hash with case insensitive keys
        signed_parameters = send(
          "get_signed_#{login_type}_parameters",
          @props.my_cert_base64
        )

        unsigned_parameters = send(
          "get_unsigned_#{login_type}_parameters",
          signed_parameters
        )

        case login_type
        when "software", "digitalsignatur"
          applet_name = SOFTWARE_APPLET
          appletPath = @props.oces_applet_name
          code_base = @props.oces_applet_server_url
          code_class = SOFTWARE_CODE_CLASS
        else
          applet_name = OTP_APPLET
          code_class = OTP_CODE_CLASS
          t = Time.now
          appletPath = @props.nemid_applet_server_url +
            "/bootapplet/#{t.to_i}#{t.usec}"
          code_base = nil
        end

        applet_tag = "<applet name=\"#{applet_name}\" tabindex=\"1\" " +
          "archive=\"#{appletPath}\" " +
          "code=\"#{code_class}\" " +
          "WIDTH=\"#{applet_width(login_type)}\" " +
          "HEIGHT=\"#{applet_height(login_type)}\" " +
          (code_base ? "codebase=\"#{code_base}\" " : "") +
          "mayscript=\"mayscript\">\n"
        applet_tag += app_param_tags(signed_parameters)
        applet_tag += app_param_tags(unsigned_parameters)
        applet_tag += "</applet>\n";
        #applet_tag.html_safe
        "applet"
      end

      def get_signed_otp_parameters(cert_base64)
        signed_parameters = Hash.new
        signed_parameters['ZIP_FILE_ALIAS'] = zip_file_alias
        signed_parameters['log_level'] = @log_level if @log_level
        signed_parameters['paramcert'] = cert_base64
        signed_parameters['ZIP_BASE_URL'] = @props.nemid_applet_server_url
        signed_parameters['ServerUrlPrefix'] = @props.nemid_applet_server_url
        signed_parameters['language'] = applet_language
        signed_parameters['signproperties'] = "challenge=#{encode(@challenge)}"
        signed_parameters
      end

      def get_signed_software_parameters(cert_base64)
        Hash.new
      end

      def get_signed_digitalsignatur_parameters(cert_base64)
        Hash.new
      end

      def get_unsigned_otp_parameters(signed_parameters)
        unsigned_parameters = default_unsigned_parameters
        param_string = normalized_parameters(signed_parameters)
        unsigned_parameters['paramsdigest'] = calculate_digest(param_string)
        unsigned_parameters['signeddigest'] = signer_digest(param_string)
        unsigned_parameters
      end

      def get_unsigned_software_parameters(signed_parameters)
        unsigned_parameters = default_unsigned_parameters
        unsigned_parameters['ZIP_BASE_URL'] = @props.oces_applet_server_url +
          "/plugins"
        unsigned_parameters['MS_SUPPORT'] = "bcjce"
        unsigned_parameters['SUN_SUPPORT'] = "jsse"
        unsigned_parameters['STRIP_ZIP'] = "yes"
        unsigned_parameters['EXTRA_ZIP_FILE_NAMES'] = 
          "capi,pkcs12,oces,cryptoki"
        unsigned_parameters['locale'] = "da,DK"
        unsigned_parameters['cabbase'] = @props.oces_applet_server_url +
          "/OpenSign-bootstrapped.cab"
        unsigned_parameters['key.store.directory'] = "null"
        unsigned_parameters['background'] = "255,255,255"
        unsigned_parameters['socialsecuritynumber'] = "no"
        unsigned_parameters['optionallid'] = "no"
        unsigned_parameters['opensign.doappletrequest'] = "false"
        unsigned_parameters['opensign.doappletrequestonmac'] = "false"
        unsigned_parameters['logonto'] = '' # NemIdProperties.getServiceProviderName
        unsigned_parameters['cdkortservice'] = "demo"
        unsigned_parameters['signproperties'] = "challenge=#{encode(@challenge)}"
        unsigned_parameters['subjectdnfilter'] = ""
        unsigned_parameters['issuerdnfilter'] = encode("TRUST2048")
        unsigned_parameters['opensign.message.name'] = "signature"
        unsigned_parameters['opensign.result.name'] = "result"
        unsigned_parameters['gui'] = "modern"
        unsigned_parameters
      end

      def get_unsigned_digitalsignatur_parameters(signed_parameters)
        unsigned_parameters = get_unsigned_software_parameters(signed_parameters)
        unsigned_parameters['issuerdnfilter'] = encode("TDC")
        unsigned_parameters
      end

      def default_unsigned_parameters
        unsigned_parameters = Hash.new
        unsigned_parameters['mayscript'] = "true";
        unsigned_parameters
      end

      def applet_language
        case I18n.locale
        when 'da'
        when 'en'
        when 'kl'
          I18n.locale
        else
          'da'
        end
      end

      def applet_width(login_type)
        case login_type
        when "software", "digitalsignatur"
          430
        else
          200
        end
      end

      def applet_height(login_type)
        250
      end

      def zip_file_alias
        "OpenLogon2"
      end

      def normalized_parameters(parameters)
        result = ''
        sorted_keys = parameters.keys.sort do |a, b|
          a.upcase <=> b.upcase
        end
        sorted_keys.each do |k|
          result += k.downcase + parameters[k]
        end
        result
      end

      def calculate_digest(params)
        encode(OpenSSL::Digest::SHA256.new.digest(params))
      end

      def app_param_tags(params)
        result = ''
        params.each do |k, v|
          result += "<param name=\"#{k}\" value=\"#{v}\" />\n"
        end
        result
      end

      def challenge=(value)
        @challenge = value
      end

      def log_level=(value)
        @log_level = value
      end

      def signer_digest(param)
        encode(@signkey.sign(OpenSSL::Digest::SHA256.new, param))
      end

      def encode(param)
        Base64.encode64(param).gsub("\n", "")
      end

      def create_challenge
        @challenge ||= SecureRandom.random_bytes(15)
      end

      def verify_login(params, challenge, logonto = nil)
        result = Base64.decode64(params[:result])
        if result != 'ok'
          flash[:error] = I18n.t("devise.dk_nemid.#{result}")
          return nil
        end

        signature = DkNemidAppletResponse.new(
          Base64.decode64(params[:signature]))
        if signature.verify_logon(challenge, logonto)
          # Logon ok
        else
          # Logon fail
        end
      end

      def test_verify(challenge = 'kch9nCwVadruv3G1DyH+')
        data = eval(File.read("applet.dump.local"))
        params = Hash.new
        params[:result] = data['result']
        params[:signature] = data['signature']
        #env['warden'].authenticated?
        #verify_login(params, challenge)
      end

      def test_cpr
        app = DkNemidAppletResponse.new
        app.test_cpr
      end

    end
  end
end
