require "./errors"
require "./policy/*"
require "./project"

class FLP::Parser

  enum Event
    Byte                   = 0
    Enabled                = 0
    NoteOn                 = 1
    Vol                    = 2
    Pan                    = 3
    MIDIChan               = 4
    MIDINote               = 5
    MIDIPatch              = 6
    MIDIBank               = 7
    LoopActive             = 9
    ShowInfo               = 10
    Shuffle                = 11
    MainVol                = 12
    Stretch                = 13
    Pitchable              = 14
    Zipped                 = 15
    Delay_Flags            = 16
    PatLength              = 17
    BlockLength            = 18
    UseLoopPoints          = 19
    LoopType               = 20
    ChanType               = 21
    MixSliceNum            = 22
    EffectChannelMuted     = 27

    Word                   = 64
    NewChan                = Word
    NewPat                 = Word + 1
    Tempo                  = Word + 2
    CurrentPatNum          = Word + 3
    PatData                = Word + 4
    FX                     = Word + 5
    Fade_Stereo            = Word + 6
    CutOff                 = Word + 7
    DotVol                 = Word + 8
    DotPan                 = Word + 9
    PreAmp                 = Word + 10
    Decay                  = Word + 11
    Attack                 = Word + 12
    DotNote                = Word + 13
    DotPitch               = Word + 14
    DotMix                 = Word + 15
    MainPitch              = Word + 16
    RandChan               = Word + 17
    MixChan                = Word + 18
    Resonance              = Word + 19
    LoopBar                = Word + 20
    StDel                  = Word + 21
    FX3                    = Word + 22
    DotReso                = Word + 23
    DotCutOff              = Word + 24
    ShiftDelay             = Word + 25
    LoopEndBar             = Word + 26
    Dot                    = Word + 27
    DotShift               = Word + 28
    LayerChans             = Word + 30

    Int                    = 128
    Color                  = Int
    PlayListItem           = Int + 1
    Echo                   = Int + 2
    FXSine                 = Int + 3
    CutCutBy               = Int + 4
    WindowH                = Int + 5
    MiddleNote             = Int + 7
    Reserved               = Int + 8
    MainResoCutOff         = Int + 9
    DelayReso              = Int + 10
    Reverb                 = Int + 11
    IntStretch             = Int + 12
    SSNote                 = Int + 13
    FineTune               = Int + 14

    Undef                  = 192
    Text                   = Undef
    Text_ChanName          = Text
    Text_PatName           = Text + 1
    Text_Title             = Text + 2
    Text_Comment           = Text + 3
    Text_SampleFileName    = Text + 4
    Text_URL               = Text + 5
    Text_CommentRTF        = Text + 6
    Text_Version           = Text + 7
    Text_PluginName        = Text + 9
    Text_EffectChanName    = Text + 12
    Text_MIDICtrls         = Text + 16
    Text_Delay             = Text + 17
    Text_TS404Params       = Text + 18
    Text_DelayLine         = Text + 19
    Text_NewPlugin         = Text + 20
    Text_PluginParams      = Text + 21
    Text_ChanParams        = Text + 23
    Text_EnvLfoParams      = Text + 26
    Text_BasicChanParams   = Text + 27
    Text_OldFilterParams   = Text + 28
    Text_AutomationData    = Text + 31
    Text_PatternNotes      = Text + 32
    Text_ChanGroupName     = Text + 39
    Text_PlayListItems     = Text + 41
    Text_Time              = Text + 45
  end

  TIME_ORIGIN = Time.new(1899, 12, 30)

  def self.parse(path)
    new.parse(path)
  end

  def parse(path : String)
    File.open(path) { |io| parse(io) }
  end

  def parse(io : IO)
    parse_header(io)
    parse_project(io)
  end

  protected def read_uint16(io)
    io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
  end

  protected def read_uint32(io)
    io.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
  end

  protected def parse_header(io)
    Policy::HeaderIdentifier.call(read_uint32(io))
    Policy::HeaderLength.call(read_uint32(io))
    Policy::HeaderFormat.call(read_uint16(io))
  end

  protected def parse_project(io)
    project = Project.new

    project.channels = read_uint16(io)
    project.ppq      = read_uint16(io)

    data_identifier = io.read_string(4)
    return project unless data_identifier == "FLdt"

    while event = parse_event(io)
      type, data = event

      if type == Event::Text_Time
        bytes = data.as(String).to_slice

        return project if bytes.size != 16

        started_at = IO::ByteFormat::LittleEndian.decode(Float64, bytes[0, 8])
        started_at = Time::Span.new(1, 0, 0, 0) * started_at
        started_at = TIME_ORIGIN + started_at

        work_time = IO::ByteFormat::LittleEndian.decode(Float64, bytes[8, 8])
        work_time = Time::Span.new(1, 0, 0, 0) * work_time

        project.started_at = started_at
        project.work_time  = work_time

        break
      end

    end

    project
  end

  protected def parse_event(io)
    type = io.read_byte
    return if type.nil?
    type = Event.new(type.to_i32)

    data = io.read_byte
    return if data.nil?
    data = data.to_u32

    if (type >= Event::Word && type < Event::Text)
      data_partial = io.read_byte
      return if data_partial.nil?
      data_partial = data_partial.to_u32

      data = data | (data_partial << 8)
    end

    if (type >= Event::Int && type < Event::Text)
      data_partial = io.read_byte
      return if data_partial.nil?
      data_partial = data_partial.to_u32

      data = data | (data_partial << 16)

      data_partial = io.read_byte
      return if data_partial.nil?
      data_partial = data_partial.to_u32

      data = data | (data_partial << 24)
    end

    if (type >= Event::Text)
      length = data & 0x7F
      shift = 0

      while (data & 0x80) == 1
        data = io.read_byte
        return if data.nil?
        data = data.to_u32

        length = length | ((data & 0x7F) << (shift+=7))
      end

      data = io.read_string(length)
      return if data.nil?
    end

    { type, data }
  end

end

