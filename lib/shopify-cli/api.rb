require 'shopify_cli'
require 'net/http'

module ShopifyCli
  class API
    include SmartProperties

    property! :ctx, accepts: ShopifyCli::Context
    property! :token, accepts: String
    property :auth_header, accepts: String
    property! :url, accepts: String

    class APIRequestError < StandardError; end
    class APIRequestNotFoundError < APIRequestError; end
    class APIRequestClientError < APIRequestError; end
    class APIRequestUnauthorizedError < APIRequestClientError; end
    class APIRequestUnexpectedError < APIRequestError; end
    class APIRequestRetriableError < APIRequestError; end
    class APIRequestServerError < APIRequestRetriableError; end
    class APIRequestThrottledError < APIRequestRetriableError; end

    def self.gid_to_id(gid)
      gid.split('/').last
    end

    def query(query_name, variables: {})
      _, resp = request(
        body: JSON.dump(query: load_query(query_name).tr("\n", ""), variables: variables),
        url: url,
      )
      ctx.debug(resp)
      resp
    rescue API::APIRequestServerError, API::APIRequestUnexpectedError
      ctx.puts(ctx.message('core.api.error.internal_server_error'))
    end

    def request(url:, body: nil, headers: {}, method: "POST")
      CLI::Kit::Util.begin do
        uri = URI.parse(url)
        unless uri.is_a?(URI::HTTP)
          ctx.abort("Invalid URL: #{url}")
        end
        http = ::Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = if method == "POST"
          ::Net::HTTP::Post.new(uri.request_uri)
        elsif method == "GET"
          ::Net::HTTP::Get.new(uri.request_uri)
        end
        headers = headers.merge(default_headers)
        req.body = body unless body.nil?
        req['Content-Type'] = 'application/json'
        headers.each { |header, value| req[header] = value }
        response = http.request(req)

        case response.code.to_i
        when 200..399
          [response.code.to_i, JSON.parse(response.body)]
        when 401
          raise APIRequestUnauthorizedError, "#{response.code}\n#{response.body}"
        when 404
          raise APIRequestNotFoundError, "#{response.code}\n#{response.body}"
        when 429
          raise APIRequestThrottledError, "#{response.code}\n#{response.body}"
        when 400..499
          raise APIRequestClientError, "#{response.code}\n#{response.body}"
        when 500..599
          raise APIRequestServerError, "#{response.code}\n#{response.body}"
        else
          raise APIRequestUnexpectedError, "#{response.code}\n#{response.body}"
        end
      end.retry_after(APIRequestRetriableError, retries: 3) do |e|
        sleep(1) if e.is_a?(APIRequestThrottledError)
      end
    end

    protected

    def load_query(name)
      project_type = ShopifyCli::Project.current_project_type
      project_file_path = File.join(
        ShopifyCli::ROOT, 'lib', 'project_types', project_type.to_s, 'graphql', "#{name}.graphql"
      )
      if !project_type.nil? && File.exist?(project_file_path)
        File.read(project_file_path)
      else
        File.read(File.join(ShopifyCli::ROOT, 'lib', 'graphql', "#{name}.graphql"))
      end
    end

    private

    def current_sha
      @current_sha ||= Git.sha(dir: ShopifyCli::ROOT)
    end

    def default_headers
      {
        'User-Agent' => "Shopify App CLI #{ShopifyCli::VERSION} #{current_sha} | #{ctx.uname}",
      }.merge(auth_headers(token))
    end

    def auth_headers(token)
      raise NotImplementedError if auth_header.nil?
      { auth_header => token }
    end
  end
end
