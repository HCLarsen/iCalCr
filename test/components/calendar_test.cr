require "minitest/autorun"

require "/../src/iCal"

class EventTest < Minitest::Test
  include IcalParser

  def initialize(argument)
    super(argument)
    @prodid = "-//hacksw/handcal//NONSGML v1.0//EN"
  end

  def test_initializes_calendar_with_single_event
    event = Event.new("19970610T172345Z-AF23B2@example.com", Time.utc(1997, 6, 10, 17, 23, 45), Time.utc(1997, 7, 14, 17, 0, 0), Time.utc(1997, 7, 15, 4, 0, 0))
    calendar = Calendar.new(@prodid, [event])
    assert_equal @prodid, calendar.prodid
    assert_equal event, calendar.events.first
  end

  def test_initializes_calendar_with_props_hash
    props = {
      "method" => "xyz",
      "version" => "2.0",
      "prodid" => "-//ABC Corporation//NONSGML My Product//EN"
    }
    event = Event.new("19970610T172345Z-AF23B2@example.com", Time.utc(1997, 6, 10, 17, 23, 45), Time.utc(1997, 7, 14, 17, 0, 0), Time.utc(1997, 7, 15, 4, 0, 0))
    calendar = Calendar.new(props, [event])
    assert_equal props["prodid"], calendar.prodid
  end

  def test_raises_without_prodid
    props = {
      "method" => "xyz",
      "version" => "2.0"
    }
    event = Event.new("19970610T172345Z-AF23B2@example.com", Time.utc(1997, 6, 10, 17, 23, 45), Time.utc(1997, 7, 14, 17, 0, 0), Time.utc(1997, 7, 15, 4, 0, 0))

    error = assert_raises do
      calendar = Calendar.new(props, [event])
    end
    assert_equal "Invalid Calendar: PRODID is REQUIRED", error.message
  end

  def test_raises_without_version
    props = {
      "method" => "xyz",
      "prodid" => "-//ABC Corporation//NONSGML My Product//EN"
    }
    event = Event.new("19970610T172345Z-AF23B2@example.com", Time.utc(1997, 6, 10, 17, 23, 45), Time.utc(1997, 7, 14, 17, 0, 0), Time.utc(1997, 7, 15, 4, 0, 0))

    error = assert_raises do
      calendar = Calendar.new(props, [event])
    end
    assert_equal "Invalid Calendar: VERSION is REQUIRED", error.message
  end
end
