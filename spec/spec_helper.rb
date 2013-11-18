require 'bundler'
Bundler.require(:default, :test)

ENV['EVERCAM_ENV'] ||= 'test'
require_relative '../lib/config'

def require_app(name)
  require_relative "../app/#{name}"
end

def require_lib(name)
  require_relative "../lib/#{name}"
end

RSpec.configure do |c|
  c.expect_with :stdlib, :rspec
end

