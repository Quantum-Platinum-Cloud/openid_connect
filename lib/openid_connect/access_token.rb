module OpenIDConnect
  class AccessToken < Rack::OAuth2::AccessToken::Bearer
    attr_required :client
    attr_optional :id_token

    def initialize(attributes = {})
      super
      @token_type = :bearer
    end

    def userinfo!(schema = :openid)
      hash = resource_request do
        get client.userinfo_uri, schema: schema
      end
      ResponseObject::UserInfo::OpenID.new hash
    end
    alias_method :user_info!, :userinfo!

    private

    def resource_request
      res = yield
      case res.status
      when 200
        JSON.parse res.body, symbolize_names: true
      when 400
        raise BadRequest.new('API Access Faild', res)
      when 401
        raise Unauthorized.new('Access Token Invalid or Expired', res)
      when 403
        raise Forbidden.new('Insufficient Scope', res)
      else
        raise HttpError.new(res.status, 'Unknown HttpError', res)
      end
    end
  end
end