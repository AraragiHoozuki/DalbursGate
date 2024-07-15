CoreTicker = {}
CoreTicker._timer = nil
CoreTicker._stamp = 0
CoreTicker.Interval = 1/60
CoreTicker.DelayedActions = {}

function CoreTicker._tick()
    CoreTicker._stamp = CoreTicker._stamp + 1
    UnitMgr.Update()
    ProjectilMgr.Update()
    CoreTicker.DoDelayedActions()
end

function CoreTicker.RegisterDelayedAction(action, delay_time)
    local target_stamp = math.floor(CoreTicker._stamp + delay_time/CoreTicker.Interval)
    if (CoreTicker.DelayedActions[target_stamp] == nil) then
        CoreTicker.DelayedActions[target_stamp] = {}
    end
    table.insert(CoreTicker.DelayedActions[target_stamp], action)
end

function CoreTicker.DoDelayedActions()
    local actions = CoreTicker.DelayedActions[CoreTicker._stamp]
    if (actions ~= nil) then
        for _,act in ipairs(actions) do
            act()
        end
        CoreTicker.DelayedActions[CoreTicker._stamp] = nil
    end
end

function CoreTicker.RestartStamp()
    local stamp = CoreTicker._stamp
    CoreTicker._stamp = 0
    local newDelayedActions = {}
    for k,v in pairs(CoreTicker.DelayedActions) do
        newDelayedActions[k-stamp] = v
        CoreTicker.DelayedActions[k] = nil
    end
end

function CoreTicker.Init(interval)
    if (interval ~= nil and interval > 0) then CoreTicker.Interval = interval end
    CoreTicker._timer = CreateTimer()
    TimerStart(CoreTicker._timer, CoreTicker.Interval, true, CoreTicker._tick)
end

