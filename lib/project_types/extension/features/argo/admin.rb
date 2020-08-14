# frozen_string_literal: true
require 'json'

module Extension
  module Features
    module Argo
      class Admin < Base
        GIT_ADMIN_TEMPLATE = 'https://github.com/Shopify/argo-admin-template.git'
        ADMIN_RENDERER_PACKAGE = '@shopify/argo-admin'

        class << self
          def admin_setup
            @admin ||= Admin.new(
              setup: ArgoSetup.new(git_template: GIT_ADMIN_TEMPLATE),
              renderer_package: ADMIN_RENDERER_PACKAGE,
            )
          end
        end
      end
    end
  end
end
