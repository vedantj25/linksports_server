redis_url = ENV.fetch("REDIS_URL")
redis_namespace = ENV.fetch("SIDEKIQ_NAMESPACE", "sidekiq")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, namespace: redis_namespace }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url, namespace: redis_namespace }
end
