class VocabulariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vocabulary, only: [:update, :destroy]

  # Supported languages - ignore vocabularies with other languages
  SUPPORTED_LANGUAGES = %w[en fr es pt it].freeze

  def index
    # Get all vocabularies for current user, grouped by language
    # Only include supported languages
    @vocabularies_by_language = current_user.vocabularies
      .where(source_language: SUPPORTED_LANGUAGES)
      .includes(:user)
      .order(:source_language, :created_at)
      .group_by(&:source_language)

    # Language display names
    @language_names = {
      "en" => "Englisch",
      "fr" => "Französisch",
      "es" => "Spanisch",
      "pt" => "Portugiesisch",
      "it" => "Italienisch"
    }
  end

  def update
    if @vocabulary.update(vocabulary_params)
      redirect_to vocabularies_path, notice: "Vokabel wurde erfolgreich aktualisiert."
    else
      redirect_to vocabularies_path, alert: "Fehler beim Aktualisieren der Vokabel."
    end
  end

  def destroy
    @vocabulary.destroy
    redirect_to vocabularies_path, notice: "Vokabel wurde erfolgreich gelöscht."
  end

  private

  def set_vocabulary
    @vocabulary = current_user.vocabularies.find(params[:id])
  end

  def vocabulary_params
    params.require(:vocabulary).permit(:source_text, :target_text, :status)
  end
end
