# frozen_string_literal: true
require 'test_helper'
require 'project_types/extension/extension_test_helpers'

module Extension
  module Features
    class ArgoConfigTest < MiniTest::Test
      def setup
        super
        File.stubs(:exist?).returns(true)
        ShopifyCli::ProjectType.load_type(:extension)
      end

      def test_parses_and_symbolizes_yaml_hash
        value = {}
        another_value = 10
        yml = { "value": value, "another_value": another_value }
        YAML.stubs(:load_file).returns(yml)

        parsed_config = ArgoConfig.parse_yaml(@context)

        assert_equal(value, parsed_config[:value])
        assert_equal(another_value, parsed_config[:another_value])
      end

      def test_aborts_when_yaml_is_invalid
        Psych::SyntaxError.any_instance.stubs(:initialize)
        YAML.stubs(:load_file).raises(Psych::SyntaxError)

        assert_raises(ShopifyCli::Abort) { ArgoConfig.parse_yaml(@context) }
      end

      def test_aborts_when_yaml_is_not_a_hash
        YAML.stubs(:load_file).returns

        assert_raises(ShopifyCli::Abort) { ArgoConfig.parse_yaml(@context) }
      end

      def test_returns_empty_hash_when_file_not_found
        File.stubs(:exist?).returns(false)

        assert_equal({}, ArgoConfig.parse_yaml(@context))
      end
    end
  end
end