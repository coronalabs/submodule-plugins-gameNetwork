local Library = require "CoronaLibrary"

-- Create library
local lib = Library:new{ name='gameNetwork', publisherId='com.coronalabs', usesProviders=true }

local didInitProvider = {}

lib.init = function( ... )
	local result = false

	local providerName = ...
	if not providerName then
		providerName = "corona"
	end
	local shouldInit = type( providerName ) == "string" and not didInitProvider[providerName]

	if shouldInit then
		if lib:setCurrentProvider( providerName ) then
			result = lib:getProvider().init( ... )
			didInitProvider[providerName] = result
		end
	else
		if providerName then
			print( "WARNING: gameNetwork.init() was already called for " .. providerName .. "." )
		else
			print( "WARNING: gameNetwork.init() expects first parameter to be a string for the providerName." )
		end
	end

	return result
end

-- Return an instance
return lib
