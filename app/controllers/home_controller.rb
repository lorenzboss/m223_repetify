class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def translate
    text = params[:text]
    source_lang = params[:source_lang].present? ? params[:source_lang] : nil
    target_lang = 'de'

    if text.blank?
      render json: { error: 'Text is required' }, status: :bad_request
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
      render json: { error: 'Translation failed' }, status: :internal_server_error
    end
  end
end
