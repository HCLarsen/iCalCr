require "./parser"

class ICal::Event
  getter summary : String
  getter uid : String
  getter start : Time
  getter description : String | Nil
  getter location : String | Nil

  def initialize(vevent : String)
    summaryRegex = /(?<=SUMMARY:)(.*)(?=\n)/
    uidRegex = /(?<=UID:)(.*)(?=\n)/
    descriptionRegex = /(?<=DESCRIPTION:)(.*)(?=\n)/

    stampRegex = /(?<=DTSTAMP).*:(.*)(?=\n)/
    startRegex = /(?<=DTSTART).*:(.*)(?=\n)/
    endRegex = /(?<=DTEND).*:(.*)(?=\n)/
    durationRegex = /(?<=DURATION).*:(.*)(?=\n)/

    @summary = summaryRegex.match(vevent).try &.[1] || ""
    @uid = uidRegex.match(vevent).try &.[1] || ""
    startString = startRegex.match(vevent).try &.[1] || ""
    @start = ICal::Parser.from_iCalDT(startString)
    if endRegex.match(vevent)
      endString = endRegex.match(vevent).try &.[1] || ""
      @end = ICal::Parser.from_iCalDT(endString)
    elsif durationRegex.match(vevent)
      durationString = durationRegex.match(vevent).try &.[1] || ""
      
    end
  end
end
