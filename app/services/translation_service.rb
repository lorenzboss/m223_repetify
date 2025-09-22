require "net/http"
require "uri"
require "json"

class TranslationService
  DEEPL_API_URL = "https://api-free.deepl.com/v2/translate"

  def self.translate(text, source_lang = nil, target_lang = "de")
    api_key = Rails.application.credentials.dig(:deepl, :api_key)

    unless api_key
      Rails.logger.error "DeepL API key not found"
      raise StandardError, "DeepL API key not configured"
    end

    uri = URI(DEEPL_API_URL)

    params = {
      "auth_key" => api_key,
      "text" => text,
      "target_lang" => "DE"
    }

    # Add source language if specified (for non-automatic detection)
    if source_lang.present?
      params["source_lang"] = source_lang
    end

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request.set_form_data(params)

    response = http.request(request)

    if response.code == "200"
      result = JSON.parse(response.body)
      translation = result["translations"].first

      {
        translated_text: translation["text"],
        detected_language: translation["detected_source_language"],
        source_language: source_lang || translation["detected_source_language"]&.downcase
      }
    else
      Rails.logger.error "DeepL API error: #{response.code} - #{response.body}"
      raise StandardError, "DeepL API error: #{response.code}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parsing error: #{e.message}"
    raise StandardError, "Invalid response from DeepL API"
  rescue Net::TimeoutError, Net::OpenTimeout => e
    Rails.logger.error "Network timeout: #{e.message}"
    raise StandardError, "Translation service timeout"
  rescue StandardError => e
    Rails.logger.error "Translation error: #{e.message}"
    raise e
  end
end
