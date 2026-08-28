--[[
    PawZHub Game Detector  v1.5.0
    ===========================
    Pure detection: takes the current PlaceId and returns a short
    game code (BF, GG, ...) or UNSUPPORTED. No HTTP, no UI.
]]

local Detector = {}

-- status constants
Detector.STATUS = {
    SUPPORTED   = "SUPPORTED",
    UNSUPPORTED = "UNSUPPORTED",
}

-- The shape of a detection result:
--   {
--     status  = "SUPPORTED" | "UNSUPPORTED",
--     code    = "BF" | "GG" | nil,        -- short ID used by router
--     name    = "Blox Fruits" | nil,
--     placeId = 2753915549,
--     reason  = "PlaceId not registered",
--   }
Detector.UNSUPPORTED = "UNSUPPORTED"

-- Main entry: returns a result table (never throws)
function Detector.detect(placeId, games)
    if type(placeId) ~= "number" then
        return { status = Detector.STATUS.UNSUPPORTED, reason = "Invalid PlaceId" }
    end
    if type(games) ~= "table" then
        return { status = Detector.STATUS.UNSUPPORTED, reason = "No game registry" }
    end
    local entry = games[placeId]
    if not entry then
        return { status = Detector.STATUS.UNSUPPORTED, placeId = placeId, reason = "Not in registry" }
    end
    return {
        status  = Detector.STATUS.SUPPORTED,
        code    = entry.code,
        name    = entry.name,
        placeId = placeId,
        entry   = entry,
    }
end

-- Helper for the "unsupported game" modal: a deterministic list of
-- supported game names + a Discord nudge. Returned as a single string
-- the loader can drop into a ScreenGui label.
function Detector.supportSummary(games)
    if type(games) ~= "table" then return "PawZHub" end
    local names = {}
    for _, e in pairs(games) do
        names[#names + 1] = "  \u{2022} " .. tostring(e.name)
    end
    table.sort(names)
    return "PawZHub\n\nThis game is not supported.\n\nSupported Games:\n" .. table.concat(names, "\n")
end

return Detector
