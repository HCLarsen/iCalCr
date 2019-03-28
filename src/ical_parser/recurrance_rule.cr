module IcalParser
  # Representation of the Recurrence Rule.
  #
  # This class defines the repetition pattern of an event, to-do, jounral entry or time zone definition.
  #
  # # Specifies a recurrence rule for an event that will repeat every 2 days, up to 10 times.
  # recur = RecurrenceRule.new(RecurrenceRule::Freq::Daily, 10, 2)
  # recur.frequency #=> Daily
  # recur.count     #=> 10
  # recur.interval  #=> 2
  #
  # # Defines an Event that will repeat every year, indefinitely.
  # recur = RecurrenceRule.new(RecurrenceRule::Freq::Yearly)
  # props = {
  #   "uid"         => "canada-day@example.com",
  #   "dtstamp"     => Time.utc(1867, 3, 29, 13, 0, 0),
  #   "dtstart"     => Time.utc(1867, 7, 1),
  #   "recurrence"  => recur
  # } of String => PropertyType
  # event = IcalParser::Event.new(props)
  # event.recurring             #=> true
  # event.recurrence.frequency  #=> Yearly
  struct RecurrenceRule
    module ByDayConverter
      def self.from_json(value : JSON::PullParser) : Array({Int32, Time::DayOfWeek})
        byday_regex = /(?<num>-?[1-9]?)(?<day>[A-Z]{2})/
        output = [] of {Int32, Time::DayOfWeek}
        value.read_array do
          day = value.read_string
          if match = day.match(byday_regex)
            num = match["num"].empty? ? 0 : match["num"].to_i
            output << {num, RecurrenceRule.weekday_to_day_of_week(match["day"])}
          else
            raise "Invalid BYDAY rule format"
          end
        end
        output
      end

      def self.to_json(value : Array({Int32, Time::DayOfWeek}), json : JSON::Builder)
        value.map do |day|
          output = day[0] > 0 ? day[0].to_s : ""
          output + day[1].to_s[0..1].upcase
        end.to_json(json)
      end
    end

    module DayOfWeekConverter
      def self.from_json(value : JSON::PullParser) : Time::DayOfWeek
        RecurrenceRule.weekday_to_day_of_week(value.read_string)
      end

      def self.to_json(value : Time::DayOfWeek, json : JSON::Builder)
        value.to_s[0..1].upcase.to_json(json)
      end
    end

    enum Freq
      Secondly
      Minutely
      Hourly
      Daily
      Weekly
      Monthly
      Yearly

      def self.from_string(string : String)
        case string
        when "secondly"
          Secondly
        when "minutely"
          Minutely
        when "hourly"
          Hourly
        when "daily"
          Daily
        when "weekly"
          Weekly
        when "monthly"
          Monthly
        when "yearly"
          Yearly
        else
          raise "Invalid Recurrence Rule FREQ value"
        end
      end
    end

    protected def self.weekday_to_day_of_week(day : String) : Time::DayOfWeek
      case day
      when "MO"
        Time::DayOfWeek::Monday
      when "TU"
        Time::DayOfWeek::Tuesday
      when "WE"
        Time::DayOfWeek::Wednesday
      when "TH"
        Time::DayOfWeek::Thursday
      when "FR"
        Time::DayOfWeek::Friday
      when "SA"
        Time::DayOfWeek::Saturday
      when "SU"
        Time::DayOfWeek::Sunday
      else
        raise "Invalid Day of Week value: #{day}"
      end
    end

    alias ByRuleType = Array({Int32, Time::DayOfWeek}) | Array(Int32)

    JSON.mapping(
      frequency: {type: Freq, key: "freq"},
      count: {type: Int32?},
      interval: {type: Int32?},
      end_time: {type: Time?, key: "until", converter: Time::EpochConverter},
      by_week: {type: Array(Int32)?, key: "byweekno"},
      by_month: {type: Array(Int32)?, key: "bymonth"},
      by_day: {type: Array({Int32, Time::DayOfWeek})?, key: "byday", converter: ByDayConverter},
      by_hour: {type: Array(Int32)?, key: "byhour"},
      by_minute: {type: Array(Int32)?, key: "byminute"},
      by_year_day: {type: Array(Int32)?, key: "byyearday"},
      by_month_day: {type: Array(Int32)?, key: "bymonthday"},
      by_set_pos: {type: Array(Int32)?, key: "bysetpos"},
      week_start: {type: Time::DayOfWeek?, key: "wkst", converter: DayOfWeekConverter}
    )

    property week_start = Time::DayOfWeek::Monday
    property by_second = [] of Int32

    def initialize(@frequency : Freq, @count = nil, @interval = 1)
    end

    def initialize(@frequency : Freq, @end_time : Time, @interval = 1)
    end

    def initialize(@frequency : Freq, *, by_rules : Hash(String, ByRuleType), @end_time : Time,  @interval = 1, week_start : Time::DayOfWeek? = nil)
      assign_rules(by_rules)
      @week_start = week_start if week_start
    end

    def initialize(@frequency : Freq, *, by_rules : Hash(String, ByRuleType), @count = nil, @interval = 1, week_start : Time::DayOfWeek? = nil)
      assign_rules(by_rules)
      @week_start = week_start if week_start
    end

    def assign_rules(rules : Hash(String, ByRuleType))
      @by_month = rules["by_month"].as? Array(Int32) if rules["by_month"]?
      @by_week = rules["by_week"].as? Array(Int32) if rules["by_week"]?
      @by_year_day = rules["by_year_day"].as? Array(Int32) if rules["by_year_day"]?
      @by_month_day = rules["by_month_day"].as? Array(Int32) if rules["by_month_day"]?
      @by_day = rules["by_day"].as? Array({Int32, Time::DayOfWeek}) if rules["by_day"]?
      @by_hour = rules["by_hour"].as? Array(Int32) if rules["by_hour"]?
      @by_minute = rules["by_minute"].as? Array(Int32) if rules["by_minute"]?
      @by_second = rules["by_second"].as? Array(Int32) if rules["by_second"]?
      @by_set_pos = rules["by_set_pos"].as? Array(Int32) if rules["by_set_pos"]?
    end

    def count=(count : Int32)
      unless @end_time
        @count = count
      else
        raise "Invalid Assignment: Recurrence Rule cannot have both a count and an end time"
      end
    end

    def end_time=(end_time : Time)
      unless @count
        @end_time = end_time
      else
        raise "Invalid Assignment: Recurrence Rule cannot have both a count and an end time"
      end
    end

    def total_frequency : Time::Span | Time::MonthSpan
      case @frequency
      when Freq::Yearly
        @interval.years
      when Freq::Monthly
        @interval.months
      when Freq::Weekly
        @interval.weeks
      when Freq::Daily
        @interval.days
      when Freq::Hourly
        @interval.hours
      when Freq::Minutely
        @interval.minutes
      when Freq::Secondly
        @interval.seconds
      else
        raise "Invalid Frequency value"
      end
    end
  end
end
