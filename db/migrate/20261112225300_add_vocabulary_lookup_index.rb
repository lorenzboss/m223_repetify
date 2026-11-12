class AddVocabularyLookupIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :vocabularies, %i[user_id source_language status],
      name: "index_vocabularies_on_user_language_status"
  end
end
