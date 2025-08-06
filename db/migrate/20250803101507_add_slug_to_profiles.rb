class AddSlugToProfiles < ActiveRecord::Migration[8.0]
  def up
    add_column :profiles, :slug, :string

    # Populate existing profiles with slugs
    execute <<-SQL
      UPDATE profiles#{' '}
      SET slug = LOWER(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            COALESCE(display_name, CONCAT(first_name, ' ', COALESCE(last_name, ''))),
            '[^a-zA-Z0-9\s]', '', 'g'
          ),
          '\s+', '-', 'g'
        )
      )
    SQL

    # Handle duplicates by appending profile id
    execute <<-SQL
      UPDATE profiles#{' '}
      SET slug = CONCAT(slug, '-', id)
      WHERE id IN (
        SELECT id FROM (
          SELECT id, ROW_NUMBER() OVER (PARTITION BY slug ORDER BY id) as rn
          FROM profiles
        ) t WHERE rn > 1
      )
    SQL

    add_index :profiles, :slug, unique: true
  end

  def down
    remove_index :profiles, :slug
    remove_column :profiles, :slug
  end
end
