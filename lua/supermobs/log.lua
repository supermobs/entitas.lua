log = {}
log.d = function( ... ) print("D", ...) --[[print(debug.traceback())]] end
log.i = function( ... ) print("I", ...) --[[print(debug.traceback())]] end
log.w = function( ... ) print("W", ...) --[[print(debug.traceback())]] end
log.e = function( ... ) print("E", ...) --[[print(debug.traceback())]] end