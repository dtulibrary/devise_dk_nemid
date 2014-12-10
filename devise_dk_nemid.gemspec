# Encoding: UTF-8
require 'rake'
Gem::Specification.new do |spec|
  spec.name = 'devise_dk_nemid'
  spec.version = '1.0.7'

  spec.authors = [ 'Morten Rønne' ]
  spec.required_ruby_version = '>= 1.9.2'
  spec.summary = 'Devise NemID login extension'
  spec.description = 'Devise NemID authentication module'
  spec.summary = <<-SUM
    This extension enables a devise setup to login through Danish NemID.
    You are required to be registered at NemId as service provider in 
    order to use this.
SUM
  spec.files = `git ls-files`.split("\n")
  spec.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.has_rdoc = false
  spec.license = 'GPL-2'
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("devise", "~> 3.2")
  spec.add_runtime_dependency("savon", "~> 2.3")
  spec.add_runtime_dependency("xmldsig", "~> 0.2")
  spec.add_runtime_dependency("jquery-cookie-rails", "~> 1.3")

  spec.add_development_dependency("devise", "~> 3.2")
  spec.add_development_dependency('rspec')

end
