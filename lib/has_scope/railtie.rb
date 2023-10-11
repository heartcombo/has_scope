require 'rails/railtie'

module HasScope
  class Railtie < Rails::Railtie
    initializer "has_scope.deprecator" do |app|
      app.deprecators[:has_scope] = HasScope.deprecator if app.respond_to?(:deprecators)
    end
  end
end

