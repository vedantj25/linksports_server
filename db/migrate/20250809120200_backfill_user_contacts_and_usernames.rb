class BackfillUserContactsAndUsernames < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    say_with_time "Backfilling user_contacts and usernames" do
      User.reset_column_information

      reserved = reserved_usernames
      existing = Set.new

      User.find_each do |user|
        # Backfill email contact
        if user.email.present?
          value = user.email.downcase
          execute <<~SQL
            INSERT INTO user_contacts (user_id, contact_type, value, verified, created_at, updated_at)
            VALUES (#{user.id}, 0, #{ActiveRecord::Base.connection.quote(value)}, #{user.verified ? 'TRUE' : 'FALSE'}, NOW(), NOW())
            ON CONFLICT DO NOTHING;
          SQL
        end

        # Backfill phone contact
        if user.phone.present?
          execute <<~SQL
            INSERT INTO user_contacts (user_id, contact_type, value, verified, created_at, updated_at)
            VALUES (#{user.id}, 1, #{ActiveRecord::Base.connection.quote(user.phone)}, #{user.verified ? 'TRUE' : 'FALSE'}, NOW(), NOW())
            ON CONFLICT DO NOTHING;
          SQL
        end

        # Generate temporary username if missing or invalid
        base = (user.first_name.presence || 'user').to_s.downcase.gsub(/[^a-z0-9\-_]/, '')
        base = 'user' if base.blank?
        candidate = base[0, 10]
        suffix = 1
        # Ensure constraints: 4..12 and not reserved
        candidate = candidate.ljust(4, '0')

        loop do
          uname = suffix == 1 ? candidate : "#{candidate[0, (12 - suffix.to_s.length - 1)]}-#{suffix}"
          next_suffix = suffix + 1
          downcased = uname.downcase
          conflict = existing.include?(downcased) || reserved.include?(downcased) || User.where('LOWER(username) = ?', downcased).exists?
          if !conflict && downcased.length.between?(4, 12)
            execute <<~SQL
              UPDATE users SET username = #{ActiveRecord::Base.connection.quote(downcased)} WHERE id = #{user.id};
            SQL
            existing.add(downcased)
            break
          end
          suffix = next_suffix
        end
      end
    end
  end

  def down
    # No-op for data backfill
  end

  private

  def reserved_usernames
    %w[admin root support api profile profiles user users system help auth login signup register settings me about contact terms privacy].to_set
  end
end
