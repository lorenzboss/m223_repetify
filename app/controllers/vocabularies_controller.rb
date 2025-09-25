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
      .includes(:user)
      .order(:source_language)

    # Custom sorting: status priority (open, learning, learned) then by updated_at DESC
    @vocabularies_by_language = all_vocabularies.group_by(&:source_language).transform_values do |vocabularies|
      vocabularies.sort_by do |vocab|
        status_priority = case vocab.status
        when "open" then 1
        when "learning" then 2
        when "learned" then 3
        else 4
        end
        [status_priority, -vocab.updated_at.to_i]
      end
    end

    # Language display names
    @language_names = LANGUAGE_NAMES
  end

  def learn
    # Overview of learning progress by language
    @vocabularies_by_language = {}
    @language_names = LANGUAGE_NAMES

    SUPPORTED_LANGUAGES.each do |lang|
      vocabularies = current_user.vocabularies.where(source_language: lang)
      next if vocabularies.empty?

      @vocabularies_by_language[lang] = {
        total: vocabularies.count,
        open: vocabularies.where(status: "open").count,
        learning: vocabularies.where(status: "learning").count,
        learned: vocabularies.where(status: "learned").count,
        to_learn: vocabularies.where(status: %w[open learning]).count
      }
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
