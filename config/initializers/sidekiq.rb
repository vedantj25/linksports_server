redis_url = ENV["REDIS_URL"] || ENV["REDIS_TLS_URL"] || ENV["UPSTASH_REDIS_URL"] || "redis://localhost:6379/0"
redis_namespace = ENV["SIDEKIQ_NAMESPACE"] || "sidekiq"

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, namespace: redis_namespace }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url, namespace: redis_namespace }
end
