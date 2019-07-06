require "./value_parser"

module IcalParser
  # Parses a TEXT property into a String object, removing escape characters.
  @@text_parser = Proc(String, String).new do |value|
    value.gsub(/\\(?![nN\\])/) { |match| "" }
  end

  # Converts a String object into a TEXT property, adding escape characters as needed.
  @@text_generator = Proc(String, String).new do |value|
    value.gsub(/(\,|\;|\\[^n])/) { |match| "\\" + match }
  end
end
