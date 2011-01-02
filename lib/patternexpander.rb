class InvalidFlowError < RuntimeError; end

# This class is used for an experimental feature that allows specifying repeats inside of
# individual patterns, instead of the song flow. This feature is currently disabled, so for
# the time being this class is dead code.
#
# TODO: The expand_pattern method in this class should probably be moved to the Pattern class.
# This class would then go away.
class PatternExpander
  BARLINE = "|"
  TICK = "-"
  REPEAT_FRAME_REGEX = /:[-]*:[0-9]*/
  NUMBER_REGEX = /[0-9]+/
  
  # TODO: What should happen if flow is longer than pattern?
  # Either ignore extra flow, or add trailing .... to each track to match up?
  def self.expand_pattern(flow, pattern)
    unless self.valid_flow? flow
      raise InvalidFlowError, "Invalid flow"
    end
    
    flow = flow.delete(BARLINE)
    
    # Count number of :
    # If odd, then there's an implicit : at the beginning of the pattern.
    # TODO: What if the first character in the flow is already :
    #       That means repeat the first step twice, right?
    number_of_colons = flow.scan(/:/).length
    if number_of_colons % 2 == 1
      # TODO: What if flow[0] is not '-'
      flow[0] = ":"  # Make the implicit : at the beginning explicit
    end
    
    repeat_frames = parse_flow_for_repeat_frames(flow)
    
    repeat_frames.reverse.each do |frame|
      pattern.tracks.each do |name, track|
        range = frame[:range]
        
        # WARNING: Don't change the three lines below to:
        #   track.rhythm[range] = whatever
        # When changing the rhythm like this, rhythm=() won't be called,
        # and Track.beats won't be updated as a result.
        new_rhythm = track.rhythm
        new_rhythm[range] = new_rhythm[range] * frame[:repeats]
        track.rhythm = new_rhythm
      end
    end
    
    return pattern
  end
  
  # TODO: Return more specific info on why flow isn't valid
  def self.valid_flow?(flow)
    flow = flow.delete(BARLINE)
    flow = flow.delete(TICK)
    
    # If flow contains any characters other than : and [0-9], it's invalid.
    if flow.match(/[^:0-9]/) != nil
      return false
    end
    
    # If flow contains nothing but :, it's always valid.
    if flow == ":" * flow.length
      return true
    end
    
    # If flow DOESN'T contain a :, it's not valid.
    if flow.match(/:/) == nil
      return false
    end
    
    segments = flow.split(/[0-9]+/)
    
    # Ignore first segment
    segments[1...segments.length].each do |segment|
      if segment.length % 2 == 1
        return false
      end
    end
    
    return true
  end
  
private

  def self.parse_flow_for_repeat_frames(flow)
    repeat_frames = []
    lower_bound = 0
    frame_start_index = flow[lower_bound...flow.length] =~ REPEAT_FRAME_REGEX
    while frame_start_index != nil do
      str = flow[lower_bound...flow.length].match(REPEAT_FRAME_REGEX).to_s
      
      range_start = lower_bound + frame_start_index
      range_end = range_start + str.length - 1
      
      num_repeats = str.match(NUMBER_REGEX).to_s
      num_repeats = (num_repeats == "") ? 2 : num_repeats.to_i
      
      repeat_frame = {}
      repeat_frame[:range] = range_start..range_end
      repeat_frame[:repeats] = num_repeats
      repeat_frames << repeat_frame
      
      lower_bound += frame_start_index + str.length
      frame_start_index = flow[lower_bound...flow.length] =~ REPEAT_FRAME_REGEX
    end
    
    return repeat_frames
  end
end
