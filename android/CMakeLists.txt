cmake_minimum_required(VERSION 3.4.1)
project( gameNetwork )
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384")
include_directories( 
	${LuaIncludePath}
	${CORONA_ROOT}/librtt/Corona
)

lua_2_c("${CORONA_ROOT}/plugins/gameNetwork/shared/gameNetwork.lua")
lua_2_c("${CORONA_ROOT}/plugins/gameNetwork/shared/CoronaProvider.gameNetwork.lua")

add_library( gameNetwork SHARED 
				../shared/CoronaGameNetworkLibrary.cpp
				${Lua2CppOutputDir}/gameNetwork.c
				${Lua2CppOutputDir}/CoronaProvider.gameNetwork.c )

target_link_libraries ( gameNetwork lua corona )
