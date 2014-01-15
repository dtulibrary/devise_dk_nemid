require 'savon'

module OpenSSL
  module X509
    # TODO: Most of these aren't defined in ruby, but exists in C.
    # See http://code.woboq.org/crypto/openssl/crypto/x509/x509_vfy.h.html
    V_FLAG_CB_ISSUER_CHECK = 0x01
    V_FLAG_X509_STRICT = 0x20
    V_FLAG_POLICY_CHECK = 0x80
    V_FLAG_EXPLICIT_POLICY = 0x100
    V_FLAG_INHIBIT_ANY = 0x200
    V_FLAG_INHIBIT_MAP = 0x400
    V_FLAG_EXTENDED_CRL_SUPPORT = 0x1000
    V_FLAG_USE_DELTAS = 0x2000
  end
end

class Devise::Models::DkNemidProperties
  include Singleton

  attr_reader :my_cert, :my_cert_base64, :my_key, :danid_certs
  attr_accessor  :ldap_server_danid, :ldap_ca_dn_danid, :crl_searchbase,
    :pid_service_url, :rid_service_url, :poces_policy_prefix,
    :moces_policy_prefix, :voces_policy_prefix, :foces_policy_prefix,
    :nemid_applet_server_url, :oces_applet_server_url, :oces_applet_name

  def initialize
    @my_cert = OpenSSL::PKCS12::new( File.read(
      File.expand_path("#{Devise.dk_nemid_certificate_path}/"+
        "#{Devise.dk_nemid_environment}.p12", Rails.root)
      ), Devise.dk_nemid_certificate_password)
    # TODO: Check expired status
    @my_key = OpenSSL::PKey::RSA.new(@my_cert.key,
      Devise.dk_nemid_certificate_password)
    # Create a ready base64 version of my_cert
    @my_cert_base64 = clean_base64(@my_cert.certificate)

    @danid_certs = OpenSSL::X509::Store.new
    @danid_certs.add_file(ca_file)
    # Load configuration for the current environment
    config = YAML.load(File.read( File.expand_path(
        "../../../nemid/#{Devise.dk_nemid_environment}.yml",
        File.dirname(__FILE__))))
    config.each do |k, v|
      send("#{k}=", v)
    end
    @danid_certs.purpose = OpenSSL::X509::PURPOSE_ANY
    # We want all these things checked
    @danid_certs.flags = OpenSSL::X509::V_FLAG_CB_ISSUER_CHECK |
#      OpenSSL::X509::V_FLAG_CRL_CHECK |
      OpenSSL::X509::V_FLAG_CRL_CHECK_ALL |
      OpenSSL::X509::V_FLAG_X509_STRICT |
      OpenSSL::X509::V_FLAG_POLICY_CHECK |
#      OpenSSL::X509::V_FLAG_EXPLICIT_POLICY |
      OpenSSL::X509::V_FLAG_INHIBIT_ANY |
      OpenSSL::X509::V_FLAG_INHIBIT_MAP
#      OpenSSL::X509::V_FLAG_EXTENDED_CRL_SUPPORT |
#      OpenSSL::X509::V_FLAG_USE_DELTAS
  end

  # OCSP verfiy
  def ocsp_verify(cert)
    true
  end

  def clean_base64(cert)
    cert.to_pem.gsub("-----BEGIN CERTIFICATE-----\n", "").
      gsub("\n-----END CERTIFICATE-----\n", "").gsub("\n", "")
  end

  def ca_file
    File.expand_path("../../../nemid/ca/#{Devise.dk_nemid_environment}.pem",
      File.dirname(__FILE__))
  end

  def pid_soap_client
    @pid_soap_client ||= create_pid_soap_client
  end

  private

  def create_pid_soap_client
    options = {
      :wsdl => "#{pid_service_url}?WSDL",
      :soap_version => 1,
      :endpoint => pid_service_url,
      :logger => Rails.logger,
      :log_level => (Rails.env.development? ? :debug : :warn),
      :convert_request_keys_to => :none,
    }
    options[:proxy] = Devise.dk_nemid_proxy if Devise.dk_nemid_proxy
    client = Savon.client(options)
    Savon.observers << SavonObserver.new if Rails.env.development?
    client
  end

end
