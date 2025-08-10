## Background jobs and realtime

This app uses Sidekiq and Redis for background jobs and Action Cable.

Set these environment variables (examples):

```
REDIS_URL=redis://localhost:6379/0
SIDEKIQ_NAMESPACE=sidekiq
SIDEKIQ_CONCURRENCY=5
```

Run worker locally:

```
bundle exec sidekiq -C config/sidekiq.yml
```

# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
