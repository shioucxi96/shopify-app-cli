# frozen_string_literal: true
require 'test_helper'
require 'project_types/extension/extension_test_helpers'
require 'base64'
require 'pathname'

module Extension
  module Features
    module Argo
      class AdminTest < MiniTest::Test
        include TestHelpers::FakeUI
        include ExtensionTestHelpers::Stubs::ArgoScript

        def setup
          super
          ShopifyCli::ProjectType.load_type(:extension)

          @argo = Features::Argo::Admin.admin_setup
        end

        def test_setup_method_returns_an_argo_extension_with_the_subscription_management_template
          git_admin_template = Admin::GIT_ADMIN_TEMPLATE
          assert_equal(@argo.setup.git_template, git_admin_template)
        end

        def test_admin_setup_method_returns_an_argo_extension_with_the_admin_renderer_package
          admin_renderer_package = Admin::ADMIN_RENDERER_PACKAGE
          assert_equal(@argo.renderer_package, admin_renderer_package)
        end
      end
    end
  end
end
