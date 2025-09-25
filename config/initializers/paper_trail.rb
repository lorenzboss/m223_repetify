# Paper Trail Configuration
PaperTrail.configure do |config|
  # Keep last 1000 versions per record
  config.version_limit = 1000
end

# Optional: Track additional metadata
PaperTrail.serializer = PaperTrail::Serializers::YAML
