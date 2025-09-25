class UpdateVocabularyStatusToEnglish < ActiveRecord::Migration[8.0]
  def up
    # Update German status values to English
    execute "UPDATE vocabularies SET status = 'open' WHERE status = 'offen'"
    execute "UPDATE vocabularies SET status = 'learning' WHERE status = 'am_lernen'"
    execute "UPDATE vocabularies SET status = 'learned' WHERE status = 'gelernt'"
  end

  def down
    # Revert English status values back to German
    execute "UPDATE vocabularies SET status = 'offen' WHERE status = 'open'"
    execute "UPDATE vocabularies SET status = 'am_lernen' WHERE status = 'learning'"
    execute "UPDATE vocabularies SET status = 'gelernt' WHERE status = 'learned'"
  end
end
