require "./object"
require "json"
require "uri"
require "./converters"

module IcalParser
  # Representation of the [Cal-Address](https://tools.ietf.org/html/rfc5545#section-3.3.3) value type
  #
  # uri = URI.parse("mailto:iamboss@example.com")
  # params = { "ROLE" => "NON-PARTICIPANT", "PARTSTAT" => "DELEGATED", "CN" => "The Big Cheese" }
  # user = CalAddress.new(uri, params)
  # user.uri.path #=> iamboss@example.com
  # user.common_name  #=> "The Big Cheese"
  # user.role #=> non-participant
  class CalAddress
    JSON.mapping(
      uri: { type: URI, converter: URI::URIConverter },
      cutype: { type: CUType?, getter: false },
      role: { type: Role?, getter: false },
      part_stat: { type: PartStat?, getter: false, key: "partstat" },
      member: { type: Array(CalAddress)?, getter: false },
      delegated_from: { type: Array(CalAddress)?, key: "delegated-from", getter: false },
      delegated_to: { type: Array(CalAddress)?, key: "delegated-to", getter: false },
      sent_by: { type: CalAddress?, key: "sent-by" },
      rsvp: { type: Bool? },
      common_name: { type: String?, key: "cn" },
      dir: { type: URI?, converter: URI::URIConverter }
    )

    getter(member) { [] of CalAddress }
    getter(delegated_from) { [] of CalAddress }
    getter(delegated_to) { [] of CalAddress }

    # Creates a new CalAddress object with the specified URI.
    #
    # uri = URI.parse("mailto:jsmith@example.com")
    # user = CalAddress.new(uri)
    # user.uri.path  #=> "jsmith@example.com"
    def initialize(@uri : URI)
    end

    def_equals @uri

    getter cutype, type: CUType, value: CUType::Individual
    getter role, type: Role, value: Role::ReqParticipant
    getter part_stat, type: PartStat, value: PartStat::NeedsAction
    getter rsvp, type: Bool, value: false
  end
end
