require "./ical_parser/*"
require "./ical_parser/components/*"
require "./ical_parser/component_parsers/*"
require "./ical_parser/property_parsers/*"

# TODO: Write documentation for `IcalParser`
module IcalParser
  TYPES = [Bool, CalAddress, Float64, Int32, PeriodOfTime, RecurrenceRule, String, Time, Time::Span, URI]

  {% begin %}
    alias ValueType = {{ TYPES.join(" | ").id }}
    {% arrays = TYPES.map{|e| "Array(#{e})".id } %}
    alias ValueArray = {{ arrays.join(" | ").id }}
    {% hashes = TYPES.map{|e| "Hash(String, #{e})".id } %}
    alias ValueHash = {{ hashes.join(" | ").id }}

    alias ParserType = {{ TYPES.map{|e| "Proc(String, Hash(String, String), #{e})".id}.join(" | ").id }}

    alias PropertyType = ValueType | ValueArray | ValueHash
  {% end %}

  PARSERS = {
    "BINARY"      => @@text_parser,  # To be replaced with BinaryParser once written.
    "BOOLEAN"     => @@boolean_parser,
    "CAL-ADDRESS" => @@caladdress_parser,
    "DATE"        => @@date_parser,
    "DATE-TIME"   => @@date_time_parser,
    "DURATION"    => @@duration_parser,
    "FLOAT"       => @@float_parser,
    "INTEGER"     => @@integer_parser,
    "PERIOD"      => @@period_parser,
    "RECUR"       => @@recurrence_parser,
    "TEXT"        => @@text_parser,
    "TIME"        => @@time_parser,
    "URI"         => @@uri_parser,
    "UTC-OFFSET"  => @@text_parser,  # To be replaced with UTCOffsetParser once written.
  }
end
