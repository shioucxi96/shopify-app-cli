# frozen_string_literal: true

module Extension
  module Features
    class ArgoConfig
      CONFIG_FILE_NAME = 'extension.config.yml'

      def self.parse_yaml(context)
        file_name = File.join(context.root, CONFIG_FILE_NAME)

        return {} unless File.exist?(file_name)

        require 'yaml' # takes 20ms, so deferred as late as possible.
        begin
          config = YAML.load_file(file_name)

          unless config.is_a?(Hash)
            raise ShopifyCli::Abort, ShopifyCli::Context.message('core.yaml.error.not_hash', CONFIG_FILE_NAME)
          end

          config.transform_keys(&:to_sym)
        rescue Psych::SyntaxError => e
          raise(
            ShopifyCli::Abort,
            ShopifyCli::Context.message('core.yaml.error.invalid', CONFIG_FILE_NAME, e.message)
          )
        end
      end
    end
  end
end
