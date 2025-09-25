class UpdateVocabularyLanguageToLowercase < ActiveRecord::Migration[8.0]
  def up
    # Convert all source_language values to lowercase
    execute "UPDATE vocabularies SET source_language = LOWER(source_language)"
  end

  def down
    # Convert all source_language values to uppercase (reverse operation)
    execute "UPDATE vocabularies SET source_language = UPPER(source_language)"
  end
end
