require 'savon'
require 'dk_nemid/models/dk_nemid_properties'

HTTPI.adapter = :net_http

# Savon/HTTPI only allows certs from pem file.
# But we do not have a pem file, so we sets the cert and key
# directly here.

module Savon
  class HTTPRequest
    old_configure_ssl = instance_method(:configure_ssl)

    define_method(:configure_ssl) do
      old_configure_ssl.bind(self).()
      props = Devise::Models::DkNemidProperties.instance
      @http_request.auth.ssl.cert = props.my_cert.certificate
      @http_request.auth.ssl.cert_key = props.my_key
    end
  end
end
