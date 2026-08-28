--[[
    PawZHub Error Handler  v1.5.0
    ==========================
    Centralized error translation. Every subsystem reports a typed
    Error to this module, and this module produces a user-friendly
    PawZHub-branded message that the loader prints + shows as a
    Roblox notification.

    Error kinds:
      LOADER, DETECTOR, API, KEY, VERSION, GAME_MODULE, UNKNOWN

    Usage:
        local Error = loadstring(... : core/error.lua)()
        local err = Error.new(Error.KIND.API, "connection refused")
        Error.report(err)             -- prints + toasts
        Error.report(err, { toast = false }) -- console only
]]

local ErrorHandler = {}

ErrorHandler.KIND = {
    LOADER      = "LOADER",
    DETECTOR    = "DETECTOR",
    API         = "API",
    KEY         = "KEY",
    VERSION     = "VERSION",
    GAME_MODULE = "GAME_MODULE",
    UNKNOWN     = "UNKNOWN",
}

-- default titles per kind
ErrorHandler.TITLES = {
    LOADER      = "PawZHub — Boot Error",
    DETECTOR    = "PawZHub — Unsupported Game",
    API         = "PawZHub — Network Error",
    KEY         = "PawZHub — Key Error",
    VERSION     = "PawZHub — Outdated Version",
    GAME_MODULE = "PawZHub — Module Error",
    UNKNOWN     = "PawZHub — Error",
}

function ErrorHandler.new(kind, detail, hint)
    return {
        kind   = ErrorHandler.KIND[kind] or kind or ErrorHandler.KIND.UNKNOWN,
        detail = tostring(detail or "Unknown error"),
        hint   = hint,
    }
end

-- Pretty-print a PawZHub block to the executor console.
-- A single block keeps the log readable: no raw stack traces.
local function formatBlock(err)
    local title = ErrorHandler.TITLES[err.kind] or "PawZHub"
    local lines = {
        "============================================================",
        "  " .. title,
        "------------------------------------------------------------",
        "  " .. err.detail,
    }
    if err.hint and err.hint ~= "" then
        lines[#lines + 1] = "  Tip: " .. err.hint
    end
    lines[#lines + 1] = "  Discord: https://discord.gg/pawzhub"
    lines[#lines + 1] = "============================================================"
    return table.concat(lines, "\n")
end

-- Send a Roblox notification (best-effort; ignore failures)
local function toast(err, duration)
    if not err or not err.detail then return end
    pcall(function()
        local title = ErrorHandler.TITLES[err.kind] or "PawZHub"
        local text  = err.detail
        if err.hint and err.hint ~= "" then
            text = text .. "  •  " .. err.hint
        end
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title   = title,
            Text    = text:sub(1, 180),
            Duration = tonumber(duration) or 8,
        })
    end)
end

-- Public: log + toast in one call
function ErrorHandler.report(err, opts)
    opts = opts or {}
    if not err then return end
    if not err.kind then err.kind = ErrorHandler.KIND.UNKNOWN end
    if not err.detail then err.detail = "Unknown" end
    local block = formatBlock(err)
    -- always print the block (so the user can copy/paste for support)
    print(block)
    if opts.toast ~= false then
        toast(err, opts.duration)
    end
    return err
end

-- Convenience wrappers: report + die
function ErrorHandler.fatal(kind, detail, hint, duration)
    local err = ErrorHandler.new(kind, detail, hint)
    ErrorHandler.report(err, { duration = duration })
    return err
end

-- Wraps a pcall: on success returns the value; on failure reports
-- an API / LOADER error and returns nil.
function ErrorHandler.wrap(kind, fn, hint)
    if type(fn) ~= "function" then
        return ErrorHandler.fatal(kind, "Internal: missing function", hint)
    end
    local ok, res = pcall(fn)
    if not ok then
        ErrorHandler.fatal(kind, tostring(res), hint)
        return nil
    end
    return res
end

return ErrorHandler
