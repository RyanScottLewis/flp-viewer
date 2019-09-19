require "./base"

# TODO UNUSED
class FLP::Policy::DataIdentifier < FLP::Policy::Base

  VALID_DATA_IDENTIFIER = 1952730182 # "FLdt" as 32-bit little-endian integer
  MESSAGE = "Invalid data identifier"

  def call(value)
    raise ParseError.new(MESSAGE) unless value == VALID_DATA_IDENTIFIER

    value
  end

end

