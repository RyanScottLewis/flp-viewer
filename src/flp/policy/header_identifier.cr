require "./base"

class FLP::Policy::HeaderIdentifier < FLP::Policy::Base

  VALID_HEADER_IDENTIFIER = 1684556870 # "FLhd" as 32-bit little-endian integer
  MESSAGE = "Invalid header identifier"

  def call(value)
    raise ParseError.new(MESSAGE) unless value == VALID_HEADER_IDENTIFIER

    value
  end

end

