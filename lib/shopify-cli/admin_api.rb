require 'shopify_cli'

module ShopifyCli
  ##
  # ShopifyCli::AdminAPI wraps our graphql functionality with authentication so that
  # these concerns are taken care of.
  #
  class AdminAPI < API
    autoload :PopulateResourceCommand, 'shopify-cli/admin_api/populate_resource_command'
    autoload :Schema, 'shopify-cli/admin_api/schema'

    class << self
      ##
      # issues a graphql query or mutation to the Shopify Admin API. It loads a graphql
      # query from a file so that you do not need to use large unwieldy query strings.
      #
      # #### Parameters
      # - `ctx`: running context from your command
      # - `query_name`: name of the query you want to use, loaded from the `lib/graphql` directory.
      # - `api_version`: an api version string to specify version. If no version is supplied then unstable will be used
      # - `shop`: shop domain string for which shop that you are calling the admin
      #   API on. If not supplied, then it will be fetched from the `.env` file
      # - `**variable`: a hash of variables to be supplied to the query ro mutation
      #
      # #### Raises
      #
      # * http 404 will raise a ShopifyCli::API::APIRequestNotFoundError
      # * http 400..499 will raise a ShopifyCli::API::APIRequestClientError
      # * http 500..599 will raise a ShopifyCli::API::APIRequestServerError
      # * All other codes will raise ShopifyCli::API::APIRequestUnexpectedError
      #
      # #### Returns
      #
      # * `resp` - graphql response data hash. This can be a different shape for every query.
      #
      # #### Example
      #
      #   ShopifyCli::AdminAPI.query(@ctx, 'all_organizations')
      #
      def query(ctx, query_name, shop:, api_version: nil, **variables)
        authenticated_req(ctx, shop) do
          api_client(ctx, api_version, shop).query(query_name, variables: variables)
        end
      end

      ##
      #
      #
      #
      # #### Parameters
      # - `ctx`: running context from your command
      # - `shop`: shop domain string for shop whose admin you are calling
      # - `path`: path string for specific JSON that you are requesting
      # - `body`: data string for corresponding REST request types
      # - `method`: REST request string for the type of request; if nil, will perform GET request
      # - `api_version`: API version string to specify version; if nil, latest will be used
      # - `token`: shop password string for authentication to shop
      #
      # #### Raises
      #
      # * http 404 will raise a ShopifyCli::API::APIRequestNotFoundError
      # * http 400..499 will raise a ShopifyCli::API::APIRequestClientError
      # * http 500..599 will raise a ShopifyCli::API::APIRequestServerError
      # * All other codes will raise ShopifyCli::API::APIRequestUnexpectedError
      #
      # #### Returns
      #
      # * `resp` - JSON response array
      #
      # #### Example
      #
      #   ShopifyCli::AdminAPI.rest_request(@ctx,
      #                                     shop: 'shop.myshopify.com',
      #                                     path: 'data.json',
      #                                     token: 'password')
      #
      def rest_request(ctx, shop:, path:, body: nil, method: "GET", api_version: nil, token: nil)
        ShopifyCli::DB.set(admin_access_token: token) unless token.nil?
        url = URI::HTTPS.build(host: shop, path: "/admin/api/#{fetch_api_version(ctx, api_version, shop)}/#{path}")
        resp = api_client(ctx, api_version, shop, path: path).request(url: url.to_s, body: body, method: method)
        ShopifyCli::DB.set(admin_access_token: nil) unless token.nil?
        resp
      end

      private

      def authenticated_req(ctx, shop)
        yield
      rescue API::APIRequestUnauthorizedError
        authenticate(ctx, shop)
        retry
      end

      def authenticate(ctx, shop)
        env = Project.current.env
        ShopifyCli::OAuth.new(
          ctx: ctx,
          service: 'admin',
          client_id: env.api_key,
          secret: env.secret,
          scopes: env.scopes,
          token_path: "/access_token",
          options: { 'grant_options[]' => 'per user' },
        ).authenticate("https://#{shop}/admin/oauth")
      end

      def api_client(ctx, api_version, shop, path: 'graphql.json')
        new(
          ctx: ctx,
          auth_header: 'X-Shopify-Access-Token',
          token: admin_access_token(ctx, shop),
          url: "https://#{shop}/admin/api/#{fetch_api_version(ctx, api_version, shop)}/#{path}",
        )
      end

      def admin_access_token(ctx, shop)
        ShopifyCli::DB.get(:admin_access_token) do
          authenticate(ctx, shop)
          ShopifyCli::DB.get(:admin_access_token)
        end
      end

      def fetch_api_version(ctx, api_version, shop)
        return api_version unless api_version.nil?
        client = new(
          ctx: ctx,
          auth_header: 'X-Shopify-Access-Token',
          token: admin_access_token(ctx, shop),
          url: "https://#{shop}/admin/api/unstable/graphql.json",
        )
        versions = client.query('api_versions')['data']['publicApiVersions']
        latest = versions.find { |version| version['displayName'].include?('Latest') }
        latest['handle']
      end
    end
  end
end
