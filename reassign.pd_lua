local reassign = pd.Class:new():register("reassign")

function reassign:initialize(sel, atoms)
    self.inlets = {SIGNAL, SIGNAL}
    self.outlets = {SIGNAL}
    self.fmin = 20
    self.fmax = 22050
    self.log_min = nil
    self.scale_factor = nil
    self.half_block = nil
    -- 输出缓冲区
    self.out_buffer = {}
    return true
end

function reassign:dsp(samplerate, blocksize)
    self.sr = samplerate
    self.blocksize = blocksize
    self.half_block = math.floor(blocksize / 2)
    self.fmax = self.sr / 2
 	
    self.log_min = math.log(self.fmin)
    local log_range = math.log(self.fmax) - self.log_min
    if log_range <= 0 then log_range = 1 end
    self.scale_factor = self.half_block / log_range

   -- 先全部填充0
    for i = 1, self.blocksize do
        self.out_buffer[i] = 0
    end
end

function reassign:perform(in1, in2)
    -- in1: Frequency Stream
    -- in2: Magnitude Stream

    local out = self.out_buffer
    local fmin = self.fmin
    local log_min = self.log_min
    local scale = self.scale_factor
    local limit = self.half_block
    local log = math.log
    local floor = math.floor
    
    -- 1. Reset
    for i = 1, #out do
        out[i] = 0
    end
    
    -- 2. Mag
    for i = 1, #in1 do
        local f = in1[i]
        if f > fmin then
            local log_val = log(f)
            local target_idx = floor((log_val - log_min) * scale) + 1
            if target_idx >= 1 and target_idx <= limit then
		                -- accumulate
                out[target_idx] = out[target_idx] + in2[i]
            end
        end
    end
    return out
end
