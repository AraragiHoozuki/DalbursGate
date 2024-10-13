 UI = UI or {}

 UI.HideDefaultSettings = {
    UnitInfo = false,
    BuffBar = true
}

function UI.HideUnitInfoPanels()
    local function CustomStatMoveOutOfScreen(frame)
        BlzFrameClearAllPoints(frame)
        BlzFrameSetAbsPoint(frame, FRAMEPOINT_CENTER, 3, 0)
    end
    for index = 0, 5, 1 do
        CustomStatMoveOutOfScreen(BlzGetFrameByName("InfoPanelIconBackdrop", index))
    end
    CustomStatMoveOutOfScreen(BlzGetFrameByName("InfoPanelIconHeroIcon", 6))
    CustomStatMoveOutOfScreen(BlzGetFrameByName("InfoPanelIconAllyTitle", 7))
    CustomStatMoveOutOfScreen(BlzGetFrameByName("InfoPanelIconAllyGoldIcon", 7))
end

function UI.HideBuffBar()
    -- hide buff bar
    local newParent = BlzCreateFrameByType("SIMPLEFRAME", "", BlzGetFrameByName("ConsoleUI", 0), "", 0)
    BlzFrameSetVisible(newParent, false)
    BlzFrameSetParent(BlzGetOriginFrame(ORIGIN_FRAME_UNIT_PANEL_BUFF_BAR, 0), newParent)
end



do
    if (UI.HideDefaultSettings.UnitInfo) then
        UI.HideUnitInfoPanels()
    end
    if (UI.HideDefaultSettings.BuffBar) then
        UI.HideBuffBar()
    end
end