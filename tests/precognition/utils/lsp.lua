local M = {}

M.messages = {}

function M.server()
    local closing = false
    local srv = {}

    function srv.request(method, params, handler)
        table.insert(M.messages, { method = method, params = params })
        if method == "initialize" then
            handler(nil, {
                capabilities = {
                    inlayHintProvider = true,
                },
            })
        elseif method == "shutdown" then
            handler(nil, nil)
        elseif method == "textDocument/inlayHint" then
            handler(nil, {
                {
                    position = { line = 0, character = 3 },
                    label = { { value = "foo" } },
                    paddingLeft = true,
                },
            })
        else
            assert(false, "Unhandled method: " .. method)
        end
    end

    function srv.notify(method, params)
        table.insert(M.messages, { method = method, params = params })
        if method == "exit" then
            closing = true
        end
    end

    function srv.is_closing()
        return closing
    end

    function srv.terminate()
        closing = true
    end

    return srv
end

function M.Reset()
    M.messages = {}
end

return M
