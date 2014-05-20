module Devise
  module Models
    module DkNemid
      extend ActiveSupport::Concern

      module ClassMethods
        ::Devise::Models.config(self,
          :dk_nemid_environment,
          :dk_nemid_certificate_password,
          :dk_nemid_allowed,
          :dk_nemid_cpr_service,
          :dk_nemid_cpr_failures,
          :dk_nemid_cpr_pid_spid,
          :dk_nemid_cpr_rid_spid,
          :dk_nemid_test_mode,
          :dk_nemid_test_pid,
          :dk_nemid_test_cpr
        )
      end
    end
  end
end
