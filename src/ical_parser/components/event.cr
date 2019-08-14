require "./../property_parsers/*"

module IcalParser
  class Event
    PROPERTIES = {
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

    JSON.mapping(
      uid: {type: String},
      dtstamp: {type: Time, converter: Time::ISO8601Converter},
      created: {type: Time?, converter: Time::ISO8601Converter},
      last_mod: {type: Time?, key: "last-mod", converter: Time::ISO8601Converter},
      dtstart: {type: Time, converter: Time::ISO8601Converter},
      dtend: {type: Time?, converter: Time::ISO8601Converter},
      duration: {type: Duration?},
      summary: {type: String?},
      classification: {type: String?},
      categories: {type: Array(String)?, getter: false},
      resources: {type: Array(String)?, getter: false},
      contacts: {type: Array(String)?, getter: false},
      related_to: {type: Array(String)?, key: "related-to", getter: false},
      request_status: {type: Array(String)?, key: "request-status", getter: false},
      transp: {type: String?, getter: false},
      description: {type: String?},
      status: {type: String?},
      comments: {type: String?},
      location: {type: String?},
      priority: {type: Int32?},
      sequence: {type: Int32?},
      organizer: {type: CalAddress?},
      attendees: {type: Array(CalAddress)?, getter: false},
      geo: {type: Hash(String, Float64)?},
      recurrence: {type: RecurrenceRule?},
      exdate: {type: Array(Time)?, getter: false, converter: JSON::ArrayConverter(Time::ISO8601Converter)},
      url: {type: URI?, converter: URI::URIConverter},
      all_day: {type: Bool?, key: "all-day", getter: false}
    )

    getter? all_day
    getter attendees, type: Array(CalAddress), value: [] of CalAddress
    getter categories, contacts, resources, related_to, request_status, type: Array(String), value: [] of String
    getter exdate, type: Array(Time), value: [] of Time
    getter rdate, type: Array(Time | PeriodOfTime), value: [] of Time | PeriodOfTime
    getter transp, type: String, value: "OPAQUE"
    getter classification, type: String, value: "PUBLIC"

    def_equals @uid, @dtstamp, @dtstart, @dtend, @summary

    def initialize(@uid : String, @dtstamp : Time, @dtstart : Time)
    end

    def initialize(@uid : String, @dtstamp : Time, @dtstart : Time, dtend : Time)
      check_end_greater_than_start(@dtstart, dtend)
    end

    def initialize(@uid : String, @dtstamp : Time, @dtstart : Time, duration : Time::Span)
      raise "Invalid Event: Duration must be positive" if duration < Time::Span.zero
      @dtend = @dtstart + duration
    end

    def dtstart=(dtstart : Time)
      dtend = @dtend
      if dtend.nil?
        @dtstart = dtstart
      else
        check_end_greater_than_start(dtstart, dtend)
      end
    end

    def dtend=(dtend : Time)
      check_end_greater_than_start(@dtstart, dtend)
    end

    def duration : Duration
      if dtend = @dtend
        Duration.between(@dtstart, dtend)
      else
        Duration.new
      end
    end

    def duration=(duration : Duration)
      if duration >= Duration.new
        @duration = duration
      else
        raise "Error: Duration value must be greater than zero"
      end
    end

    def opaque?
      @transp != "TRANSPARENT"
    end

    def recurring
      !@recurrence.nil?
    end

    private def later(time : Time, span : (Time::Span | Time::MonthSpan))
      newtime = time + span
      if span.is_a?(Time::Span) && span.days != 0
        if time.zone.dst? && !newtime.zone.dst?
          newtime += Time::Span.new(1, 0, 0)
        elsif !time.zone.dst? && newtime.zone.dst?
          newtime -= Time::Span.new(1, 0, 0)
        end
      end
      newtime
    end

    private def check_end_greater_than_start(dtstart : Time, dtend : Time)
      if dtend > dtstart
        @dtstart = dtstart
        @dtend = dtend
      else
        raise "Invalid Event: End time cannot precede start time"
      end
    end

    def initialize(pull : JSON::PullParser)
      previous_def
      duration = @duration
      unless duration.nil?
        @dtend = @dtstart.shift(days: duration.days, hours: duration.hours, minutes: duration.minutes, seconds: duration.seconds)
      end
    end
  end
end
