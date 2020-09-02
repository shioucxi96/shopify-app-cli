# frozen_string_literal: true
require 'project_types/theme/test_helper'

module Theme
  module Commands
    class PullTest < MiniTest::Test
      include TestHelpers::FakeUI

      SHOPIFYCLI_FILE = <<~CLI
        ---
        project_type: theme
        organization_id: 0
      CLI

      def test_can_pull_theme
        FakeFS do
          context = ShopifyCli::Context.new
          Themekit.expects(:ensure_themekit_installed).with(context)
          Theme::Forms::Pull.expects(:ask)
            .with(context, [], {})
            .returns(Theme::Forms::Pull.new(context, [], { store: 'shop.myshopify.com',
                                                           password: 'boop',
                                                           themeid: '2468',
                                                           name: 'my_theme' }))

          Themekit.expects(:pull)
            .with(context, store: 'shop.myshopify.com', password: 'boop', themeid: '2468')
            .returns(true)
          context.expects(:done).with(context.message('theme.pull.pulled',
                                                      'my_theme',
                                                      'shop.myshopify.com',
                                                      File.join('', 'my_theme')))

          Theme::Commands::Pull.new(context).call([], 'pull')
          assert_equal SHOPIFYCLI_FILE, File.read(".shopify-cli.yml")
        end
      end

      # def test_aborts_if_invalid_credentials
      #   FakeFS do
      #     context = ShopifyCli::Context.new
      #     Themekit.expects(:ensure_themekit_installed).with(context)
      #     Theme::Forms::Pull.expects(:ask)
      #       .with(context, [], {})
      #       .returns(Theme::Forms::Pull.new(context, [], { store: 'shop.myshopify.com',
      #                                                      password: 'boop',
      #                                                      themeid: '1357' }))
      #
      #     Themekit.expects(:pull)
      #       .with(context, store: 'shop.myshopify.com', password: 'boop', themeid: '1357')
      #       .returns(false)
      #     context.expects(:abort).with(context.message('theme.pull.failed'))
      #   end
      # end
    end
  end
end
