class FLP::Project

  def initialize
  end

  property path       : String     = ""
  property channels   : UInt16     = 0
  property ppq        : UInt16     = 0
  property started_at : Time?
  property work_time  : Time::Span?

end

