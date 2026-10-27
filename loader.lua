--[[
	CheatMenuUI loader
	Put the whole CheatMenuUI folder in your executor's workspace, then run:
		loadstring(readfile("CheatMenuUI/loader.lua"))()
	Or host the files (e.g. GitHub raw) and set BASE_URL below.
]]
local ROOT = "CheatMenuUI/"
local BASE_URL = "https://raw.githubusercontent.com/FISHYSHUN/NewRepository/main/" -- e.g. "https://raw.githubusercontent.com/you/repo/main/CheatMenuUI/"
local MODULES = { "core", "config", "themes", "kit", "features", "commands", "shell", "pages", "init" }

pcall(function()
	if getgenv and getgenv().CheatMenuUI then getgenv().CheatMenuUI.Destroy() end
end)

local M = {}
pcall(function() getgenv().CheatMenuUI = M end)

local function fetch(name)
	if readfile and isfile and isfile(ROOT .. name .. ".lua") then
		return readfile(ROOT .. name .. ".lua")
	end
	if BASE_URL then
		local ok, res = pcall(function() return game:HttpGet(BASE_URL .. name .. ".lua") end)
		if ok then return res end
	end
end

for _, name in ipairs(MODULES) do
	local src = fetch(name)
	if not src then
		warn("[CheatMenuUI] missing module: " .. name .. ".lua (expected in workspace/" .. ROOT .. ")")
		if M.Destroy then M.Destroy() end
		return
	end
	local fn, err = loadstring(src, "=" .. name)
	if not fn then
		warn("[CheatMenuUI] syntax error in " .. name .. ": " .. tostring(err))
		if M.Destroy then M.Destroy() end
		return
	end
	local ok, e = pcall(fn, M)
	if not ok then
		warn("[CheatMenuUI] runtime error in " .. name .. ": " .. tostring(e))
		if M.Destroy then M.Destroy() end
		return
	end
end
