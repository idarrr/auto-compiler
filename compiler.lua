--[[
AUTO COMPILER

WE DONT GIVE ALL ADMINS PERMISSION TO USE THIS.
SO IF YOU WANT TO GIVE ACCESS TO SOMEONE TO USE THIS, PLEASE ADD THE ACCOUNT NAME TO ACCESS TABLE

]]
local access = {
	idarrr = true,
	Deihim007 = true
}
local QUEUE = {
	compiling = false,
	restarting = {},
}


function openGUI (thePlayer)

	local account = getPlayerAccount (thePlayer)
	if not account or isGuestAccount(account) then return end
	local accname = getAccountName(account)
	if not access[accname] then
		outputDebugString("COMPILER: Access denied for account"..accname)
		return
	end

	local res = getResources()
	local data = {}
	for i, v in pairs(res) do
		local name = getResourceName(v)
		local state = getResourceState(v)
		local meta = xmlLoadFile(":".. name .."/meta.xml")
		local child = xmlNodeGetChildren(meta)
		local files = {}
		for k, f in pairs(child) do
			local name = xmlNodeGetName (f)
			if name == "script" then
				local attr = xmlNodeGetAttribute (f, "type")
				if attr == "client" then
					local path = xmlNodeGetAttribute (f, "src")
					table.insert(files, path)
				end
			end
		end
		table.insert(data,{
				name = name,
				state = state,
				files = files
			})

	end
	triggerClientEvent(thePlayer, "compiler:open", thePlayer, data)
end
addCommandHandler("compile", openGUI)

function compileResource (resname, restart)
	local client = client
	local account = getPlayerAccount (client)
	if not account or isGuestAccount(account) then return end
	local accname = getAccountName(account)
	if not access[accname] then
		outputDebugString("COMPILER: Access denied for account"..accname)
		return
	end

	local resname = tostring(resname)
	local meta = xmlLoadFile(":".. resname .."/meta.xml")
	if not meta then
		triggerClientEvent(client, "compiler:addLog", client, "Can't find meta.xml. Compile canceled.")
		--outputDebugString("Can't find meta.xml. Compile canceled.")
		return
	end
	triggerClientEvent(client, "compiler:addLog", client, "PLEASE DON'T DO ANY OPERATION UNTIL COMPILE IS DONE!\nChecking file...")
	--outputDebugString("COMPILER: PLEASE DON'T DO ANY OPERATION UNTIL COMPILE IS DONE!")
	outputDebugString("COMPILER: Checking file...")
	local count = 0
	done = 0
	local child = xmlNodeGetChildren(meta)
	for i, v in pairs(child) do
		local name = xmlNodeGetName (v)
		if name == "script" then
			local attr = xmlNodeGetAttribute (v, "type")
			if attr == "client" then
				local path = xmlNodeGetAttribute (v, "src")
				local realpath = ":".. resname .."/"..path..""
				local luafile = path:sub(-3, -1) == "lua"
				local luacfile = path:sub(-4, -1) == "luac"
				if luafile then
					local file = fileOpen(realpath)
					local size = fileGetSize (file)
					if file and (size ~= 0) then
						local newpath = realpath.."c"
						fetchRemote( "http://luac.mtasa.com/?compile=1&debug=0&obfuscate=2",  
						function(data)  
							local compiled = fileCreate ( newpath ) 
							if compiled then

								fileWrite(compiled, data)  
								fileFlush(compiled) 
								fileClose(compiled)
								triggerClientEvent(client, "compiler:addLog", client, realpath.." compiled to ".. newpath)
								--outputDebugString("COMPILER: "..realpath.." compiled to ".. newpath .."")
								done = done + 1
							end 
						end, fileRead(file, fileGetSize ( file )) , true )--fileLoad(FROM) 
						--https://luac.mtasa.com/api/ 
						count = count + 1
						fileClose(file)
						local edit = xmlNodeSetAttribute (v, "src", path.."c")
						xmlSaveFile(meta)
					elseif size == 0 then
						triggerClientEvent(client, "compiler:addLog", client, "Skipping file "..realpath..". Reason: file is empty.")
					end
				elseif luacfile then
					local path = path:sub(0, -2)
					local realpath = ":".. resname .."/"..path..""
					if fileExists(realpath) then
						local file = fileOpen(realpath)
						if file then
							local newpath = realpath.."c"
							fetchRemote( "http://luac.mtasa.com/?compile=1&debug=0&obfuscate=2",  
							function(data)  
								local compiled = fileCreate ( newpath ) 
								if compiled then 
									fileWrite(compiled, data)  
									fileFlush(compiled) 
									fileClose(compiled)
									triggerClientEvent(client, "compiler:addLog", client, ""..realpath.." replaced to ".. newpath .."")
									--outputDebugString("COMPILER: "..realpath.." replaced to ".. newpath .."")
									done = done + 1
								end 
							end, fileRead(file, fileGetSize ( file )) , true )--fileLoad(FROM) 
							--https://luac.mtasa.com/api/ 
							count = count + 1
							fileClose(file)
						end
					end
				end
			end
		end
	end
	xmlUnloadFile(meta)
	if count == 0 then
		outputDebugString("COMPILER: There is no client file to compile.")
	else
		checking = setTimer(
			function ()
				if count == done then
					triggerClientEvent(client, "compiler:addLog", client, "COMPILER: Done! "..done.." file has been compiled.")
					outputDebugString("COMPILER: Done! "..done.." file has been compiled.")
					killTimer(checking)
					if restart then
						resResource(client, resname)
					end
				end
			end
		, 500, 0)
		
	end
end
addEvent("compiler:start", true)
addEventHandler("compiler:start", root, compileResource)

function resResource(thePlayer, resname)
	if hasObjectPermissionTo (thePlayer, "command.restart", true) then
		local res = getResourceFromName(resname)
		if res then
			restartResource(res)
			QUEUE.restarting[""..resname..""] = thePlayer
			triggerClientEvent(thePlayer, "compiler:addLog", thePlayer, "Restarting ("..resname..")...")
		end
	end
end
addEvent("compiler:restart", true)
addEventHandler("compiler:restart", root, resResource)

addEventHandler("onResourceStart", root,
	function (res)
		local name = getResourceName(res)
		if name == "NGScompiler" then
			if not hasObjectPermissionTo (res, "function.restartResource", true) then
				outputDebugString("COMPILER: ACL function.restartResource request is needed.")
			end
			if not hasObjectPermissionTo (res, "function.fetchRemote", true) then
				outputDebugString("COMPILER: ACL function.fetchRemote request is needed.")
			end
			if not hasObjectPermissionTo (res, "general.ModifyOtherObjects", true) then
				outputDebugString("COMPILER: ACL general.ModifyOtherObjects request is needed.")
			end
		end
		if QUEUE.restarting[""..name..""] then
			local player = QUEUE.restarting[""..name..""]
			triggerClientEvent(player, "compiler:addLog", player, "Resource ("..name..") restarted.")
		end
	end
)
