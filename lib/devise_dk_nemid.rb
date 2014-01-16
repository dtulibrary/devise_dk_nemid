require 'active_support/concern'
require 'devise'

module Devise
  mattr_accessor :dk_nemid_environment
  @@dk_nemid_environment = 'ocesii_danid_env_prod'

  mattr_accessor :dk_nemid_certificate_path
  @@dk_nemid_certificate_path = 'nemid'

  mattr_accessor :dk_nemid_certificate_password
  @@dk_nemid_certificate_password

  mattr_accessor :dk_nemid_allowed
  @@dk_nemid_allowed = ['otp', 'software', 'digitalsignatur']

  mattr_accessor :dk_nemid_cpr_service
  @@dk_nemid_cpr_service = :none

  mattr_accessor :dk_nemid_cpr_failures
  @@dk_nemid_cpr_failures = 5

  mattr_accessor :dk_nemid_cpr_pid_spid
  @@dk_nemid_cpr_pid_spid = ''

  mattr_accessor :dk_nemid_cpr_rid_spid
  @@dk_nemid_cpr_rid_spid = ''

  mattr_accessor :dk_nemid_proxy
  @@dk_nemid_proxy = nil

end

Devise.add_module(:dk_nemid,
  :route => :dk_nemid,
  :strategy => true,
  :controller => :dk_nemid_sessions,
  :model => 'dk_nemid/models/dk_nemid'
)

require 'dk_nemid/routes'
require 'dk_nemid/models/dk_nemid'
require 'dk_nemid/engine' if defined?(Rails)
require 'dk_nemid/strategies/dk_nemid'
require 'dk_nemid/savon_ssl'

