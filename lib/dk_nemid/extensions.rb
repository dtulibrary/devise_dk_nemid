module Devise
  module DkNemid
    module Extensions
      autoload :SessionsControllerDkNemid,
        'dk_nemid/extensions/sessions_controller_dk_nemid'

      class << self
        def apply
          Devise::SessionsController.send(:include,
            Extensions::SessionsControllerDkNemid)
        end
      end
    end
  end
end
