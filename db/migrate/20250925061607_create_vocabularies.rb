class CreateVocabularies < ActiveRecord::Migration[8.0]
  def change
    create_table :vocabularies do |t|
      t.references :user, null: false, foreign_key: true
      t.string :source_text
      t.string :target_text
      t.string :source_language
      t.string :status

      t.timestamps
    end
  end
end
