require 'base64'
require 'openssl'

module Devise
  module Models
    class TestCase
      APPLET_CLASS = "dk.pbs.applet.bootstrap.BootApplet"
      SERVER_URL = "https://applet.danid.dk"

      def initialize
        super
        @challenge = nil
        @log_level = nil
      end

      def make_test_case
        file = File.expand_path("nemid/#{Devise.dk_nemid_environment}.p12",
          Rails.root)
        @signer = OpenSSL::PKCS12::new(
          File.read(file), Devise.dk_nemid_certificate_password)
        # TODO: Check expired status
        @signkey = OpenSSL::PKey::RSA.new(@signer.key,
          Devise.dk_nemid_certificate_password)

        signed_parameters = Hash.new
        signed_parameters['LANGUAGE'] = 'en'
        signed_parameters['ServerUrlPrefix'] = 'https://applet.danid.dk'
        signed_parameters['ZIP_BASE_URL'] = 'https://applet.danid.dk'
        signed_parameters['ZIP_FILE_ALIAS'] = 'OpenLogon2'
        signed_parameters['log_level'] = 'debug'
        signed_parameters['paramcert'] = 
          "MIIGTzCCBTegAwIBAgIETKh6kzANBgkqhkiG9w0BAQsFADA/MQswCQYDVQQGEwJE" +
          "SzESMBAGA1UECgwJVFJVU1QyNDA4MRwwGgYDVQQDDBNUUlVTVDI0MDggT0NFUyBD" +
          "QSBJMB4XDTEzMDkyNzA3NDM1NFoXDTE2MDkyNzA3NDE1N1owgaYxCzAJBgNVBAYT" +
          "AkRLMTYwNAYDVQQKDC1EYW5tYXJrcyBUZWtuaXNrZSBVbml2ZXJzaXRldCAvLyBD" +
          "VlI6MzAwNjA5NDYxXzAgBgNVBAUTGUNWUjozMDA2MDk0Ni1VSUQ6OTkzNjczMTkw" +
          "OwYDVQQDDDREYW5tYXJrcyBUZWtuaXNrZSBVbml2ZXJzaXRldCAtIERUVSBCaWJs" +
          "aW90ZWsgLSBOZW1JMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApIyZ" +
          "6z3Je32WnwIXOni3Us4yP9gSqerAnwNsOb9fHudIcwKP8jKa5zxnXt+U9Qg2wYRB" +
          "BW+0+/uOAgrJFkY9gVlU/dgJKl5gzbVYlV24bPnHi1PEZ0Zpigb2hD2JHthId3gJ" +
          "3Tdi2B8ZEW+Zfy+9LH0xm6WWcGn+ZR6ZCeIVuCcjtaCtN/23b2mnl88M+SQXODXk" +
          "U65yNBeWx/2zIAd/PkBmIG0htR7JQXQsZzJCuPp/SAwaly12J+BzymeHjd+Ad0pu" +
          "t3E5LOwVUrcf+mMn7ZI3jnLxo+HofU1i71CdvSG3itCK1tNjTg1uYQm5RwAY+/2E" +
          "TOCS8gtM4Z5IkPskZQIDAQABo4IC6TCCAuUwDgYDVR0PAQH/BAQDAgO4MIGdBggr" +
          "BgEFBQcBAQSBkDCBjTA+BggrBgEFBQcwAYYyaHR0cDovL29jc3Aub2Nlcy1pc3N1" +
          "aW5nMDEudHJ1c3QyNDA4LmNvbS9yZXNwb25kZXIwSwYIKwYBBQUHMAKGP2h0dHA6" +
          "Ly92LmFpYS5vY2VzLWlzc3VpbmcwMS50cnVzdDI0MDguY29tL29jZXMtaXNzdWlu" +
          "ZzAxLWNhLmNlcjCCAUMGA1UdIASCATowggE2MIIBMgYKKoFQgSkBAQEDBDCCASIw" +
          "LwYIKwYBBQUHAgEWI2h0dHA6Ly93d3cudHJ1c3QyNDA4LmNvbS9yZXBvc2l0b3J5" +
          "MIHuBggrBgEFBQcCAjCB4TAQFglUUlVTVDI0MDgwAwIBARqBzEZvciBhbnZlbmRl" +
          "bHNlIGFmIGNlcnRpZmlrYXRldCBn5mxkZXIgT0NFUyB2aWxr5XIsIENQUyBvZyBP" +
          "Q0VTIENQLCBkZXIga2FuIGhlbnRlcyBmcmEgd3d3LnRydXN0MjQwOC5jb20vcmVw" +
          "b3NpdG9yeS4gQmVt5nJrLCBhdCBUUlVTVDI0MDggZWZ0ZXIgdmlsa+VyZW5lIGhh" +
          "ciBldCBiZWdy5m5zZXQgYW5zdmFyIGlmdC4gcHJvZmVzc2lvbmVsbGUgcGFydGVy" +
          "LjCBoAYDVR0fBIGYMIGVMDigNqA0hjJodHRwOi8vY3JsLm9jZXMtaXNzdWluZzAx" +
          "LnRydXN0MjQwOC5jb20vaWNhMDExLmNybDBZoFegVaRTMFExCzAJBgNVBAYTAkRL" +
          "MRIwEAYDVQQKDAlUUlVTVDI0MDgxHDAaBgNVBAMME1RSVVNUMjQwOCBPQ0VTIENB" +
          "IEkxEDAOBgNVBAMMB0NSTDcyNTkwHwYDVR0jBBgwFoAU3D4gOQRRdQoY/b+J1a6l" +
          "pSpLcncwHQYDVR0OBBYEFIMAlziHe1FzyRi4fnK/zVEoHu5dMAkGA1UdEwQCMAAw" +
          "DQYJKoZIhvcNAQELBQADggEBABScWy33pVHNnJzi41p7ZPAaw6Q2Um+6T1DYruoP" +
          "D/Ig3ivxflqTB8CTvs60dxIVA3jROU09uPDbuEgouOcHLkDhpyHB5A3rPyF5FJT0" +
          "iAeYDJFIH8s4RsUFM/Uw1hJEHC1ofgGPOYhph5OqdiZv5Biff4pz85rMp6j0QnaN" +
          "MVhHwx9aBSf2NkcGCZON39U3ADu4e/RJrBKve09or7VpT4xCCqau+GaocTu3meKM" +
          "YZ4yIRWmNIZ1LZmN2zKz3vY9YBNbnMUwsaGZuQbvDkhgbTrsgbrZCkulxdpF3F9O" +
          "y7DGnAAs63UwpqxvMmYp6ltorJHSf4O6Sabf4ZF3Y6ww5Qo="
        signed_parameters['signproperties'] = 'challenge=MzUxMjAyNjk4NzQ0OTUwNjAxMA=='
        param_string = normalized_parameters(signed_parameters);
        digest = calculate_digest(param_string)

        correct_digest = 'ZmoZs6ts9ZjzxTtB4ldee4oq0JNindiIstGs2wxc+iY='
        unless encode(digest) == correct_digest
          puts "Digest error"
          puts "  Have: #{encode(digest)}"
          puts "  Want: #{correct_digest}"
        end
        correct_sign =
          'JqMAGSjSwaOKdfaWYF69zyQ5dVxbEghNOp3duooaVUldZYV7UlZeyGl5a/ydBY40+' +
          'amy1/ml+b6dXc8sCirXNvrir1KSNNFA7sFj66e41DXoLR1CXPIPgCj/ITfKLXAsRT' +
          'MiS8tGGywbckJDHdNSdtHRU+yuADyTtDMQedFH3hUrQ2B8N61R2DaCWekqS7gRBir' +
          'C5wLeKNeTShgl+gCpYXBFbVYJIseMXEk6Xxr6kASSr4LZd3qZeri8K67IIe5fwcrt' +
          'wjww5ICm2gUxKhctB2DUbfZ32KbrBDdAIEg+8M9Qt8Ay3fnFpqgXU5ZrE2pT6r9yo' +
          'E3Kut7EE+2jZ7/vrw=='
        #digest = OpenSSL::Digest::SHA1.new.digest(param_string)
        #puts "Sign digest #{digest}"
        #sign = encode(signer_digest(digest))
        sign = encode(@signkey.sign(OpenSSL::Digest::SHA256.new, param_string))
        #@signkey.private_encrypt(param)
        unless sign == correct_sign
          puts "Sign error"
          puts "  Have: #{sign}"
          puts "  Want: #{correct_sign}"
        end
      end

      def generate_logon_applet_element()
        file = File.expand_path("nemid/#{Devise.dk_nemid_environment}.p12",
          Rails.root)
        @signer = OpenSSL::PKCS12::new(
          File.read(file), Devise.dk_nemid_certificate_password)
        # TODO: Check expired status
        @signkey = OpenSSL::PKey::RSA.new(@signer.key,
          Devise.dk_nemid_certificate_password)

        # Make sure we have a challenge
        create_challenge

        # signedParamters Hash with case insensitive keys
        signed_parameters = get_signed_parameters

        param_string = normalized_parameters(signed_parameters);
        digest = calculate_digest(param_string)

        unsigned_parameters = Hash.new
        unsigned_parameters['mayscript'] = "true";
        unsigned_parameters['paramsdigest'] = encode(digest)
        unsigned_parameters['signeddigest'] = encode(signer_digest(digest))

        t = Time.now
        appletPath = SERVER_URL + "/bootapplet/#{t.to_i}#{t.usec}"
        applet_tag = "<applet name=\"DANID_DIGITAL_SIGNATUR\" tabindex=\"1\" " +
          "archive=\"#{appletPath}\" " +
          "code=\"#{APPLET_CLASS}\" " +
          "WIDTH=\"#{applet_width}\" " +
          "HEIGHT=\"#{applet_height}\" " +
          "mayscript=\"mayscript\">\n"
        applet_tag += app_param_tags(signed_parameters)
        applet_tag += app_param_tags(unsigned_parameters)
        applet_tag += "</applet>\n";
        applet_tag.html_safe
      end

      def get_signed_parameters
        signed_parameters = Hash.new
        # Plain base64 version of cert.
        signed_parameters['paramcert'] = clean_base64(@signer.certificate)
        signed_parameters['ZIP_FILE_ALIAS'] = zip_file_alias
        signed_parameters['ZIP_BASE_URL'] = SERVER_URL
        signed_parameters['ServerUrlPrefix'] = SERVER_URL
        signed_parameters['language'] = applet_language
        signed_parameters['signproperties'] = "challenge=#{encode(@challenge)}"
        signed_parameters['log_level'] = @log_level if @log_level
        signed_parameters
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

      def applet_width
        200
      end

      def applet_height
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
        OpenSSL::Digest::SHA256.new.digest(params)
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

      def set_sign_text(text, format)
        @sign_text = Base64.encode64(text)
        @sign_format = format
      end

      def signer_digest(param)
        @signkey.private_encrypt(param)
      end

      def encode(param)
        Base64.encode64(param).gsub("\n", "")
      end

      def clean_base64(cert)
        cert.to_pem.gsub("-----BEGIN CERTIFICATE-----\n", "").
          gsub("\n-----END CERTIFICATE-----\n", "").gsub("\n", "")
      end

      def create_challenge
        @challenge ||= SecureRandom.random_bytes(15)
      end

      def verify_login(params)
        File.open("applet_response.dump", "wb") do |f|
          f.write(params.inspect)
        end
      end

    end
  end
end
