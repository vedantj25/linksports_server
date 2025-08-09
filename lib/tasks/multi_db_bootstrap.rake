# frozen_string_literal: true

namespace :db do
  namespace :bootstrap do
    desc "Conditionally load schemas for cache/cable/queue if missing (safe for production)"
    task aux: :environment do
      require "active_record"
      required_tables_by_role = {
        cache: [
          "solid_cache_entries"
        ],
        cable: [
          "solid_cable_messages"
        ],
        queue: [
          "solid_queue_jobs",
          "solid_queue_ready_executions",
          "solid_queue_claimed_executions",
          "solid_queue_failed_executions",
          "solid_queue_blocked_executions",
          "solid_queue_pauses",
          "solid_queue_processes",
          "solid_queue_recurring_tasks",
          "solid_queue_recurring_executions",
          "solid_queue_scheduled_executions",
          "solid_queue_semaphores"
        ]
      }

      required_tables_by_role.each do |role, required_tables|
        puts "[db:bootstrap:aux] Checking #{role} database for required Solid tables..."

        # Ensure database exists
        begin
          Rake::Task["db:create:#{role}"].invoke
        rescue => e
          # Database likely already exists; ignore
          Rake::Task["db:create:#{role}"].reenable
        end

        missing = []
        begin
          ActiveRecord::Base.connected_to(database: role) do
            required_tables.each do |table|
              exists = ActiveRecord::Base.connection.data_source_exists?(table)
              missing << table unless exists
            end
          end
        rescue => e
          puts "[db:bootstrap:aux] Warning: could not check #{role} database: #{e.class}: #{e.message}"
        end

        if missing.empty?
          puts "[db:bootstrap:aux] #{role} already initialized; skipping schema load."
        else
          puts "[db:bootstrap:aux] #{role} missing tables: #{missing.join(', ')}; loading schema..."
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
