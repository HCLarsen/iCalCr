module IcalParser
  class EventParser
    private def initialize; end

    def self.parser : EventParser
      if @@instance.nil?
        @@instance = new
      else
        @@instance.not_nil!
      end
    end

    def parse(eventc : String)
      component_properties = {
        "uid"             => Property.new(TextParser.parser),
        "dtstamp"         => Property.new(DateTimeParser.parser),
        "dtstart"         => Property.new(DateTimeParser.parser),
        "dtend"           => Property.new(DateTimeParser.parser),
        "summary"         => Property.new(TextParser.parser),
        "classification"  => Property.new(TextParser.parser),
        "categories"      => Property.new(TextParser.parser, Property::Quantity::List),
        "transp"          => Property.new(TextParser.parser),
      }
      all_day = false
      found = Hash(String, String | Time | Time::Span | Array(String)).new
      regex = /(?<name>.*?)(?<params>;.*?)?:(?<value>.*)/

      lines = eventc.lines
      lines.each do |line|
        if match = line.match(regex)
          name = match["name"].downcase
          name = "classification" if name == "class"
          all_day = true if name == "dtstart" && match["params"]? && match["params"].includes?("VALUE=DATE")

          if component_properties.keys.includes? name
            property = component_properties[name]

            if property.quantity == Property::Quantity::One
              found[name] = property.parse(match["value"], match["params"]?)
            else
              list = match["value"].split(/(?<!\\),/)
              found[name] = list.map { |e| property.parse(e, match["params"]?).as String }
            end
          end
        else
          raise "Invalid Event: No value on line #{line}"
        end
      end

      event = Event.new(found)
      event.all_day = all_day
      return event
    end

    def dup
      raise Exception.new("Can't duplicate instance of singleton #{self.class}")
    end
  end
end
