# frozen_string_literal: true
require 'test_helper'
require 'project_types/extension/extension_test_helpers'
require 'base64'
require 'pathname'

module Extension
  module Features
    module Argo
      class CheckoutTest < MiniTest::Test
        include TestHelpers::FakeUI
        include ExtensionTestHelpers::Stubs::ArgoScript

        def setup
          super
          ShopifyCli::ProjectType.load_type(:extension)

          @argo = Features::Argo::Checkout.checkout_setup
        end

        def test_checkout_method_returns_an_argo_extension_with_the_checkout_post_purchase_template
          git_checkout_template = Checkout::GIT_CHECKOUT_TEMPLATE
          assert_equal(@argo.setup.git_template, git_checkout_template)
        end

        def test_checkout_setup_method_returns_an_argo_extension_with_the_checkout_renderer_package
          checkout_renderer_package = Checkout::CHECKOUT_RENDERER_PACKAGE
          assert_equal(@argo.renderer_package, checkout_renderer_package)
        end
      end
    end
  end
end
