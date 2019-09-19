require "./base"

class FLP::Policy::HeaderFormat < FLP::Policy::Base

  VALID_HEADER_FORMAT = 0 # 0 for full song. It's unknown what the other possible values are
  MESSAGE = "Invalid header format"

  def call(value)
    raise ParseError.new(MESSAGE) unless value == VALID_HEADER_FORMAT

    value
  end

end

