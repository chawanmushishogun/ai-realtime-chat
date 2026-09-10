Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("REDIS_URL", "redis://redis:6379/1"))

class Rack::Attack
  # 1) IP ごとの全体制限
  throttle("req/ip", limit: 100, period: 1.minute) { |req| req.ip }

  # 2) /messages POST をユーザー単位で
  throttle("messages/create/user", limit: 20, period: 1.minute) do |req|
    req.path == "/messages" && req.post? && req.session["user_id"].presence
  end

  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"] || {}
    retry_after = match_data[:period].to_i
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [{ error: "Too Many Requests" }.to_json]
    ]
  end
end
