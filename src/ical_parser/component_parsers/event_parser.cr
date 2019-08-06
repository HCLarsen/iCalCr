module IcalParser
  class EventParser
    DELIMITER = "VEVENT"
    LINES_REGEX = /(?<name>.*?)(?<params>;[a-zA-Z\-]*=(?:".*"|[^:;\n]*)+)?:(?<value>.*)/
    COMPONENT_REGEX = /^BEGIN:(?<type>.*?)$.*?^END:.*?$/m

    COMPONENT_PROPERTIES = {
      "uid"             => Property.new("TEXT"),
      "dtstamp"         => Property.new("DATE-TIME"),
      "created"         => Property.new("DATE-TIME"),
      "last-mod"        => Property.new("DATE-TIME"),
      "dtstart"         => Property.new("DATE-TIME", alt_values: ["DATE"]),
      "dtend"           => Property.new("DATE-TIME", alt_values: ["DATE"]),
      "duration"        => Property.new("DURATION"),
      "summary"         => Property.new("TEXT"),
      "description"     => Property.new("TEXT"),
      "classification"  => Property.new("TEXT"),
      "categories"      => Property.new("TEXT", single_value: false, only_once: false),
      "resources"       => Property.new("TEXT", single_value: false, only_once: false),
      "contacts"        => Property.new("TEXT", single_value: false, only_once: false),
      "related_to"      => Property.new("TEXT", single_value: false, only_once: false),
      "request-status"  => Property.new("TEXT", only_once: false),
      "transp"          => Property.new("TEXT"),
      "status"          => Property.new("TEXT"),
      "comments"        => Property.new("TEXT"),
      "location"        => Property.new("TEXT"),
      "priority"        => Property.new("INTEGER"),
      "sequence"        => Property.new("INTEGER"),
      "organizer"       => Property.new("CAL-ADDRESS"),
      "attendees"       => Property.new("CAL-ADDRESS", only_once: false),
      "geo"             => Property.new("FLOAT", parts: ["lat", "lon"]),
      "recurrence"      => Property.new("RECUR"),
      "exdate"          => Property.new("DATE-TIME", alt_values: ["DATE"], single_value: false, only_once: false),
      "rdate"           => Property.new("DATE-TIME", alt_values: ["DATE", "PERIOD"], single_value: false, only_once: false),
      "url"             => Property.new("URI"),
    }

    private def initialize; end

    def self.parser : EventParser
      if @@instance.nil?
        @@instance = new
      else
        @@instance.not_nil!
      end
    end

    def parse(component : String) : Event
      found = parse_to_json(component)
      Event.from_json(found)
    end

    def parse_to_json(component : String) : String
      component = remove_delimiters(component)
      props = parse_properties(component)

      %({#{props.join(",")}})
    end

    private def parse_properties(component : String) : Array(String)
      property_names = {
        "last-modified"   => "last-mod",
        "class"           => "classification",
        "attendee"        => "attendees",
        "comment"         => "comments",
        "contact"         => "contacts",
        "rrule"           => "recurrence",
      }
      found = Hash(String, String).new

      lines = content_lines(component)
      matches = lines_matches(lines)

      matches.each do |match|
        name = match["name"].downcase
        if property_names[name]?
          name = property_names[name]
        end

        if COMPONENT_PROPERTIES.keys.includes? name
          property = COMPONENT_PROPERTIES[name]
          value = property.parse(match["value"], match["params"]?)

          unless found[name]?
            found[name] = value
          else
            if property.only_once
              raise "Invalid Event: #{name.upcase} MUST NOT occur more than once"
            else
              value = value.strip("[]")
              found[name] = found[name].insert(-2, ",#{value}")
            end
          end
        end
      end

      if found["dtstart"]? && found["dtstart"].match(/^"\d{4}-\d{2}-\d{2}"$/)
        found["all-day"] = "true"
      end

      found.map do |k, v|
        %("#{k}":#{v})
      end
    end

    private def remove_delimiters(component : String) : String
      component.lchop("BEGIN:#{DELIMITER}\r\n").rchop("END:#{DELIMITER}")
    end

    private def content_lines(component : String) : Array(String)
      lines = component.lines
      lines
    end

    private def lines_matches(lines : Array(String)) : Array(Regex::MatchData)
      lines.map_with_index do |line, index|
        if match = line.match(LINES_REGEX)
          match
        else
          raise "Invalid Event: Invalid content line ##{index}: #{line}"
        end
      end
    end

    def dup
      raise Exception.new("Can't duplicate instance of singleton #{self.class}")
    end
  end
end
