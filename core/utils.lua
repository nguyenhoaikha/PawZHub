--[[
    PawZHub Utilities  v1.5.0
    ======================
    Small helpers shared by every core/* module and the UI.
    No state, no side effects.  Pure functions where possible.
]]

local Utils = {}

-- safe pcall wrapper: returns default on any error
function Utils.safe(fn, default)
    if type(fn) ~= "function" then return default end
    local ok, res = pcall(fn)
    if not ok then return default end
    return res
end

-- numeric clamp
function Utils.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- type-aware equality
function Utils.isString(v)  return type(v) == "string" end
function Utils.isNumber(v)  return type(v) == "number" end
function Utils.isTable(v)   return type(v) == "table"  end
function Utils.isFunction(v) return type(v) == "function" end

-- truncate a string with ellipsis
function Utils.truncate(s, maxLen)
    if type(s) ~= "string" then return "" end
    if maxLen and #s > maxLen then
        return s:sub(1, math.max(0, maxLen - 1)) .. "\u{2026}"
    end
    return s
end

-- safe JSON encode/decode (HttpService may be missing in some envs)
function Utils.jsonEncode(t)
    return Utils.safe(function()
        return game:GetService("HttpService"):JSONEncode(t)
    end, "{}")
end

function Utils.jsonDecode(s)
    if type(s) ~= "string" or s == "" then return nil end
    return Utils.safe(function()
        return game:GetService("HttpService"):JSONDecode(s)
    end, nil)
end

-- http GET with multiple fallback transports (mirrors checkkey.lua behavior
-- so any module can call Utils.httpGet without re-implementing the chain)
function Utils.httpGet(url)
    if not url or url == "" then return nil end
    local ok, res = pcall(game.HttpGet, game, url, true)
    if ok and type(res) == "string" and res ~= "" then return res end
    -- 2) request() (Synapse X, Script-Ware)
    if type(request) == "function" then
        ok, res = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)
        if ok and type(res) == "table" and res.StatusCode and res.StatusCode < 400 then
            return res.Body or res.body
        end
    end
    -- 3) http_request / syn.request fallbacks
    if type(http_request) == "function" then
        ok, res = pcall(http_request, url, "GET", "", {})
        if ok and type(res) == "string" and res ~= "" then return res end
    end
    if syn and type(syn.request) == "function" then
        ok, res = pcall(function()
            return syn.request({ Url = url, Method = "GET" })
        end)
        if ok and type(res) == "table" and res.StatusCode and res.StatusCode < 400 then
            return res.Body or res.body
        end
    end
    return nil
end

function Utils.httpPost(url, body, extraHeaders)
    extraHeaders = extraHeaders or {}
    local headers = { ["Content-Type"] = "application/json" }
    for k, v in pairs(extraHeaders) do headers[k] = v end
    local payload = Utils.jsonEncode(body)
    local ok, res = pcall(function()
        return game:GetService("HttpService"):PostAsync(
            url, payload,
            Enum.HttpContentType.ApplicationJson,
            false, headers
        )
    end)
    if ok and type(res) == "string" and res ~= "" then return res end
    if type(request) == "function" then
        ok, res = pcall(function()
            return request({ Url = url, Method = "POST", Headers = headers, Body = payload })
        end)
        if ok and type(res) == "table" and res.StatusCode and res.StatusCode < 400 then
            return res.Body or res.body
        end
    end
    if type(http_request) == "function" then
        ok, res = pcall(http_request, url, "POST", payload, headers)
        if ok and type(res) == "string" and res ~= "" then return res end
    end
    if syn and type(syn.request) == "function" then
        ok, res = pcall(function()
            return syn.request({ Url = url, Method = "POST", Headers = headers, Body = payload })
        end)
        if ok and type(res) == "table" and res.StatusCode and res.StatusCode < 400 then
            return res.Body or res.body
        end
    end
    return nil
end

-- executor + platform detection (matches checkkey.lua's expectations)
function Utils.detectExecutor()
    local ok, name = pcall(identifyexecutor)
    if ok and type(name) == "string" and name ~= "" then return name end
    if type(syn) == "table" and syn.request then return "Synapse X" end
    if type(KRNL_LOADED) == "boolean" and KRNL_LOADED then return "KRNL" end
    if type(fluxus) == "table" then return "Fluxus" end
    if type(Arceus) == "table" then return "Arceus X" end
    if type(hydrogen) == "table" then return "Hydrogen" end
    if type(Delta) == "table" or type(APPLETOUCHHOOK_LOADED) == "boolean" then return "Delta" end
    if type(APEX_LOADED) == "boolean" and APEX_LOADED then return "Apex" end
    return "Unknown"
end

function Utils.detectPlatform()
    local UIS = game:GetService("UserInputService")
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then return "Mobile" end
    if UIS.TouchEnabled and UIS.KeyboardEnabled then return "Tablet" end
    return "PC"
end

-- progress-bar renderer. The loader uses this to keep a single
-- line in the F9 console (no spam, just one moving line).
function Utils.renderProgress(label, current, total, width)
    if type(label) ~= "string" then label = "PawZHub" end
    if type(current) ~= "number" then current = 0 end
    if type(total) ~= "number" or total <= 0 then total = 100 end
    width = width or 20
    local ratio = Utils.clamp(current / total, 0, 1)
    local filled = math.floor(ratio * width)
    local empty  = width - filled
    local bar = string.rep("\u{2588}", filled) .. string.rep("\u{2591}", empty)
    return string.format("%s [%s] %d%%", label, bar, math.floor(ratio * 100))
end

-- Update a single-line progress in the executor console.
-- Uses \r so most log viewers re-render the same line.
function Utils.updateProgressLine(label, current, total)
    local line = Utils.renderProgress(label, current, total)
    pcall(function()
        -- rconsole / loggers strip \r; write to stdout as-is
        io.write("\r" .. line)
        io.flush()
    end)
end

-- One-shot progress log that finishes with a newline so subsequent
-- log lines don't pile up on top of the progress bar.
function Utils.logProgress(label, current, total)
    local line = Utils.renderProgress(label, current, total)
    print(line)
end

-- Small Device / Locale helpers
function Utils.getHWID()
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and type(id) == "string" and id ~= "" then return id end
    -- fallback: Player UserId + AccountAge
    local p = game:GetService("Players").LocalPlayer
    return tostring(p.UserId) .. "-" .. tostring(p.AccountAge)
end

return Utils
