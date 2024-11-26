CoreTicker = {}
CoreTicker._timer = nil
CoreTicker._stamp = 0
CoreTicker.Interval = 1/60
CoreTicker.DelayedActions = {}
CoreTicker.AttachedActions = {}

function CoreTicker._tick()
    CoreTicker._stamp = CoreTicker._stamp + 1
    UnitMgr.Update()
    ProjectilMgr.Update()
    MapObjectMgr.Update()
    CoreTicker.DoDelayedActions()
    CoreTicker.DoAttachedActions()
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

function CoreTicker.AttachAction(action, interval, id)
    if (CoreTicker.AttachedActions[id] == nil) then
        CoreTicker.AttachedActions[id] = {
            func = action,
            interval = interval or CoreTicker.Interval,
            elapsed = 0
        }
    else
        print('action attach failed: same id')
    end
end

function CoreTicker.DoAttachedActions()
    for id,act in pairs(CoreTicker.AttachedActions) do
        act.elapsed = act.elapsed + CoreTicker.Interval
        if (act.elapsed > act.interval) then
            act.elapsed = act.elapsed - act.interval
            act.func(act.interval)
        end
    end
end

function CoreTicker.DetachAction(id)
    if (CoreTicker.AttachedActions[id] == nil) then
        print('action detach failed: id not found')
    else
        CoreTicker.AttachedActions[id] = nil
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

