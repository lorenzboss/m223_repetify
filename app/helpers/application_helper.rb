module ApplicationHelper
  # Activity Log Helper Methods - minimal set used in views
  def activity_badge_class(event)
    case event
    when "create"
      "bg-success"
    when "update"
      "bg-warning text-dark"
    when "destroy"
      "bg-danger"
    else
      "bg-secondary"
    end
  end

  # Raw rendering of changes - show exactly what's in the database
  def render_raw_activity_changes(version)
    return "" unless version.object_changes.present?

    # Remove only the first --- line if it exists
    clean_content = version.object_changes.sub(/^---\s*\n/, "")

    "<pre class=\"mb-0 p-2 bg-white border rounded\" style=\"font-size: 0.8rem; max-height: 300px; overflow-y: auto;\">#{CGI.escapeHTML(clean_content)}</pre>".html_safe
  end

  # Raw rendering of complete object
  def render_raw_activity_object(version)
    return "" unless version.object.present?

    # Remove only the first --- line if it exists
    clean_content = version.object.sub(/^---\s*\n/, "")

    "<pre class=\"mb-0 p-2 bg-white border rounded\" style=\"font-size: 0.8rem; max-height: 400px; overflow-y: auto;\">#{CGI.escapeHTML(clean_content)}</pre>".html_safe
  end

  # Readable summary for the timeline
  def get_readable_change_summary(version)
    return "#{version.event.upcase} #{version.item_type}" unless version.object_changes.present?

    begin
      changes = YAML.safe_load(
        version.object_changes,
        permitted_classes: [ Time, Date, ActiveSupport::TimeWithZone ],
        aliases: true
      )
      return "#{version.event.upcase} #{version.item_type}" unless changes.is_a?(Hash)

      meaningful_changes = changes.except("created_at", "updated_at", "id")

      if meaningful_changes.empty?
        return "#{version.event.upcase} #{version.item_type}"
      end

      case version.event
      when "create"
        "Created #{version.item_type.downcase}"
      when "update"
        changed_fields = meaningful_changes.keys
        if changed_fields.length == 1
          field = changed_fields.first
          "#{field.humanize} changed"
        else
          "Updated #{changed_fields.length} fields"
        end
      when "destroy"
        "Deleted #{version.item_type.downcase}"
      else
        "#{version.event.upcase} #{version.item_type}"
      end
    rescue
      "#{version.event.upcase} #{version.item_type}"
    end
  end
end
