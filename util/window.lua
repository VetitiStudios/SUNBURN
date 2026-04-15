local window = {}

function window.create(w, h, title)
    return _G.window_impl.create(w, h, title)
end

function window.should_close(obj)
    return _G.window_impl.should_close(obj)
end

function window.swap(obj)
    _G.window_impl.swap(obj)
end

function window.destroy(obj)
    _G.window_impl.destroy(obj)
end

return window
