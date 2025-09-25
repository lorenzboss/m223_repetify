class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def translate
    text = params[:text]
    source_lang = params[:source_lang].present? ? params[:source_lang] : nil
    target_lang = "de"

    if text.blank?
      render json: { error: "Text is required" }, status: :bad_request
      return
    end

    begin
      translation_result = TranslationService.translate(text, source_lang, target_lang)
      render json: {
        translated_text: translation_result[:translated_text],
        detected_language: translation_result[:detected_language],
        source_language: translation_result[:source_language]
      }
    rescue StandardError => e
      render json: { error: "Translation failed" }, status: :internal_server_error
    end
  end

  def save_vocabulary
    source_text = params[:source_text]
    target_text = params[:target_text]
    source_language = params[:source_language]

    if source_text.blank? || target_text.blank? || source_language.blank?
      render json: { error: "Alle Felder sind erforderlich" }, status: :bad_request
      return
    end

    begin
      # Check if vocabulary already exists for this user
      existing_vocabulary = current_user.vocabularies.find_by(
        source_text: source_text.strip,
        source_language: source_language
      )

      if existing_vocabulary
        render json: {
          success: false,
          message: "Diese Vokabel wurde bereits gespeichert"
        }, status: :unprocessable_entity
        return
      end

      # Create new vocabulary entry
      vocabulary = current_user.vocabularies.create!(
        source_text: source_text.strip,
        target_text: target_text.strip,
        source_language: source_language
      )

      render json: {
        success: true,
        message: "Vokabel erfolgreich gespeichert!",
        vocabulary_id: vocabulary.id
      }
    rescue StandardError => e
      render json: {
        success: false,
        error: "Fehler beim Speichern der Vokabel"
      }, status: :internal_server_error
    end
  end
end
