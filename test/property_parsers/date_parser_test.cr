require "minitest/autorun"

require "/../src/ical_parser/property_parsers/date_time_parser"
require "/../src/ical_parser/common"
# require "/../src/iCal"

class DateParserTest < Minitest::Test
  include IcalParser

  @parser : Proc(String, String)

  def initialize(arg)
    super(arg)
    @parser = @@date_parser
  end

  def test_parses_date
    string = "19970714"
    date = @parser.call(string)
    assert_equal string, date
  end

  def test_raises_for_invalid_date_format
    string = "970714"
    error = assert_raises do
      @parser.call(string)
    end
    assert_equal "Invalid Date format", error.message
  end

  def test_raises_for_invalid_date
    string = "19970740"
    error = assert_raises do
      @parser.call(string)
    end
    assert_equal "Invalid Date", error.message
  end
end
