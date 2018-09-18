require "minitest/autorun"

require "/../src/iCal"

class PropertyTest < Minitest::Test
  include IcalParser

  def initialize(argument)
    super(argument)
  end

  def test_property_parses_value
    prop = Property(String).new(@@text_parser)
    params = ""
    value = "Networld+Interop Conference and Exhibit\nAtlanta World Congress Center\nAtlanta\, Georgia"
    text = prop.parse(value, params)
    assert_equal "Networld+Interop Conference and Exhibit\nAtlanta World Congress Center\nAtlanta, Georgia", text

    found = Hash(String, PropertyType).new
    found["description"] = text
  end

  def test_property_parses_value_with_params
    prop = Property(CalAddress).new(@@caladdress_parser)
    params = ";RSVP=TRUE;ROLE=REQ-PARTICIPANT;CUTYPE=GROUP"
    value = "mailto:employee-A@example.com"
    address = prop.parse(value, params)
    assert_equal CalAddress.new(URI.parse("mailto:employee-A@example.com")), address
    assert_equal CalAddress | Array(CalAddress) | Hash(String, CalAddress), typeof(address)
  end

  def test_single_category_returns_as_array
    prop = Property(String).new(@@text_parser, single_value: false, only_once: false)
    value = "MEETING"
    list = prop.parse(value, "")
    assert_equal ["MEETING"], list
  end

  def test_parses_geo
    NamedTuple(lat: Float64, lon: Float64)
    prop = Property(Float64).new(@@float_parser, parts: ["lat", "lon"])
    value = "37.386013;-122.082932"
    coords = prop.parse(value, "")
    assert_equal coords.as(Hash(String, Float64))["lat"], 37.386013
    assert_equal coords.as(Hash(String, Float64))["lon"], -122.082932
  end

  def test_parses_tz_params
    prop = Property(String).new(@@text_parser)
    params = ";TZID=America/New_York"
    hash = {"TZID" => "America/New_York"}
    assert_equal hash, prop.parse_params(params)
  end

  def test_parses_multiple_params
    prop = Property(String).new(@@text_parser)
    params = ";ROLE=REQ-PARTICIPANT;PARTSTAT=TENTATIVE;CN=Henry Cabot"
    hash = {"ROLE" => "REQ-PARTICIPANT", "PARTSTAT" => "TENTATIVE", "CN" => "Henry Cabot"}
    assert_equal hash, prop.parse_params(params)
  end

  def test_property_parses_params_with_array_value
    prop = Property(CalAddress).new(@@caladdress_parser)
    params = %(;DELEGATED-TO="mailto:jdoe@example.com","mailto:jqpublic@example.com")
    parsed_params = prop.parse_params(params)
    assert_equal %("mailto:jdoe@example.com","mailto:jqpublic@example.com"), parsed_params["DELEGATED-TO"]
  end
end
