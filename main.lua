local GUI = {}
local sw, sh = guiGetScreenSize()
local w, h = 500, 400
local x, y = sw/2-w/2, sh/2-h/2
local logs = "Client File Compiler\nSelect resource to compile."

function openGUI (datas)
	if GUI.window and isElement(GUI.window) then
		return
	end
	GUI.window = guiCreateWindow(x, y, w, h, "Nexus Compiler", false)
	guiWindowSetSizable (GUI.window, false)
	GUI.version = guiCreateLabel(w-100, h-25, 100, 25, "By: Idarrr - V 1.0", false, GUI.window)
	GUI.list = guiCreateGridList (5, 30, 220, h-40, false, GUI.window)
	guiGridListAddColumn (GUI.list, "Resource", 0.6)
	guiGridListAddColumn (GUI.list, "State", 0.25)
	for i, v in pairs(datas) do
		local row = guiGridListAddRow (GUI.list, v.name, v.state)
		guiGridListSetItemText (GUI.list, row, 1, v.name, false, false )
	end

	GUI.log = guiCreateMemo(235, 30, w-235-5, 150, logs, false, GUI.window)
	guiMemoSetReadOnly (GUI.log, true)
	GUI.files = guiCreateGridList (235, 30+155, w-235-5, 150, false, GUI.window)
	guiGridListAddColumn (GUI.files, "Client file", 0.8)
	guiSetVisible(GUI.files, false)
	GUI.button = {}
	GUI.button[1] = guiCreateButton (235, 190+150, 80, 35, "Compile", false, GUI.window)
	addEventHandler ( "onClientGUIClick", GUI.button[1],
		function ()
			local index = guiGridListGetSelectedItem(GUI.list)
			local res = guiGridListGetItemText(GUI.list, index, 1)
			triggerServerEvent("compiler:start", localPlayer, res)
		end,
	false )
	GUI.button[2] = guiCreateButton (325, 190+150, 80, 35, "Compile and Restart", false, GUI.window)
	addEventHandler ( "onClientGUIClick", GUI.button[2],
		function ()
			local index = guiGridListGetSelectedItem(GUI.list)
			local res = guiGridListGetItemText(GUI.list, index, 1)
			triggerServerEvent("compiler:start", localPlayer, res, true)
		end,
	false )
	GUI.button[3] = guiCreateButton (415, 190+150, 80, 35, "Close", false, GUI.window)
	addEventHandler ( "onClientGUIClick", GUI.button[3],
		function ()
			closeGUI ()
		end,
	false )
	for i, v in pairs(GUI.button) do
		--
		guiSetVisible(v, false)
	end

	addEventHandler ( "onClientGUIClick", GUI.list, 
		function ()
			local index = guiGridListGetSelectedItem(GUI.list)
			if index == -1 then
				guiSetVisible(GUI.files, false)
				for i, v in pairs(GUI.button) do
					guiSetVisible(v, false)
				end
				return
			end
			local res = guiGridListGetItemText(GUI.list, index, 1)
			for i, v in pairs(datas) do
				if v.name == res then
					addLog ("Resource: "..res..". Client file :"..#v["files"].." file(s).")
					onResSelect (v["files"])
					break
				end
			end
			guiSetVisible(GUI.files, true)
			for i, v in pairs(GUI.button) do
				guiSetVisible(v, true)
			end
		end,
	false )
end
addEvent("compiler:open", true)
addEventHandler("compiler:open", root, openGUI)

function onResSelect (files)
	guiGridListClear (GUI["files"])
	for i, v in pairs(files) do
		guiGridListAddRow (GUI["files"], v)
	end
end

function addLog (text)
	local text = tostring(text)
	logs = logs.."\n"..text
	if GUI.log then
		guiSetText(GUI.log, logs)
		local ci = string.len(logs)
		guiMemoSetCaretIndex(GUI.log,ci)
	end
end
addEvent("compiler:addLog", true)
addEventHandler("compiler:addLog", root, addLog)

function closeGUI ()
	if GUI.window and isElement(GUI.window) then
		destroyElement(GUI.window)
	end
end
