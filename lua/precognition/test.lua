local function watch_table(t, key, interval, callback)
    local last_value = t[key]
    vim.loop.new_timer():start(0, interval, function()
        if last_value ~= t[key] then
            last_value = t[key]
            vim.schedule(callback(t[key]))
        end
    end)
end

watch_table(vim.v, "count1", vim.o.updatetime, function(value)
    if value > 1 then
        vim.print("count : " .. value)
    end
end)
