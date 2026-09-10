class RateLimiter
  def initialize(namespace:, limit:, period: 60)
    @ns = namespace
    @limit = limit
    @period = period
  end

  def allowed?(key)
    r = Redis.new(url: ENV.fetch("REDIS_URL", "redis://redis:6379/1"))
    bucket = (Time.now.to_i / @period)
    k = "rl:#{@ns}:#{key}:#{bucket}"
    count = r.incr(k)
    r.expire(k, @period + 1) if count == 1
    count <= @limit
  end
end
