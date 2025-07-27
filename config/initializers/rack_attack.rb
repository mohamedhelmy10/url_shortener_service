class Rack::Attack
  # Configure cache store based on environment
  cache_store = begin
    redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'
    redis_client = Redis.new(url: redis_url)
    redis_client.ping
    puts "✅ Redis connection successful!"
    ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)
  rescue => e
    puts "❌ Redis connection failed: #{e.message}"
    Rails.logger.warn "Redis not available, using memory store: #{e.message}"
    ActiveSupport::Cache::MemoryStore.new
  end

  Rack::Attack.cache.store = cache_store

  throttle("encode by ip", limit: 2, period: 1.minute) do |request|
    if request.path == "/encode" && request.post?
      request.ip
    end
  end

  throttle("decode by ip", limit: 5, period: 1.minute) do |request|
    if request.path == "/decode" && request.get?
      request.ip
    end
  end

  throttled_responder = lambda do |env|
    rack_env = env.is_a?(Rack::Attack::Request) ? env.env : env
    match_data = rack_env["rack.attack.match_data"] || {}
    retry_after = match_data[:period] || 60

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ {
        error: "Rate limit exceeded",
        message: "Too many requests. Please try again later.",
        retry_after: "#{retry_after} seconds"
      }.to_json ]
    ]
  end

  self.throttled_responder = throttled_responder

  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    if req.env["rack.attack.match_type"] == :throttle
      Rails.logger.warn "Rate limit exceeded for IP: #{req.ip}, Path: #{req.path}"
    end
  end
end
