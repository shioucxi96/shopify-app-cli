# frozen_string_literal: true
require 'base64'

module Extension
  module Models
    module Types
      class CheckoutPostPurchase < Models::Type
        IDENTIFIER = 'CHECKOUT_POST_PURCHASE'
        CONFIG_FILE_NAME = 'extension.config.yml'
        ALLOWED_CONFIG_KEYS = [:metafields]

        def create(directory_name, context)
          Features::Argo.checkout.create(directory_name, IDENTIFIER, context)
        end

        def config(context)
          {
            **Features::Argo.checkout.config(context),
            **extension_config(context)
          }
        end

        private

        def extension_config(context)
          config = load_extension_config_yaml(context)

          unless config.is_a?(Hash)
            raise ShopifyCli::Abort, Context.message('core.project.error.cli_yaml.not_hash')
          end

          config
            .transform_keys(&:to_sym)
            .slice(*ALLOWED_CONFIG_KEYS)
        end

        def load_extension_config_yaml(context)
          require 'yaml' # takes 20ms, so deferred as late as possible.
          begin
            YAML.load_file(File.join(context.root, CONFIG_FILE_NAME))
          rescue Psych::SyntaxError => e
            # TODO: change translation
            raise(ShopifyCli::Abort, Context.message('core.project.error.cli_yaml.invalid', relative_path, e.message))
          rescue Errno::ENOENT
            nil
          end
        end

      end
    end
  end
end
