# frozen_string_literal: true

namespace :db do
  namespace :bootstrap do
    desc "Conditionally load schemas for cache/cable/queue if missing (safe for production)"
    task aux: :environment do
      require "active_record"
      roles = {
        cache: "solid_cache_entries",
        cable: "solid_cable_messages",
        queue: "solid_queue_jobs"
      }

      roles.each do |role, sentinel_table|
        puts "[db:bootstrap:aux] Checking #{role} database for #{sentinel_table}..."

        # Ensure database exists
        begin
          Rake::Task["db:create:#{role}"].invoke
        rescue => e
          # Database likely already exists; ignore
          Rake::Task["db:create:#{role}"].reenable
        end

        exists = false
        begin
          ActiveRecord::Base.connected_to(database: role) do
            exists = ActiveRecord::Base.connection.data_source_exists?(sentinel_table)
          end
        rescue => e
          puts "[db:bootstrap:aux] Warning: could not check #{role} database: #{e.class}: #{e.message}"
        end

        if exists
          puts "[db:bootstrap:aux] #{role} already initialized; skipping schema load."
        else
          puts "[db:bootstrap:aux] #{role} not initialized; loading schema..."
          begin
            ENV["DISABLE_DATABASE_ENVIRONMENT_CHECK"] = "1"
            Rake::Task["db:schema:load:#{role}"].invoke
          ensure
            Rake::Task["db:schema:load:#{role}"].reenable
          end
          puts "[db:bootstrap:aux] #{role} schema loaded."
        end

        # Reenable create task for future runs
        Rake::Task["db:create:#{role}"].reenable
      end

      puts "[db:bootstrap:aux] Done."
    end
  end
end
