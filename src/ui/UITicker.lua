UITicker = {
    timer = CreateTimer(),
    interval = 1/10,
    handlers = {},
    Init = function()
        TimerStart(UITicker.timer, UITicker.interval, true, function()
            for _,h in pairs(UITicker.handlers) do
                h(UITicker.interval)
            end
        end)
    end,
    AddHandler = function(key, h)
        if (UITicker.handlers[key] == nil) then
            UITicker.handlers[key] = h
        end
    end,
    DeleteHandler = function(key)
        if (UITicker.handlers[key] ~= nil) then
            UITicker.handlers[key] = nil
        end
    end
}

do
    UITicker.Init()
end