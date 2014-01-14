require 'devise'

module DeviseDkNemid
  class Engine < ::Rails::Engine
    isolate_namespace DeviseDkNemid
  end
end

#puts Rails::Application::Railties.engines.map() { |i| i.class }

