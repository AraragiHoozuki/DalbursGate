FrameLoader = {
    OnLoadTimer = function ()
        for _,v in ipairs(FrameLoader) do v() end

    end
    ,OnLoadAction = function()
        TimerStart(FrameLoader.Timer, 0, false, FrameLoader.OnLoadTimer)
     end
}
function FrameLoaderAdd(func)
    if not FrameLoader.Timer then
        FrameLoader.Trigger = CreateTrigger()
        FrameLoader.Timer = CreateTimer()
        TriggerRegisterGameEvent(FrameLoader.Trigger, EVENT_GAME_LOADED)
        TriggerAddAction(FrameLoader.Trigger, FrameLoader.OnLoadAction)
    end
    table.insert(FrameLoader, func)
end