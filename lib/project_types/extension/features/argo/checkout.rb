# frozen_string_literal: true
module Extension
  module Features
    module Argo
      class Checkout < Base
        GIT_CHECKOUT_TEMPLATE = 'https://github.com/Shopify/argo-checkout-template.git'
        CHECKOUT_RENDERER_PACKAGE = '@shopify/argo-checkout'

        def self.checkout_setup
          @checkout ||= Checkout.new(
            setup: ArgoSetup.new(
              git_template: GIT_CHECKOUT_TEMPLATE,
              dependency_checks: [ArgoDependencies.node_installed(min_major: 10, min_minor: 16)]
            ),
            renderer_package: CHECKOUT_RENDERER_PACKAGE,
          )
        end
      end
    end
  end
end
