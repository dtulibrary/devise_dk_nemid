module Devise
  module Models
    class DkNemidSign < Devise::Models::DkNemidLogon
      def initialize
        super
        @sign_pointer = nil
        @sign_format = nil
        @sign_method = "internal"
      end

      def clientflow
        "OCESSIGN2"
      end

      def sign_monospacefont
        "FALSE"
      end

      # SIGNTEXT or SIGNTEXT_URI are mandatory
      def get_signed_parameters
        signed_parameters = super
        signed_parameters['SIGNTEXT_FORMAT'] = @sign_format
        if @sign_method = "internal"
          signed_parameters['SIGNTEXT'] = @sign_pointer
        else
          signed_parameters['SIGNTEXT_URI'] = @sign_pointer
          signed_parameters['SIGNTEXT_REMOTE_HASH'] = sha256 of external link
        end
        case @sign_format
        when "TEXT"
          signed_parameters['SIGNTEXT_MONOSPACEFONT'] = sign_monospacefont
        when "XML"
          signed_parameters['SIGNTEXT_TRANSFORMATION'] = @sign_transformation
          signed_parameters['SIGNTEXT_TRANSFORMATION_ID'] =
            @sign_transformation_id
        end
      end

      def set_sign_text(text, monospacefont = "FALSE")
        set_sign_pointer(text)
        @sign_format = "TEXT"
        @sign_monospacefont = monospacefont
      end

      def set_sign_pdf(pdf)
        set_sign_pointer(pdf)
        @sign_format = "PDF"
      end

      def set_sign_html(html)
        set_sign_pointer(html)
        @sign_format = "HTML"
      end

      def set_sign_xml(xml, xslt, id)
        set_sign_pointer(xml)
        @sign_transformation = Base64.encode(xslt)
        @sign_transformation_id = id
        @sign_format = "XML"
      end

      protected

      def set_sign_pointer(pointer)
        if pointer.match('^https?://')
          @sign_pointer = pointer
          @sign_method = "external"
          @sign_remote_hash = @props.sign_remote_hash
        else
          @sign_pointer = Base64.encode64(pointer)
          @sign_method = "internal"
        end
      end

    end
  end
end
