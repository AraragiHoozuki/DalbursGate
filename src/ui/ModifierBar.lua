require('ui.UITicker')
UI = UI or {}

UI.ModifierBar = {
    Enabled = true,
    Container = nil,
    SelectedUnit = nil,
    MaxIconNum = 15,
    IconSize = 0.02,
    Icons = {},
    Tooltips = {},
    Key = 'ModifierBar'
}

UI.ModifierBar.Init = function()
    local container = BlzCreateFrameByType("FRAME", "Container", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
    UI.ModifierBar.Container = container
    for i = 1, UI.ModifierBar.MaxIconNum, 1 do
        local icon = BlzCreateFrameByType("BACKDROP", "Button", container, "", i)
        local iconHover = BlzCreateFrameByType("FRAME", "ButtonFrame", icon, "", 0)
        BlzFrameSetAllPoints(iconHover, icon)
        local tooltipBackground = BlzCreateFrame("QuestButtonBaseTemplate", icon, 0, i)
        local tooltipText = BlzCreateFrameByType("TEXT", "ModifierTooltipText", tooltipBackground, "", i)

        BlzFrameSetSize(icon, UI.ModifierBar.IconSize, UI.ModifierBar.IconSize)
        BlzFrameSetAbsPoint(icon, FRAMEPOINT_TOPLEFT, 0.24 + (i - 1) * UI.ModifierBar.IconSize, 0.16)
        BlzFrameSetTexture(icon, "ReplaceableTextures\\CommandButtons\\BTNHeroPaladin", 0, true)

        BlzFrameSetSize(tooltipText, 0.24, 0)
        BlzFrameSetPoint(tooltipBackground, FRAMEPOINT_BOTTOMLEFT, tooltipText, FRAMEPOINT_BOTTOMLEFT, -0.01, -0.01)
        BlzFrameSetPoint(tooltipBackground, FRAMEPOINT_TOPRIGHT, tooltipText, FRAMEPOINT_TOPRIGHT, 0.01, 0.01)

        BlzFrameSetTooltip(iconHover, tooltipBackground)
        BlzFrameSetPoint(tooltipText, FRAMEPOINT_BOTTOM, icon, FRAMEPOINT_TOP, 0, 0.01)
        BlzFrameSetEnable(tooltipText, false)

        UI.ModifierBar.Icons[i] = icon
        UI.ModifierBar.Tooltips[i] = tooltipText
        BlzFrameSetText(tooltipText, 'Empty')
        BlzFrameSetVisible(icon, false)
    end
    BlzFrameSetVisible(container, false)
    local updateHandler = function()
        if UI.ModifierBar.SelectedUnit == nil then return end
        local index = 1
        for _, mod in pairs(UnitWrapper.Get(UI.ModifierBar.SelectedUnit).modifiers) do
            if index <= 15 then
                if not mod.hidden then
                    BlzFrameSetVisible(UI.ModifierBar.Icons[index], true)
                    BlzFrameSetTexture(UI.ModifierBar.Icons[index], mod.icon, 0, true)
                    BlzFrameSetText(UI.ModifierBar.Tooltips[index], mod:GetDescription())
                    index = index + 1
                end
            else
                break
            end
        end
        for i = index, UI.ModifierBar.MaxIconNum, 1 do
            BlzFrameSetVisible(UI.ModifierBar.Icons[i], false)
        end
    end

    local trig = CreateTrigger()
    TriggerAddAction(trig, function()
        if (GetTriggerPlayer() == GetLocalPlayer()) then
            if (GetTriggerUnit() ~= nil) then
                BlzFrameSetVisible(container, true)
                UI.ModifierBar.SelectedUnit = GetTriggerUnit()
            else
                BlzFrameSetVisible(container, false)
                UI.ModifierBar.SelectedUnit = nil
            end
        end
    end)
    local player = 0
    repeat
        TriggerRegisterPlayerSelectionEventBJ(trig, Player(player), true)
        --TriggerRegisterPlayerSelectionEventBJ(trig, Player(index), false)
        player = player + 1
    until player == bj_MAX_PLAYER_SLOTS

    UITicker.AddHandler(UI.ModifierBar.Key, updateHandler)
end

do
    if UI.ModifierBar.Enabled == true then
        UI.ModifierBar.Init()
    end
end
