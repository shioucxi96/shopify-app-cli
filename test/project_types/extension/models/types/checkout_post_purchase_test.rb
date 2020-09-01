# frozen_string_literal: true
require 'test_helper'

module Extension
  module Models
    module Types
      class CheckoutPostPurchaseTest < MiniTest::Test
        def setup
          super
          YAML.stubs(:load_file).returns({})
          ShopifyCli::ProjectType.load_type(:extension)
          Features::Argo.checkout.stubs(:config).returns({})
          @checkout_post_purchase = Models::Type.load_type(CheckoutPostPurchase::IDENTIFIER)
        end

        def test_create_uses_standard_argo_create_implementation
          directory_name = 'checkout_post_purchase'

          Features::Argo.checkout
            .expects(:create)
            .with(directory_name, CheckoutPostPurchase::IDENTIFIER, @context)
            .once

          @checkout_post_purchase.create(directory_name, @context)
        end

        def test_config_uses_standard_argo_config_implementation
          Features::Argo.checkout.expects(:config).with(@context).once.returns({})
          @checkout_post_purchase.config(@context)
        end

        def test_config_merges_with_standard_argo_config_implementation
          script_content ="alert(true)";
          metafields = [{key: 'a-key'}]

          initial_config = {script_content: script_content}
          yaml_config = {"metafields": metafields}
          YAML.stubs(:load_file).returns(yaml_config)

          Features::Argo.checkout.expects(:config).with(@context).once.returns(initial_config)

          config = @checkout_post_purchase.config(@context)

          assert_equal(metafields, config[:metafields])
          assert_equal(script_content, config[:script_content])
        end

        def test_config_filters_keys
          YAML.stubs(:load_file).returns({"illegal_one": {}, "metafields": [], "illegal_two": []})

          config = @checkout_post_purchase.config(@context)

          assert_nil(config[:illegal_one])
          assert_nil(config[:illegal_two])
          refute_nil(config[:metafields])
        end

        def test_config_aborts_when_yaml_is_invalid
          Psych::SyntaxError.any_instance.stubs(:initialize)
          YAML.stubs(:load_file).raises(Psych::SyntaxError)

          assert_raises(ShopifyCli::Abort) { @checkout_post_purchase.config(@context) }
        end

        def test_config_aborts_when_yaml_is_not_a_hash
          YAML.stubs(:load_file).returns()

          assert_raises(ShopifyCli::Abort) { @checkout_post_purchase.config(@context) }
        end
      end
    end
  end
end
