class InvalidFlowError < RuntimeError; end

class PatternExpander
  BARLINE = "|"
  TICK = "-"
  
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