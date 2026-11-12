class VocabulariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vocabulary, only: [:update, :destroy]

  # Supported languages - ignore vocabularies with other languages
  SUPPORTED_LANGUAGES = %w[en fr es pt it].freeze

  # Language display names mapping
  LANGUAGE_NAMES = {
    "en" => "Englisch",
    "fr" => "Französisch",
    "es" => "Spanisch",
    "pt" => "Portugiesisch",
    "it" => "Italienisch"
  }.freeze

  def index
    # Get all vocabularies for current user, grouped by language
    # Only include supported languages
    all_vocabularies = current_user.vocabularies
      .where(source_language: SUPPORTED_LANGUAGES)
      .order(
        :source_language,
        Arel.sql("CASE status WHEN 'open' THEN 1 WHEN 'learning' THEN 2 WHEN 'learned' THEN 3 ELSE 4 END"),
        updated_at: :desc
      )

    @vocabularies_by_language = all_vocabularies.group_by(&:source_language)

    # Language display names
    @language_names = LANGUAGE_NAMES
  end

  def learn
    # Overview of learning progress by language
    @language_names = LANGUAGE_NAMES

    counts = current_user.vocabularies
      .where(source_language: SUPPORTED_LANGUAGES)
      .group(:source_language, :status)
      .count

    @vocabularies_by_language = counts.each_with_object({}) do |((language, status), count), result|
      result[language] ||= { total: 0, open: 0, learning: 0, learned: 0, to_learn: 0 }
      result[language][:total] += count
      result[language][status.to_sym] = count
      result[language][:to_learn] += count if %w[open learning].include?(status)
    end
  end

  def learn_language
    @language = params[:language]
    redirect_to learn_vocabularies_path, alert: "Ungültige Sprache." unless SUPPORTED_LANGUAGES.include?(@language)

    @language_name = LANGUAGE_NAMES[@language]

    # Get vocabularies to learn (open and learning status only)
    @vocabularies = current_user.vocabularies
      .where(source_language: @language, status: %w[open learning])
      .order(Arel.sql("RANDOM()")) # Use Arel.sql for PostgreSQL RANDOM()
      .limit(20) # Limit to 20 cards per session
      .to_a

    if @vocabularies.empty?
      redirect_to learn_vocabularies_path, notice: "Keine Vokabeln zum Lernen in dieser Sprache!"
    end
  end

  def update_learning_status
    vocabulary = current_user.vocabularies.find(params[:id])
    correct = params[:correct] == true

    if correct
      # Move to next status: open -> learning -> learned
      case vocabulary.status
      when "open"
        vocabulary.update!(status: "learning")
      when "learning"
        vocabulary.update!(status: "learned")
      # If already learned, keep it learned
      else
        Rails.logger.error "Status is #{vocabulary.status}, keeping unchanged"
      end
    else
      vocabulary.update!(status: "open")
    end

    # Just send back the new status
    render json: vocabulary.status_german
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Vocabulary not found with ID: #{params[:id]}"
    render json: { error: "Vokabel nicht gefunden" }, status: 404
  rescue => e
    Rails.logger.error "Error in update_learning_status: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Ein Fehler ist aufgetreten" }, status: 500
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
