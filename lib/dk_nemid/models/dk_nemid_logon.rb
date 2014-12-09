require 'base64'
require 'openssl'
require 'dk_nemid/models/dk_nemid_properties'

module Devise
  module Models
    class DkNemidLogon
      SOFTWARE_APPLET = 'applet'
      SOFTWARE_CODE_CLASS =
        'org.openoces.opensign.client.applet.bootstrap.BootApplet'

      def initialize
        super
        @challenge = nil
        @log_level = nil
      end

      def generate_setup
        @props ||= DkNemidProperties.instance
        @signer = @props.my_cert
        @signkey = @props.my_key

        # Make sure we have a challenge
        create_challenge
      end

      def generate_json_parameters(login_type)
        generate_setup

        # signedParameters Hash with case insensitive keys
        signed_parameters = send(
          "get_signed_#{login_type}_parameters",
          @props.my_cert_base64
        )

        unsigned_parameters = send(
          "get_unsigned_#{login_type}_parameters",
          signed_parameters
        )

        # JSON data structure to be parsed into NemID
        json_tag = '<script type="text/x-nemidjson" id="nemid_parameters">' +
          unsigned_parameters.to_json + "</script>\n"
        Rails.logger.info "JSON " + json_tag
        json_tag.html_safe
      end

      def generate_iframe_element(login_type)
        generate_setup

        # Iframe tag for NemID integration
        # If limited mode is implemented 'std' should be changed
        iframe_tag = '<iframe id="nemid_iframe" title="NemID" ' +
          'allowfullscreen="true" scrolling="no" frameborder="0" ' +
          "style=\"width:#{applet_width(login_type)}px;" +
                  "height:#{applet_height(login_type)}px;border:0\" " +
          "src=\"#{@props.nemid_iframe_server_url_unique('std')}\">\n"
        iframe_tag += "</iframe>\n";
        iframe_tag.html_safe
      end

      def number_login_options
        Devise.dk_nemid_allowed.count
      end

      def get_signed_otp_parameters(cert_base64)
        signed_parameters = Hash.new
        signed_parameters['CLIENTFLOW'] = clientflow
        signed_parameters['CLIENTMODE'] = "STANDARD"
        signed_parameters['DO_NOT_SHOW_CANCEL'] = "FALSE"
        signed_parameters['LANGUAGE'] = nemid_language
        #signed_parameters['ORIGIN'] = "http://self"
        #signed_parameters['REMEMBER_USER_ID'] = previous token
        signed_parameters['REQUEST_ISSUER_ID'] = Devise.dk_nemid_request_issuer_id
        signed_parameters['SIGN_PROPERTIES'] = "challenge=#{encode(@challenge)}"
        signed_parameters['SP_CERT'] = cert_base64
        t = DateTime.now.utc
        signed_parameters['TIMESTAMP'] = t.strftime('%F %T%z')
        signed_parameters
      end

      def get_signed_software_parameters(cert_base64)
        Hash.new
      end

      def get_signed_digitalsignatur_parameters(cert_base64)
        Hash.new
      end

      def get_unsigned_otp_parameters(signed_parameters)
        unsigned_parameters = signed_parameters
        param_string = normalized_parameters(signed_parameters)
        unsigned_parameters['PARAMS_DIGEST'] = calculate_digest(param_string)
        unsigned_parameters['DIGEST_SIGNATURE'] = signer_digest(param_string)
        unsigned_parameters
      end

      def get_unsigned_software_parameters(signed_parameters)
        unsigned_parameters = default_unsigned_parameters
        unsigned_parameters['mayscript'] = "true";
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
        Hash.new
      end

      def nemid_language
        case I18n.locale
        when :da, :en, :kl
          I18n.locale.to_s
        else
          'da'
        end
      end

      def applet_width(login_type)
        500
      end

      def applet_height(login_type)
        450
      end

      def clientflow
        "OCESLOGIN2"
      end

      def normalized_parameters(parameters)
        result = ''
        sorted_keys = parameters.keys.sort do |a, b|
          a.upcase <=> b.upcase
        end
        sorted_keys.each do |k|
          result += k + parameters[k]
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
