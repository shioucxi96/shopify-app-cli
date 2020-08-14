# frozen_string_literal: true
require 'base64'
require 'shopify_cli'
require 'semantic/semantic'

module Extension
  module Features
    module Argo
      class Base
        include SmartProperties

        NPM_LIST_COMMAND = %w(list).freeze
        YARN_LIST_COMMAND = %w(list --pattern).freeze
        NPM_LIST_PARAMETERS = %w(--json --prod=true --depth=0).freeze
        YARN_LIST_PARAMETERS = %w(--depth=0).freeze

        SCRIPT_PATH = %w(build main.js).freeze

        property! :setup, accepts: Features::ArgoSetup
        property! :renderer_package, accepts: String

        def create(directory_name, identifier, context)
          setup.call(directory_name, identifier, context)
        end

        def config(context)
          filepath = File.join(context.root, SCRIPT_PATH)
          context.abort(context.message('features.argo.missing_file_error')) unless File.exist?(filepath)
          begin
            {
              renderer_version: extract_argo_renderer_version(context),
              serialized_script: Base64.strict_encode64(File.open(filepath).read.chomp),
            }
          rescue StandardError
            context.abort(context.message('features.argo.script_prepare_error'))
          end
        end

        private

        def extract_argo_renderer_version(context)
          renderer_package = self.renderer_package
          js_system = ShopifyCli::JsSystem.new(ctx: context)
          installed_package_manager = js_system.package_manager
          result, error, stat = js_system.call(
            yarn: YARN_LIST_COMMAND + [renderer_package] + YARN_LIST_PARAMETERS,
            npm: NPM_LIST_COMMAND + [renderer_package] + NPM_LIST_PARAMETERS,
            with_capture: true
          )
          context.abort(
            context.message('features.argo.dependencies.argo_renderer_package_error', error)
          ) unless stat.success?

          found_version = if installed_package_manager == 'yarn'
            extract_version_with_yarn(result)
          else
            extract_version_with_npm(result)
          end
          ::Semantic::Version.new(found_version).to_s
        rescue ArgumentError
          context.abort(
            context.message('features.argo.dependencies.argo_renderer_package_invalid_version_error')
          )
        end

        def extract_version_with_yarn(result)
          packages = result.to_json.split('\n')
          match = packages.find do |package|
            package.match(/#{renderer_package}@/)
          end
          match.split('@')[2]
        end

        def extract_version_with_npm(result)
          hash_contents = JSON.parse(result)
          hash_contents.dig("dependencies", renderer_package, "version")
        end
      end
    end
  end
end
