# frozen_string_literal: true
require 'test_helper'
require 'project_types/extension/extension_test_helpers'
require 'base64'
require 'pathname'

module Extension
  module Features
    module Argo
      class BaseTest < MiniTest::Test
        include TestHelpers::FakeUI
        include ExtensionTestHelpers::Stubs::ArgoScript

        def setup
          super
          ShopifyCli::ProjectType.load_type(:extension)

          @argo_admin = Features::Argo::Admin.admin_setup
          @argo_checkout = Features::Argo::Checkout.checkout_setup
          @error = ''
          @version_tag_regexp = /^([0-9]\d*)\.([0-9]\d*)\.([0-9]\d*)$/
        end

        def test_config_aborts_with_error_if_script_file_doesnt_exist
          @argo_admin.stubs(:extract_argo_renderer_version).returns('0.0.1')
          error = assert_raises ShopifyCli::Abort do
            @argo_admin.config(@context)
          end

          assert error.message.include?(@context.message('features.argo.missing_file_error'))
        end

        def test_config_aborts_with_error_if_script_serialization_fails
          @argo_admin.stubs(:extract_argo_renderer_version).returns('0.0.1')
          File.stubs(:exist?).returns(true)
          Base64.stubs(:strict_encode64).raises(IOError)

          error = assert_raises(ShopifyCli::Abort) { @argo_admin.config(@context) }
          assert error.message.include?(@context.message('features.argo.script_prepare_error'))
        end

        def test_config_aborts_with_error_if_file_read_fails
          @argo_admin.stubs(:extract_argo_renderer_version).returns('0.0.1')
          File.stubs(:exist?).returns(true)
          File.any_instance.stubs(:read).raises(IOError)

          error = assert_raises(ShopifyCli::Abort) { @argo_admin.config(@context) }
          assert error.message.include?(@context.message('features.argo.script_prepare_error'))
        end

        def test_config_encodes_script_into_context_if_it_exists
          with_stubbed_script(@context, Argo::Base::SCRIPT_PATH) do
            @argo_admin.stubs(:extract_argo_renderer_version).returns('0.0.1')
            config = @argo_admin.config(@context)

            assert_includes config.keys, :serialized_script
            assert_equal Base64.strict_encode64(TEMPLATE_SCRIPT.chomp), config[:serialized_script]
          end
        end

        def test_config_aborts_with_error_if_extracting_the_version_of_renderer_package_fails
          fake_script = Base64.strict_encode64('var fake={}')
          Base64.stubs(:strict_encode64).returns(fake_script)
          result = '{}'
          error_message = 'npm ERR! missing: @shopify/argo-admin@latest, required by fake-app-extension-template@0.1.0'
          with_stubbed_script(@context, Argo::Base::SCRIPT_PATH) do
            ShopifyCli::JsSystem.any_instance.stubs(:call).returns([result, error_message, mock(success?: false)])
            error = assert_raises(ShopifyCli::Abort) { @argo_admin.config(@context) }
            assert error
              .message
              .include?(@context.message('features.argo.dependencies.argo_renderer_package_error', error_message))
          end
        end

        def test_version_renderer_returns_argo_admin_renderer_package_version_with_npm_package_manager
          result = '{
               "name": "fake-extension-template",
               "version": "0.1.0",
               "dependencies": {
                 "@shopify/argo-admin": {
                   "version": "0.4.0",
                   "from": "@shopify/argo-admin@latest",
                   "resolved": "https://test_example.com.tgz"
                 }
                }
              }'
          with_stubbed_script(@context, Features::Argo::Base::SCRIPT_PATH) do
            ShopifyCli::JsSystem.any_instance.stubs(:call).returns([result, @error, mock(success?: true)])
            ShopifyCli::JsSystem.any_instance.stubs(:package_manager).returns('npm')
            config = @argo_admin.config(@context)

            assert_includes(config.keys, :renderer_version)
            assert_match(@version_tag_regexp, config[:renderer_version])
          end
        end

        def test_version_renderer_returns_argo_admin_renderer_package_version_with_yarn_package_manager
          result = 'yarn list v1.22.5
          ├─ @shopify/argo-admin-cli@0.1.2
          ├─ @shopify/argo-admin-host@0.4.1
          ├─ @shopify/argo-admin-react@0.4.1
          └─ @shopify/argo-admin@0.4.1
          ✨  Done in 0.44s.'
          with_stubbed_script(@context, Features::Argo::Base::SCRIPT_PATH) do
            ShopifyCli::JsSystem.any_instance.stubs(:call).returns([result, @error, mock(success?: true)])
            ShopifyCli::JsSystem.any_instance.stubs(:package_manager).returns('yarn')
            config = @argo_admin.config(@context)
            assert_includes(config.keys, :renderer_version)
            assert_match(@version_tag_regexp, config[:renderer_version])
          end
        end

        def test_version_renderer_returns_argo_checkout_renderer_package_version_with_yarn_package_manager
          result = 'yarn list v1.22.4
          ├─ @shopify/argo-checkout-react@0.3.4
          └─ @shopify/argo-checkout@0.3.4
          ✨  Done in 0.42s.'
          with_stubbed_script(@context, Features::Argo::Base::SCRIPT_PATH) do
            ShopifyCli::JsSystem.any_instance.stubs(:call).returns([result, @error, mock(success?: true)])
            ShopifyCli::JsSystem.any_instance.stubs(:package_manager).returns('yarn')
            config = @argo_checkout.config(@context)
            assert_includes(config.keys, :renderer_version)
            assert_match(@version_tag_regexp, config[:renderer_version])
          end
        end

        def test_version_renderer_returns_argo_checkout_renderer_package_version_with_npm_package_manager
          result = '{
            "name": "argo-checkout-template",
            "version": "0.1.0",
            "dependencies": {
              "@shopify/argo-checkout": {
                "version": "0.3.4"
              },
              "@shopify/argo-checkout-react": {
                "version": "0.3.4"
              }
            }
          }'
          with_stubbed_script(@context, Features::Argo::Base::SCRIPT_PATH) do
            ShopifyCli::JsSystem.any_instance.stubs(:call).returns([result, @error, mock(success?: true)])
            ShopifyCli::JsSystem.any_instance.stubs(:package_manager).returns('npm')
            config = @argo_checkout.config(@context)

            assert_includes(config.keys, :renderer_version)
            assert_match(@version_tag_regexp, config[:renderer_version])
          end
        end

        def test_returns_error_when_no_version_found
          fake_script = Base64.strict_encode64('var fake={}')
          Base64.stubs(:strict_encode64).returns(fake_script)
          result = '{}'
          with_stubbed_script(@context, Argo::Base::SCRIPT_PATH) do
            ShopifyCli::JsSystem.any_instance.stubs(:call).returns([result, @error, mock(success?: true)])
            ShopifyCli::JsSystem.any_instance.stubs(:package_manager).returns('npm')
            Argo::Base.stubs(:extract_version_with_npm).returns(nil)

            error_message = 'The renderer package version is not a valid SemVer Version (http://semver.org)'
            error = assert_raises(ShopifyCli::Abort) { @argo_admin.config(@context) }
            assert error
              .message
              .include?(@context
                .message('features.argo.dependencies.argo_renderer_package_invalid_version_error', error_message))
          end
        end
      end
    end
  end
end
