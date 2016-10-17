local random = {}
random.__index = random

function random:new(seed)
	local o = {}
	setmetatable(o, random)
	
	o.seed = seed
	
	o:reset()
	
	return o
end

function random:reset()
	self._seedarray = {}
	local num2 = 0x9a4ec86 - math.abs(self.seed)
	self._seedarray[0x37] = num2
	local num3 = 1
    for i = 1, 0x37-1 do
        local index = (0x15 * i) % 0x37
        self._seedarray[index] = num3
        num3 = num2 - num3
        if (num3 < 0) then
            num3 = num3 + 0x7fffffff
        end
        num2 = self._seedarray[index]
    end
	
    for  j = 1, 4 do
        for  k = 1,0x37 do
            self._seedarray[k] = self._seedarray[k] - self._seedarray[1+((k+30)%0x37)]
            if (self._seedarray[k] < 0) then
                self._seedarray[k] = self._seedarray[k] + 0x7fffffff
            end
        end
    end
	
    self._next = 0
    self._nextp = 0x15
end

function random:_internalsample()
    local index = self._next + 1
    local indexp = self._nextp + 1
	
	if index > 0x37 then index = 1 end
	if indexp > 0x37 then indexp = 1 end
	
    local num = self._seedarray[index] - self._seedarray[indexp]
	if num == 0x7fffffff then num = num - 1 end
    if num < 0 then num = num + 0x7fffffff end
	
    self._seedarray[index] = num
    self._next = index
    self._nextp = indexp
	
	if num < 0 then
		self.seed = self.seed + 1
		self:reset()
		
		num = self:_internalsample()
	end

    return num
end

function random:next()
    return self:_internalsample()
end

function random:nextratio()
	local res = self:_internalsample() / 0x7fffffff
    return res
end

function random:nextint(min,max)
	return math.floor(self:nextratio() * (max - min) + min + 0.5)
end

local _instance = nil
function random:getinstance()
	_instance = _instance or random:new(math.floor(os.time()) % 100000)
	return _instance
end

return random