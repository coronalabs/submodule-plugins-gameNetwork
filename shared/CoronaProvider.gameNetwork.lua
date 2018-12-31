local Provider = require "CoronaProvider"

local Class = Provider:newClass( "CoronaProvider.gameNetwork" )

-- Default implementations
local function defaultFunction()
	print( "WARNING: The 'gameNetwork' library is not available on this platform." )
end

Class.init = defaultFunction
Class.request = defaultFunction
Class.show = defaultFunction

-- Return an instance
return Class
