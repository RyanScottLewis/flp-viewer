abstract class FLP::Policy::Base

  def self.call(value)
    new.call(value)
  end

  abstract def call(value)

end

