local timeutils = {}

function timeutils.now()
	-- now just for windows
	return os.clock()
end

return timeutils