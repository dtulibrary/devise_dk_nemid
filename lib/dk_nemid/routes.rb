ActionDispatch::Routing::Mapper.class_eval do

  protected

  # route for dk nemid page
  def devise_dk_nemid(mapping, controllers)
    resource :session, :only => [],
      :controller => controllers[:dk_nemid_sessions] do
      get :new, :path => mapping.path_names[:sign_in], :as => "new"
      post :create, :path => mapping.path_names[:sign_in], :as => "create"
      match :destroy, :path => mapping.path_names[:sign_out], :as => "destroy"
    end
  end
  
end
