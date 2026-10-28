--[[ init: input handling, lifecycle, startup ]]
local M = ...
local S, cfg, FLAT = M.S, M.cfg, M.FLAT
local UIS, RunService, Players = M.UIS, M.RunService, M.Players
local cmdBox = M.ui.cmdBox

M.connect(UIS.InputBegan, function(i, gp)
	if i.UserInputType ~= Enum.UserInputType.Keyboard then return end

	-- key capture (rebinding)
	if M.capturing then
		local cb = M.capturing
		M.capturing = nil
		cb(i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode.Name or nil)
		return
	end

	-- command bar editing keys
	if cmdBox:IsFocused() then
		if i.KeyCode == Enum.KeyCode.Tab then task.defer(M.completeTop)
		elseif i.KeyCode == Enum.KeyCode.Up then M.historyStep(1)
		elseif i.KeyCode == Enum.KeyCode.Down then M.historyStep(-1)
		elseif i.KeyCode == Enum.KeyCode.Escape then cmdBox:ReleaseFocus() end
		return
	end
	if gp then return end

	local name = i.KeyCode.Name
	if name == S.menuKey then M.ui.gui.Enabled = not M.ui.gui.Enabled; return end
	if i.KeyCode == Enum.KeyCode.Escape then if M.hideConfig then M.hideConfig() end; return end
	if name == S.cmdKey then
		if not M.isOpen then M.setMenu(true) end
		task.spawn(function()
			RunService.RenderStepped:Wait()
			cmdBox:CaptureFocus()
			cmdBox.Text = ""
		end)
		return
	end
	for _, ch in ipairs(FLAT) do
		if ch.key == name and ch.setState then M.Features.userToggle(ch) end
	end
end)

M.connect(Players.PlayerAdded, function() if M.cur == 3 and M.isOpen then M.refreshPlayers() end end)
M.connect(Players.PlayerRemoving, function() if M.cur == 3 and M.isOpen then task.defer(M.refreshPlayers) end end)

-- font / radius / theme settings were applied before the UI existed
M.applyFonts()
M.applyRadius()

M.cur = 1
if S.rememberPage and M.pages[M.saved.page or 1] then M.cur = M.saved.page or 1 end
local info = M.PINFO[M.cur]
M.setPage(M.cur)
if S.autoOpen then M.setMenu(true) end

print(string.format("[CheatMenuUI %s] loaded. Click the bar to open · %s = command bar · %s hides/shows.", M.Version, M.keyLabel(S.cmdKey), M.keyLabel(S.menuKey)))
