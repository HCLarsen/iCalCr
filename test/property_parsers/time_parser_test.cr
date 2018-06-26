require "minitest/autorun"

require "/../src/iCal"

class TimeParserTest < Minitest::Test
  include IcalParser

  def initialize(arg)
    super(arg)
    @parser = TimeParser.parser
  end

  def test_parses_time
    time = "230000"
    assert_equal Time.new(1,1,1,23,0,0, nanosecond: 0, location: Time::Location.local), @parser.parse(time)
    assert_equal Time::Location.local, @parser.parse(time).location
  end

  def test_parses_utc_time
    time = "070000Z"
    assert_equal Time.utc(1,1,1,7,0,0), @parser.parse(time)
  end

  def test_parses_time_zone_time
    string = "083000"
    params = { "TZID" => "America/New_York" }
    time = @parser.parse(string, params)
    assert_equal Time.utc(1,1,1,13, 30, 0), time
    assert_equal Time::Location.load("America/New_York"), time.location
  end

  def test_raises_invalid_time_format
    error = assert_raises do
      @parser.parse("230000-0800")
    end
    assert_equal "Invalid Time format", error.message
  end
end
