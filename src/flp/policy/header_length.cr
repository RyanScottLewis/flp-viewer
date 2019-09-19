require "./base"

class FLP::Policy::HeaderLength < FLP::Policy::Base

  VALID_HEADER_LENGTH = 6
  MESSAGE = "Invalid header length"

  def call(value)
    raise ParseError.new(MESSAGE) unless value == VALID_HEADER_LENGTH

    value
  end

end

