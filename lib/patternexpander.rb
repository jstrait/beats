class InvalidFlowError < RuntimeError; end

class PatternExpander
  BARLINE = "|"
  TICK = "-"
  
  def self.expand_pattern(flow, pattern)
    unless self.valid_flow? flow
      raise InvalidFlowError, "Invalid flow"
    end
    
    flow = flow.delete(BARLINE)
    
    # Count number of :
    # If odd, then there's an implicit : at the beginning of the pattern.
    number_of_colons = flow.scan(/:/).length
    if number_of_colons % 2 == 1
      # TODO: What if flow[0] is not -?
      flow[0] = ":"  # Make the implicit : at the beginning explicit
    end
    
    regex = /:[-]*:[0-9]*/
    repeat_frames = []
    lower_bound = 0
    start = flow[lower_bound...flow.length] =~ regex
    while start != nil do
      h = {}
      str = flow[lower_bound...flow.length].match(regex).to_s
      h[:range] = (lower_bound + start)..(lower_bound + start + str.length - 1)
      num_repeats = str.match(/[0-9]+/).to_s
      h[:repeats] = (num_repeats == "") ? 2 : num_repeats.to_i
      repeat_frames << h
      lower_bound += str.length
      
      start = flow[lower_bound...flow.length] =~ regex
    end
    
    repeat_frames.reverse.each do |frame|
      pattern.tracks.each do |name, track|
        range = frame[:range]
        track.rhythm[range] = track.rhythm[range] * frame[:repeats]
      end
    end
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
end