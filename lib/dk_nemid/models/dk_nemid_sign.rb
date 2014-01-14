module Devise
  module Models
    class DkNemidSign < Devise::Models::DkNemidLogon
      def applet_width
        500
      end

      def applet_heigth
        450
      end

      def zip_file_alias
        "OpenSign2"
      end

      def get_signed_parameters
        signed_parameters = super
        signed_parameters['signtext'] = @sign_text
        signed_parameters['signtextformat'] = @sign_format
      end

      def set_sign_text(text, format)
        @sign_text = Base64.encode64(text)
        @sign_format = format
      end

    end
  end
end
