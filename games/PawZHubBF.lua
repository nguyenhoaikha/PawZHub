--[[
    ========================================================
    PAWZHub - Blox Fruits  v1.0.0
    Premium UI + Full feature engine
    Farm · Combat · Fruit · Quest · Raid · Player · More
    ========================================================
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

-- Function namespace: avoids Luau 200 local register limit in main chunk
local Paw = {}

-- ========== RE-EXEC: kill old instance completely ==========
local ENV = (getgenv and getgenv()) or _G
local HUB_KEY = "PawZHub_BloxFruits"

function Paw.DestroyHubGuis()
    local names = { "PawZHub", "PawHub", "PawZHubBF", "PawZHubLoader", "PawZHubToast" }
    local parents = {}
    pcall(function() parents[#parents + 1] = CoreGui end)
    pcall(function()
        if gethui then parents[#parents + 1] = gethui() end
    end)
    pcall(function()
        local pg = Player:FindFirstChild("PlayerGui")
        if pg then parents[#parents + 1] = pg end
    end)
    for _, parent in ipairs(parents) do
        for _, name in ipairs(names) do
            pcall(function()
                local g = parent:FindFirstChild(name)
                if g then g:Destroy() end
            end)
        end
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and child:GetAttribute("PawZHubScript") == true then
                    child:Destroy()
                end
            end
        end)
    end
end

if type(ENV[HUB_KEY]) == "table" and type(ENV[HUB_KEY].Unload) == "function" then
    pcall(function() ENV[HUB_KEY]:Unload() end)
end
Paw.DestroyHubGuis()
task.wait(0.05)

local HubInstance = {
    connections = {},
    stopped = false,
}
function HubInstance:AddConnection(conn)
    if conn then
        self.connections[#self.connections + 1] = conn
    end
    return conn
end
function HubInstance:ForceAllFeaturesOff(cfg)
    cfg = cfg or self.Config
    if type(cfg) ~= "table" then return end
    -- Home / Utility
    cfg.AntiAFK = false
    cfg.SpeedEnabled = false
    cfg.AutoServerHop = false
    -- Farm
    cfg.AutoFarmLevel = false
    cfg.AutoFarmMastery = false
    cfg.AutoFarmFruit = false
    cfg.AutoLeviathan = false
    cfg.AutoBone = false
    cfg.AutoDeathKing = false
    cfg.AutoGacha = false
    cfg.AutoSaber = false
    cfg.AutoCDK = false
    cfg.AutoSoulGuitar = false
    cfg.AutoRaceV4 = false
    cfg.AutoTrial = false
    cfg.BossHop = false
    cfg.FruitHop = false
    -- Keep BringMobs / OwnIslandOnly as user prefs (forcing them off breaks farm after Stop)
    cfg.AutoChest = false
    -- Combat
    cfg.AutoAttack = false
    cfg.AutoSkill = false
    cfg.AutoKen = false
    cfg.AutoDodge = false
    cfg.ComboMode = false
    -- Fruit & Inventory
    cfg.AutoStoreFruit = false
    cfg.AutoEatFruit = false
    cfg.FruitNotify = false
    cfg.FruitSniper = false
    cfg.SniperHop = false
    -- Quest / Sea
    cfg.AutoQuest = false
    cfg.AutoNextIsland = false
    cfg.AutoDialogue = false
    -- Raid / Boss
    cfg.AutoRaid = false
    cfg.AutoBoss = false
    cfg.SafeMode = false
    cfg.AutoEliteHunter = false
    cfg.AutoCakePrince = false
    cfg.AutoSeaEvent = false
    cfg.AutoMirage = false
    cfg.AutoKitsune = false
    cfg.AutoMaterial = false
    cfg.AutoObservation = false
    cfg.AutoStats = false
    -- Player
    cfg.Noclip = false
    cfg.ESP = false
end

function HubInstance:Unload()
    if self.stopped then return end
    self.stopped = true
    local eng = self.FeatureEngine
    local hop = self.ServerHop
    local cfg = self.Config
    pcall(function()
        if eng and eng.Stop then eng:Stop() end
    end)
    pcall(function()
        if hop and hop.Stop then hop:Stop() end
        if hop then hop.Active = false end
    end)
    pcall(function()
        if self.SetNoclip then self.SetNoclip(false) end
        if self.SetESP then self.SetESP(false) end
        if self.AntiAFK and self.AntiAFK.Stop then self.AntiAFK:Stop() end
        if self.RestoreWalkSpeed then self.RestoreWalkSpeed() end
        if self.RestoreBringState then self.RestoreBringState() end
    end)
    self:ForceAllFeaturesOff(cfg)
    for _, conn in ipairs(self.connections) do
        pcall(function()
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            elseif type(conn) == "table" and conn.Disconnect then
                conn:Disconnect()
            end
        end)
    end
    self.connections = {}
    Paw.DestroyHubGuis()
end
ENV[HUB_KEY] = HubInstance

-- Embedded PawZ logo (paw print). Optional override: LOGO_ASSET = "rbxassetid://..."
local LOGO_ASSET = ""
local BG_ASSET = ""
local LOGO_PNG_B64 = [[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]]
local LOGO_FILE = "PawZHub/pawzlogo.png"

function Paw.MaterializeLogoAsset()
    if type(LOGO_ASSET) == "string" and LOGO_ASSET ~= "" then
        return LOGO_ASSET
    end
    local path = LOGO_FILE
    pcall(function()
        if isfolder and not isfolder("PawZHub") and makefolder then
            makefolder("PawZHub")
        end
    end)
    pcall(function()
        if writefile and LOGO_PNG_B64 and #LOGO_PNG_B64 > 0 then
            local data = nil
            local decoders = {
                function() return crypt and crypt.base64decode and crypt.base64decode(LOGO_PNG_B64) end,
                function() return crypt and crypt.base64 and crypt.base64.decode and crypt.base64.decode(LOGO_PNG_B64) end,
                function() return base64_decode and base64_decode(LOGO_PNG_B64) end,
                function() return syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode and syn.crypt.base64.decode(LOGO_PNG_B64) end,
            }
            for _, dec in ipairs(decoders) do
                local ok, res = pcall(dec)
                if ok and type(res) == "string" and #res > 100 then
                    data = res
                    break
                end
            end
            if not data then
                -- pure Lua base64 decode fallback
                local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
                data = (LOGO_PNG_B64:gsub('[^'..b..'=]', ''):gsub('.', function(x)
                    if x == '=' then return '' end
                    local r, f = '', (b:find(x) - 1)
                    for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
                    return r
                end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
                    if #x ~= 8 then return '' end
                    local c = 0
                    for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2^(8 - i) or 0) end
                    return string.char(c)
                end))
            end
            if data and #data > 0 then
                writefile(path, data)
            end
        end
    end)
    local asset = nil
    pcall(function()
        if getcustomasset then
            asset = getcustomasset(path)
        end
    end)
    if type(asset) == "string" and asset ~= "" then
        return asset
    end
    -- try alternate paths
    for _, p in ipairs({"pawzlogo.png", "PawZHub/pawzlogo.png", "PawZHubLogo.png"}) do
        local ok, a = pcall(function() return getcustomasset and getcustomasset(p) end)
        if ok and type(a) == "string" and a ~= "" then return a end
    end
    return ""
end

-- ========== CONFIG ==========
local Config = {
    -- Home / Utility
    AntiAFK = false,
    SpeedEnabled = false,
    WalkSpeed = 16,
    AutoServerHop = false,
    MaxPlayers = 6,

    -- Farm
    AutoFarmLevel = false,
    AutoFarmMastery = false,
    AutoFarmFruit = false,
    BringMobs = true,       -- gom quái về 1 điểm
    BringRange = 120,       -- bán kính quét gom
    BringMax = 12,          -- tối đa mob gom 1 lúc (AOE)
    BringLock = true,       -- giữ mob tại stack (retry)
    FarmRange = 80,
    AttackSpeed = 1.6,         -- >1 = đánh nhanh hơn (khuyến nghị 1.2–2.5)
    FastAttack = true,      -- spam M1 nhanh
    TweenFarm = true,       -- tiếp cận mượt (tween steps)
    FarmHeight = 5,         -- cao so với mob (tránh bay trời)
    PreferNearest = true,
    PreferHighestXP = false,
    OwnIslandOnly = true,
    SelectedWeapon = "Melee",
    QuestByLevel = true,    -- ưu tiên mob/quest theo level
    AutoChest = false,      -- farm rương

    -- Combat
    AutoAttack = false,
    AutoSkill = false,
    AutoKen = false,
    AutoDodge = false,
    ComboMode = false,
    TargetMode = "Nearest", -- Nearest | LowestHP | BossOnly

    -- Fruit & Inventory
    AutoStoreFruit = false,
    AutoEatFruit = false,
    FruitNotify = false,
    FruitSniper = false,
    SniperHop = false,      -- DISABLED: Fruit Sniper never auto-hops
    SniperHopSec = 90,      -- (unused — hop logic removed)
    SelectedFruit = "None",
    -- whitelist sniper (thứ tự = độ ưu tiên, đầu list = hiếm hơn)
    SniperList = {
        "Kitsune", "Dragon", "Yeti", "T-Rex", "Mammoth", "Leopard",
        "Dough", "Venom", "Control", "Spirit", "Shadow", "Gas",
        "Gravity", "Buddha", "Portal", "Rumble", "Pain", "Phoenix",
        "Blizzard", "Sound", "Spider", "Quake", "Love", "Light",
    },

    -- Quest / Sea
    AutoQuest = false,
    AutoNextIsland = false,
    AutoDialogue = false,
    CurrentSea = 1,
    AutoDetectSea = true,
    AutoStats = false,
    StatMelee = true,
    StatDefense = true,
    StatSword = false,
    StatGun = false,

    -- Raid / Boss
    AutoRaid = false,
    AutoBoss = false,
    SafeMode = false,
    SelectedRaid = "Flame",
    SelectedBoss = "None",
    RaidKill = true,        -- đánh mob trong raid
    RaidNext = true,        -- bấm next / tiếp tầng
    RaidBuyChip = false,    -- thử mua chip (cẩn thận beli)

    -- Advanced / Sea Events
    AutoEliteHunter = false,
    EliteHop = false,
    EliteHopWait = 45,
    ElitePreferLowHP = true,
    AutoCakePrince = false,
    AutoSeaEvent = false,
    AutoLeviathan = false,
    AutoMirage = false,
    AutoKitsune = false,
    AutoMaterial = false,
    SelectedMaterial = "Leather",
    AutoObservation = false,
    AutoBone = false,
    AutoDeathKing = false,
    AutoGacha = false,
    AutoSaber = false,
    AutoCDK = false,
    AutoSoulGuitar = false,
    AutoRaceV4 = false,
    AutoTrial = false,
    BossHop = false,
    FruitHop = false,
    HopRejoin = true,
    TweenSpeed = 160,           -- mượt hơn, giảm giật (trước 280 quá nhanh)
    HideUI = false,

    -- Player / ESP
    Noclip = false,
    ESP = false,
    ESP_Players = true,
    ESP_Fruit = true,
    ESP_Chest = true,
    ESP_NPC = false,
    ESP_Boss = true,
    ESP_Flower = false,
    ESP_Gear = false,

    -- UI / Settings
    Language = "en",           -- "en" | "vi"
    ThemeMode = "bw",          -- "bw" | "accent"
    UIScale = 1.0,
    UIOpacity = 0.0,
    ToggleKey = Enum.KeyCode.RightControl,

    -- Safety
    SafetyEnabled = true,
    MinBeli = 0,
    StopOnFullInventory = true,
    MaxPromptFails = 8,
    IdleThrottle = true,
    PerformanceMode = true,
}

local SCRIPT_VERSION = "1.0.0"
local WEBSITE_URL = "https://getpawzhub.vercel.app/"
local CHANGELOG = [[v1.0.0
• Stable release
• Fix: Out of local registers (Paw namespace, safe replace)
]]

-- ========== i18n ==========
local Locale = {
    en = {
        tab_home = "Home", tab_sea = "Biển", tab_raid = "Raid", tab_quest = "Quest", tab_esp = "ESP", tab_tp = "TP", auto_bone = "Auto Farm Bone", tab_sea = "Sea", tab_raid = "Raid", tab_quest = "Quest", tab_esp = "ESP", tab_tp = "TP", auto_bone = "Auto Farm Bone", tab_farm = "Farm", tab_combat = "Combat",
        tab_fruit = "Fruit", tab_quest = "Quest", tab_raid = "Raid",
        tab_player = "Player", tab_more = "More",
        status = "STATUS", features = "FEATURES", farming = "FARMING",
        combat = "COMBAT", fruits = "FRUIT & INVENTORY", quest_sea = "QUEST / SEA",
        raid_boss = "RAID / BOSS", player_util = "PLAYER / UTILITY",
        safety = "SAFETY", settings = "SETTINGS", preset = "PRESET", info = "INFO",
        anti_afk = "Anti AFK", speed_boost = "Speed Boost", server_hop = "Server Hop",
        auto_farm_level = "Auto Farm Level", auto_farm_mastery = "Auto Farm Mastery",
        auto_farm_fruit = "Auto Farm Fruit", auto_chest = "Auto Chest",
        own_island = "Own Island Only",
        prefer_nearest = "Prefer Nearest", prefer_xp = "Prefer Highest XP",
        bring_mobs = "Bring Mobs", bring_lock = "Bring Lock",
        bring_section = "BRING / MAGNET",
        target_opts = "TARGET", farm_tuning = "TUNING",
        quest_by_level = "Quest By Level",
        fast_attack = "Fast Attack", tween_farm = "Tween Farm",
        tp_islands = "TELEPORT ISLANDS",
        auto_attack = "Auto Attack", auto_skill = "Auto Skill", auto_ken = "Auto Ken",
        auto_dodge = "Auto Dodge", combo_mode = "Combo Mode",
        auto_store = "Auto Store Fruit", auto_eat = "Auto Eat Fruit",
        fruit_notify = "Fruit Notify", fruit_sniper = "Fruit Sniper",
        sniper_hop = "Sniper Server Hop",
        auto_quest = "Auto Quest", auto_next_island = "Auto Next Island",
        auto_dialogue = "Auto Dialogue",
        auto_raid = "Auto Raid", auto_boss = "Auto Boss", safe_mode = "Safe Mode",
        raid_kill = "Raid Kill Mobs", raid_next = "Raid Next Island", raid_buy_chip = "Raid Buy Chip",
        advanced_section = "ADVANCED", material_section = "MATERIAL",
        auto_elite = "Auto Elite Hunter", elite_hop = "Elite Server Hop",
        elite_low_hp = "Elite Prefer Low HP",
        auto_cake = "Auto Cake Prince",
        auto_sea_event = "Auto Sea Event", auto_mirage = "Auto Mirage",
        auto_kitsune = "Auto Kitsune Island", auto_observation = "Auto Observation Haki",
        auto_material = "Auto Material Farm",
        noclip = "Noclip", esp = "ESP",
        esp_players = "ESP Players", esp_fruit = "ESP Fruit",
        esp_chest = "ESP Chest", esp_npc = "ESP NPC",
        stats_section = "STATS",
        auto_stats = "Auto Stats",
        stat_melee = "Stat: Melee", stat_defense = "Stat: Defense",
        stat_sword = "Stat: Sword", stat_gun = "Stat: Gun",
        safety_limits = "Safety Limits", idle_throttle = "Idle Throttle",
        theme_accent = "Theme Accent", language = "Language: English",
        save_config = "Save Config", load_config = "Load Config",
        idle = "Idle", running = "Running",
        help_footer_pc = "Click outside · Right-click feature for help",
        help_footer_mobile = "Tap outside to close",
        help_missing = "No detailed help for this feature.\n\nLeft-click toggles it.",
        toast_saved = "Config saved", toast_loaded = "Config loaded",
        toast_no_cfg = "No saved config", toast_cfg_fail = "Config load failed",
        toast_theme = "Theme", toast_ui_hide = "UI hidden", toast_ui_show = "UI shown",
        toast_engine = "Engine reconnected", toast_safety = "Safety: too many fails — paused",
        toggle_hint = "Toggle UI: Right Ctrl",
        lang_switched = "Language: English",
        ui_scale = "UI Scale", opacity = "Opacity",
    },
    vi = {
        tab_home = "Trang chủ", tab_farm = "Farm", tab_combat = "Combat",
        tab_fruit = "Fruit", tab_quest = "Quest", tab_raid = "Raid",
        tab_player = "Player", tab_more = "Thêm",
        status = "TRẠNG THÁI", features = "TÍNH NĂNG", farming = "FARM",
        combat = "CHIẾN ĐẤU", fruits = "FRUIT & TÚI ĐỒ", quest_sea = "QUEST / SEA",
        raid_boss = "RAID / BOSS", player_util = "NGƯỜI CHƠI / TIỆN ÍCH",
        safety = "AN TOÀN", settings = "CÀI ĐẶT", preset = "PRESET", info = "THÔNG TIN",
        anti_afk = "Chống AFK", speed_boost = "Tăng tốc", server_hop = "Chuyển server",
        auto_farm_level = "Tự farm Level", auto_farm_mastery = "Tự farm Mastery",
        auto_farm_fruit = "Tự farm Fruit", auto_chest = "Tự farm rương",
        own_island = "Chỉ đảo của mình",
        prefer_nearest = "Ưu tiên gần nhất", prefer_xp = "Ưu tiên XP cao",
        bring_mobs = "Gom quái", bring_lock = "Khóa gom",
        bring_section = "GOM QUÁI / MAGNET",
        target_opts = "MỤC TIÊU", farm_tuning = "CHỈNH FARM",
        quest_by_level = "Quest theo level",
        fast_attack = "Tấn công nhanh", tween_farm = "Tween farm",
        tp_islands = "DỊCH CHUYỂN ĐẢO",
        auto_attack = "Tự đánh", auto_skill = "Tự skill", auto_ken = "Tự Ken",
        auto_dodge = "Tự né", combo_mode = "Chế độ combo",
        auto_store = "Tự cất Fruit", auto_eat = "Tự ăn Fruit",
        fruit_notify = "Thông báo Fruit", fruit_sniper = "Fruit Sniper",
        sniper_hop = "Hop khi hết fruit sniper",
        auto_quest = "Tự nhận Quest", auto_next_island = "Tự chuyển đảo",
        auto_dialogue = "Tự bỏ qua thoại",
        auto_raid = "Tự Raid", auto_boss = "Tự Boss", safe_mode = "Chế độ an toàn",
        raid_kill = "Đánh mob trong Raid", raid_next = "Raid đảo tiếp", raid_buy_chip = "Mua chip Raid",
        advanced_section = "NÂNG CAO", material_section = "NGUYÊN LIỆU",
        auto_elite = "Tự Elite Hunter", elite_hop = "Hop khi hết Elite",
        elite_low_hp = "Ưu tiên Elite máu thấp",
        auto_cake = "Tự Cake Prince",
        auto_sea_event = "Tự Sea Event", auto_mirage = "Tự Mirage",
        auto_kitsune = "Tự đảo Kitsune", auto_observation = "Tự Observation Haki",
        auto_material = "Tự farm nguyên liệu",
        noclip = "Noclip", esp = "ESP",
        esp_players = "ESP người chơi", esp_fruit = "ESP Fruit",
        esp_chest = "ESP rương", esp_npc = "ESP NPC",
        stats_section = "CHỈ SỐ",
        auto_stats = "Tự cộng chỉ số",
        stat_melee = "Chỉ số: Melee", stat_defense = "Chỉ số: Defense",
        stat_sword = "Chỉ số: Sword", stat_gun = "Chỉ số: Gun",
        safety_limits = "Giới hạn an toàn", idle_throttle = "Giảm tải khi idle",
        theme_accent = "Theme màu accent", language = "Ngôn ngữ: Tiếng Việt",
        save_config = "Lưu cấu hình", load_config = "Tải cấu hình",
        idle = "Chờ", running = "Đang chạy",
        help_footer_pc = "Bấm ra ngoài · Chuột phải xem hướng dẫn",
        help_footer_mobile = "Chạm ra ngoài để đóng",
        help_missing = "Chưa có hướng dẫn cho tính năng này.\n\nClick trái để bật/tắt.",
        toast_saved = "Đã lưu cấu hình", toast_loaded = "Đã tải cấu hình",
        toast_no_cfg = "Chưa có file cấu hình", toast_cfg_fail = "Tải cấu hình thất bại",
        toast_theme = "Giao diện", toast_ui_hide = "Đã ẩn UI", toast_ui_show = "Hiện UI",
        toast_engine = "Engine đã kết nối lại", toast_safety = "An toàn: quá nhiều lỗi — tạm dừng",
        toggle_hint = "Ẩn/hiện UI: Right Ctrl",
        lang_switched = "Ngôn ngữ: Tiếng Việt",
        ui_scale = "Tỷ lệ UI", opacity = "Độ trong suốt",
    },
}

function Paw.T(key)
    local lang = Config.Language or "en"
    local pack = Locale[lang] or Locale.en
    return pack[key] or Locale.en[key] or key
end

local FeatureHelpEN = {
    ["Anti AFK"] = "Prevents idle kick with small virtual inputs.",
    ["Speed Boost"] = "Raises WalkSpeed while enabled.",
    ["Server Hop"] = "Searches for servers with ≤ MaxPlayers and hops when crowded.",
    ["Auto Farm Level"] = "Smart target score: nearest + finish low-HP + stick to target. Positions at the correct fight spot.",
    ["Auto Farm Mastery"] = "Prefers same mob type and higher HP for longer hit chains (mastery).",
    ["Auto Farm Fruit"] = "Priority path to nearby fruit drops, then farm mobs.",
    ["Own Island Only"] = "Only target mobs near your position when farm was enabled (island anchor).",
    ["Prefer Nearest"] = "Weight score toward closer enemies.",
    ["Prefer Highest XP"] = "Weight score toward higher MaxHP (proxy for XP).",
    ["Bring Mobs"] = "Pull nearby mobs into a stack in front of you for easier AOE kills (magnet).",
    ["Bring Lock"] = "Keep pulled mobs locked at the stack so the server cannot drag them away easily.",
    ["Quest By Level"] = "Prefer mobs that match the level guide for your current level / sea.",
    ["Auto Attack"] = "Auto click / attack nearest target.",
    ["Auto Skill"] = "Auto use skills Z/X/C/V/F according to fruit/weapon.",
    ["Auto Ken"] = "Auto enable Buso / Ken.",
    ["Auto Dodge"] = "Auto dodge / Instinct when HP is low.",
    ["Combo Mode"] = "Follow skill order combo.",
    ["Auto Store Fruit"] = "Automatically store fruit into inventory.",
    ["Auto Eat Fruit"] = "Auto eat selected fruit.",
    ["Fruit Notify"] = "Notify when a fruit drops nearby.",
    ["Fruit Sniper"] = "Hunt only fruits on your priority list (top of list = higher priority).",
    ["Sniper Server Hop"] = "Server hop if no sniper-list fruit is found for a while.",
    ["Auto Quest"] = "Auto take quest according to level.",
    ["Auto Next Island"] = "Auto teleport to next island / sea.",
    ["Auto Dialogue"] = "Auto skip dialogue / claim reward.",
    ["Auto Raid"] = "Auto join and complete selected raid.",
    ["Auto Boss"] = "Auto farm selected bosses.",
    ["Safe Mode"] = "Retreat upward when HP is very low.",
    ["Noclip"] = "Walk through walls (use carefully).",
    ["ESP"] = "Show ESP for players / fruit / chest / NPC.",
    ["ESP Players"] = "Show labels on other players.",
    ["ESP Fruit"] = "Show labels on fruit drops.",
    ["ESP Chest"] = "Show labels on chests / crates.",
    ["ESP NPC"] = "Show labels on quest / shop NPCs.",
    ["Safety Limits"] = "Pause features after too many consecutive fails.",
    ["Idle Throttle"] = "Slow cache refresh while idle.",
    ["Theme Accent"] = "Switch black/white vs accent theme.",
    ["Language"] = "Switch UI language between English and Vietnamese.",
}
local FeatureHelpVI = {
    ["Anti AFK"] = "Chống bị kick AFK bằng thao tác ảo nhẹ.",
    ["Speed Boost"] = "Tăng tốc độ chạy (WalkSpeed) khi bật.",
    ["Server Hop"] = "Tìm server ≤ MaxPlayers và chuyển server khi đông.",
    ["Auto Farm Level"] = "Chấm điểm mục tiêu: gần + dứt điểm máu thấp + bám target. Đứng đúng chỗ đánh.",
    ["Auto Farm Mastery"] = "Ưu tiên cùng loại mob và máu cao để đánh lâu (mastery).",
    ["Auto Farm Fruit"] = "Ưu tiên nhặt fruit gần, sau đó farm mob.",
    ["Own Island Only"] = "Chỉ farm mob gần vị trí lúc bật farm (neo đảo).",
    ["Prefer Nearest"] = "Ưu tiên kẻ địch gần hơn.",
    ["Prefer Highest XP"] = "Ưu tiên MaxHP cao (ước lượng XP).",
    ["Bring Mobs"] = "Kéo mob quanh bạn về một điểm để đánh AOE dễ hơn (magnet).",
    ["Bring Lock"] = "Giữ mob tại điểm gom để server khó kéo chúng ra lại.",
    ["Quest By Level"] = "Ưu tiên mob đúng bảng level / sea hiện tại.",
    ["Auto Attack"] = "Tự click / đánh mục tiêu gần nhất.",
    ["Auto Skill"] = "Tự dùng skill Z/X/C/V/F theo fruit/weapon.",
    ["Auto Ken"] = "Tự bật Buso / Ken.",
    ["Auto Dodge"] = "Tự né / Instinct khi máu thấp.",
    ["Combo Mode"] = "Dùng skill theo thứ tự combo.",
    ["Auto Store Fruit"] = "Tự cất fruit vào túi đồ.",
    ["Auto Eat Fruit"] = "Tự ăn fruit đã chọn.",
    ["Fruit Notify"] = "Thông báo khi có fruit rơi gần.",
    ["Fruit Sniper"] = "Chỉ săn fruit trong danh sách ưu tiên (đầu list = ưu tiên cao hơn).",
    ["Sniper Server Hop"] = "Chuyển server nếu lâu không thấy fruit trong list sniper.",
    ["Auto Quest"] = "Tự nhận quest theo level.",
    ["Auto Next Island"] = "Tự dịch chuyển sang đảo / sea tiếp theo.",
    ["Auto Dialogue"] = "Tự bỏ qua thoại / nhận thưởng.",
    ["Auto Raid"] = "Tự tham gia và hoàn thành raid đã chọn.",
    ["Auto Boss"] = "Tự farm boss đã chọn.",
    ["Safe Mode"] = "Bay lên cao khi máu rất thấp.",
    ["Noclip"] = "Đi xuyên tường (cẩn thận bị ban).",
    ["ESP"] = "Hiện ESP người chơi / fruit / rương / NPC.",
    ["ESP Players"] = "Hiện nhãn trên người chơi khác.",
    ["ESP Fruit"] = "Hiện nhãn trên fruit.",
    ["ESP Chest"] = "Hiện nhãn trên rương / thùng.",
    ["ESP NPC"] = "Hiện nhãn trên NPC quest / shop.",
    ["Safety Limits"] = "Tạm dừng khi lỗi liên tiếp quá nhiều.",
    ["Idle Throttle"] = "Giảm tần suất quét khi đang idle.",
    ["Theme Accent"] = "Đổi theme đen-trắng / accent.",
    ["Language"] = "Đổi ngôn ngữ giao diện Anh / Việt.",
}

function Paw.GetFeatureHelp(title)
    local pack = (Config.Language == "vi") and FeatureHelpVI or FeatureHelpEN
    return pack[title]
end

local UILangRefs = {}
function Paw.BindLang(obj, key)
    if obj then UILangRefs[#UILangRefs + 1] = {obj = obj, key = key} end
    return obj
end

function Paw.ApplyLanguage()
    for _, ref in ipairs(UILangRefs) do
        local o = ref.obj
        if o and o.Parent then
            if ref.key then
                pcall(function() o.Text = Paw.T(ref.key) end)
            elseif ref.fn then
                pcall(ref.fn)
            end
        end
    end
end

-- ========== PREMIUM THEME ==========
local Theme = {
    bg          = Color3.fromRGB(8, 8, 8),
    bgDark      = Color3.fromRGB(16, 16, 16),
    card        = Color3.fromRGB(22, 22, 22),
    cardHover   = Color3.fromRGB(32, 32, 32),
    cardDark    = Color3.fromRGB(14, 14, 14),
    glass       = Color3.fromRGB(24, 24, 24),
    accent1     = Color3.fromRGB(255, 255, 255),
    accent2     = Color3.fromRGB(220, 220, 220),
    accent3     = Color3.fromRGB(180, 180, 180),
    text        = Color3.fromRGB(255, 255, 255),
    textSub     = Color3.fromRGB(180, 180, 180),
    textMuted   = Color3.fromRGB(120, 120, 120),
    success     = Color3.fromRGB(255, 255, 255),
    successDark = Color3.fromRGB(200, 200, 200),
    danger      = Color3.fromRGB(40, 40, 40),
    gloss       = Color3.fromRGB(255, 255, 255),
    glossSoft   = Color3.fromRGB(230, 230, 230),
    shadow      = Color3.fromRGB(0, 0, 0),
    border      = Color3.fromRGB(48, 48, 48),
}

-- ========== TOAST ==========
local Toast = { Queue = {}, Active = 0, Max = 5 }
function Toast:Show(msg, kind)
    kind = kind or "info"
    task.spawn(function()
        local gui = HubInstance.ScreenGui
        if not gui or not gui.Parent then
            pcall(function()
                if gethui then gui = gethui():FindFirstChild("PawZHub") end
            end)
            if not gui then gui = CoreGui:FindFirstChild("PawZHub") end
        end
        if not gui then return end
        self.Active = self.Active + 1
        local idx = self.Active
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 0, 0, 34)
        f.Position = UDim2.new(1, -16, 1, -20 - (idx * 40))
        f.AnchorPoint = Vector2.new(1, 1)
        f.BackgroundColor3 = Theme.card
        f.BackgroundTransparency = 0.05
        f.BorderSizePixel = 0
        f.ZIndex = 100
        f.Parent = gui
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 10)
        c.Parent = f
        local s = Instance.new("UIStroke")
        s.Color = Theme.border
        s.Thickness = 1
        s.Parent = f
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -16, 1, 0)
        t.Position = UDim2.new(0, 12, 0, 0)
        t.BackgroundTransparency = 1
        t.Text = tostring(msg)
        t.TextColor3 = Theme.text
        t.TextSize = 12
        t.Font = Enum.Font.GothamMedium
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 101
        t.Parent = f
        TweenService:Create(f, TweenInfo.new(0.28, Enum.EasingStyle.Quint), {
            Size = UDim2.new(0, 260, 0, 34)
        }):Play()
        task.wait(2.2)
        TweenService:Create(f, TweenInfo.new(0.25), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 20, 1, -20 - (idx * 40))
        }):Play()
        TweenService:Create(t, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
        TweenService:Create(s, TweenInfo.new(0.25), {Transparency = 1}):Play()
        task.wait(0.28)
        f:Destroy()
        self.Active = math.max(0, self.Active - 1)
    end)
end

-- ========== CONFIG SAVE / LOAD ==========
local ConfigIO = {}
local CONFIG_PATH = "PawZHub/config_bf.json"
local CONFIG_KEYS = {
    "AntiAFK","SpeedEnabled","WalkSpeed","AutoServerHop","MaxPlayers",
    "AutoFarmLevel","AutoFarmMastery","AutoFarmFruit","BringMobs","BringRange","BringMax","BringLock",
    "FarmRange","AttackSpeed","FastAttack","TweenFarm","FarmHeight",
    "PreferNearest","PreferHighestXP","OwnIslandOnly","SelectedWeapon","QuestByLevel","AutoChest",
    "AutoAttack","AutoSkill","AutoKen","AutoDodge","ComboMode","TargetMode",
    "AutoStoreFruit","AutoEatFruit","FruitNotify","FruitSniper","SniperHop","SniperHopSec","SelectedFruit","SniperList",
    "AutoQuest","AutoNextIsland","AutoDialogue","CurrentSea","AutoDetectSea",
    "AutoStats","StatMelee","StatDefense","StatSword","StatGun",
    "AutoRaid","AutoBoss","SafeMode","SelectedRaid","SelectedBoss",
    "RaidKill","RaidNext","RaidBuyChip",
    "AutoEliteHunter","EliteHop","EliteHopWait","ElitePreferLowHP",
    "AutoCakePrince","AutoSeaEvent","AutoLeviathan","AutoMirage","AutoKitsune",
    "AutoMaterial","SelectedMaterial","AutoObservation","AutoBone","AutoDeathKing",
    "AutoGacha","AutoSaber","AutoCDK","AutoSoulGuitar","AutoRaceV4","AutoTrial",
    "BossHop","FruitHop","HopRejoin","HideUI",
    "Noclip","ESP","ESP_Players","ESP_Fruit","ESP_Chest","ESP_NPC",
    "Language","ThemeMode","UIScale","UIOpacity",
    "SafetyEnabled","MinBeli","StopOnFullInventory","MaxPromptFails",
    "IdleThrottle","PerformanceMode"
}

function Paw.encodeJSON(val)
    local t = typeof(val)
    if t == "nil" then return "null"
    elseif t == "boolean" then return val and "true" or "false"
    elseif t == "number" then return tostring(val)
    elseif t == "string" then return '"' .. val:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n') .. '"'
    elseif t == "table" then
        local isArr = #val > 0
        if isArr then
            local parts = {}
            for i,v in ipairs(val) do parts[i] = Paw.encodeJSON(v) end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k,v in pairs(val) do
                if type(k) == "string" then
                    parts[#parts+1] = Paw.encodeJSON(k) .. ":" .. Paw.encodeJSON(v)
                end
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

function Paw.decodeJSON(str)
    if not str or str == "" then return nil end
    local ok, res = pcall(function()
        return HttpService:JSONDecode(str)
    end)
    if ok and res then return res end
    return nil
end

function ConfigIO:Save()
    local data = {}
    for _, k in ipairs(CONFIG_KEYS) do
        data[k] = Config[k]
    end
    local body
    pcall(function() body = HttpService:JSONEncode(data) end)
    if not body then body = Paw.encodeJSON(data) end
    pcall(function()
        if isfolder and not isfolder("PawZHub") then makefolder("PawZHub") end
        if writefile then writefile(CONFIG_PATH, body) end
    end)
    Toast:Show(Paw.T("toast_saved"), "ok")
    return true
end

function ConfigIO:Load()
    local raw
    pcall(function()
        if readfile and isfile and isfile(CONFIG_PATH) then
            raw = readfile(CONFIG_PATH)
        end
    end)
    if not raw then
        Toast:Show(Paw.T("toast_no_cfg"), "warn")
        return false
    end
    local data = Paw.decodeJSON(raw)
    if type(data) ~= "table" then
        Toast:Show(Paw.T("toast_cfg_fail"), "warn")
        return false
    end
    for _, k in ipairs(CONFIG_KEYS) do
        if data[k] ~= nil then
            Config[k] = data[k]
        end
    end
    pcall(function()
        if ApplyTheme then ApplyTheme() end
        if ApplyUILayout then ApplyUILayout() end
        if Paw.ApplyLanguage then Paw.ApplyLanguage() end
        if Paw.ReconcileRuntimeConfig then Paw.ReconcileRuntimeConfig() end
    end)
    Toast:Show(Paw.T("toast_loaded"), "ok")
    return true
end

local ThemeBW = {
    bg = Color3.fromRGB(8,8,8), bgDark = Color3.fromRGB(16,16,16),
    card = Color3.fromRGB(22,22,22), cardHover = Color3.fromRGB(32,32,32),
    accent1 = Color3.fromRGB(255,255,255), accent2 = Color3.fromRGB(220,220,220),
    accent3 = Color3.fromRGB(180,180,180), text = Color3.fromRGB(255,255,255),
    textSub = Color3.fromRGB(180,180,180), textMuted = Color3.fromRGB(120,120,120),
    success = Color3.fromRGB(255,255,255), danger = Color3.fromRGB(40,40,40),
    border = Color3.fromRGB(48,48,48),
}
local ThemeAccent = {
    bg = Color3.fromRGB(10,10,14), bgDark = Color3.fromRGB(14,14,20),
    card = Color3.fromRGB(22,22,30), cardHover = Color3.fromRGB(32,32,42),
    accent1 = Color3.fromRGB(99,102,241), accent2 = Color3.fromRGB(129,140,248),
    accent3 = Color3.fromRGB(165,180,252), text = Color3.fromRGB(250,250,252),
    textSub = Color3.fromRGB(170,170,185), textMuted = Color3.fromRGB(120,120,140),
    success = Color3.fromRGB(74,222,128), danger = Color3.fromRGB(248,113,113),
    border = Color3.fromRGB(45,45,60),
}

function ApplyTheme()
    local src = (Config.ThemeMode == "accent") and ThemeAccent or ThemeBW
    for k,v in pairs(src) do Theme[k] = v end
end
ApplyTheme()

-- ========== FEATURE ENGINE ==========
local VirtualUser = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)
local TeleportService = game:GetService("TeleportService")
local CollectionService = game:GetService("CollectionService")

function Paw.GetCharacter()
    return Player.Character
end

function Paw.GetHumanoid()
    local char = Paw.GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Paw.GetHRP()
    local char = Paw.GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ========== WORLD MAP + REMOTE LOADER ==========
-- Mỗi lần chạy script: quét Workspace + ReplicatedStorage,
-- đánh dấu folder mob, đảo, NPC quest, fruit, remote hữu ích.
local World = {
    Scanned = false,
    ScannedAt = 0,
    EnemyFolders = {},
    Islands = {},      -- { name, position, part }
    QuestNPCs = {},    -- { name, position, model, prompt }
    FruitSpawns = {},  -- { name, position, part }
    Chests = {},
    Remotes = {
        Store = {},
        Raid = {},
        Quest = {},
        Combat = {},
        Other = {},
    },
    AllRemotes = {},   -- full dump: { Class, Name, Path, Instance }
    DumpPath = "PawZHub/BF_Remotes.txt",
    Stats = {
        enemies = 0,
        islands = 0,
        quests = 0,
        fruits = 0,
        remotes = 0,
    },
}

function Paw.WorldClassifyRemote(name)
    local n = string.lower(name or "")
    if n:find("store") or n:find("fruit") and (n:find("put") or n:find("save") or n:find("inventory")) then
        return "Store"
    end
    if n:find("raid") or n:find("chip") or n:find("dungeon") then
        return "Raid"
    end
    if n:find("quest") or n:find("dialogue") or n:find("talk") or n:find("npc") then
        return "Quest"
    end
    if n:find("combat") or n:find("attack") or n:find("damage") or n:find("hit") or n:find("skill") then
        return "Combat"
    end
    return "Other"
end

function Paw.WorldIsIslandName(n)
    n = string.lower(n or "")
    return n:find("island") or n:find("town") or n:find("kingdom") or n:find("castle")
        or n:find("village") or n:find("port") or n:find("dock") or n:find("sea")
        or n:find("jungle") or n:find("desert") or n:find("frozen") or n:find("skypiea")
        or n:find("fountain") or n:find("cafe") or n:find("mansion") or n:find("factory")
end

function World:Clear()
    self.EnemyFolders = {}
    self.Islands = {}
    self.QuestNPCs = {}
    self.FruitSpawns = {}
    self.Chests = {}
    self.Remotes = { Store = {}, Raid = {}, Quest = {}, Combat = {}, Other = {} }
    self.AllRemotes = {}
    self.Stats = { enemies = 0, islands = 0, quests = 0, fruits = 0, remotes = 0 }
end

-- Dump toàn bộ remote ra file + print (gọi khi load)
function World:DumpRemotesToFile()
    local lines = {}
    local timeStr = tostring(os.time and os.time() or tick())
    pcall(function()
        if os.date then timeStr = os.date("%Y-%m-%d %H:%M:%S") end
    end)
    lines[#lines + 1] = "-- PawZHub Blox Fruits Remote Dump"
    lines[#lines + 1] = "-- Time: " .. timeStr
    lines[#lines + 1] = "-- PlaceId: " .. tostring(game.PlaceId)
    lines[#lines + 1] = "-- JobId: " .. tostring(game.JobId)
    lines[#lines + 1] = "-- Total: " .. tostring(#self.AllRemotes)
    lines[#lines + 1] = string.rep("-", 60)

    local byCat = { Store = {}, Raid = {}, Quest = {}, Combat = {}, Other = {} }
    for _, info in ipairs(self.AllRemotes) do
        local cat = Paw.WorldClassifyRemote(info.Name)
        byCat[cat] = byCat[cat] or {}
        table.insert(byCat[cat], info)
    end

    for _, cat in ipairs({ "Store", "Raid", "Quest", "Combat", "Other" }) do
        local list = byCat[cat] or {}
        lines[#lines + 1] = ""
        lines[#lines + 1] = string.format("[%s] (%d)", cat, #list)
        table.sort(list, function(a, b) return a.Path < b.Path end)
        for _, info in ipairs(list) do
            lines[#lines + 1] = string.format("%s\t%s", info.Class, info.Path)
        end
    end

    local text = table.concat(lines, "\n")
    local path = self.DumpPath or "PawZHub/BF_Remotes.txt"

    pcall(function()
        if makefolder then
            pcall(function() makefolder("PawZHub") end)
        end
    end)
    local wrote = false
    pcall(function()
        if writefile then
            writefile(path, text)
            wrote = true
        end
    end)
    pcall(function()
        if setclipboard then setclipboard(text) end
        if toclipboard then toclipboard(text) end
    end)
    pcall(function()
        print("[PawZHub] Remote dump: " .. tostring(#self.AllRemotes) .. " remotes")
        print("[PawZHub] Saved: " .. path)
    end)

    self.LastDumpText = text
    self.LastDumpPath = path
    self.LastDumpWrote = wrote
    return path, #self.AllRemotes, wrote
end

function World:Scan(silent)
    self:Clear()
    local t0 = tick()

    -- 1) Enemy folders
    local enemyNames = {
        "Enemies", "NPCs", "Monsters", "Mobs", "Enemy", "Characters",
        "SpawnedNPCs", "EnemyNpc", "NPC", "Bosses",
    }
    local seenFolder = {}
    local function addEnemyFolder(f)
        if f and not seenFolder[f] then
            seenFolder[f] = true
            table.insert(self.EnemyFolders, f)
        end
    end
    for _, n in ipairs(enemyNames) do
        addEnemyFolder(workspace:FindFirstChild(n))
    end
    pcall(function()
        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("Folder") or child:IsA("Model") then
                for _, subName in ipairs(enemyNames) do
                    local sub = child:FindFirstChild(subName)
                    if sub then addEnemyFolder(sub) end
                end
                -- deep one level
                for _, grand in ipairs(child:GetChildren()) do
                    if grand:IsA("Folder") or grand:IsA("Model") then
                        for _, subName in ipairs(enemyNames) do
                            local sub = grand:FindFirstChild(subName)
                            if sub then addEnemyFolder(sub) end
                        end
                    end
                end
            end
        end
    end)
    self.Stats.enemies = #self.EnemyFolders

    -- 2) Islands / locations
    pcall(function()
        for _, child in ipairs(workspace:GetChildren()) do
            if (child:IsA("Folder") or child:IsA("Model") or child:IsA("BasePart")) and Paw.WorldIsIslandName(child.Name) then
                local part = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true)
                local pos = part and part.Position or nil
                if not pos then
                    pcall(function()
                        local cf = child:GetBoundingBox()
                        pos = cf.Position
                    end)
                end
                if pos then
                    table.insert(self.Islands, { Name = child.Name, Position = pos, Part = part, Instance = child })
                end
            end
        end
        -- also markers
        for _, obj in ipairs(workspace:GetDescendants()) do
            if #self.Islands > 40 then break end
            local n = string.lower(obj.Name)
            if obj:IsA("BasePart") and (n:find("spawn") or n:find("island") or n:find("teleport") or n:find("tp_")) then
                local already = false
                for _, is in ipairs(self.Islands) do
                    if (is.Position - obj.Position).Magnitude < 50 then already = true break end
                end
                if not already then
                    table.insert(self.Islands, { Name = obj.Name, Position = obj.Position, Part = obj, Instance = obj })
                end
            end
        end
    end)
    self.Stats.islands = #self.Islands

    -- 3) Quest NPCs + prompts (gồm ActionText = "Interact" trên NPC quest/giver)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if #self.QuestNPCs > 80 then break end
            if obj:IsA("ProximityPrompt") then
                local parent = obj.Parent
                local model = parent and (parent:IsA("Model") and parent or parent:FindFirstAncestorOfClass("Model"))
                local text = string.lower(table.concat({
                    tostring(obj.ActionText or ""),
                    tostring(obj.ObjectText or ""),
                    tostring(parent and parent.Name or ""),
                    tostring(model and model.Name or ""),
                }, " "))
                if text:find("quest") or text:find("talk") or text:find("accept") or text:find("claim")
                    or text:find("mission") or text:find("giver") or text:find("interact")
                    or text:find("bandit") then
                    local part = parent and (parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart"))
                    if not part and model then
                        part = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                    end
                    if part then
                        table.insert(self.QuestNPCs, {
                            Name = (model and model.Name) or (parent and parent.Name) or "Quest",
                            Position = part.Position,
                            Part = part,
                            Prompt = obj,
                            Model = model or parent,
                        })
                    end
                end
            elseif obj:IsA("Model") then
                local n = string.lower(obj.Name)
                if n:find("quest") or n:find("giver") then
                    local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                    if root then
                        table.insert(self.QuestNPCs, {
                            Name = obj.Name,
                            Position = root.Position,
                            Part = root,
                            Prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true),
                            Model = obj,
                        })
                    end
                end
            end
        end
    end)
    self.Stats.quests = #self.QuestNPCs

    -- 4) Fruit / chest markers (sample)
    pcall(function()
        for _, name in ipairs({ "Fruit", "Fruits", "FruitSpawns", "DevilFruits", "Spawn" }) do
            local f = workspace:FindFirstChild(name)
            if f then
                for _, child in ipairs(f:GetDescendants()) do
                    if #self.FruitSpawns > 40 then break end
                    if child:IsA("BasePart") then
                        table.insert(self.FruitSpawns, { Name = child.Name, Position = child.Position, Part = child })
                    end
                end
            end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if #self.Chests > 30 then break end
            local n = string.lower(obj.Name)
            if (obj:IsA("BasePart") or obj:IsA("Model")) and (n:find("chest") or n:find("crate")) then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    table.insert(self.Chests, { Name = obj.Name, Position = part.Position, Part = part })
                end
            end
        end
    end)
    self.Stats.fruits = #self.FruitSpawns

    -- 5) Remotes (full dump)
    self.AllRemotes = {}
    pcall(function()
        local roots = { game:GetService("ReplicatedStorage") }
        pcall(function()
            local ps = game:GetService("Players").LocalPlayer
            if ps then
                local pg = ps:FindFirstChild("PlayerGui")
                if pg then table.insert(roots, pg) end
            end
        end)
        local seen = {}
        for _, root in ipairs(roots) do
            for _, r in ipairs(root:GetDescendants()) do
                if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction") or r:IsA("UnreliableRemoteEvent")) and not seen[r] then
                    seen[r] = true
                    local path = r:GetFullName()
                    local info = {
                        Class = r.ClassName,
                        Name = r.Name,
                        Path = path,
                        Instance = r,
                    }
                    table.insert(self.AllRemotes, info)
                    local cat = Paw.WorldClassifyRemote(r.Name)
                    if self.Remotes[cat] then
                        table.insert(self.Remotes[cat], r)
                    else
                        table.insert(self.Remotes.Other, r)
                    end
                    self.Stats.remotes = self.Stats.remotes + 1
                end
            end
        end
    end)

    -- Remote dump is opt-in; never do file/clipboard work during startup scan.

    self.Scanned = true
    self.ScannedAt = tick()
    local ms = math.floor((tick() - t0) * 1000)

    if not silent then
        local msg = string.format(
            "Map loaded · E%d · I%d · Q%d · R%d (%dms)",
            self.Stats.enemies, self.Stats.islands, self.Stats.quests, self.Stats.remotes, ms
        )
        pcall(function() Toast:Show(msg, "ok") end)
        if dumpOk then
            pcall(function()
                Toast:Show("Remotes dumped → " .. tostring(dumpPath) .. " (" .. tostring(dumpN) .. ")", "ok")
            end)
        elseif dumpN and dumpN > 0 then
            pcall(function()
                Toast:Show("Remotes: " .. tostring(dumpN) .. " (clipboard / console)", "info")
            end)
        end
    end
    return self.Stats
end

function World:NearestIsland(fromPos)
    local best, bestD = nil, 1e9
    for _, is in ipairs(self.Islands) do
        local d = (is.Position - fromPos).Magnitude
        if d < bestD then bestD = d best = is end
    end
    return best, bestD
end

function World:NearestQuest(fromPos, maxD)
    maxD = maxD or 400
    local best, bestD = nil, maxD
    for _, q in ipairs(self.QuestNPCs) do
        if q.Part and q.Part.Parent then
            local d = (q.Position - fromPos).Magnitude
            if d < bestD then bestD = d best = q end
        end
    end
    return best, bestD
end

function World:FireRemotes(category, ...)
    local list = self.Remotes[category]
    if not list then return 0 end
    local args = table.pack(...)
    -- One candidate per logical action. Do not fan out the same payload to
    -- several name-matched remotes: that creates duplicate/incorrect state.
    for _, r in ipairs(list) do
        local ok, result = pcall(function()
            if r:IsA("RemoteEvent") then
                r:FireServer(table.unpack(args, 1, args.n))
                return true
            elseif r:IsA("RemoteFunction") then
                return r:InvokeServer(table.unpack(args, 1, args.n))
            end
            return false
        end)
        if ok and result ~= false then return 1, result end
    end
    return 0
end

-- ========== FARM AI ==========
local FarmAI = {
    Cache = {},
    CacheAt = 0,
    CacheTTL = 0.45,
    CurrentTarget = nil,
    TargetSince = 0,
    LastPos = nil,
    StuckSince = 0,
    LastKillPos = nil,
    AnchorPos = nil, -- for OwnIslandOnly
    ComboStep = 0,
    LastCombo = 0,
}

local BOSS_KEYWORDS = {
    "boss", "king", "lord", "admiral", "captain", "diamond", "cake", "dough",
    "rip_indra", "indra", "dough king", "stone", "tide", "cyborg", "core",
}
local SKIP_KEYWORDS = {
    "quest", "seller", "shop", "boat", "ship", "trainer", "aura", "blacksmith",
    "npc", "dummy", "statue", "fruit", "dealer", "cousin", "giver", "luxury",
    "sword dealer", "set home", "spawn", "adventurer", "crew", "manager",
    "indra", "mysterious", "title", "home point", "boat dealer", "shipwright",
    "misc", "safe zone",
}

-- Quái farm: trong Enemies + (có [Lv. hoặc tên mob phổ biến), loại NPC shop/quest
local MOB_NAME_OK = {
    "bandit", "monkey", "gorilla", "pirate", "brute", "desert", "snow", "yeti",
    "fishman", "marine", "chief", "sky", "prison", "gladiator", "toga", "military",
    "shanda", "galley", "zombie", "vampire", "raider", "mercenary", "lava", "arctic",
}
local MOB_MAX_HEIGHT = 6000
function Paw.IsValidMobHeight(y)
    y = tonumber(y)
    return y ~= nil and math.abs(y) <= MOB_MAX_HEIGHT
end

function Paw.IsHostileMob(model)
    if not model or not model:IsA("Model") then return false end
    if model == Paw.GetCharacter() then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local n = model.Name or ""
    local lower = string.lower(n)
    -- loại NPC thân thiện
    if lower:find("giver", 1, true) or lower:find("dealer", 1, true)
        or lower:find("shop", 1, true) or lower:find("quest", 1, true)
        or lower:find("seller", 1, true) or lower:find("trainer", 1, true)
        or lower:find("boat", 1, true) or lower:find("set home", 1, true) then
        return false
    end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or hum.MaxHealth <= 0 then return false end
    local root = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model.PrimaryPart
    if not root or not root:IsA("BasePart") then return false end
    if not Paw.IsValidMobHeight(root.Position.Y) then return false end
    -- Y được kiểm tra theo MOB_MAX_HEIGHT để hỗ trợ các khu vực trên cao (Sky và các vùng tương tự).
    -- BF: "Bandit [Lv. 5]" hoặc tên mob
    if n:find("[Lv", 1, true) or n:find("[lv", 1, true) then return true end
    for _, k in ipairs(MOB_NAME_OK) do
        if lower:find(k, 1, true) then return true end
    end
    return false
end

function Paw.IsPlayerChar(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

function Paw.GetRoot(model)
    if not model then return nil end
    local root = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model.PrimaryPart
    if root and root:IsA("BasePart") then return root end
    -- fallback: largest BasePart near center
    local best, bestVol = nil, 0
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") and not p:IsA("Terrain") then
            local s = p.Size
            local vol = s.X * s.Y * s.Z
            if vol > bestVol then
                bestVol = vol
                best = p
            end
        end
    end
    return best
end

function Paw.GetModelCenter(model, root)
    local ok, cf, size = pcall(function()
        return model:GetBoundingBox()
    end)
    if ok and cf then
        return cf.Position, size
    end
    if root then
        return root.Position, root.Size
    end
    return nil, nil
end

-- Combat stand distance by weapon
local FARM_DIST = {
    Melee = 4.5,
    Sword = 5.5,
    Gun   = 18,
    Fruit = 10,
}
local FARM_HEIGHT = {
    Melee = 3.5,
    Sword = 4.0,
    Gun   = 6.0,
    Fruit = 5.0,
}

function Paw.NameLooksBoss(name)
    local n = string.lower(name or "")
    for _, k in ipairs(BOSS_KEYWORDS) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

function Paw.NameLooksSkip(name)
    local n = string.lower(name or "")
    for _, k in ipairs(SKIP_KEYWORDS) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

function Paw.GetPlayerLevel()
    local lvl = 0
    pcall(function()
        local data = Player:FindFirstChild("Data")
        if data then
            local lv = data:FindFirstChild("Level") or data:FindFirstChild("level") or data:FindFirstChild("Lvl")
            if lv then lvl = tonumber(lv.Value) or tonumber(tostring(lv.Value)) or 0 end
        end
        if lvl == 0 then
            local ls = Player:FindFirstChild("leaderstats")
            if ls then
                local lv = ls:FindFirstChild("Level") or ls:FindFirstChild("level")
                if lv then lvl = tonumber(lv.Value) or 0 end
            end
        end
        -- BF đôi khi lưu dưới Player.PlayerGui / replicated folders
        if lvl == 0 then
            for _, name in ipairs({ "Level", "level", "Lvl" }) do
                local v = Player:FindFirstChild(name, true)
                if v and v:IsA("ValueBase") then
                    local n = tonumber(v.Value)
                    if n and n > 0 and n < 10000 then lvl = n break end
                end
            end
        end
    end)
    if lvl <= 0 then lvl = 1 end
    return lvl
end

function Paw.DetectSeaFromLevel(level)
    level = tonumber(level) or Paw.GetPlayerLevel() or 0
    if level >= 1500 then return 3 end
    if level >= 700 then return 2 end
    return 1
end

function Paw.UpdateCurrentSea(force)
    if not force and Config.AutoDetectSea == false then
        return Config.CurrentSea or 1
    end
    local sea = Paw.DetectSeaFromLevel(Paw.GetPlayerLevel())
    -- refine by island name if World scanned
    pcall(function()
        local hrp = Paw.GetHRP()
        if hrp and World.Scanned and #World.Islands > 0 then
            local nearest = World:NearestIsland(hrp.Position)
            if nearest and nearest.Name then
                local n = string.lower(nearest.Name)
                if n:find("cake") or n:find("port") or n:find("hydra") or n:find("haunted") or n:find("tiki") then
                    sea = 3
                elseif n:find("kingdom") or n:find("grave") or n:find("lab") or n:find("hot") or n:find("frozen") then
                    sea = 2
                end
            end
        end
    end)
    Config.CurrentSea = sea
    return sea
end

function Paw.TryAutoStats()
    if not Config.AutoStats then return end
    pcall(function()
        local data = Player:FindFirstChild("Data")
        local points = 0
        if data then
            local p = data:FindFirstChild("Points") or data:FindFirstChild("StatPoints") or data:FindFirstChild("SkillPoints")
            if p then points = tonumber(p.Value) or 0 end
        end
        if points <= 0 then return end
        local order = {}
        if Config.StatMelee then table.insert(order, "Melee") end
        if Config.StatDefense then table.insert(order, "Defense") end
        if Config.StatSword then table.insert(order, "Sword") end
        if Config.StatGun then table.insert(order, "Gun") end
        if #order == 0 then order = { "Melee", "Defense" } end
        local rs = game:GetService("ReplicatedStorage")
        for _, stat in ipairs(order) do
            local remote = nil
            pcall(function()
                for _, r in ipairs(rs:GetDescendants()) do
                    if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
                        local n = string.lower(r.Name)
                        if n:find("stat",1,true) or n:find("upgrade",1,true) or n:find("addpoint",1,true) then
                            remote = r
                            break
                        end
                    end
                end
            end)
            if remote then
                pcall(function()
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer(stat)
                    else
                        remote:InvokeServer(stat)
                    end
                end)
            end
        end
        -- UI fallback
        local pg = Player:FindFirstChild("PlayerGui")
        if pg then
            for _, gui in ipairs(pg:GetDescendants()) do
                if gui:IsA("TextButton") then
                    local t = string.lower(gui.Text or gui.Name or "")
                    for _, stat in ipairs(order) do
                        if t:find(string.lower(stat)) and (t:find("+") or t:find("add") or t:find("upgrade")) then
                            pcall(function() firesignal(gui.MouseButton1Click) end)
                        end
                    end
                end
            end
        end
    end)
end

-- Bảng quest/mob theo level (BF CommF_ StartQuest)
-- QuestName + QuestNum dùng remote; keys = match tên mob; npcCF = vị trí NPC
local LEVEL_FARM_GUIDE = {
    -- Sea 1
    { minL = 0,    maxL = 9,    sea = 1, keys = { "bandit" }, quest = "bandit",
      QuestName = "BanditQuest1", QuestNum = 1,
      npcCF = CFrame.new(1059.37, 16.46, 1550.42),
      mobCF = CFrame.new(1199.0, 16.0, 1630.0) },
    { minL = 10,   maxL = 14,   sea = 1, keys = { "monkey" }, quest = "monkey",
      QuestName = "JungleQuest", QuestNum = 1,
      npcCF = CFrame.new(-1600.34, 36.85, 154.44),
      mobCF = CFrame.new(-1442, 12, 123) },
    { minL = 15,   maxL = 29,   sea = 1, keys = { "gorilla" }, quest = "gorilla",
      QuestName = "JungleQuest", QuestNum = 2,
      npcCF = CFrame.new(-1600.34, 36.85, 154.44),
      mobCF = CFrame.new(-1240, 12, -450) },
    { minL = 30,   maxL = 39,   sea = 1, keys = { "pirate" }, quest = "pirate",
      QuestName = "BuggyQuest1", QuestNum = 1,
      npcCF = CFrame.new(-1141.07, 4.10, 3831.55) },
    { minL = 40,   maxL = 59,   sea = 1, keys = { "brute" }, quest = "brute",
      QuestName = "BuggyQuest1", QuestNum = 2,
      npcCF = CFrame.new(-1141.07, 4.10, 3831.55) },
    { minL = 60,   maxL = 74,   sea = 1, keys = { "desert bandit", "desert" }, quest = "desert",
      QuestName = "DesertQuest", QuestNum = 1,
      npcCF = CFrame.new(894.49, 6.44, 4392.43) },
    { minL = 75,   maxL = 89,   sea = 1, keys = { "desert officer", "officer" }, quest = "desert2",
      QuestName = "DesertQuest", QuestNum = 2,
      npcCF = CFrame.new(894.49, 6.44, 4392.43) },
    { minL = 90,   maxL = 99,   sea = 1, keys = { "snow bandit", "snow" }, quest = "snow",
      QuestName = "SnowQuest", QuestNum = 1,
      npcCF = CFrame.new(1389.74, 87.27, -1298.91) },
    { minL = 100,  maxL = 119,  sea = 1, keys = { "snowman" }, quest = "snow2",
      QuestName = "SnowQuest", QuestNum = 2,
      npcCF = CFrame.new(1389.74, 87.27, -1298.91) },
    { minL = 120,  maxL = 149,  sea = 1, keys = { "chief petty", "marine" }, quest = "marine",
      QuestName = "MarineQuest2", QuestNum = 1,
      npcCF = CFrame.new(-5035.08, 28.65, 4324.29) },
    { minL = 150,  maxL = 174,  sea = 1, keys = { "sky bandit", "sky" }, quest = "sky",
      QuestName = "SkyQuest", QuestNum = 1,
      npcCF = CFrame.new(-4841.83, 717.67, -2623.93) },
    { minL = 175,  maxL = 189,  sea = 1, keys = { "dark master" }, quest = "sky2",
      QuestName = "SkyQuest", QuestNum = 2,
      npcCF = CFrame.new(-4841.83, 717.67, -2623.93) },
    { minL = 190,  maxL = 209,  sea = 1, keys = { "prisoner" }, quest = "prison",
      QuestName = "PrisonerQuest", QuestNum = 1,
      npcCF = CFrame.new(5308.93, 1.65, 474.24) },
    { minL = 210,  maxL = 249,  sea = 1, keys = { "dangerous prisoner" }, quest = "prison2",
      QuestName = "PrisonerQuest", QuestNum = 2,
      npcCF = CFrame.new(5308.93, 1.65, 474.24) },
    { minL = 250,  maxL = 274,  sea = 1, keys = { "toga" }, quest = "colo",
      QuestName = "ColosseumQuest", QuestNum = 1,
      npcCF = CFrame.new(-1576.12, 7.39, -2983.30) },
    { minL = 275,  maxL = 299,  sea = 1, keys = { "gladiator" }, quest = "colo2",
      QuestName = "ColosseumQuest", QuestNum = 2,
      npcCF = CFrame.new(-1576.12, 7.39, -2983.30) },
    { minL = 300,  maxL = 329,  sea = 1, keys = { "military soldier", "military" }, quest = "magma",
      QuestName = "MagmaQuest", QuestNum = 1,
      npcCF = CFrame.new(-5312.36, 12.24, 8517.19) },
    { minL = 330,  maxL = 374,  sea = 1, keys = { "military spy" }, quest = "magma2",
      QuestName = "MagmaQuest", QuestNum = 2,
      npcCF = CFrame.new(-5312.36, 12.24, 8517.19) },
    { minL = 375,  maxL = 399,  sea = 1, keys = { "fishman warrior" }, quest = "fish",
      QuestName = "FishmanQuest", QuestNum = 1,
      npcCF = CFrame.new(61122.65, 18.50, 1569.40) },
    { minL = 400,  maxL = 449,  sea = 1, keys = { "fishman commando" }, quest = "fish2",
      QuestName = "FishmanQuest", QuestNum = 2,
      npcCF = CFrame.new(61122.65, 18.50, 1569.40) },
    { minL = 450,  maxL = 474,  sea = 1, keys = { "god's guard", "gods guard" }, quest = "skyexp",
      QuestName = "SkyExp1Quest", QuestNum = 1,
      npcCF = CFrame.new(-4721.89, 843.87, -1949.97) },
    { minL = 475,  maxL = 524,  sea = 1, keys = { "shanda" }, quest = "skyexp2",
      QuestName = "SkyExp1Quest", QuestNum = 2,
      npcCF = CFrame.new(-7859.10, 5544.19, -381.48) },
    { minL = 525,  maxL = 549,  sea = 1, keys = { "royal squad" }, quest = "skyexp3",
      QuestName = "SkyExp2Quest", QuestNum = 1,
      npcCF = CFrame.new(-7894.62, 5547.14, -380.29) },
    { minL = 550,  maxL = 624,  sea = 1, keys = { "royal soldier" }, quest = "skyexp4",
      QuestName = "SkyExp2Quest", QuestNum = 2,
      npcCF = CFrame.new(-7894.62, 5547.14, -380.29) },
    { minL = 625,  maxL = 649,  sea = 1, keys = { "galley pirate" }, quest = "fountain",
      QuestName = "FountainQuest", QuestNum = 1,
      npcCF = CFrame.new(5259.82, 38.53, 4050.03) },
    { minL = 650,  maxL = 699,  sea = 1, keys = { "galley captain" }, quest = "fountain2",
      QuestName = "FountainQuest", QuestNum = 2,
      npcCF = CFrame.new(5259.82, 38.53, 4050.03) },
    -- Sea 2 (simplified keys; QuestName common BF)
    { minL = 700,  maxL = 874,  sea = 2, keys = { "raider", "pirate" }, quest = "area1",
      QuestName = "Area1Quest", QuestNum = 1 },
    { minL = 875,  maxL = 899,  sea = 2, keys = { "mercenary" }, quest = "area1b",
      QuestName = "Area1Quest", QuestNum = 2 },
    { minL = 900,  maxL = 949,  sea = 2, keys = { "swan pirate" }, quest = "area2",
      QuestName = "Area2Quest", QuestNum = 1 },
    { minL = 950,  maxL = 974,  sea = 2, keys = { "factory staff" }, quest = "area2b",
      QuestName = "Area2Quest", QuestNum = 2 },
    { minL = 975,  maxL = 999,  sea = 2, keys = { "marine lieutenant", "marine captain" }, quest = "marinef",
      QuestName = "MarineQuest3", QuestNum = 1 },
    { minL = 1000, maxL = 1049, sea = 2, keys = { "zombie" }, quest = "grave",
      QuestName = "ZombieQuest", QuestNum = 1 },
    { minL = 1050, maxL = 1099, sea = 2, keys = { "vampire" }, quest = "grave2",
      QuestName = "ZombieQuest", QuestNum = 2 },
    { minL = 1100, maxL = 1124, sea = 2, keys = { "snow trooper" }, quest = "snow2",
      QuestName = "SnowQuest2", QuestNum = 1 },
    { minL = 1125, maxL = 1174, sea = 2, keys = { "winter warrior" }, quest = "snow2b",
      QuestName = "SnowQuest2", QuestNum = 2 },
    { minL = 1175, maxL = 1199, sea = 2, keys = { "lab sub", "scientist" }, quest = "lab",
      QuestName = "IceSideQuest", QuestNum = 1 },
    { minL = 1200, maxL = 1249, sea = 2, keys = { "arctic warrior" }, quest = "lab2",
      QuestName = "IceSideQuest", QuestNum = 2 },
    { minL = 1250, maxL = 1299, sea = 2, keys = { "fire" }, quest = "fire",
      QuestName = "FireSideQuest", QuestNum = 1 },
    { minL = 1300, maxL = 1324, sea = 2, keys = { "lava pirate" }, quest = "fire2",
      QuestName = "FireSideQuest", QuestNum = 2 },
    { minL = 1325, maxL = 1349, sea = 2, keys = { "ship deckhand" }, quest = "ship",
      QuestName = "ShipQuest1", QuestNum = 1 },
    { minL = 1350, maxL = 1374, sea = 2, keys = { "ship engineer" }, quest = "ship2",
      QuestName = "ShipQuest1", QuestNum = 2 },
    { minL = 1375, maxL = 1424, sea = 2, keys = { "ship steward" }, quest = "ship3",
      QuestName = "ShipQuest2", QuestNum = 1 },
    { minL = 1425, maxL = 1449, sea = 2, keys = { "ship officer" }, quest = "ship4",
      QuestName = "ShipQuest2", QuestNum = 2 },
    { minL = 1450, maxL = 1499, sea = 2, keys = { "arctic warrior", "snow" }, quest = "frost",
      QuestName = "FrostQuest", QuestNum = 1 },
    -- Sea 3
    { minL = 1500, maxL = 1524, sea = 3, keys = { "pirate soldier", "girl" }, quest = "port",
      QuestName = "PiratePortQuest", QuestNum = 1 },
    { minL = 1525, maxL = 1574, sea = 3, keys = { "pistol brevet" }, quest = "port2",
      QuestName = "PiratePortQuest", QuestNum = 2 },
    { minL = 1575, maxL = 1599, sea = 3, keys = { "female island raider" }, quest = "amazon",
      QuestName = "AmazonQuest", QuestNum = 1 },
    { minL = 1600, maxL = 1624, sea = 3, keys = { "giant islander" }, quest = "amazon2",
      QuestName = "AmazonQuest", QuestNum = 2 },
    { minL = 1625, maxL = 1649, sea = 3, keys = { "marine commodore" }, quest = "marine3",
      QuestName = "MarineTreeIsland", QuestNum = 1 },
    { minL = 1650, maxL = 1699, sea = 3, keys = { "marine rear" }, quest = "marine3b",
      QuestName = "MarineTreeIsland", QuestNum = 2 },
    { minL = 1700, maxL = 1724, sea = 3, keys = { "front seed" }, quest = "cake",
      QuestName = "CandyQuest1", QuestNum = 1 },
    { minL = 1725, maxL = 1774, sea = 3, keys = { "cake" }, quest = "cake2",
      QuestName = "CandyQuest1", QuestNum = 2 },
    { minL = 1775, maxL = 1799, sea = 3, keys = { "peanut" }, quest = "peanut",
      QuestName = "IceCreamIslandQuest", QuestNum = 1 },
    { minL = 1800, maxL = 1924, sea = 3, keys = { "ice cream" }, quest = "icecream",
      QuestName = "IceCreamIslandQuest", QuestNum = 2 },
    { minL = 1925, maxL = 1974, sea = 3, keys = { "cookie" }, quest = "cookie",
      QuestName = "CakeQuest1", QuestNum = 1 },
    { minL = 1975, maxL = 1999, sea = 3, keys = { "cake baked" }, quest = "cookie2",
      QuestName = "CakeQuest1", QuestNum = 2 },
    { minL = 2000, maxL = 2049, sea = 3, keys = { "cocoa" }, quest = "cocoa",
      QuestName = "ChocQuest1", QuestNum = 1 },
    { minL = 2050, maxL = 2074, sea = 3, keys = { "candy" }, quest = "cocoa2",
      QuestName = "ChocQuest2", QuestNum = 1 },
    { minL = 2075, maxL = 2099, sea = 3, keys = { "candy pirate" }, quest = "candy",
      QuestName = "ChocQuest2", QuestNum = 2 },
    { minL = 2100, maxL = 2149, sea = 3, keys = { "peanut" }, quest = "peanut2",
      QuestName = "CandyQuest2", QuestNum = 1 },
    { minL = 2150, maxL = 2199, sea = 3, keys = { "cake" }, quest = "cake3",
      QuestName = "CandyQuest2", QuestNum = 2 },
    { minL = 2200, maxL = 2249, sea = 3, keys = { "baking staff" }, quest = "bake",
      QuestName = "CakeQuest2", QuestNum = 1 },
    { minL = 2250, maxL = 2299, sea = 3, keys = { "head baker" }, quest = "bake2",
      QuestName = "CakeQuest2", QuestNum = 2 },
    { minL = 2300, maxL = 2349, sea = 3, keys = { "cocoa warrior" }, quest = "hydra",
      QuestName = "TikiQuest1", QuestNum = 1 },
    { minL = 2350, maxL = 2399, sea = 3, keys = { "chocolate bar" }, quest = "hydra2",
      QuestName = "TikiQuest1", QuestNum = 2 },
    { minL = 2400, maxL = 2449, sea = 3, keys = { "sweet fruit" }, quest = "tiki",
      QuestName = "TikiQuest2", QuestNum = 1 },
    { minL = 2450, maxL = 2499, sea = 3, keys = { "cake queen" }, quest = "tiki2",
      QuestName = "TikiQuest2", QuestNum = 2 },
    { minL = 2500, maxL = 9999, sea = 3, keys = { "haunted", "ghost", "posses" }, quest = "haunted",
      QuestName = "HauntedQuest1", QuestNum = 1 },
}

function Paw.GetLevelFarmGuide(level)
    level = tonumber(level) or Paw.GetPlayerLevel() or 0
    local sea = tonumber(Config.CurrentSea) or 1
    local best = LEVEL_FARM_GUIDE[1]
    for _, row in ipairs(LEVEL_FARM_GUIDE) do
        if level >= row.minL and level <= row.maxL then
            -- ưu tiên đúng sea nếu có
            if row.sea == sea or sea == 0 then
                return row
            end
            best = row
        end
    end
    -- fallback: row gần level nhất
    local closest, cd = best, 1e9
    for _, row in ipairs(LEVEL_FARM_GUIDE) do
        local mid = (row.minL + row.maxL) / 2
        local d = math.abs(mid - level)
        if d < cd then cd = d closest = row end
    end
    return closest
end

function Paw.MobMatchesGuide(mobName, guide)
    if not guide or not guide.keys then return false end
    local n = string.lower(mobName or "")
    for _, k in ipairs(guide.keys) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

-- Fruit Sniper helpers
local FruitSniperAI = {
    Cache = {},
    CacheAt = 0,
    CacheTTL = 0.8,
    LastFound = 0,
    LastHop = 0,
    LastToast = {},
}

function Paw.FruitInSniperList(name, cfg)
    local list = (cfg and cfg.SniperList) or Config.SniperList
    if type(list) ~= "table" or #list == 0 then return true, 99 end
    local n = string.lower(name or "")
    for i, key in ipairs(list) do
        local k = string.lower(tostring(key))
        if k ~= "" and n:find(k, 1, true) then
            return true, i -- index = priority (1 = highest)
        end
    end
    return false, 999
end

function Paw.ResolveFruitName(obj)
    if not obj then return "" end
    local names = { obj.Name }
    pcall(function()
        if obj.Parent then table.insert(names, obj.Parent.Name) end
        if obj.Parent and obj.Parent.Parent then table.insert(names, obj.Parent.Parent.Name) end
        local attr = obj:GetAttribute("FruitName") or obj:GetAttribute("Name")
        if attr then table.insert(names, tostring(attr)) end
        if obj:IsA("Model") or obj:IsA("Tool") then
            local handle = obj:FindFirstChild("Handle")
            if handle then table.insert(names, handle.Name) end
        end
    end)
    return table.concat(names, " ")
end

function Paw.IsFruitLike(obj, nameBlob)
    local n = string.lower(nameBlob or Paw.ResolveFruitName(obj))
    if n:find("fruit", 1, true) or n:find("eatable", 1, true) or n:find("devil", 1, true) then
        return true
    end
    -- sniper keys often appear without "fruit" suffix
    local ok = Paw.FruitInSniperList(n, Config)
    if ok then return true end
    if obj:IsA("Tool") then
        -- Tools include swords/guns as well as fruits. Only treat a Tool as a
        -- fruit when its identity actually looks fruit-like.
        return n:find("fruit", 1, true) ~= nil
            or n:find("eatable", 1, true) ~= nil
            or n:find("devil", 1, true) ~= nil
            or Paw.FruitInSniperList(n, Config)
    end
    return false
end

function Paw.CollectEnemyFolders()
    -- CHỈ folder Enemies — không quét NPCs (shop / quest giver)
    local folders = {}
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then table.insert(folders, enemies) end
    pcall(function()
        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("Folder") or child:IsA("Model") then
                local sub = child:FindFirstChild("Enemies")
                if sub and sub ~= enemies then table.insert(folders, sub) end
            end
        end
    end)
    if World.Scanned and World.EnemyFolders then
        for _, f in ipairs(World.EnemyFolders) do
            if f and f.Parent and f.Name:lower():find("enem") then
                local dup = false
                for _, x in ipairs(folders) do if x == f then dup = true break end end
                if not dup then table.insert(folders, f) end
            end
        end
    end
    return folders
end

function Paw.RefreshEnemyCache()
    local now = tick()
    if now - FarmAI.CacheAt < FarmAI.CacheTTL and #FarmAI.Cache > 0 then
        return FarmAI.Cache
    end
    local list = {}
    local function consider(model)
        if not Paw.IsHostileMob(model) then return end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = Paw.GetRoot(model)
        if not hum or not root then return end
        if hum.Health <= 0 or hum.MaxHealth <= 0 then return end
        -- nhớ Y mặt đất gốc (tránh kéo lên trời)
        local gy = root.Position.Y
        if not Paw.IsValidMobHeight(gy) then return end
        table.insert(list, {
            Model = model,
            Humanoid = hum,
            Root = root,
            Name = model.Name,
            IsBoss = Paw.NameLooksBoss(model.Name),
            MaxHP = hum.MaxHealth,
            HP = hum.Health,
            GroundY = gy,
        })
    end
    for _, folder in ipairs(Paw.CollectEnemyFolders()) do
        for _, child in ipairs(folder:GetChildren()) do
            consider(child)
        end
    end
    -- không fallback workspace (tránh dính NPC)
    FarmAI.Cache = list
    FarmAI.CacheAt = now
    return list
end

function Paw.ScoreTarget(entry, hrp, cfg, mode)
    if not entry or not entry.Root or not entry.Root.Parent then return -1e9 end
    if entry.Model and not Paw.IsHostileMob(entry.Model) then return -1e9 end
    local hum = entry.Humanoid
    if not hum or not hum.Parent then
        hum = entry.Model and entry.Model:FindFirstChildOfClass("Humanoid")
        entry.Humanoid = hum
    end
    if not hum or hum.Health <= 0 then return -1e9 end
    if not Paw.IsValidMobHeight(entry.Root.Position.Y) then return -1e9 end
    local dist = (entry.Root.Position - hrp.Position).Magnitude
    local range = tonumber(cfg.FarmRange) or 80
    if dist > range * 3 then return -1e9 end -- hard reject very far

    -- Own island: only near anchor
    if cfg.OwnIslandOnly ~= false and FarmAI.AnchorPos then
        local fromAnchor = (entry.Root.Position - FarmAI.AnchorPos).Magnitude
        if fromAnchor > math.max(range * 2.5, 180) then
            return -1e9
        end
    end

    local score = 0
    local hpRatio = entry.Humanoid.Health / math.max(1, entry.Humanoid.MaxHealth)
    local guide = (cfg.QuestByLevel ~= false) and Paw.GetLevelFarmGuide(Paw.GetPlayerLevel()) or nil
    local levelMatch = guide and Paw.MobMatchesGuide(entry.Name, guide)

    if mode == "boss" then
        if entry.IsBoss then score = score + 5000 end
        score = score - dist * 2
        score = score + (1 - hpRatio) * 100
    elseif mode == "mastery" then
        -- Mastery: mob khỏe, gần, cùng loại — để đánh lâu bằng đúng weapon
        score = score - dist * 2.5
        if not entry.IsBoss then score = score + 250 end
        -- máu cao hơn = farm mastery lâu hơn
        score = score + hpRatio * 120
        score = score + math.min(entry.MaxHP or 0, 80000) * 0.001
        if FarmAI.CurrentTarget and FarmAI.CurrentTarget.Parent
            and entry.Name == FarmAI.CurrentTarget.Name then
            score = score + 500
        end
        if levelMatch then score = score + 200 end
    elseif mode == "fruit" then
        score = score - dist * 2
        if not entry.IsBoss then score = score + 150 end
    else -- level
        score = score - dist * 4
        if cfg.PreferNearest ~= false then
            score = score - dist * 2
        end
        if cfg.PreferHighestXP then
            score = score + math.min(entry.MaxHP or 0, 50000) * 0.002
        end
        -- Ưu tiên mạnh mob đúng bảng level
        if levelMatch then
            score = score + 800
        elseif guide then
            score = score - 120 -- mob lệch level
        end
        if entry.IsBoss then
            if dist > 40 then score = score - 800 end
        else
            score = score + 120
        end
        score = score + (1 - hpRatio) * 150
        if FarmAI.CurrentTarget and FarmAI.CurrentTarget == entry.Model then
            score = score + 350
        end
    end

    if dist <= range then
        score = score + 100
    else
        score = score - (dist - range) * 1.5
    end
    return score
end

-- cfg chiến đấu mở rộng: tránh kẹt OwnIsland / range nhỏ / Bring tắt
function Paw.ExpandFarmCfg(cfg, opts)
    opts = opts or {}
    local t = {}
    if type(cfg) == "table" then
        for k, v in pairs(cfg) do t[k] = v end
    end
    local minRange = tonumber(opts.minRange) or 250
    t.FarmRange = math.max(tonumber(t.FarmRange) or 80, minRange)
    if opts.ownIsland == nil then
        t.OwnIslandOnly = false
    else
        t.OwnIslandOnly = opts.ownIsland and true or false
    end
    -- Preserve BringMobs unless caller explicitly overrides it.
    if opts.bringMobs ~= nil then
        t.BringMobs = opts.bringMobs and true or false
    else
        t.BringMobs = t.BringMobs ~= false
    end
    t.BringRange = math.max(tonumber(t.BringRange) or 120, tonumber(opts.bringRange) or 220)
    t.BringMax = math.max(tonumber(t.BringMax) or 8, tonumber(opts.bringMax) or 12)
    if t.BringLock == nil then t.BringLock = true end
    t.FastAttack = true
    t.PreferNearest = t.PreferNearest ~= false
    return t
end

function Paw.SelectFarmTarget(cfg, mode)
    local hrp = Paw.GetHRP()
    if not hrp then return nil, nil end
    if not FarmAI.AnchorPos then
        FarmAI.AnchorPos = hrp.Position
    end
    local list = Paw.RefreshEnemyCache()
    local best, bestScore, bestDist = nil, -1e9, 99999
    for _, entry in ipairs(list) do
        local s = Paw.ScoreTarget(entry, hrp, cfg, mode)
        if s > bestScore then
            bestScore = s
            best = entry
            bestDist = (entry.Root.Position - hrp.Position).Magnitude
        end
    end
    if best and bestScore > -1e8 then
        return best.Model, bestDist, best
    end
    return nil, nil, nil
end

--[[
    Đứng đúng chỗ đánh:
    - Lấy tâm / HRP thật của mob (bounding box)
    - Khoảng cách theo vũ khí (Melee gần, Gun xa)
    - Cao theo hitbox mob + offset an toàn
    - Đứng phía trước mặt mob một chút (hoặc orbit nhẹ) và nhìn vào tâm
]]
function Paw.GetFarmCFrame(targetModel, targetRoot, cfg)
    local weapon = tostring(cfg and cfg.SelectedWeapon or "Melee")
    local baseDist = FARM_DIST[weapon] or FARM_DIST.Melee
    local baseH = tonumber(cfg and cfg.FarmHeight) or FARM_HEIGHT[weapon] or FARM_HEIGHT.Melee

    local center, size = Paw.GetModelCenter(targetModel, targetRoot)
    if not center then
        center = targetRoot and targetRoot.Position or Vector3.zero
        size = targetRoot and targetRoot.Size or Vector3.new(2, 5, 2)
    end

    -- scale distance/height by mob size (boss lớn → đứng xa hơn, cao hơn)
    local span = 2
    if size then
        span = math.max(size.X, size.Z, 2)
        baseDist = baseDist + math.clamp(span * 0.35, 0, 12)
        baseH = baseH + math.clamp((size.Y or 5) * 0.12, 0, 6)
    end

    -- hướng đứng: từ mob nhìn ra — ưu tiên LookVector; nếu mob quay lung thì vẫn ổn vì ta lookAt center
    local forward = Vector3.new(0, 0, -1)
    if targetRoot then
        local lv = targetRoot.CFrame.LookVector
        forward = Vector3.new(lv.X, 0, lv.Z)
        if forward.Magnitude < 0.1 then
            forward = Vector3.new(0, 0, -1)
        else
            forward = forward.Unit
        end
    end

    -- orbit nhẹ theo thời gian để skill AOE / tránh stuck cùng 1 điểm
    local angle = (tick() * 0.7) % (math.pi * 2)
    local side = Vector3.new(-forward.Z, 0, forward.X) -- perpendicular
    local orbit = (forward * math.cos(angle * 0.15) + side * math.sin(angle * 0.15))
    if orbit.Magnitude > 0.05 then
        orbit = orbit.Unit
    else
        orbit = -forward
    end

    -- FarmHeight is a real user setting. Keep it within a sane combat range,
    -- but do not collapse every value to 4..8 (that made the UI setting lie).
    baseH = math.clamp(tonumber(baseH) or 5, 0, 30)
    local bodyH = math.clamp((size and size.Y) or 5, 2, 20)
    local baseY = center.Y
    -- Only flatten low-altitude terrain noise. Do not raycast from Y=80 for
    -- Sky/Sea-3 targets because that can snap the combat position to sea level.
    if math.abs(baseY) < 300 then
        pcall(function()
            local res = workspace:Raycast(Vector3.new(center.X, center.Y + 60, center.Z), Vector3.new(0, -180, 0))
            if res then baseY = res.Position.Y + 2 end
        end)
    end

    -- Đứng hơi lệch trước mặt mob (ổn định, orbit rất chậm để tránh giật)
    -- baseDist giữ khoảng cách đánh; height = FarmHeight
    local orbitDir = -forward
    if orbitDir.Magnitude < 0.05 then orbitDir = Vector3.new(0, 0, -1) else orbitDir = orbitDir.Unit end
    -- orbit cực chậm + biên độ nhỏ (chỉ khi xa), gần thì đứng yên tương đối
    local slowAngle = (tick() * 0.08) % (math.pi * 2)
    local orbitAmt = math.clamp(baseDist * 0.12, 0.4, 1.8)
    orbitDir = (orbitDir * math.cos(slowAngle * 0.05) + side * math.sin(slowAngle * 0.05) * 0.35)
    if orbitDir.Magnitude > 0.05 then orbitDir = orbitDir.Unit end
    -- Melee/Sword: đứng sát + hơi cao để M1 chạm nhiều mob trong stack
    -- Gun/Fruit: đứng xa hơn (đánh xa)
    local weapon = tostring(cfg and cfg.SelectedWeapon or "Melee")
    local distMul = 0.55
    local standH = math.clamp(baseH, 1.5, 14)
    if weapon == "Gun" then
        distMul = 1.15
        standH = math.clamp(baseH + 2, 4, 16)
    elseif weapon == "Fruit" then
        distMul = 0.95
        standH = math.clamp(baseH + 1, 3, 14)
    else
        -- gần stack để AOE M1 / skill trúng nhiều con
        distMul = 0.35
        standH = math.clamp(baseH * 0.7, 2, 9)
    end
    local dest = Vector3.new(center.X, baseY + bodyH * 0.25 + standH, center.Z) + orbitDir * math.max(2.0, baseDist * distMul)

    local maxCombatY = baseY + 24
    if dest.Y > maxCombatY then dest = Vector3.new(dest.X, maxCombatY, dest.Z) end
    if dest.Y < baseY - 6 then dest = Vector3.new(dest.X, baseY + 2, dest.Z) end

    return CFrame.new(dest, center), dest, center, baseDist
end

function Paw.ClampWorldPos(pos, refY)
    if typeof(pos) ~= "Vector3" then return pos end
    local y = pos.Y
    local base = tonumber(refY) or y
    -- Keep large but legitimate Sky/Sea-3 coordinates; only reject clearly
    -- corrupted/fling values. The old 250 cap broke every high-altitude island.
    local WORLD_Y_MIN, WORLD_Y_MAX = -250, 6500
    if y ~= y or math.abs(y) > 5e4 then
        y = math.clamp(base, WORLD_Y_MIN, WORLD_Y_MAX)
    else
        y = math.clamp(y, WORLD_Y_MIN, WORLD_Y_MAX)
    end
    local x, z = pos.X, pos.Z
    if x ~= x or math.abs(x) > 5e4 then x = 0 end
    if z ~= z or math.abs(z) > 5e4 then z = 0 end
    return Vector3.new(x, y, z)
end

-- Tween-style step: tiến dần tới dest (mượt hơn TP cứng)
function Paw.StabilizeHRP(hrp)
    if not hrp then return end
    -- Chỉ zero velocity để server không kéo nhân vật lại (giật)
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    pcall(function()
        local hum = Paw.GetHumanoid()
        if hum and hum.FloorMaterial == Enum.Material.Air then
            -- đang bay/farm trên đầu mob: tắt jump để không bay thêm
            hum.Jump = false
        end
    end)
end

-- Tween-style step: chậm + zero velocity → giảm giật do server reconcile
function Paw.TweenStepTo(hrp, dest, lookAt, speed)
    if not hrp or not dest then return end
    speed = math.clamp(tonumber(speed) or tonumber(Config and Config.TweenSpeed) or 160, 60, 320)
    if Paw.ClampWorldPos then dest = Paw.ClampWorldPos(dest, hrp.Position.Y) end
    local myPos = hrp.Position
    local delta = dest - myPos
    local dist = delta.Magnitude
    local look = lookAt or dest
    -- Đã gần điểm đánh: chỉ chỉnh hướng nhìn, KHÔNG teleport liên tục (gây giật)
    if dist < 2.5 then
        pcall(function()
            local face = Vector3.new(look.X, myPos.Y, look.Z)
            if (face - myPos).Magnitude > 0.05 then
                hrp.CFrame = CFrame.new(myPos, face)
            end
            Paw.StabilizeHRP(hrp)
        end)
        return true
    end
    -- Bước ngắn theo tốc độ (mặc định ~8–18 studs/tick), không nhảy lớn
    local step = math.clamp(speed * 0.035, 4, 22)
    local nextPos = myPos + delta.Unit * math.min(step, dist)
    if Paw.ClampWorldPos then nextPos = Paw.ClampWorldPos(nextPos, hrp.Position.Y) end
    pcall(function()
        hrp.CFrame = CFrame.new(nextPos, look)
        Paw.StabilizeHRP(hrp)
    end)
    return false
end

-- Tiếp cận: TweenFarm = bước mượt; tắt = TP theo khoảng cách
function Paw.MoveToFarmSpot(hrp, targetModel, targetRoot, cfg, stuck)
    if not hrp or not targetRoot then return end
    local cf, dest, center, fightDist = Paw.GetFarmCFrame(targetModel, targetRoot, cfg)
    local myPos = hrp.Position
    local dist = (myPos - center).Magnitude
    local useTween = cfg.TweenFarm ~= false

    if stuck then
        local jitter = CFrame.new(math.random(-5, 5), math.random(1, 4), math.random(-5, 5))
        pcall(function() hrp.CFrame = cf * jitter end)
        return dest
    end

    if useTween then
        if dist > (fightDist or 8) + 90 then
            -- Quá xa: TP gần vòng ngoài (1 lần), rồi tween mượt
            local radial = myPos - center
            if radial.Magnitude < 0.1 then radial = Vector3.new(0, 0, 1) end
            radial = radial.Unit
            local mid = center + radial * ((fightDist or 8) + 30)
            local h = math.clamp(tonumber(cfg.FarmHeight) or 6, 0, 18)
            mid = Vector3.new(mid.X, center.Y + h, mid.Z)
            pcall(function()
                hrp.CFrame = CFrame.new(mid, center)
                Paw.StabilizeHRP(hrp)
            end)
        elseif dist > (fightDist or 8) + 6 then
            Paw.TweenStepTo(hrp, dest, center, tonumber(cfg.TweenSpeed) or 160)
        else
            -- Trong tầm đánh: chỉ giữ hướng nhìn + zero velocity (không giật)
            pcall(function()
                local face = Vector3.new(center.X, myPos.Y, center.Z)
                if (myPos - dest).Magnitude > 3.5 then
                    Paw.TweenStepTo(hrp, dest, center, math.min(tonumber(cfg.TweenSpeed) or 160, 120))
                else
                    if (face - myPos).Magnitude > 0.1 then
                        hrp.CFrame = CFrame.new(myPos, face)
                    end
                    Paw.StabilizeHRP(hrp)
                end
            end)
        end
        return dest
    end

    if dist > (fightDist or 8) + 35 then
        local radial = myPos - center
        if radial.Magnitude < 0.1 then radial = Vector3.new(0, 0, 1) end
        radial = radial.Unit
        local mid = center + radial * ((fightDist or 8) + 8)
        mid = Vector3.new(mid.X, center.Y + math.clamp(tonumber(cfg.FarmHeight) or 4, 0, 30), mid.Z)
        pcall(function() hrp.CFrame = CFrame.new(mid, center) end)
    elseif dist > (fightDist or 8) + 8 then
        pcall(function() hrp.CFrame = cf end)
    else
        local toDest = (dest - myPos).Magnitude
        if toDest > 2.2 then
            pcall(function() hrp.CFrame = cf end)
        else
            pcall(function()
                hrp.CFrame = CFrame.new(myPos, Vector3.new(center.X, myPos.Y, center.Z))
            end)
        end
    end
    return dest
end

--[[
  Gom quái (Bring / Magnet) — kéo mob trong BringRange về 1 điểm trước mặt player
  Giống các hub BF phổ biến: stack HRP → đánh AOE 1 phát nhiều con
]]
local BringState = { locked = {}, original = {}, last = 0 }
local RestoreBringState

function Paw.BringMobsToStack(hrp, cfg, primaryTarget)
    if not cfg or not cfg.BringMobs then
        if next(BringState.original or {}) ~= nil then RestoreBringState() end
        return 0
    end
    if not hrp then return 0 end
    local range = tonumber(cfg.BringRange) or 120
    local maxN = tonumber(cfg.BringMax) or 8
    local lock = cfg.BringLock ~= false
    local list = Paw.RefreshEnemyCache()
    if not list or #list == 0 then return 0 end

    -- player quá cao (đã bay trời) → không bring cho đến khi về gần đất
    if not Paw.IsValidMobHeight(hrp.Position.Y) then return 0 end

    local look = hrp.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.1 then flat = Vector3.new(0, 0, -1) else flat = flat.Unit end

    local function resolveGroundY(pos)
        local gy = pos.Y
        pcall(function()
            local origin = Vector3.new(pos.X, pos.Y + 8, pos.Z)
            local res = workspace:Raycast(origin, Vector3.new(0, -120, 0))
            if res then gy = res.Position.Y + 1.5 end
        end)
        if math.abs(gy) > 150 then gy = 5 end
        return gy
    end

    local pr0 = primaryTarget and Paw.GetRoot(primaryTarget)
    local groundY = resolveGroundY(pr0 and pr0.Position or hrp.Position)
    -- ưu tiên GroundY đã lưu trên cache entry
    if primaryTarget then
        for _, e in ipairs(list) do
            if e.Model == primaryTarget and e.GroundY then
                groundY = e.GroundY
                break
            end
        end
    end

    local stackPos = Vector3.new(hrp.Position.X, groundY, hrp.Position.Z) + flat * 3.5
    if pr0 then
        stackPos = Vector3.new(pr0.Position.X, groundY, pr0.Position.Z)
    end

    local anchor = FarmAI.AnchorPos
    local ownOnly = cfg.OwnIslandOnly ~= false
    local guide = (cfg.QuestByLevel ~= false and cfg.AutoFarmLevel) and Paw.GetLevelFarmGuide(Paw.GetPlayerLevel()) or nil

    local candidates = {}
    for _, entry in ipairs(list) do
        local hum = entry.Humanoid or (entry.Model and entry.Model:FindFirstChildOfClass("Humanoid"))
        local root = entry.Root
        if root and hum and hum.Parent and hum.Health > 0 and entry.Model and entry.Model.Parent then
            if not Paw.IsHostileMob(entry.Model) then
                -- skip NPC / shop
            elseif entry.IsBoss and not cfg.AutoBoss then
                -- skip bosses unless boss farm
            else
                -- bỏ mob đã fling / void
                if not Paw.IsValidMobHeight(root.Position.Y) then
                    -- skip
                else
                    local d = (root.Position - hrp.Position).Magnitude
                    if d <= range then
                        local ok = true
                        if ownOnly and anchor then
                            if (root.Position - anchor).Magnitude > math.max(range * 1.2, 150) then
                                ok = false
                            end
                        end
                        if ok then
                            local bonus = 0
                            if guide and Paw.MobMatchesGuide(entry.Name, guide) then bonus = -30 end
                            candidates[#candidates + 1] = { e = entry, hum = hum, d = d + bonus }
                        end
                    end
                end
            end
        end
    end
    table.sort(candidates, function(a, b) return a.d < b.d end)

    local brought = 0
    local now = tick()
    for i, item in ipairs(candidates) do
        if brought >= maxN then break end
        local entry = item.e
        local root = entry.Root
        local hum = item.hum
        local offset = Vector3.new(
            ((i - 1) % 3 - 1) * 1.1,
            0,
            (math.floor((i - 1) / 3) % 3 - 1) * 1.1
        )
        local gy = entry.GroundY or stackPos.Y
        if math.abs(gy) > 150 then gy = stackPos.Y end
        local dest = Vector3.new(stackPos.X + offset.X, gy, stackPos.Z + offset.Z)
        pcall(function()
            if not root or not root.Parent or not root:IsA("BasePart") then return end
            if not hum or not hum.Parent then return end
            if not Paw.IsHostileMob(entry.Model) then return end
            pcall(function()
                if root.SetNetworkOwner then root:SetNetworkOwner(Player) end
            end)
            pcall(function()
                local snap = BringState.original[entry.Model]
                if not snap then
                    snap = { parts = {}, humanoid = nil, bodyVelocity = false }
                    BringState.original[entry.Model] = snap
                end
                for _, bp in ipairs(entry.Model:GetDescendants()) do
                    if bp:IsA("BasePart") then
                        if snap.parts[bp] == nil then snap.parts[bp] = bp.CanCollide end
                        bp.CanCollide = false
                        pcall(function()
                            if bp.SetNetworkOwner then bp:SetNetworkOwner(Player) end
                        end)
                    end
                end
            end)
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
            root.CFrame = CFrame.new(dest, Vector3.new(hrp.Position.X, dest.Y, hrp.Position.Z))
            if lock then
                local drift = (root.Position - dest).Magnitude
                if drift > 3 and Paw.IsValidMobHeight(root.Position.Y) then
                    root.CFrame = CFrame.new(dest, Vector3.new(hrp.Position.X, dest.Y, hrp.Position.Z))
                end
                pcall(function()
                    local bv = root:FindFirstChild("PawZBringBV")
                    if not bv then
                        bv = Instance.new("BodyVelocity")
                        bv.Name = "PawZBringBV"
                        bv.MaxForce = Vector3.new(9e4, 9e4, 9e4)
                        bv.Velocity = Vector3.zero
                        bv.Parent = root
                    end
                    bv.Velocity = Vector3.zero
                end)
            end
            pcall(function()
                if hum and hum.Parent then
                    local snap = BringState.original[entry.Model]
                    if snap and not snap.humanoid then
                        snap.humanoid = {
                            WalkSpeed = hum.WalkSpeed,
                            JumpPower = hum.JumpPower,
                            JumpHeight = hum.JumpHeight,
                            PlatformStand = hum.PlatformStand,
                        }
                    end
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                    pcall(function() hum.JumpHeight = 0 end)
                    pcall(function() hum.PlatformStand = true end)
                end
            end)
            BringState.locked[entry.Model] = now
        end)
        brought = brought + 1
    end
    -- dọn lock cũ
    if now - (BringState.last or 0) > 5 then
        BringState.last = now
        for m, t in pairs(BringState.locked) do
            if now - t > 8 or not m or not m.Parent then
                -- Restore stale state immediately instead of leaving old mobs
                -- modified in memory until the whole feature is stopped.
                local snap = BringState.original[m]
                if snap then
                    pcall(function()
                        if snap.parts then
                            for part, canCollide in pairs(snap.parts) do
                                if part and part.Parent then part.CanCollide = canCollide end
                            end
                        end
                        if m and m.Parent and snap.humanoid then
                            local hum = m:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum.WalkSpeed = snap.humanoid.WalkSpeed
                                hum.JumpPower = snap.humanoid.JumpPower
                                pcall(function() hum.JumpHeight = snap.humanoid.JumpHeight end)
                                pcall(function() hum.PlatformStand = snap.humanoid.PlatformStand end)
                            end
                        end
                        if m and m.Parent then
                            local bv = m:FindFirstChild("PawZBringBV", true)
                            if bv then bv:Destroy() end
                        end
                    end)
                    BringState.original[m] = nil
                end
                BringState.locked[m] = nil
            end
        end
    end
    return brought
end

function RestoreBringState()
    for model, snap in pairs(BringState.original or {}) do
        pcall(function()
            if snap.parts then
                for part, canCollide in pairs(snap.parts) do
                    if part and part.Parent then part.CanCollide = canCollide end
                end
            end
            if snap.humanoid and model and model.Parent then
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.WalkSpeed = snap.humanoid.WalkSpeed
                    hum.JumpPower = snap.humanoid.JumpPower
                    pcall(function() hum.JumpHeight = snap.humanoid.JumpHeight end)
                    pcall(function() hum.PlatformStand = snap.humanoid.PlatformStand end)
                end
            end
            if model and model.Parent then
                local bv = model:FindFirstChild("PawZBringBV", true)
                if bv then bv:Destroy() end
            end
        end)
    end
    BringState.locked = {}
    BringState.original = {}
end

HubInstance.RestoreBringState = RestoreBringState

local WEAPON_MATCH = {
    Melee = {
        "combat", "black leg", "electro", "fishman karate", "dragon claw",
        "superhuman", "death step", "sharkman karate", "electric claw",
        "dragon talon", "godhuman", "sanguine art", "melee", "fighting style",
    },
    Sword = {
        "sword", "blade", "katana", "cutlass", "saber", "dual katana",
        "dark blade", "yama", "shisui", "tushita", "rengoku", "canvander",
        "buddy sword", "midnight blade", "triple katana", "pipe", "iron mace",
    },
    Gun = {
        "gun", "rifle", "pistol", "flintlock", "musket", "refined",
        "kabucha", "acidum", "bazooka", "serpent", "soul guitar",
    },
    Fruit = {
        "fruit", "buzo", "gum-gum", "hie", "mera", "pika", "magu", "ito",
        "zushi", "yami", "gura", "suna", "bomu", "kilo", "tori",
    },
}

function Paw.ToolMatchesCategory(toolName, category)
    local n = string.lower(toolName or "")
    local keys = WEAPON_MATCH[category]
    if not keys then
        return n:find(string.lower(category), 1, true) ~= nil
    end
    for _, k in ipairs(keys) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

function Paw.EquipFarmWeapon(cfg)
    local char = Paw.GetCharacter()
    if not char then return end
    local hum = Paw.GetHumanoid()
    if not hum then return end
    local want = tostring(cfg.SelectedWeapon or "Melee")
    local backpack = Player:FindFirstChild("Backpack")
    local function tryEquip(tool)
        if tool and tool:IsA("Tool") then
            pcall(function() hum:EquipTool(tool) end)
            return true
        end
        return false
    end
    local held = char:FindFirstChildOfClass("Tool")
    if held and Paw.ToolMatchesCategory(held.Name, want) then
        return held
    end
    local pools = {}
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then pools[#pools + 1] = tool end
        end
    end
    if held then pools[#pools + 1] = held end
    for _, tool in ipairs(pools) do
        if Paw.ToolMatchesCategory(tool.Name, want) then
            if tryEquip(tool) then return tool end
        end
    end
    -- mastery fruit: try any tool with "fruit" in name from character abilities folder
    if want == "Fruit" then
        pcall(function()
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and tryEquip(t) then return t end
            end
        end)
    end
    for _, tool in ipairs(pools) do
        if tool:IsA("Tool") and tryEquip(tool) then return tool end
    end
    return char:FindFirstChildOfClass("Tool")
end

-- Auto Quest (level farm): stand at NPC + fire ProximityPrompt + click Accept UI
function Paw.FirePromptAggressive(prompt)
    if not prompt or not prompt.Parent then return false end
    local fired = false
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
            fired = true
        end
    end)
    if fired then return true end
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(0.15, (prompt.HoldDuration or 0) + 0.1))
        prompt:InputHoldEnd()
    end)
    if ok then return true end
    return false
end

function Paw.ClickGuiButton(gui)
    if not gui or not gui.Parent or gui.Visible == false then return false end
    local fired = false
    pcall(function()
        if firesignal and gui.MouseButton1Click then
            firesignal(gui.MouseButton1Click)
            fired = true
        end
    end)
    if fired then return true end
    -- Physical input is a true fallback, never a second action in the same call.
    local ok = pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if not vim or not gui.AbsolutePosition then return false end
        local pos = gui.AbsolutePosition + (gui.AbsoluteSize / 2)
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        task.wait(0.03)
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        return true
    end)
    return ok
end

function Paw.IsDeclineQuestText(t)
    t = string.lower(tostring(t or ""))
    return t:find("nevermind", 1, true) or t:find("never mind", 1, true)
        or t:find("cancel", 1, true) or t:find("close", 1, true)
        or t:find("no thanks", 1, true) or t == "no" or t:find("decline", 1, true)
        or t:find("exit", 1, true) or t:find("back", 1, true)
end

-- Click quest dialogue: chọn "Bandits" / quest đúng level, không bấm Nevermind
function Paw.ClickQuestButtons()
    local pg = Player:FindFirstChild("PlayerGui")
    if not pg then return false end
    if Paw.HasActiveQuest and Paw.HasActiveQuest() then return true end

    local guide = Paw.GetLevelFarmGuide(Paw.GetPlayerLevel())
    local preferKeys = {}
    if guide then
        if guide.quest then preferKeys[#preferKeys + 1] = string.lower(guide.quest) end
        if guide.keys then
            for _, k in ipairs(guide.keys) do preferKeys[#preferKeys + 1] = string.lower(k) end
        end
    end
    preferKeys[#preferKeys + 1] = "bandits"
    preferKeys[#preferKeys + 1] = "bandit"

    local best, bestScore = nil, -math.huge
    pcall(function()
        for _, gui in ipairs(pg:GetDescendants()) do
            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible ~= false then
                local raw = tostring(gui.Text or "")
                local name = tostring(gui.Name or "")
                local t = string.lower(raw .. " " .. name)
                if t ~= "" and not Paw.IsDeclineQuestText(t) then
                    local score = 0
                    for _, k in ipairs(preferKeys) do
                        if k ~= "" and t:find(k, 1, true) then score = score + 100; break end
                    end
                    if t:find("accept",1,true) or t:find("claim",1,true) or
                       t:find("complete",1,true) or t:find("finish",1,true) or
                       t:find("continue",1,true) or t:find("confirm",1,true) or
                       t == "yes" then
                        score = score + 50
                    end
                    local inQuestUi = false
                    local parent = gui.Parent
                    for _ = 1, 6 do
                        if not parent then break end
                        local pn = string.lower(tostring(parent.Name or ""))
                        if pn:find("quest") or pn:find("dialogue") or pn:find("npc") or pn:find("talk") or pn:find("option") then
                            inQuestUi = true
                            break
                        end
                        parent = parent.Parent
                    end
                    if inQuestUi then score = score + 30 end
                    if score > bestScore then bestScore, best = score, gui end
                end
            end
        end
    end)

    if not best or bestScore <= 0 then return false end
    if Paw.ClickGuiButton(best) then
        task.wait(0.12)
        return Paw.HasActiveQuest()
    end
    return false
end

function Paw.IsQuestLikeText(s)
    s = string.lower(tostring(s or ""))
    return s:find("quest", 1, true) or s:find("giver", 1, true)
        or s:find("talk", 1, true) or s:find("accept", 1, true)
        or s:find("claim", 1, true) or s:find("mission", 1, true)
        or s:find("dialogue", 1, true) or s:find("interact", 1, true)
        or s:find("bandit", 1, true) or s:find("marine", 1, true)
end


-- Nhận quest qua remote BF (không cần bấm UI)
function Paw.GetCommF()
    local r = nil
    pcall(function()
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        if remotes then
            r = remotes:FindFirstChild("CommF_")
        end
        if not r then
            for _, d in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if d:IsA("RemoteFunction") and (d.Name == "CommF_" or d.Name:lower():find("commf")) then
                    r = d
                    break
                end
            end
        end
    end)
    return r
end

function Paw.StartQuestRemote(guide)
    guide = guide or Paw.GetLevelFarmGuide(Paw.GetPlayerLevel())
    if not guide or not guide.QuestName then return false end
    local rf = Paw.GetCommF()
    if not rf then return false end
    local ok, result = pcall(function()
        return rf:InvokeServer("StartQuest", guide.QuestName, tonumber(guide.QuestNum) or 1)
    end)
    return ok and result ~= false
end

local _questUICache = { text = "", at = 0 }
function Paw.ReadQuestUIText()
    local now = tick()
    if now - (_questUICache.at or 0) < 0.4 then
        return _questUICache.text or ""
    end
    local blob = ""
    pcall(function()
        local pg = Player:FindFirstChild("PlayerGui")
        if not pg then return end
        local main = pg:FindFirstChild("Main")
        -- chỉ quét panel Quest (tránh scan cả PlayerGui → lag)
        local roots = {}
        if main then
            local q = main:FindFirstChild("Quest") or main:FindFirstChild("Quests")
            if q then table.insert(roots, q) end
            -- Quest frame đôi khi nằm trong Main trực tiếp
            for _, ch in ipairs(main:GetChildren()) do
                local n = string.lower(ch.Name)
                if n:find("quest", 1, true) then table.insert(roots, ch) end
            end
        end
        if #roots == 0 and main then table.insert(roots, main) end
        for _, root in ipairs(roots) do
            for _, g in ipairs(root:GetDescendants()) do
                if g:IsA("TextLabel") or g:IsA("TextButton") then
                    local t = tostring(g.Text or "")
                    if #t > 2 and #t < 100 then
                        blob = blob .. " " .. t
                    end
                end
            end
        end
    end)
    blob = string.lower(blob)
    _questUICache.text = blob
    _questUICache.at = now
    return blob
end

function Paw.HasActiveQuest()
    local t = Paw.ReadQuestUIText()
    local function looksLikeQuest(s)
        if not s or s == "" then return false end
        if s:find("defeat", 1, true) or s:find("kill", 1, true) or s:find("destroy", 1, true) then
            return true
        end
        if s:find("%d+%s*/%s*%d+") then return true end
        if s:find("bandit", 1, true) and s:find("%d+") then return true end
        return false
    end
    if looksLikeQuest(t) then return true end
    -- fallback: quét nhanh PlayerGui (text Defeat / 0/5)
    local found = false
    pcall(function()
        local pg = Player:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, g in ipairs(pg:GetDescendants()) do
            if g:IsA("TextLabel") or g:IsA("TextButton") then
                local s = string.lower(tostring(g.Text or ""))
                if #s > 4 and #s < 80 and looksLikeQuest(s) then
                    found = true
                    break
                end
            end
        end
    end)
    return found
end

function Paw.IsQuestReadyToClaim()
    local t = Paw.ReadQuestUIText()
    if t == "" then return false end
    if t:find("claim", 1, true) or t:find("complete", 1, true) or t:find("return to", 1, true)
        or t:find("talk to", 1, true) or t:find("finished", 1, true) then
        return true
    end
    -- progress full e.g. 5/5
    local a, b = t:match("(%d+)%s*/%s*(%d+)")
    if a and b and tonumber(a) and tonumber(b) and tonumber(b) > 0 and tonumber(a) >= tonumber(b) then
        return true
    end
    return false
end

function Paw.ClaimQuestRemote()
    -- BF: claim = nói chuyện NPC / StartQuest lại (không Abandon)
    pcall(function()
        local rf = Paw.GetCommF()
        local g = Paw.GetLevelFarmGuide(Paw.GetPlayerLevel())
        if rf and g and g.QuestName then
            pcall(function() rf:InvokeServer("StartQuest", g.QuestName, tonumber(g.QuestNum) or 1) end)
        end
    end)
    Paw.ClickQuestButtons()
end

function Paw.GoToQuestNPC(guide)
    local hrp = Paw.GetHRP()
    if not hrp then return false end
    guide = guide or Paw.GetLevelFarmGuide(Paw.GetPlayerLevel())
    if guide and guide.npcCF then
        pcall(function()
            hrp.CFrame = guide.npcCF * CFrame.new(0, 3, 5)
        end)
        task.wait(0.2)
        return true
    end
    return false
end

function Paw.TryAutoQuest()
    local hrp = Paw.GetHRP()
    if not hrp then return false end
    if Paw.HasActiveQuest() then return true end
    local guide = Paw.GetLevelFarmGuide(Paw.GetPlayerLevel())
    if guide and guide.QuestName then
        local npcDist = guide.npcCF and (hrp.Position - guide.npcCF.Position).Magnitude or math.huge
        if npcDist > 18 and guide.npcCF then
            pcall(function() hrp.CFrame = guide.npcCF * CFrame.new(0, 3, 4) end)
        end
        Paw.StartQuestRemote(guide)
        task.wait(0.12)
        Paw.ClickQuestButtons()
        return Paw.HasActiveQuest()
    end
    if World.Scanned then
        local q = World:NearestQuest(hrp.Position, 250)
        if q and q.Part and q.Part.Parent then
            if (q.Position - hrp.Position).Magnitude > 15 then
                pcall(function() hrp.CFrame = CFrame.new(q.Position + Vector3.new(0, 3, 4), q.Position) end)
            end
            if q.Prompt then pcall(function() fireproximityprompt(q.Prompt) end) end
            Paw.ClickQuestButtons()
            return Paw.HasActiveQuest()
        end
    end
    return false
end

function Paw.IsMouseOverHub()
    local ok, over = pcall(function()
        local gui = HubInstance and HubInstance.ScreenGui
        if not gui or not gui.Parent then return false end
        local m = UserInputService:GetMouseLocation()
        local objs = Player.PlayerGui:GetGuiObjectsAtPosition(m.X, m.Y - 36)
        for _, o in ipairs(objs) do
            if o:IsDescendantOf(gui) then return true end
        end
        return false
    end)
    return ok and over
end

function Paw.GetAttackInterval(cfg)
    cfg = cfg or Config
    local spd = tonumber(cfg.AttackSpeed) or 1
    spd = math.clamp(spd, 0.5, 3.5)
    -- FastAttack: ~0.035–0.08s ; thường: ~0.08–0.18s
    if cfg.FastAttack ~= false then
        return math.clamp(0.07 / spd, 0.03, 0.10)
    end
    return math.clamp(0.14 / spd, 0.06, 0.22)
end

function Paw.EnsureFarmTool()
    local char = Paw.GetCharacter()
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool end
    pcall(function() Paw.EquipFarmWeapon(Config) end)
    tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool end
    local bp = Player:FindFirstChild("Backpack")
    local hum = Paw.GetHumanoid()
    if bp and hum then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                pcall(function() hum:EquipTool(t) end)
                tool = char:FindFirstChildOfClass("Tool")
                if tool then return tool end
            end
        end
    end
    return nil
end

function Paw.DoMeleeClick(fast)
    -- Chỉ Tool:Activate — không chuột ảo (tránh khóa UI)
    local ok, did = pcall(function()
        if UserInputService:GetFocusedTextBox() then return false end
        local tool = Paw.EnsureFarmTool()
        if not tool then return false end

        local spd = math.clamp(tonumber(Config.AttackSpeed) or 1, 0.5, 3.5)
        local useFast = (fast == true) or (fast ~= false and Config.FastAttack)
        -- Nhiều Activate/tick khi Fast + AttackSpeed cao (BF M1 chain)
        local n = 1
        if useFast then
            n = math.clamp(math.floor(2 + spd * 2), 3, 8)
        end
        for _ = 1, n do
            pcall(function() tool:Activate() end)
        end
        return true
    end)
    return ok and did or false
end

function Paw.AttackMob(mob, fast)
    if not mob or not mob.Parent then return false end
    if Players:GetPlayerFromCharacter(mob) then return false end
    if not Paw.IsHostileMob(mob) then return false end
    local hrp = Paw.GetHRP()
    local root = Paw.GetRoot(mob)
    if hrp and root then
        pcall(function()
            local look = Vector3.new(root.Position.X, hrp.Position.Y, root.Position.Z)
            if (look - hrp.Position).Magnitude > 0.15 then
                hrp.CFrame = CFrame.new(hrp.Position, look)
            end
            if Paw.StabilizeHRP then Paw.StabilizeHRP(hrp) end
        end)
    end
    return Paw.DoMeleeClick(fast ~= false)
end

function Paw.FireSkillKeys(keys)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if not vim then return end
        for _, key in ipairs(keys) do
            vim:SendKeyEvent(true, key, false, game)
            vim:SendKeyEvent(false, key, false, game)
        end
    end)
end

-- Đánh AOE nhanh: Bring (caller) + M1 burst + skill theo nhịp
function Paw.AttackAOE(primary, cfg)
    cfg = cfg or Config
    local hrp = Paw.GetHRP()
    if not hrp then return false end
    if primary and (Players:GetPlayerFromCharacter(primary) or not Paw.IsHostileMob(primary)) then
        primary = nil
    end

    pcall(function()
        local lookAt = hrp.Position + hrp.CFrame.LookVector * 4
        if primary then
            local root = Paw.GetRoot(primary)
            if root then lookAt = root.Position end
        end
        local face = Vector3.new(lookAt.X, hrp.Position.Y, lookAt.Z)
        if (face - hrp.Position).Magnitude > 0.15 then
            hrp.CFrame = CFrame.new(hrp.Position, face)
        end
        if Paw.StabilizeHRP then Paw.StabilizeHRP(hrp) end
    end)

    local hit = Paw.DoMeleeClick(true)

    local weapon = tostring(cfg.SelectedWeapon or "Melee")
    local now = tick()
    Paw._lastSkillAOE = Paw._lastSkillAOE or 0
    local spd = math.clamp(tonumber(cfg.AttackSpeed) or 1, 0.5, 3.5)
    local skillCd = ((weapon == "Gun" or weapon == "Fruit") and 0.45 or 0.70) / spd
    skillCd = math.clamp(skillCd, 0.25, 1.0)
    if (cfg.AutoSkill or cfg.ComboMode or cfg.AutoFarmLevel or cfg.AutoFarmMastery)
        and (now - Paw._lastSkillAOE) >= skillCd then
        Paw._lastSkillAOE = now
        if cfg.ComboMode then
            FarmAI.ComboStep = ((FarmAI.ComboStep or 0) % 4) + 1
            local k = ({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V })[FarmAI.ComboStep]
            Paw.FireSkillKeys({ k })
        else
            -- Xoay Z/X/C/V; khi AttackSpeed cao bấm 2 phím/lần
            local step = math.floor(now * spd) % 4
            local keys = { Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V }
            if spd >= 1.8 then
                Paw.FireSkillKeys({ keys[step + 1], keys[(step + 1) % 4 + 1] })
            else
                Paw.FireSkillKeys({ keys[step + 1] })
            end
        end
    end
    return hit
end

function Paw.FindNearestChest()
    local hrp = Paw.GetHRP()
    if not hrp or not World.Scanned then return nil end
    local best, bestD = nil, 500
    for _, c in ipairs(World.Chests or {}) do
        if c.Part and c.Part.Parent then
            local d = (c.Part.Position - hrp.Position).Magnitude
            if d < bestD then bestD = d; best = c.Part end
        end
    end
    return best, bestD
end

function Paw.TryAutoChest(hrp, cfg)
    if not cfg.AutoChest or not hrp then return false end
    local part, dist = Paw.FindNearestChest()
    if not part or not dist then return false end
    local dest = part.Position + Vector3.new(0, 3, 0)
    if cfg.TweenFarm ~= false and dist < 120 then
        Paw.TweenStepTo(hrp, dest, part.Position, 280)
    else
        pcall(function() hrp.CFrame = CFrame.new(dest, part.Position) end)
    end
    if dist < 14 then
        Paw.DoMeleeClick(true)
        pcall(function()
            for _, d in ipairs(part:GetDescendants()) do
                if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end
            end
            local pr = part:FindFirstChildOfClass("ProximityPrompt")
            if pr then pcall(function() fireproximityprompt(pr) end) end
            if part.Parent then
                for _, d in ipairs(part.Parent:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end
                end
            end
        end)
    end
    return true
end

local ISLAND_TP_LIST = {
    -- Sea 1
    { name = "Pirate Starter", keys = { "pirate", "starter", "marine starter" } },
    { name = "Jungle", keys = { "jungle" } },
    { name = "Pirate Village", keys = { "pirate village", "middle" } },
    { name = "Desert", keys = { "desert" } },
    { name = "Frozen", keys = { "frozen", "snow" } },
    { name = "Marine Fortress", keys = { "marine fortress", "fortress" } },
    { name = "Skylands", keys = { "sky", "upper sky" } },
    { name = "Prison", keys = { "prison" } },
    { name = "Colosseum", keys = { "colosseum", "colo" } },
    { name = "Magma", keys = { "magma" } },
    { name = "Underwater", keys = { "underwater", "fountain" } },
    -- Sea 2
    { name = "Kingdom of the Town", keys = { "kingdom", "town" } },
    { name = "Green Zone", keys = { "green zone", "greenhouse" } },
    { name = "Graveyard", keys = { "graveyard", "grave" } },
    { name = "Snow Mountain", keys = { "snow mountain", "hot and cold" } },
    { name = "Hot and Cold", keys = { "hot and cold", "hot" } },
    { name = "Cursed Ship", keys = { "cursed", "ship" } },
    { name = "Ice Castle", keys = { "ice castle" } },
    { name = "Forgotten Island", keys = { "forgotten" } },
    -- Sea 3
    { name = "Port Town", keys = { "port town", "port" } },
    { name = "Hydra Island", keys = { "hydra" } },
    { name = "Great Tree", keys = { "great tree", "tree" } },
    { name = "Castle on the Sea", keys = { "castle on the sea", "castle" } },
    { name = "Haunted Castle", keys = { "haunted" } },
    { name = "Sea of Treats", keys = { "treats", "cake" } },
    { name = "Tiki Outpost", keys = { "tiki" } },
}

function Paw.TeleportToIsland(islandName)
    local hrp = Paw.GetHRP()
    if not hrp then return false end
    local target = nil
    local want = string.lower(islandName or "")
    -- 1) World.Islands
    if World.Scanned and World.Islands then
        for _, is in ipairs(World.Islands) do
            local n = string.lower(is.Name or "")
            if n:find(want, 1, true) or want:find(n, 1, true) then
                target = is.Position
                break
            end
        end
    end
    -- 2) keyword match workspace
    if not target then
        local entry = nil
        for _, row in ipairs(ISLAND_TP_LIST) do
            if string.lower(row.name) == want then entry = row break end
        end
        local keys = entry and entry.keys or { want }
        pcall(function()
            for _, obj in ipairs(workspace:GetChildren()) do
                local n = string.lower(obj.Name)
                for _, k in ipairs(keys) do
                    if n:find(k, 1, true) then
                        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            target = part.Position
                            return
                        end
                        pcall(function()
                            local cf = obj:GetBoundingBox()
                            target = cf.Position
                        end)
                        if target then return end
                    end
                end
            end
        end)
    end
    if target then
        pcall(function()
            hrp.CFrame = CFrame.new(target + Vector3.new(0, 12, 0))
        end)
        FarmAI.AnchorPos = target
        Toast:Show("TP: " .. islandName, "ok")
        return true
    end
    Toast:Show("Island not found: " .. islandName, "err")
    return false
end

function Paw.DoSkillBurst(comboMode)
    -- Không block Heartbeat: chỉ bấm 1–2 phím, không chuỗi wait dài
    pcall(function()
        if comboMode then
            FarmAI.ComboStep = (FarmAI.ComboStep % 4) + 1
            local k = ({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V })[FarmAI.ComboStep]
            Paw.FireSkillKeys({ k })
        else
            local step = math.floor(tick()) % 4
            local k = ({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V })[step + 1]
            Paw.FireSkillKeys({ k })
        end
    end)
end

--[[
  FindBestFruit — tối ưu Fruit Sniper:
  - Cache scan
  - Ưu tiên theo thứ tự SniperList (index thấp = hiếm hơn)
  - Match tên qua object + parent + attribute
  - Trả về part, distance, displayName, priority
]]
function Paw.FindBestFruit(opts)
    opts = opts or {}
    local sniperOnly = opts.sniperOnly
    if sniperOnly == nil then sniperOnly = Config.FruitSniper end
    local hrp = Paw.GetHRP()
    if not hrp then return nil end

    local now = tick()
    if now - FruitSniperAI.CacheAt < FruitSniperAI.CacheTTL and #FruitSniperAI.Cache > 0 then
        -- rank from cache
        local best, bestScore = nil, 1e12
        for _, item in ipairs(FruitSniperAI.Cache) do
            if item.part and item.part.Parent then
                local d = (item.part.Position - hrp.Position).Magnitude
                local score = item.priority * 10000 + d
                if score < bestScore then
                    bestScore = score
                    best = item
                    best.dist = d
                end
            end
        end
        if best then
            return best.part, best.dist, best.name, best.priority
        end
    end

    local found = {}
    pcall(function()
        local folders = {}
        for _, name in ipairs({ "Fruit", "Fruits", "FruitSpawns", "Spawn", "DevilFruits", "Tools" }) do
            local f = workspace:FindFirstChild(name)
            if f then table.insert(folders, f) end
        end
        -- World cache
        if World.Scanned and World.FruitSpawns then
            for _, fs in ipairs(World.FruitSpawns) do
                if fs.Part and fs.Part.Parent then
                    table.insert(folders, fs.Part)
                end
            end
        end

        local function consider(obj)
            if not obj then return end
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if not part then return end
            local blob = Paw.ResolveFruitName(obj)
            if not Paw.IsFruitLike(obj, blob) then return end
            local inList, prio = Paw.FruitInSniperList(blob, Config)
            -- A generic Tool is not automatically a fruit. Require either
            -- fruit-like naming or a configured sniper-list match.
            if sniperOnly and not inList then return end
            if not sniperOnly and not inList then
                local ln = string.lower(blob)
                if not (ln:find("fruit", 1, true) or ln:find("eatable", 1, true) or ln:find("devil", 1, true)) then
                    return
                end
                prio = 50
            end
            table.insert(found, {
                part = part,
                name = blob,
                priority = prio or 99,
                dist = (part.Position - hrp.Position).Magnitude,
            })
        end

        local function scan(container)
            if not container then return end
            if container:IsA("BasePart") or container:IsA("Model") or container:IsA("Tool") then
                consider(container)
            end
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("Tool") or obj:IsA("Model") then
                    local n = string.lower(obj.Name)
                    if n:find("fruit") or n:find("eatable") or Paw.FruitInSniperList(obj.Name, Config) then
                        consider(obj)
                    end
                elseif obj:IsA("BasePart") then
                    local n = string.lower(obj.Name)
                    if n:find("fruit") or n:find("eatable") then
                        consider(obj)
                    end
                end
            end
        end

        for _, f in ipairs(folders) do
            if f:IsA("BasePart") then consider(f) else scan(f) end
        end
        -- full workspace fallback (cap)
        if #found == 0 then
            for _, obj in ipairs(workspace:GetChildren()) do
                local ln = string.lower(obj.Name)
                if obj:IsA("Tool") or (obj:IsA("Model") and (ln:find("fruit") or Paw.FruitInSniperList(obj.Name, Config))) then
                    consider(obj)
                elseif obj:IsA("BasePart") and ln:find("fruit") then
                    consider(obj)
                end
            end
        end
    end)

    FruitSniperAI.Cache = found
    FruitSniperAI.CacheAt = now

    local best, bestScore = nil, 1e12
    for _, item in ipairs(found) do
        local score = (item.priority or 99) * 10000 + (item.dist or 9999)
        if score < bestScore then
            bestScore = score
            best = item
        end
    end
    if best then
        FruitSniperAI.LastFound = now
        return best.part, best.dist, best.name, best.priority
    end
    return nil
end

-- backward compatible alias
function Paw.FindNearestFruit(sniperOnly)
    local part, dist, name, prio = Paw.FindBestFruit({ sniperOnly = sniperOnly })
    return part, dist, name, prio
end

-- Fruit multi-step: FIND → GOTO → PICK → STORE → (HOP)
FruitSniperAI.State = FruitSniperAI.State or "FIND"
FruitSniperAI.StateSince = FruitSniperAI.StateSince or 0
FruitSniperAI.TargetPart = FruitSniperAI.TargetPart or nil
FruitSniperAI.PickUntil = FruitSniperAI.PickUntil or 0
FruitSniperAI.StoreUntil = FruitSniperAI.StoreUntil or 0
FruitSniperAI.PickedIds = FruitSniperAI.PickedIds or {}

function Paw.FruitTryStore()
    local pg = Player:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("Main")
    if not main then return false end
    local best, bestScore = nil, -math.huge
    pcall(function()
        for _, gui in ipairs(main:GetDescendants()) do
            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible ~= false then
                local t = string.lower(tostring(gui.Text or "") .. " " .. tostring(gui.Name or ""))
                local score = 0
                if t:find("store fruit",1,true) then score = score + 100 end
                if t:find("save fruit",1,true) then score = score + 90 end
                if t:find("inventory",1,true) then score = score + 50 end
                if score > bestScore then bestScore, best = score, gui end
            end
        end
    end)
    if best and bestScore > 0 then return Paw.ClickGuiButton(best) end
    return false
end

function Paw.TryFruitSniperTick(hrp, cfg, engine)
    if not cfg.FruitSniper and not cfg.AutoFarmFruit then return false end
    local now = tick()
    local st = FruitSniperAI.State or "FIND"

    if st == "STORE" then
        if now >= (FruitSniperAI.StoreUntil or 0) then
            Paw.FruitTryStore()
            FruitSniperAI.StoreUntil = now + 1.0
        end
        if now - (FruitSniperAI.StateSince or now) > 1.2 then
            FruitSniperAI.State = "FIND"
            FruitSniperAI.TargetPart = nil
        end
        return true
    end

    -- Once a fruit has entered PICK, do not execute the pickup sequence again
    -- until the target disappears or the short pickup guard expires.
    if st == "PICK" and now < (FruitSniperAI.PickUntil or 0) then
        return true
    elseif st == "PICK" then
        FruitSniperAI.State = "FIND"
        FruitSniperAI.TargetPart = nil
    end

    local part, dist, name, prio = Paw.FindBestFruit({ sniperOnly = cfg.FruitSniper })
    if part and dist then
        FruitSniperAI.LastFound = now
        FruitSniperAI.TargetPart = part
        local id = tostring(part:GetFullName())
        if not FruitSniperAI.LastToast[id] then
            FruitSniperAI.LastToast[id] = now
            local tag = (prio and prio <= 6) and "⭐ " or ""
            Toast:Show(tag .. "Fruit: " .. (name or part.Name) .. " · " .. math.floor(dist) .. "m", "ok")
        end
        local fpos = part.Position
        if dist > 12 then
            FruitSniperAI.State = "GOTO"
            if cfg.TweenFarm ~= false then
                Paw.TweenStepTo(hrp, fpos + Vector3.new(0, 3, 0), fpos, tonumber(cfg.TweenSpeed) or 300)
            else
                pcall(function() hrp.CFrame = CFrame.new(fpos + Vector3.new(0, 3, 0), fpos) end)
            end
        else
            local id = tostring(part:GetFullName())
            if FruitSniperAI.PickedIds[id] and part.Parent then
                return true
            end
            FruitSniperAI.PickedIds[id] = now
            FruitSniperAI.State = "PICK"
            FruitSniperAI.PickUntil = now + 0.75
            local beforeParent = part.Parent
            pcall(function()
                local targets = { part, part.Parent }
                for _, t in ipairs(targets) do
                    if t then
                        for _, d in ipairs(t:GetDescendants()) do
                            if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end
                        end
                        if t:IsA("Tool") then
                            local hum = Paw.GetHumanoid()
                            if hum then pcall(function() hum:EquipTool(t) end) end
                        end
                    end
                end
            end)
            task.defer(function()
                if beforeParent and not part.Parent and engine then
                    engine.FruitCount = (engine.FruitCount or 0) + 1
                end
            end)
            if cfg.AutoStoreFruit then
                FruitSniperAI.State = "STORE"
                FruitSniperAI.StateSince = now
            else
                FruitSniperAI.State = "FIND"
                FruitSniperAI.TargetPart = nil
            end
        end
        return true
    end

    FruitSniperAI.State = "FIND"
    -- Fruit Sniper NEVER auto-hops (even if SniperHop toggle is on).
    -- Flow stays: FIND → GOTO → PICK → STORE only. No server hop.
    return false
end


--[[ ======================================================================
  AUTO FARM LEVEL (viết lại sạch)
  Flow:
    TAKE_QUEST  → chưa có quest → remote StartQuest + đứng NPC
    FARM        → tìm mob trong Enemies → đứng trên đầu → bring → đánh
    CLAIM       → quest 5/5 → về NPC nhận thưởng / quest mới
  Quy tắc:
    - Có quest rồi thì KHÔNG đứng NPC
    - Chỉ đánh model trong workspace.Enemies có [Lv. hoặc tên mob
    - Không tự server hop
====================================================================== ]]

local LevelFarmAI = {
    State = "INIT", StateSince = 0, StatusText = "Idle",
    LastQuestTry = 0, LastClaimTry = 0, LastBring = 0, LastEquip = 0, LastAttack = 0, LastSearchTP = 0,
    Target = nil, QuestGuideKey = nil, QuestProgress = 0, QuestGoal = 0, LastProgressAt = 0, ClaimVerifyUntil = 0, ClaimRequestedAt = 0, ClaimBlockedUntil = 0,
    RecoveryLevel = 0, SearchStartedAt = 0, StallCount = 0,
}

function Paw.LF_Set(state, status)
    if LevelFarmAI.State ~= state then
        LevelFarmAI.State = state
        LevelFarmAI.StateSince = tick()
    end
    if status then LevelFarmAI.StatusText = status end
end

function Paw.LF_GuideKey(guide)
    if not guide then return "nil" end
    return table.concat({tostring(guide.QuestName or ""), tostring(guide.QuestNum or ""), table.concat(guide.keys or {}, "|")}, "#")
end

function Paw.LF_ReadProgress()
    local t = Paw.ReadQuestUIText()
    if t == "" then return 0, 0 end
    local a, b = t:match("(%d+)%s*/%s*(%d+)")
    return tonumber(a) or 0, tonumber(b) or 0
end

function Paw.LF_IsTargetValid(target, guide)
    if not target or not target.Parent or not Paw.LF_IsMob(target) then return false end
    if guide and guide.keys and #guide.keys > 0 and not Paw.MobMatchesGuide(target.Name, guide) then return false end
    local hum, root = target:FindFirstChildOfClass("Humanoid"), Paw.GetRoot(target)
    return hum ~= nil and hum.Health > 0 and root ~= nil and Paw.IsValidMobHeight(root.Position.Y)
end

function Paw.LF_ResetTarget(reason)
    LevelFarmAI.Target = nil
    FarmAI.CurrentTarget = nil
    FarmAI.CacheAt = 0
    if reason then LevelFarmAI.StatusText = reason end
end

function Paw.LF_RecordProgress()
    local a, b = Paw.LF_ReadProgress()
    if a ~= LevelFarmAI.QuestProgress or b ~= LevelFarmAI.QuestGoal then
        LevelFarmAI.QuestProgress, LevelFarmAI.QuestGoal = a, b
        LevelFarmAI.LastProgressAt = tick()
        LevelFarmAI.StallCount = 0
        return true
    end
    return false
end

-- Quest đang chạy? (UI có "Defeat … (x/y)")
function Paw.LF_HasQuest()
    local t = Paw.ReadQuestUIText()
    if t == "" then return false end
    if t:find("defeat", 1, true) or t:find("kill", 1, true) or t:find("destroy", 1, true) then
        return true
    end
    if t:find("%d+%s*/%s*%d+") then return true end
    return t:find("quest", 1, true) ~= nil and t:find("%d") ~= nil
end

-- Quest đủ chỉ tiêu? (5/5)
function Paw.LF_QuestDone()
    local t = Paw.ReadQuestUIText()
    if t == "" then return false end
    local a, b = t:match("(%d+)%s*/%s*(%d+)")
    if a and b and tonumber(b) and tonumber(b) > 0 and tonumber(a) >= tonumber(b) then
        return t:find("defeat", 1, true) ~= nil or t:find("kill", 1, true) ~= nil
            or t:find("quest", 1, true) ~= nil or t:find("bandit", 1, true) ~= nil
    end
    return t:find("claim", 1, true) ~= nil or t:find("complete", 1, true) ~= nil
        or t:find("return to", 1, true) ~= nil or t:find("finished", 1, true) ~= nil
end

-- Mob hợp lệ để farm
function Paw.LF_IsMob(model)
    if not model or not model:IsA("Model") then return false end
    if model == Paw.GetCharacter() then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local name = model.Name or ""
    local low = string.lower(name)
    if low:find("giver", 1, true) or low:find("dealer", 1, true)
        or low:find("shop", 1, true) or low:find("quest", 1, true)
        or low:find("seller", 1, true) or low:find("trainer", 1, true) then
        return false
    end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not root or not root:IsA("BasePart") then return false end
    if not Paw.IsValidMobHeight(root.Position.Y) then return false end
    -- BF enemy: "Bandit [Lv. 5]"
    if name:find("[Lv", 1, true) or name:find("[lv", 1, true) then return true end
    for _, k in ipairs({ "bandit", "monkey", "gorilla", "pirate", "brute", "desert",
        "snow", "marine", "fishman", "sky", "prison", "zombie", "vampire", "lava" }) do
        if low:find(k, 1, true) then return true end
    end
    return false
end

-- Tìm mob gần nhất (ưu tiên đúng keys của guide)
function Paw.LF_FindMob(guide, maxDist)
    maxDist = maxDist or 2000
    local hrp = Paw.GetHRP()
    if not hrp then return nil end
    local best, bestScore = nil, math.huge
    local function consider(m)
        if not Paw.LF_IsTargetValid(m, guide) then return end
        local root = Paw.GetRoot(m)
        if not root then return end
        local d = (root.Position - hrp.Position).Magnitude
        if d > maxDist then return end
        local hum = m:FindFirstChildOfClass("Humanoid")
        local score = d - (hum and hum.MaxHealth > 0 and math.clamp((1 - hum.Health / hum.MaxHealth) * 25, 0, 25) or 0)
        if FarmAI.CurrentTarget == m then score = score - 30 end
        if score < bestScore then bestScore, best = score, m end
    end
    pcall(function()
        for _, folder in ipairs(Paw.CollectEnemyFolders()) do
            for _, m in ipairs(folder:GetChildren()) do consider(m) end
        end
    end)
    return best
end

-- Đứng trên đầu mob + nhìn xuống
function Paw.LF_StandOnMob(hrp, mob, height)
    local root = mob and Paw.GetRoot(mob)
    if not root then return false end
    Paw.MoveToFarmSpot(hrp, mob, root, Paw.ExpandFarmCfg(Config, { minRange = 220 }), false)
    return true
end

-- Gôm quái sát đất quanh target
function Paw.LF_Bring(hrp, primary, range, maxN)
    if not hrp or not primary then return false end
    local cfg = Paw.ExpandFarmCfg(Config, {
        minRange = 220,
        bringRange = tonumber(range) or 150,
        bringMax = tonumber(maxN) or 8,
    })
    return pcall(function() Paw.BringMobsToStack(hrp, cfg, primary) end)
end

-- Đánh thường
function Paw.LF_Attack()
    local t = LevelFarmAI and LevelFarmAI.Target
    if t then pcall(function() Paw.AttackMob(t, true) end)
    else pcall(function() Paw.DoMeleeClick(Config.FastAttack) end) end
end

-- Nhận quest
function Paw.LF_TakeQuest(guide)
    guide = guide or Paw.GetLevelFarmGuide(Paw.GetPlayerLevel())
    local hrp = Paw.GetHRP()
    if not hrp then return false end
    if guide.npcCF and (hrp.Position - guide.npcCF.Position).Magnitude > 18 then
        pcall(function() hrp.CFrame = guide.npcCF * CFrame.new(0, 3, 4) end)
    end
    local started = false
    if guide and guide.QuestName then
        started = Paw.StartQuestRemote(guide) or false
    end
    if World.Scanned then
        local q = World:NearestQuest(hrp.Position, 80)
        if q then
            if q.Prompt then pcall(function() fireproximityprompt(q.Prompt) end) end
            if q.Model then
                local prompt = q.Model:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then pcall(function() fireproximityprompt(prompt) end) end
            end
        end
    end
    Paw.ClickQuestButtons()
    return started or Paw.HasActiveQuest()
end

function Paw.LF_ClaimQuest(guide)
    guide = guide or Paw.GetLevelFarmGuide(Paw.GetPlayerLevel())
    local hrp = Paw.GetHRP()
    if not hrp or not guide then return false end
    if guide.npcCF and (hrp.Position - guide.npcCF.Position).Magnitude > 22 then
        pcall(function() hrp.CFrame = guide.npcCF * CFrame.new(0, 3, 4) end)
    end
    -- Non-blocking claim request: Heartbeat must never yield.
    Paw.ClaimQuestRemote()
    Paw.ClickQuestButtons()
    LevelFarmAI.ClaimVerifyUntil = tick() + 1.5
    LevelFarmAI.ClaimRequestedAt = tick()
    return true
end

-- ========== MAIN TICK ==========
function Paw.TryLevelFarmTick(hrp, cfg, engine)
    if not cfg or not cfg.AutoFarmLevel or not hrp then return false end
    local now, level = tick(), Paw.GetPlayerLevel() or 0
    local guide, key = Paw.GetLevelFarmGuide(level), nil
    key = Paw.LF_GuideKey(guide)
    if LevelFarmAI.QuestGuideKey ~= key then
        LevelFarmAI.QuestGuideKey, LevelFarmAI.QuestProgress, LevelFarmAI.QuestGoal = key, 0, 0
        LevelFarmAI.LastProgressAt, LevelFarmAI.RecoveryLevel, LevelFarmAI.StallCount = now, 0, 0
        Paw.LF_ResetTarget("new guide")
        Paw.LF_Set("INIT", "Sync level guide")
    end
    if now - (LevelFarmAI.LastEquip or 0) >= 0.8 then
        LevelFarmAI.LastEquip = now
        pcall(Paw.EquipFarmWeapon, cfg)
    end
    local hasQuest, done = false, false
    pcall(function() hasQuest = Paw.LF_HasQuest(); done = hasQuest and Paw.LF_QuestDone() end)
    Paw.LF_RecordProgress()
    if not hasQuest then
        Paw.LF_ResetTarget("waiting for quest")
        Paw.LF_Set("TAKE_QUEST", "Take quest")
        if now - (LevelFarmAI.LastQuestTry or 0) >= 3 then
            LevelFarmAI.LastQuestTry = now
            local ok, started = pcall(Paw.LF_TakeQuest, guide)
            if ok and started then LevelFarmAI.LastProgressAt = now; LevelFarmAI.SearchStartedAt = now; Paw.LF_Set("FARM", "Quest active") end
        end
        return true
    end
    if LevelFarmAI.ClaimVerifyUntil and LevelFarmAI.ClaimVerifyUntil > 0 then
        -- Verify claim without treating a temporarily blank UI as success.
        Paw.LF_Set("CLAIM", "Verify claim")
        local stillDone = Paw.IsQuestReadyToClaim()
        local activeAfter = Paw.LF_HasQuest()
        if not stillDone and activeAfter then
            LevelFarmAI.ClaimVerifyUntil = 0
            LevelFarmAI.ClaimRequestedAt = 0
            LevelFarmAI.LastProgressAt, LevelFarmAI.RecoveryLevel, LevelFarmAI.StallCount = now, 0, 0
            Paw.LF_ResetTarget("claim verified")
            Paw.LF_Set("FARM", "Next quest active")
        elseif not stillDone and not activeAfter and now < LevelFarmAI.ClaimVerifyUntil then
            -- Quest UI can briefly disappear while the next quest panel loads.
            return true
        elseif now >= LevelFarmAI.ClaimVerifyUntil then
            LevelFarmAI.ClaimVerifyUntil = 0
            LevelFarmAI.StallCount = (LevelFarmAI.StallCount or 0) + 1
            LevelFarmAI.LastClaimTry = now
            if LevelFarmAI.StallCount >= 3 then
                Paw.LF_ResetTarget("claim failed repeatedly")
                LevelFarmAI.StallCount = 0
                LevelFarmAI.LastQuestTry = 0
                LevelFarmAI.ClaimBlockedUntil = now + 30
                Paw.LF_Set("RECOVER", "Claim failed · cooldown")
            else
                Paw.LF_Set("CLAIM", "Claim retry")
            end
        end
        return true
    end
    if done or Paw.IsQuestReadyToClaim() then
        if now < (LevelFarmAI.ClaimBlockedUntil or 0) then
            Paw.LF_ResetTarget("claim temporarily blocked")
            Paw.LF_Set("RECOVER", "Claim blocked · waiting")
            if now - (LevelFarmAI.LastSearchTP or 0) >= 5 and guide and guide.npcCF then
                LevelFarmAI.LastSearchTP = now
                pcall(function() hrp.CFrame = guide.npcCF * CFrame.new(0, 3, 4) end)
            end
            return true
        end
        Paw.LF_ResetTarget("quest complete")
        Paw.LF_Set("CLAIM", "Claim quest")
        if now - (LevelFarmAI.LastClaimTry or 0) >= 2.5 then
            LevelFarmAI.LastClaimTry = now
            pcall(Paw.LF_ClaimQuest, guide)
        end
        if now - (LevelFarmAI.StateSince or now) > 20 then
            LevelFarmAI.StallCount = (LevelFarmAI.StallCount or 0) + 1
            if LevelFarmAI.StallCount >= 3 then
                LevelFarmAI.ClaimVerifyUntil = 0
                Paw.LF_ResetTarget("claim state reset")
                LevelFarmAI.LastClaimTry, LevelFarmAI.LastQuestTry = 0, 0
                LevelFarmAI.StallCount = 0
                LevelFarmAI.ClaimBlockedUntil = now + 30
                Paw.LF_Set("RECOVER", "Claim stalled · cooldown")
            end
        end
        return true
    end
    local target = LevelFarmAI.Target
    if not Paw.LF_IsTargetValid(target, guide) then
        Paw.LF_ResetTarget("target invalid")
        target = Paw.LF_FindMob(guide, 700)
        if not target then
            local farmCfg = Paw.ExpandFarmCfg(cfg, {minRange=350, ownIsland=false, bringMobs=cfg.BringMobs})
            pcall(function() target = Paw.SelectFarmTarget(farmCfg, "level") end)
            if target and not Paw.LF_IsTargetValid(target, guide) then target = nil end
        end
        if target then LevelFarmAI.Target = target; LevelFarmAI.SearchStartedAt = now; FarmAI.CurrentTarget = target end
    end
    if target then
        local root, hum = Paw.GetRoot(target), target:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 and Paw.LF_IsTargetValid(target, guide) then
            Paw.LF_Set("FARM", "Kill " .. tostring(target.Name))
            FarmAI.CurrentTarget = target
            local farmCfg = Paw.ExpandFarmCfg(cfg, {minRange=350, ownIsland=false, bringMobs=cfg.BringMobs})
            local stuck = Paw.UpdateStuck(hrp)
            pcall(function() Paw.MoveToFarmSpot(hrp, target, root, farmCfg, stuck) end)
            if stuck then
                LevelFarmAI.RecoveryLevel = math.min((LevelFarmAI.RecoveryLevel or 0)+1,3)
                Paw.LF_Set("RECOVER", "Unstuck " .. tostring(LevelFarmAI.RecoveryLevel))
                if LevelFarmAI.RecoveryLevel == 1 then
                    pcall(function() hrp.CFrame = root.CFrame * CFrame.new(math.random(-6,6),4,math.random(-6,6)) end)
                elseif LevelFarmAI.RecoveryLevel == 2 then
                    if cfg.BringMobs ~= false then pcall(function() Paw.BringMobsToStack(hrp, farmCfg, target) end) end
                else
                    Paw.LF_ResetTarget("stuck target reset"); FarmAI.StuckSince = 0; FarmAI.LastPos = hrp.Position
                end
                return true
            end
            if cfg.BringMobs ~= false and now - (LevelFarmAI.LastBring or 0) >= 0.6 then
                LevelFarmAI.LastBring = now
                pcall(function() Paw.BringMobsToStack(hrp, farmCfg, target) end)
            end
            if Paw.LF_RecordProgress() then LevelFarmAI.RecoveryLevel, LevelFarmAI.StallCount = 0,0
            elseif LevelFarmAI.LastProgressAt > 0 and now - LevelFarmAI.LastProgressAt > 12 then
                LevelFarmAI.StallCount = (LevelFarmAI.StallCount or 0)+1
                Paw.LF_ResetTarget("quest progress stalled")
                LevelFarmAI.LastProgressAt = now
                LevelFarmAI.RecoveryLevel = math.min((LevelFarmAI.RecoveryLevel or 0)+1,3)
                if LevelFarmAI.StallCount >= 3 then
                    Paw.LF_Set("RECOVER", "Progress stalled"); LevelFarmAI.StallCount = 0
                    if guide.mobCF then pcall(function() hrp.CFrame = guide.mobCF * CFrame.new(0,8,8) end) end
                end
                return true
            end
            -- Đánh AOE nhanh: interval theo AttackSpeed / FastAttack
            local atkInterval = Paw.GetAttackInterval(cfg)
            if now - (LevelFarmAI.LastAttack or 0) >= atkInterval then
                LevelFarmAI.LastAttack = now
                pcall(function()
                    if not Paw.EnsureFarmTool() then
                        Paw.EquipFarmWeapon(cfg or Config)
                    end
                    if cfg.BringMobs ~= false and now - (LevelFarmAI.LastBring or 0) >= 0.45 then
                        LevelFarmAI.LastBring = now
                        pcall(function() Paw.BringMobsToStack(hrp, farmCfg, target) end)
                    end
                    Paw.AttackAOE(target, cfg)
                end)
            end
            if engine then engine.FarmCount = (engine.FarmCount or 0)+1; engine._lastAttack = now end
            return true
        end
        Paw.LF_ResetTarget("target died")
    end
    Paw.LF_Set("FARM", "Search mobs")
    if LevelFarmAI.SearchStartedAt == 0 then LevelFarmAI.SearchStartedAt = now end
    if now - (LevelFarmAI.LastSearchTP or 0) >= 1.5 and guide then
        LevelFarmAI.LastSearchTP = now
        local pos = guide.mobCF or guide.npcCF
        if pos then pcall(function() hrp.CFrame = pos * CFrame.new(0,8,8) end) end
    end
    if now - LevelFarmAI.SearchStartedAt > 12 then
        LevelFarmAI.SearchStartedAt = now
        LevelFarmAI.StallCount = (LevelFarmAI.StallCount or 0)+1
        if LevelFarmAI.StallCount >= 2 then
            Paw.LF_Set("RECOVER", "No quest mob · reset scan")
            FarmAI.CacheAt = 0; Paw.LF_ResetTarget("no target timeout"); LevelFarmAI.StallCount = 0; LevelFarmAI.LastQuestTry = 0
        end
    end
    return true
end

-- aliases (không redeclare HasActiveQuest — đã có ở trên)
function Paw.LevelFarmSet(st, text) Paw.LF_Set(st, text) end
function Paw.FindNearestHostile(maxDist, guide) return Paw.LF_FindMob(guide, maxDist) end
function Paw.LevelFarmTrackTarget() end


-- Boss multi-step: FIND → GOTO → KILL → LOOT → HOP
local BossAI = {
    State = "FIND",
    StateSince = 0,
    Current = nil,
    LastSeen = 0,
}

function Paw.TryBossTick(hrp, cfg, engine)
    if not cfg.AutoBoss or not hrp then return false end
    local now = tick()
    local farmCfg = Paw.ExpandFarmCfg(cfg, { minRange = 400 })
    local target = Paw.SelectFarmTarget(farmCfg, "boss")
    if not target then
        target = Paw.FindEnemyByKeywords({
            "boss", "king", "queen", "admiral", "captain", "rip_indra", "indra",
            "dough king", "cake prince", "soul reaper", "thunder god"
        }, 5000)
    end
    if target then
        BossAI.Current = target
        BossAI.LastSeen = now
        BossAI.State = "KILL"
        local root = Paw.GetRoot(target)
        local hum = target:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            pcall(function() Paw.EquipFarmWeapon(cfg) end)
            Paw.MoveToFarmSpot(hrp, target, root, farmCfg, Paw.UpdateStuck(hrp))
            pcall(function() Paw.BringMobsToStack(hrp, farmCfg, target) end)
            Paw.DoMeleeClick(true)
            if now - (engine._lastSkill or 0) > 0.7 then
                engine._lastSkill = now
                task.spawn(function() Paw.DoSkillBurst(true) end)
            end
            engine.FarmCount = (engine.FarmCount or 0) + 1
            FarmAI.CurrentTarget = target
            return true
        end
    end
    BossAI.State = "FIND"
    if BossAI.LastSeen == 0 then BossAI.LastSeen = now end
    -- KHÔNG tự hop (tránh spam đổi server — chỉ hop khi user bật BossHop)
    if cfg.BossHop == true and now - BossAI.LastSeen > 90 then
        BossAI.LastSeen = now
        Toast:Show("No Boss · hopping...", "info")
        task.spawn(function() pcall(function() ServerHop:TryHop() end) end)
        return true
    end
    return false
end

-- Cake Prince multi-step: FARM_DOUGH → SPAWN_WAIT → KILL_PRINCE
local CakeAI = {
    State = "FARM_DOUGH",
    StateSince = 0,
    Kills = 0,
}

function Paw.TryCakeTick(hrp, cfg, engine)
    if not cfg.AutoCakePrince or not hrp then return false end
    local now = tick()
    -- priority: prince/king first
    local prince = Paw.FindEnemyByKeywords({ "cake prince", "dough king", "prince" }, 2500)
    if prince then
        CakeAI.State = "KILL_PRINCE"
        local root = Paw.GetRoot(prince)
        local hum = prince:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            local farmCfg = Paw.ExpandFarmCfg(cfg, { minRange = 300 })
            Paw.MoveToFarmSpot(hrp, prince, root, farmCfg, Paw.UpdateStuck(hrp))
            pcall(function() Paw.BringMobsToStack(hrp, farmCfg, prince) end)
            Paw.DoMeleeClick(true)
            if now - (engine._lastSkill or 0) > 0.6 then
                engine._lastSkill = now
                task.spawn(function() Paw.DoSkillBurst(true) end)
            end
            engine.FarmCount = (engine.FarmCount or 0) + 1
            return true
        end
    end
    -- farm cake/dough mobs to spawn
    CakeAI.State = "FARM_DOUGH"
    local dough = Paw.FindEnemyByKeywords({ "baking", "cake", "cookie", "doughnut", "dough", "chef" }, 2000)
    if dough then
        local root = Paw.GetRoot(dough)
        local hum = dough:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            local farmCfg = Paw.ExpandFarmCfg(cfg, { minRange = 300 })
            Paw.MoveToFarmSpot(hrp, dough, root, farmCfg, Paw.UpdateStuck(hrp))
            pcall(function() Paw.BringMobsToStack(hrp, farmCfg, dough) end)
            Paw.DoMeleeClick(true)
            engine.FarmCount = (engine.FarmCount or 0) + 1
            CakeAI.Kills = (CakeAI.Kills or 0) + 1
            return true
        end
    end
    -- TP sea of treats
    local pos = Paw.FindIslandOrPartByKeys({ "treats", "cake", "chocolate", "candy" })
    if pos and (hrp.Position - pos).Magnitude > 80 then
        if cfg.TweenFarm ~= false then
            Paw.TweenStepTo(hrp, pos + Vector3.new(0, 12, 0), pos, 280)
        else
            pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 12, 0)) end)
        end
        return true
    end
    return false
end

-- Material multi-step: GOTO_ISLAND → KILL → (repeat)
local MaterialAI = { State = "GOTO", StateSince = 0 }

function Paw.TryMaterialTick(hrp, cfg, engine)
    if not cfg.AutoMaterial or not hrp then return false end
    local mat = tostring(cfg.SelectedMaterial or "Leather")
    local keys = MATERIAL_MOB_KEYS[mat] or MATERIAL_MOB_KEYS.Leather
    local mob = Paw.FindEnemyByKeywords(keys, 2000)
    if mob then
        MaterialAI.State = "KILL"
        local root = Paw.GetRoot(mob)
        local hum = mob:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            local farmCfg = Paw.ExpandFarmCfg(cfg, { minRange = 300 })
            Paw.MoveToFarmSpot(hrp, mob, root, farmCfg, Paw.UpdateStuck(hrp))
            pcall(function() Paw.BringMobsToStack(hrp, farmCfg, mob) end)
            Paw.DoMeleeClick(cfg.FastAttack)
            engine.FarmCount = (engine.FarmCount or 0) + 1
            return true
        end
    end
    MaterialAI.State = "GOTO"
    -- try island by material theme
    local islandKeys = keys
    local pos = Paw.FindIslandOrPartByKeys(islandKeys)
    if pos and (hrp.Position - pos).Magnitude > 100 then
        if cfg.TweenFarm ~= false then
            Paw.TweenStepTo(hrp, pos + Vector3.new(0, 10, 0), pos, 260)
        else
            pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 10, 0)) end)
        end
        return true
    end
    return false
end

-- ========== EXTRA FEATURE HELPERS ==========
local FruitNotifyState = { seen = {}, lastScan = 0 }

function Paw.GetPlayerHP()
    local hum = Paw.GetHumanoid()
    if not hum or hum.MaxHealth <= 0 then return 1 end
    return hum.Health / hum.MaxHealth
end

function Paw.TryAutoDodge()
    local hum = Paw.GetHumanoid()
    if not hum then return end
    -- dodge when low HP or random threaten
    if Paw.GetPlayerHP() > 0.55 then return end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if not vim then return end
        -- Q / F common dodge / instinct keys in BF-style controls
        for _, key in ipairs({ Enum.KeyCode.Q, Enum.KeyCode.F, Enum.KeyCode.LeftControl }) do
            vim:SendKeyEvent(true, key, false, game)
            task.wait(0.03)
            vim:SendKeyEvent(false, key, false, game)
            task.wait(0.05)
        end
    end)
end

function Paw.TryStoreOrEatFruit(cfg)
    local char = Paw.GetCharacter()
    local bp = Player:FindFirstChild("Backpack")
    if not char then return end

    local function isFruitTool(t)
        if not t or not t:IsA("Tool") then return false end
        local n = string.lower(t.Name)
        return n:find("fruit", 1, true) ~= nil or n:find("eatable", 1, true) ~= nil
    end

    if cfg.AutoEatFruit then
        local tool = char:FindFirstChildOfClass("Tool")
        if isFruitTool(tool) then
            pcall(function() tool:Activate() end)
            return
        end
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if isFruitTool(t) then
                    pcall(function()
                        local hum = Paw.GetHumanoid()
                        if hum then hum:EquipTool(t) end
                    end)
                    task.wait(0.1)
                    pcall(function() t:Activate() end)
                    return
                end
            end
        end
    end

    if cfg.AutoStoreFruit then
        local attempted = false
        pcall(function()
            if World.Scanned and World:FireRemotes("Store") > 0 then
                attempted = true
            end
        end)
        if not attempted then
            pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                for _, name in ipairs({ "StoreFruit", "FruitStorage" }) do
                    local r = rs:FindFirstChild(name, true)
                    if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
                        if r:IsA("RemoteEvent") then r:FireServer() else r:InvokeServer() end
                        attempted = true
                        break
                    end
                end
            end)
        end
        pcall(function()
            local pg = Player:FindFirstChild("PlayerGui")
            if not pg then return end
            for _, gui in ipairs(pg:GetDescendants()) do
                if gui:IsA("TextButton") then
                    local t = string.lower(gui.Text or gui.Name or "")
                    if t:find("store") or t:find("storage") or t:find("inventory") then
                        pcall(function() firesignal(gui.MouseButton1Click) end)
                    end
                end
            end
        end)
    end
end

function Paw.ScanFruitNotify()
    if not Config.FruitNotify and not Config.FruitSniper then return end
    local now = tick()
    if now - FruitNotifyState.lastScan < 2 then return end
    FruitNotifyState.lastScan = now
    local part, dist, name, prio = Paw.FindBestFruit({ sniperOnly = Config.FruitSniper })
    if part and dist and dist < 800 then
        local id = tostring(part:GetFullName())
        if not FruitNotifyState.seen[id] then
            FruitNotifyState.seen[id] = true
            local label = name or part.Name
            if Config.FruitSniper and prio and prio <= 8 then
                Toast:Show("⭐ Sniper hit: " .. label .. " · " .. math.floor(dist) .. "m", "ok")
            else
                Toast:Show("Fruit: " .. label .. " · " .. math.floor(dist) .. "m", "ok")
            end
        end
    end
    if now % 45 < 3 then
        FruitNotifyState.seen = {}
        FruitSniperAI.LastToast = {}
    end
end

function Paw.TryAutoDialogue()
    pcall(function()
        local pg = Player:FindFirstChild("PlayerGui")
        local main = pg and pg:FindFirstChild("Main")
        if not main then return end
        local best, bestScore = nil, -math.huge
        for _, gui in ipairs(main:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local t = string.lower(tostring(gui.Text or "") .. " " .. tostring(gui.Name or ""))
                local score = 0
                for _, k in ipairs({"continue","next","skip","claim","accept","yes"}) do if t:find(k,1,true) then score = score + 10 end end
                if t:find("close",1,true) then score = score - 5 end
                if score > bestScore then bestScore, best = score, gui end
            end
        end
        if best and bestScore > 0 then pcall(function() firesignal(best.MouseButton1Click) end) end
    end)
end


-- Sea / island markers (generic) for Auto Next Island
local NavigationAI = { LastTargetName = nil, LastTargetAt = 0 }

function Paw.TryNextIsland()
    local hrp = Paw.GetHRP()
    if not hrp or not World.Scanned then return false end
    local now = tick()
    if now - (NavigationAI.LastTargetAt or 0) < 3 then return false end

    local current, currentD = World:NearestIsland(hrp.Position)
    local best, bestD = nil, math.huge
    for _, is in ipairs(World.Islands or {}) do
        if is.Position and is.Name ~= (current and current.Name) and is.Name ~= NavigationAI.LastTargetName then
            local d = (is.Position - hrp.Position).Magnitude
            if d > 120 and d < 5000 and d < bestD then
                best, bestD = is, d
            end
        end
    end
    if not best then
        -- Allow the previous target again only after all alternatives are exhausted.
        for _, is in ipairs(World.Islands or {}) do
            local d = (is.Position - hrp.Position).Magnitude
            if is.Name ~= (current and current.Name) and d > 120 and d < 5000 and d < bestD then
                best, bestD = is, d
            end
        end
    end
    if not best then return false end

    NavigationAI.LastTargetName = best.Name
    NavigationAI.LastTargetAt = now
    local dest = best.Position
    local ok = pcall(function()
        Paw.TweenStepTo(hrp, dest + Vector3.new(0, 8, 0), dest, tonumber(Config.TweenSpeed) or 280)
    end)
    if ok then
        FarmAI.AnchorPos = dest
        return true
    end
    return false
end


local RAID_TYPES = {
    "Flame", "Ice", "Quake", "Light", "Dark", "String", "Rumble",
    "Buddha", "Magma", "Sand", "Bird", "Human",
}

--[[
  Auto Raid multi-step state machine:
  IDLE → GOTO_LAB → BUY_CHIP → SELECT_CHIP → PLACE_START → LOADING
      → CLEAR_MOBS → NEXT_ISLAND → (loop) → REWARD → RESTART
]]
local RaidAI = {
    State = "IDLE",
    InRaid = false,
    LastJoin = 0,
    LastKill = 0,
    LastNext = 0,
    LastDetect = 0,
    LastStateChange = 0,
    StateSince = 0,
    NoMobSince = 0,
    IslandPos = nil,
    ClearCount = 0,
    CycleCount = 0,
    StatusText = "Idle",
}

function Paw.RaidSetState(st, text)
    if RaidAI.State ~= st then
        RaidAI.State = st
        RaidAI.StateSince = tick()
        RaidAI.LastStateChange = tick()
        RaidAI.ActionAt = 0
    end
    if text then RaidAI.StatusText = text end
end

function Paw.RaidActionDue(minInterval)
    local now = tick()
    minInterval = minInterval or 1.0
    if now - (RaidAI.ActionAt or 0) < minInterval then return false end
    RaidAI.ActionAt = now
    return true
end

function Paw.RaidClickUI(keywords)
    local pg = Player:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("Main")
    if not main then return false end
    local best, bestScore = nil, -math.huge
    pcall(function()
        for _, gui in ipairs(main:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local t = string.lower(tostring(gui.Text or "") .. " " .. tostring(gui.Name or ""))
                local score = 0
                for i, k in ipairs(keywords) do
                    if t:find(k, 1, true) then score = math.max(score, 100 - i) end
                end
                if score > bestScore then bestScore, best = score, gui end
            end
        end
    end)
    if best and bestScore > 0 then
        pcall(function() firesignal(best.MouseButton1Click) end)
        return true
    end
    return false
end

function Paw.RaidFireRemotes(keywords, argsList)
    if not World.Scanned then return 0 end
    local list = World.Remotes and World.Remotes.Raid or {}
    local best, bestScore = nil, 0
    for _, r in ipairs(list) do
        local n = string.lower(r.Name or "")
        local score = 0
        for i, k in ipairs(keywords or {}) do
            if n:find(string.lower(k), 1, true) then score = math.max(score, 100 - i) end
        end
        if score > bestScore then best, bestScore = r, score end
    end
    if not best then return 0 end
    local args = (argsList and argsList[1]) or {}
    local ok = pcall(function()
        if best:IsA("RemoteEvent") then
            best:FireServer(table.unpack(args))
        elseif best:IsA("RemoteFunction") then
            best:InvokeServer(table.unpack(args))
        else
            return false
        end
        return true
    end)
    return ok and 1 or 0
end

function Paw.RaidFirePrompts(keywords, maxDist)
    local hrp = Paw.GetHRP()
    if not hrp then return 0 end
    maxDist = maxDist or 50
    local count = 0
    pcall(function()
        for _, root in ipairs(workspace:GetChildren()) do
            local n = string.lower(root.Name or "")
            if n:find("raid",1,true) or n:find("dungeon",1,true) or n:find("chip",1,true) or n:find("special",1,true) then
                for _, obj in ipairs(root:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local t = string.lower(tostring(obj.ActionText or "") .. " " .. tostring(obj.ObjectText or "") .. " " .. tostring(obj.Name or ""))
                        local hit = false
                        for _, k in ipairs(keywords) do if t:find(k,1,true) then hit = true; break end end
                        local part = obj.Parent
                        if hit and part and part:IsA("BasePart") and (part.Position - hrp.Position).Magnitude <= maxDist then
                            pcall(function() fireproximityprompt(obj) end)
                            count = count + 1
                            return
                        end
                    end
                end
            end
        end
    end)
    return count
end

function Paw.DetectInRaid()
    local inRaid = false
    local enemyNear = 0
    pcall(function()
        local pg = Player:FindFirstChild("PlayerGui")
        if pg then
            for _, g in ipairs(pg:GetDescendants()) do
                local n = string.lower(g.Name or "")
                local t = ""
                pcall(function() t = string.lower(g.Text or "") end)
                if (n:find("raid") or t:find("raid") or t:find("wave") or (t:find("island") and t:find("%"))) then
                    if (g:IsA("TextLabel") or g:IsA("Frame") or g:IsA("TextButton")) and g.Visible ~= false then
                        inRaid = true
                    end
                end
            end
        end
        local hrp = Paw.GetHRP()
        if hrp then
            for _, folder in ipairs(World.EnemyFolders or {}) do
                for _, m in ipairs(folder:GetChildren()) do
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    local root = Paw.GetRoot(m)
                    if hum and hum.Health > 0 and root and (root.Position - hrp.Position).Magnitude < 280 then
                        enemyNear = enemyNear + 1
                    end
                end
            end
            -- Nearby enemies alone do not prove that a raid is active.
            -- Keep enemyNear as telemetry only; raid state must come from a
            -- raid-specific UI/world marker.
        end
        -- Do not treat globally loaded folders/models named "raid"/"dungeon" as
        -- proof that the player is currently inside a raid. Only accept a world
        -- marker when it has a nearby physical part, otherwise it creates a
        -- persistent false-positive and skips the Lab/Chip states.
        if hrp then
            for _, obj in ipairs(workspace:GetChildren()) do
                local n = string.lower(obj.Name or "")
                if n:find("raid", 1, true) or n:find("dungeon", 1, true)
                    or n:find("chip island", 1, true) or n:find("special island", 1, true) then
                    local part = nil
                    if obj:IsA("BasePart") then
                        part = obj
                    elseif obj:IsA("Model") then
                        part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                    else
                        part = obj:FindFirstChildWhichIsA("BasePart", true)
                    end
                    if part and (part.Position - hrp.Position).Magnitude <= 350 then
                        inRaid = true
                        break
                    end
                end
            end
        end
    end)
    RaidAI.InRaid = inRaid
    RaidAI.EnemyNear = enemyNear
    return inRaid, enemyNear
end

function Paw.CountRaidEnemies(maxDist)
    local hrp = Paw.GetHRP()
    if not hrp then return 0, nil end
    maxDist = maxDist or 350
    local count, best, bestD = 0, nil, maxDist
    pcall(function()
        local folders = World.EnemyFolders
        if not folders or #folders == 0 then
            folders = {}
            for _, n in ipairs({ "Enemies", "NPCs", "Mobs", "Monster", "Enemy" }) do
                local f = workspace:FindFirstChild(n)
                if f then table.insert(folders, f) end
            end
        end
        for _, folder in ipairs(folders) do
            for _, m in ipairs(folder:GetChildren()) do
                if m:IsA("Model") and m ~= Paw.GetCharacter() then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    local root = Paw.GetRoot(m)
                    if hum and hum.Health > 0 and root then
                        local n = string.lower(m.Name or "")
                        local raidLike = n:find("raid",1,true) or n:find("awak",1,true) or n:find("island",1,true)
                            or n:find("npc",1,true) == nil and not Players:GetPlayerFromCharacter(m)
                        local d = (root.Position - hrp.Position).Magnitude
                        if raidLike and d < maxDist then
                            count = count + 1
                            if d < bestD then bestD = d best = m end
                        end
                    end
                end
            end
        end
    end)
    return count, best
end

function Paw.FindRaidEnemy(maxDist)
    local _, best = Paw.CountRaidEnemies(maxDist or 320)
    return best
end

function Paw.FindRaidCircle()
    local hrp = Paw.GetHRP()
    if not hrp then return nil end
    local best, bestD = nil, 200
    pcall(function()
        for _, obj in ipairs(workspace:GetChildren()) do
            local n = string.lower(obj.Name or "")
            local part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)))
            if part and (n:find("raid",1,true) or n:find("next",1,true) or n:find("summon",1,true) or n:find("challenge",1,true)) then
                local d = (part.Position - hrp.Position).Magnitude
                if d < bestD then bestD, best = d, part.Position end
            end
        end
    end)
    return best
end


function Paw.RaidGoToLab(hrp, cfg)
    local lab = Paw.FindIslandOrPartByKeys({ "lab", "raid", "scientist", "awaken", "microchip", "circle" })
    if lab then
        if (hrp.Position - lab).Magnitude > 25 then
            if cfg.TweenFarm ~= false then
                Paw.TweenStepTo(hrp, lab + Vector3.new(0, 8, 0), lab, 300)
            else
                pcall(function() hrp.CFrame = CFrame.new(lab + Vector3.new(0, 8, 0)) end)
            end
            return false -- chưa tới
        end
        return true
    end
    -- fallback: vẫn thử UI/remote tại chỗ
    return true
end

function Paw.RaidBuyChip(cfg)
    local raidName = tostring(cfg.SelectedRaid or "Flame")
    Paw.RaidClickUI({ "buy", "purchase", "chip", "microchip", string.lower(raidName) })
    Paw.RaidFireRemotes({ "buy", "chip", "microchip", "shop" }, {
        { raidName },
        { raidName .. " Chip" },
        { raidName .. " Raid" },
        { "Special Microchip" },
        {},
    })
end

function Paw.RaidSelectAndStart(cfg)
    local raidName = tostring(cfg.SelectedRaid or "Flame")
    local rn = string.lower(raidName)
    -- select type
    Paw.RaidClickUI({ rn, "raid", "chip", "select", "special microchip", "microchip" })
    -- start / challenge
    Paw.RaidClickUI({ "start", "challenge", "begin", "go", "confirm", "yes" })
    Paw.RaidFireRemotes({ "raid", "chip", "microchip", "dungeon", "challenge" }, {
        { raidName },
        { raidName .. " Raid" },
        { "Start", raidName },
        { "Select", raidName },
        {},
    })
    if World.Scanned then
        pcall(function() World:FireRemotes("Raid") end)
    end
    Paw.RaidFirePrompts({ "raid", "chip", "challenge", "start", "place" }, 55)
end

function Paw.TryRaidNextIsland()
    Paw.RaidClickUI({ "next", "continue", "advance", "next island", "go" })
    Paw.RaidFireRemotes({ "raid", "next", "island", "stage", "wave" }, {
        {},
        { "Next" },
        { "Island" },
    })
    local hrp = Paw.GetHRP()
    if hrp then
        local circle = Paw.FindRaidCircle()
        if circle then
            pcall(function() hrp.CFrame = CFrame.new(circle + Vector3.new(0, 5, 0)) end)
        end
        Paw.RaidFirePrompts({ "next", "island", "continue", "advance" }, 45)
    end
end

function Paw.TryRaidReward()
    Paw.RaidClickUI({ "claim", "reward", "collect", "close", "ok", "continue", "finish" })
    Paw.RaidFireRemotes({ "reward", "claim", "raid", "finish", "complete" }, {
        {},
        { "Claim" },
        { "Reward" },
    })
end

function Paw.TryJoinRaid(cfg)
    cfg = cfg or Config
    local now = tick()
    if now - (RaidAI.LastJoin or 0) < 3 then return end
    RaidAI.LastJoin = now
    -- SELECT_CHIP already handled chip/type selection; PLACE_START should only
    -- attempt the final start/confirm action to avoid duplicate selection calls.
    Paw.RaidClickUI({ "start", "challenge", "begin", "go", "confirm", "yes" })
    Paw.RaidFireRemotes({ "start", "challenge", "raid", "dungeon" }, {
        { "Start" },
        { "Challenge" },
        {},
    })
    Paw.RaidFirePrompts({ "start", "challenge", "confirm", "go" }, 60)
end

function Paw.RaidAttackEnemy(hrp, enemy, cfg, engine)
    local root = Paw.GetRoot(enemy)
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end
    local now = tick()
    Paw.MoveToFarmSpot(hrp, enemy, root, cfg, Paw.UpdateStuck(hrp))
    pcall(function() Paw.BringMobsToStack(hrp, Paw.ExpandFarmCfg(cfg), enemy) end)
    local rate = Paw.GetAttackInterval(cfg)
    if now - (engine._lastAttack or 0) >= rate then
        engine._lastAttack = now
        Paw.AttackAOE(nil, cfg)
    end
    if (cfg.AutoSkill or cfg.ComboMode) and now - (engine._lastSkill or 0) >= 0.65 then
        engine._lastSkill = now
        task.spawn(function() Paw.DoSkillBurst(true) end)
    end
    engine.FarmCount = (engine.FarmCount or 0) + 1
    FarmAI.CurrentTarget = enemy
    return true
end

-- Multi-step raid tick
function Paw.TryRaidTick(hrp, cfg, engine)
    if not cfg.AutoRaid or not hrp then return false end
    local now = tick()
    if not RaidAI.StateSince or RaidAI.StateSince <= 0 then
        RaidAI.StateSince = now
        RaidAI.LastStateChange = now
    end

    if now - (RaidAI.LastDetect or 0) > 1.5 then
        RaidAI.LastDetect = now
        Paw.DetectInRaid()
    end

    local inRaid = RaidAI.InRaid
    local state = RaidAI.State or "IDLE"
    local stateAge = now - (RaidAI.StateSince or now)

    -- Force into CLEAR if detected in raid
    if inRaid and state ~= "CLEAR_MOBS" and state ~= "NEXT_ISLAND" and state ~= "REWARD" and state ~= "LOADING" then
        Paw.RaidSetState("CLEAR_MOBS", "Clearing mobs")
        RaidAI.NoMobSince = 0
        state = "CLEAR_MOBS"
    end
    if not inRaid and (state == "CLEAR_MOBS" or state == "NEXT_ISLAND" or state == "LOADING") and stateAge > 8 then
        -- raid ended unexpectedly
        if state == "CLEAR_MOBS" and RaidAI.ClearCount > 0 then
            Paw.RaidSetState("REWARD", "Claim reward")
        else
            Paw.RaidSetState("IDLE", "Idle")
        end
        state = RaidAI.State
    end

    ---------- STATE MACHINE ----------
    if state == "IDLE" or state == "GOTO_LAB" then
        Paw.RaidSetState("GOTO_LAB", "Go to Lab")
        local atLab = Paw.RaidGoToLab(hrp, cfg)
        if atLab or stateAge > 12 then
            if cfg.RaidBuyChip then
                Paw.RaidSetState("BUY_CHIP", "Buy chip")
            else
                Paw.RaidSetState("SELECT_CHIP", "Select chip")
            end
        end
        return true

    elseif state == "BUY_CHIP" then
        if Paw.RaidActionDue(2.0) then Paw.RaidBuyChip(cfg) end
        if stateAge > 2.5 then
            Paw.RaidSetState("SELECT_CHIP", "Select chip")
        end
        return true

    elseif state == "SELECT_CHIP" then
        if Paw.RaidActionDue(2.0) then Paw.RaidSelectAndStart(cfg) end
        if stateAge > 2 then
            Paw.RaidSetState("PLACE_START", "Start raid")
        end
        return true

    elseif state == "PLACE_START" then
        if Paw.RaidActionDue(2.0) then Paw.TryJoinRaid(cfg) end
        if stateAge > 2.5 then
            Paw.RaidSetState("LOADING", "Loading raid...")
        end
        return true

    elseif state == "LOADING" then
        if inRaid then
            Paw.RaidSetState("CLEAR_MOBS", "Clearing mobs")
            RaidAI.NoMobSince = 0
            RaidAI.ClearCount = 0
        elseif stateAge > 18 then
            -- timeout — thử lại từ lab
            Paw.RaidSetState("GOTO_LAB", "Retry lab")
        end
        return true

    elseif state == "CLEAR_MOBS" then
        if cfg.RaidKill == false then
            Paw.RaidSetState("NEXT_ISLAND", "Next island")
            return true
        end
        local count, enemy = Paw.CountRaidEnemies(350)
        if enemy and Paw.RaidAttackEnemy(hrp, enemy, cfg, engine) then
            RaidAI.NoMobSince = 0
            RaidAI.ClearCount = (RaidAI.ClearCount or 0) + 1
            Paw.RaidSetState("CLEAR_MOBS", string.format("Kill · %d near", count))
            return true
        end
        -- không còn mob
        if RaidAI.NoMobSince == 0 then
            RaidAI.NoMobSince = now
        end
        local emptyFor = now - RaidAI.NoMobSince
        if emptyFor > 1.8 then
            if cfg.RaidNext ~= false then
                Paw.RaidSetState("NEXT_ISLAND", "Next island")
            else
                Paw.RaidSetState("REWARD", "Reward / wait")
            end
        else
            -- quét rộng hơn
            local far = Paw.FindRaidEnemy(600)
            if far then
                RaidAI.NoMobSince = 0
                Paw.RaidAttackEnemy(hrp, far, cfg, engine)
            end
        end
        return true

    elseif state == "NEXT_ISLAND" then
        if now - (RaidAI.LastNext or 0) > 2.2 then
            RaidAI.LastNext = now
            Paw.TryRaidNextIsland()
        end
        -- có mob mới → clear tiếp
        local count = select(1, Paw.CountRaidEnemies(300))
        if count > 0 then
            Paw.RaidSetState("CLEAR_MOBS", "Clearing mobs")
            RaidAI.NoMobSince = 0
        elseif stateAge > 10 then
            -- hết raid hoặc kẹt
            if not inRaid then
                Paw.RaidSetState("REWARD", "Claim reward")
            else
                -- vẫn trong raid, lặp next
                RaidAI.StateSince = now
            end
        end
        return true

    elseif state == "REWARD" then
        if Paw.RaidActionDue(2.0) then Paw.TryRaidReward() end
        if stateAge > 3 then
            RaidAI.CycleCount = (RaidAI.CycleCount or 0) + 1
            Paw.RaidSetState("IDLE", "Restart cycle #" .. tostring(RaidAI.CycleCount))
        end
        return true
    end

    -- fallback
    if not inRaid and now - (RaidAI.LastJoin or 0) > 8 then
        Paw.RaidSetState("GOTO_LAB", "Go to Lab")
    end
    return RaidAI.InRaid or state ~= "IDLE"
end

-- ===== ADVANCED TARGETS =====
local MATERIAL_MOB_KEYS = {
    Leather = { "leather", "bandit", "monkey", "gorilla", "brutes" },
    Scrap = { "scrap", "factory", "machine", "android" },
    MagmaOre = { "magma", "lava", "fishman" },
    FishTail = { "fish", "shark", "sea" },
    Ectoplasm = { "ectoplasm", "ghost", "ship", "raid" },
    Bones = { "bone", "skeleton", "undead", "zombie" },
    VampireFang = { "vampire", "fang", "blood" },
    Gunpowder = { "gun", "soldier", "marine" },
    MysticDroplet = { "water", "waterkey", "sea" },
    ConjuredCocoa = { "cocoa", "candy", "cake", "cookie" },
}

local ADV_TARGET_KEYS = {
    Elite = { "elite", "deandre", "diablo", "urban", "chance", "awaken" },
    CakePrince = { "cake prince", "dough king", "cake", "prince", "baking" },
    SeaBeast = { "sea beast", "seabeast", "terror shark", "leviathan", "shark" },
    Mirage = { "mirage", "gear", "moon" },
    Kitsune = { "kitsune", "temple", "shrine" },
}

-- Elite Hunter: tên elite phổ biến Sea 3 (match chính xác hơn keyword lỏng)
local ELITE_EXACT = {
    "deandre", "diablo", "urban", "chance", "elite pirate", "elite hunter",
}
local ELITE_NPC_KEYS = { "elite hunter", "elite", "hunter", "quest" }

local EliteAI = {
    Current = nil,
    LastSeen = 0,
    LastQuest = 0,
    LastScan = 0,
    KillCount = 0,
    Cache = {},
    CacheUntil = 0,
}

function Paw.FindEnemyByKeywords(keys, maxDist)
    local hrp = Paw.GetHRP()
    if not hrp or not keys then return nil end
    maxDist = maxDist or 2000
    local best, bestD = nil, maxDist
    pcall(function()
        local folders = World.EnemyFolders
        if not folders or #folders == 0 then
            folders = {}
            for _, n in ipairs({ "Enemies", "NPCs", "Mobs", "Monster", "Enemy" }) do
                local f = workspace:FindFirstChild(n)
                if f then table.insert(folders, f) end
            end
            -- Never fall back to the entire Workspace: that turns a targeted
            -- enemy search into an arbitrary NPC/world-model search.
            if #folders == 0 then return end
        end
        for _, folder in ipairs(folders) do
            for _, m in ipairs(folder:GetChildren()) do
                if m:IsA("Model") and m ~= Paw.GetCharacter() then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    local root = Paw.GetRoot(m)
                    if hum and hum.Health > 0 and root then
                        local n = string.lower(m.Name)
                        local ok = false
                        for _, k in ipairs(keys) do
                            if n:find(k, 1, true) then ok = true break end
                        end
                        if ok then
                            local d = (root.Position - hrp.Position).Magnitude
                            if d < bestD then bestD = d best = m end
                        end
                    end
                end
            end
        end
        -- also scan workspace direct children for world bosses
        for _, m in ipairs(workspace:GetChildren()) do
            if m:IsA("Model") then
                local hum = m:FindFirstChildOfClass("Humanoid")
                local root = Paw.GetRoot(m)
                if hum and hum.Health > 0 and root then
                    local n = string.lower(m.Name)
                    for _, k in ipairs(keys) do
                        if n:find(k, 1, true) then
                            local d = (root.Position - hrp.Position).Magnitude
                            if d < bestD then bestD = d best = m end
                            break
                        end
                    end
                end
            end
        end
    end)
    return best, bestD
end

function Paw.FindIslandOrPartByKeys(keys)
    local hrp = Paw.GetHRP()
    if not hrp then return nil end
    local best, bestD = nil, 1e9
    pcall(function()
        if World.Scanned and World.Islands then
            for _, is in ipairs(World.Islands) do
                local n = string.lower(is.Name or "")
                for _, k in ipairs(keys) do
                    if n:find(k, 1, true) then
                        local d = (is.Position - hrp.Position).Magnitude
                        if d < bestD then bestD = d best = is.Position end
                    end
                end
            end
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            local n = string.lower(obj.Name)
            for _, k in ipairs(keys) do
                if n:find(k, 1, true) then
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local d = (part.Position - hrp.Position).Magnitude
                        if d < bestD then bestD = d best = part.Position end
                    end
                end
            end
        end
    end)
    return best, bestD
end

function Paw.IsEliteModel(model)
    if not model or not model.Name then return false, 0 end
    local n = string.lower(model.Name)
    -- exact / high confidence
    for _, k in ipairs(ELITE_EXACT) do
        if n == k or n:find(k, 1, true) then
            local score = 100
            if n:find("elite", 1, true) then score = score + 40 end
            if n:find("pirate", 1, true) then score = score + 10 end
            -- exclude false positives
            if n:find("quest") or n:find("board") or n:find("npc") and not n:find("elite") then
                return false, 0
            end
            return true, score
        end
    end
    -- Billboard / title
    local score = 0
    pcall(function()
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextBox") then
                local t = string.lower(d.Text or "")
                if t:find("elite", 1, true) then score = score + 50 end
            end
        end
    end)
    if n:find("elite", 1, true) and not n:find("hunter", 1, true) then
        score = score + 60
    end
    return score >= 50, score
end

function Paw.ScanElites(maxDist)
    local hrp = Paw.GetHRP()
    if not hrp then return {} end
    maxDist = maxDist or 4000
    local now = tick()
    if now < EliteAI.CacheUntil and #EliteAI.Cache > 0 then
        -- filter dead from cache
        local alive = {}
        for _, e in ipairs(EliteAI.Cache) do
            if e.Model and e.Model.Parent then
                local hum = e.Model:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    e.HP = hum.Health
                    e.MaxHP = hum.MaxHealth
                    e.Root = Paw.GetRoot(e.Model)
                    if e.Root then
                        e.Dist = (e.Root.Position - hrp.Position).Magnitude
                        table.insert(alive, e)
                    end
                end
            end
        end
        EliteAI.Cache = alive
        return alive
    end

    local list = {}
    local function consider(m)
        if not m:IsA("Model") or m == Paw.GetCharacter() then return end
        local ok, score = Paw.IsEliteModel(m)
        if not ok then return end
        local hum = m:FindFirstChildOfClass("Humanoid")
        local root = Paw.GetRoot(m)
        if not hum or hum.Health <= 0 or not root then return end
        local d = (root.Position - hrp.Position).Magnitude
        if d > maxDist then return end
        table.insert(list, {
            Model = m,
            Root = root,
            HP = hum.Health,
            MaxHP = hum.MaxHealth,
            Dist = d,
            Score = score,
            Name = m.Name,
        })
    end

    pcall(function()
        local folders = World.EnemyFolders
        if folders and #folders > 0 then
            for _, folder in ipairs(folders) do
                for _, m in ipairs(folder:GetChildren()) do consider(m) end
            end
        end
        for _, n in ipairs({ "Enemies", "NPCs", "Mobs", "Monster", "Enemy", "Characters" }) do
            local f = workspace:FindFirstChild(n)
            if f then
                for _, m in ipairs(f:GetChildren()) do consider(m) end
            end
        end
        for _, m in ipairs(workspace:GetChildren()) do consider(m) end
    end)

    EliteAI.Cache = list
    EliteAI.CacheUntil = now + 0.6
    return list
end

function Paw.SelectBestElite(cfg)
    local list = Paw.ScanElites(4500)
    if #list == 0 then return nil end
    local preferLow = cfg.ElitePreferLowHP ~= false
    table.sort(list, function(a, b)
        -- sticky current
        if EliteAI.Current then
            if a.Model == EliteAI.Current then return true end
            if b.Model == EliteAI.Current then return false end
        end
        if preferLow then
            local ra = (a.HP or 1) / math.max(a.MaxHP or 1, 1)
            local rb = (b.HP or 1) / math.max(b.MaxHP or 1, 1)
            if math.abs(ra - rb) > 0.08 then return ra < rb end
        end
        if a.Score ~= b.Score then return a.Score > b.Score end
        return (a.Dist or 0) < (b.Dist or 0)
    end)
    return list[1]
end

function Paw.TryAcceptEliteQuest()
    local now = tick()
    if now - (EliteAI.LastQuest or 0) < 8 then return end
    EliteAI.LastQuest = now
    local hrp = Paw.GetHRP()
    if not hrp then return end
    pcall(function()
        local best, bestD = nil, 120
        for _, q in ipairs(World.QuestNPCs or {}) do
            local n = string.lower(q.Name or "")
            if (n:find("elite hunter",1,true) or n:find("hunter",1,true)) and q.Part then
                local d = (q.Position - hrp.Position).Magnitude
                if d < bestD then bestD, best = d, q end
            end
        end
        if best then
            if bestD > 18 then pcall(function() hrp.CFrame = CFrame.new(best.Position + Vector3.new(0,4,0), best.Position) end) end
            if best.Prompt then pcall(function() fireproximityprompt(best.Prompt) end) end
            if best.Model then
                local pr = best.Model:FindFirstChildWhichIsA("ProximityPrompt", true)
                if pr then pcall(function() fireproximityprompt(pr) end) end
            end
        end
    end)
    pcall(function()
        local pg = Player:FindFirstChild("PlayerGui")
        local main = pg and pg:FindFirstChild("Main")
        if not main then return end
        local bestBtn, bestScore = nil, -math.huge
        for _, gui in ipairs(main:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local t = string.lower(tostring(gui.Text or "") .. " " .. tostring(gui.Name or ""))
                local score = 0
                if t:find("elite",1,true) or t:find("hunter",1,true) then score = score + 50 end
                if t:find("accept",1,true) or t:find("quest",1,true) or t:find("start",1,true) then score = score + 20 end
                if score > bestScore then bestScore, bestBtn = score, gui end
            end
        end
        if bestBtn and bestScore > 50 then pcall(function() firesignal(bestBtn.MouseButton1Click) end) end
    end)
end

function Paw.TryEliteHunterTick(hrp, cfg, engine)
    if not cfg.AutoEliteHunter or not hrp then return false end
    local now = tick()

    -- nhận quest định kỳ
    if now - (EliteAI.LastQuest or 0) > 12 then
        task.spawn(Paw.TryAcceptEliteQuest)
    end

    local entry = Paw.SelectBestElite(cfg)
    if entry and entry.Model then
        EliteAI.Current = entry.Model
        EliteAI.LastSeen = now
        local root = entry.Root or Paw.GetRoot(entry.Model)
        local hum = entry.Model:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then
            EliteAI.Current = nil
            EliteAI.CacheUntil = 0
            return false
        end

        -- di chuyển + đánh
        local stuck = Paw.UpdateStuck(hrp)
        local farmCfg = Paw.ExpandFarmCfg(cfg, { minRange = 350 })
        Paw.MoveToFarmSpot(hrp, entry.Model, root, farmCfg, stuck)
        pcall(function() Paw.BringMobsToStack(hrp, farmCfg, entry.Model) end)

        local rate = Paw.GetAttackInterval(cfg)
        if now - (engine._lastAttack or 0) >= rate then
            engine._lastAttack = now
            Paw.AttackAOE(entry and entry.Model, cfg) -- elite fast via AttackSpeed
        end
        if (cfg.AutoSkill or cfg.ComboMode) and now - (engine._lastSkill or 0) >= 0.75 then
            engine._lastSkill = now
            task.spawn(function() Paw.DoSkillBurst(true) end)
        end
        if cfg.AutoKen and now - (engine._lastKen or 0) > 6 then
            engine._lastKen = now
            task.spawn(function()
                pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    if vim then
                        vim:SendKeyEvent(true, Enum.KeyCode.J, false, game)
                        task.wait(0.05)
                        vim:SendKeyEvent(false, Enum.KeyCode.J, false, game)
                    end
                end)
            end)
        end

        engine.FarmCount = (engine.FarmCount or 0) + 1
        FarmAI.CurrentTarget = entry.Model
        return true
    end

    -- Không thấy elite
    EliteAI.Current = nil
    if EliteAI.LastSeen == 0 then EliteAI.LastSeen = now end
    local waitSec = tonumber(cfg.EliteHopWait) or 45
    if cfg.EliteHop == true and (now - EliteAI.LastSeen) >= waitSec then
        EliteAI.LastSeen = now
        Toast:Show("No Elite · hopping...", "info")
        task.spawn(function()
            pcall(function() ServerHop:TryHop() end)
        end)
        return true
    end

    -- chờ: thử nhận quest / đứng gần Castle area nếu có
    if now - (EliteAI.LastScan or 0) > 5 then
        EliteAI.LastScan = now
        task.spawn(Paw.TryAcceptEliteQuest)
        local castle = Paw.FindIslandOrPartByKeys({ "castle on the sea", "castle", "port town" })
        if castle and (hrp.Position - castle).Magnitude > 120 then
            if cfg.TweenFarm ~= false then
                Paw.TweenStepTo(hrp, castle + Vector3.new(0, 15, 0), castle, 300)
            else
                pcall(function() hrp.CFrame = CFrame.new(castle + Vector3.new(0, 15, 0)) end)
            end
        end
    end
    return false
end

function Paw.TryAdvancedTarget(cfg)
    -- Elite handled by TryEliteHunterTick (dedicated)
    -- priority: Cake > Sea Beast > Material > Mirage/Kitsune island TP
    if cfg.AutoCakePrince then
        local t = Paw.FindEnemyByKeywords(ADV_TARGET_KEYS.CakePrince, 2500)
        if t then return t, "CakePrince" end
    end
    if cfg.AutoSeaEvent then
        local t = Paw.FindEnemyByKeywords(ADV_TARGET_KEYS.SeaBeast, 3000)
        if t then return t, "SeaBeast" end
    end
    if cfg.AutoMaterial then
        local mat = tostring(cfg.SelectedMaterial or "Leather")
        local keys = MATERIAL_MOB_KEYS[mat] or MATERIAL_MOB_KEYS.Leather
        local t = Paw.FindEnemyByKeywords(keys, 1500)
        if t then return t, "Material" end
    end
    if cfg.AutoMirage then
        local pos = Paw.FindIslandOrPartByKeys(ADV_TARGET_KEYS.Mirage)
        if pos then return pos, "MirageTP" end
        local t = Paw.FindEnemyByKeywords(ADV_TARGET_KEYS.Mirage, 2500)
        if t then return t, "Mirage" end
    end
    if cfg.AutoKitsune then
        local pos = Paw.FindIslandOrPartByKeys(ADV_TARGET_KEYS.Kitsune)
        if pos then return pos, "KitsuneTP" end
        local t = Paw.FindEnemyByKeywords(ADV_TARGET_KEYS.Kitsune, 2500)
        if t then return t, "Kitsune" end
    end
    return nil, nil
end

function Paw.TryObservationHaki(cfg)
    if not cfg.AutoObservation then return false end
    local now = tick()
    if now - (cfg._lastObservationPulse or 0) < 1.5 then return false end
    cfg._lastObservationPulse = now
    local ok = pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if not vim then return end
        vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    return ok
end

function Paw.UpdateStuck(hrp)
    local pos = hrp.Position
    if FarmAI.LastPos then
        local moved = (pos - FarmAI.LastPos).Magnitude
        if moved < 1.2 then
            if FarmAI.StuckSince == 0 then FarmAI.StuckSince = tick() end
        else
            FarmAI.StuckSince = 0
        end
    end
    FarmAI.LastPos = pos
    return FarmAI.StuckSince > 0 and (tick() - FarmAI.StuckSince > 4)
end

function Paw.GetNearestNPC(maxRange)
    local model, dist = Paw.SelectFarmTarget({ FarmRange = maxRange or 80, PreferNearest = true, OwnIslandOnly = false }, "level")
    return model, dist
end

-- Anti AFK
local AntiAFK = { Conn = nil, PulseConn = nil, Last = 0 }
function AntiAFK:Start()
    Config.AntiAFK = true
    if self.Conn then return end
    self.Conn = HubInstance:AddConnection(Player.Idled:Connect(function()
        if not Config.AntiAFK then return end
        pcall(function()
            if VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end
        end)
    end))
    -- also light virtual input every ~60s
    self.PulseConn = HubInstance:AddConnection(RunService.Heartbeat:Connect(function()
        if not Config.AntiAFK or HubInstance.stopped then return end
        local now = tick()
        if now - self.Last < 55 then return end
        self.Last = now
        pcall(function()
            if VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end
        end)
    end))
end
function AntiAFK:Stop()
    Config.AntiAFK = false
    if self.Conn then
        pcall(function() self.Conn:Disconnect() end)
        self.Conn = nil
    end
    if self.PulseConn then
        pcall(function() self.PulseConn:Disconnect() end)
        self.PulseConn = nil
    end
end

-- Speed Boost
local SpeedState = { original = nil, character = nil }
function Paw.ApplyWalkSpeed()
    local hum = Paw.GetHumanoid()
    if not hum then return end
    if SpeedState.character ~= hum.Parent then
        SpeedState.character = hum.Parent
        SpeedState.original = hum.WalkSpeed
    end
    if Config.SpeedEnabled then
        local spd = tonumber(Config.WalkSpeed) or 32
        if spd < 16 then spd = 32 end
        pcall(function() hum.WalkSpeed = spd end)
    else
        pcall(function()
            hum.WalkSpeed = tonumber(SpeedState.original) or 16
        end)
    end
end

HubInstance.RestoreWalkSpeed = function()
    local hum = Paw.GetHumanoid()
    if hum then
        pcall(function() hum.WalkSpeed = tonumber(SpeedState.original) or 16 end)
    end
end

-- Server Hop
local ServerHop = { Active = false, Busy = false, Generation = 0 }
function ServerHop:Stop()
    Config.AutoServerHop = false
    self.Active = false
    self.Generation = (self.Generation or 0) + 1
    self.Busy = false
end
function ServerHop:Start()
    Config.AutoServerHop = true
    self.Active = true
    self.Generation = (self.Generation or 0) + 1
    self:TryHop()
end
function ServerHop:Toggle()
    if self.Active then
        self:Stop()
    else
        self:Start()
    end
end
function ServerHop:TryHop()
    if self.Busy or not self.Active or not Config.AutoServerHop then return end
    self.Busy = true
    local generation = self.Generation or 0
    task.spawn(function()
        local ok, err = pcall(function()
            if not self.Active or not Config.AutoServerHop or generation ~= self.Generation then return end
            local maxP = tonumber(Config.MaxPlayers) or 6
            local placeId = game.PlaceId
            local req = game:HttpGet(
                ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
            )
            if not self.Active or not Config.AutoServerHop or generation ~= self.Generation then return end
            local data = HttpService:JSONDecode(req)
            if type(data) == "table" and type(data.data) == "table" then
                for _, server in ipairs(data.data) do
                    if not self.Active or not Config.AutoServerHop or generation ~= self.Generation then return end
                    local playing = server.playing or 0
                    local maxPlayers = server.maxPlayers or 12
                    local id = server.id
                    if id and id ~= game.JobId and playing < maxP and playing < maxPlayers then
                        TeleportService:TeleportToPlaceInstance(placeId, id, Player)
                        return
                    end
                end
            end
            if not self.Active or not Config.AutoServerHop or generation ~= self.Generation then return end
            -- fallback: random teleport
            TeleportService:Teleport(placeId, Player)
        end)
        if not ok and self.Active and Config.AutoServerHop and generation == self.Generation then
            Toast:Show("Server hop failed", "warn")
        end
        task.wait(3)
        if generation == self.Generation then
            self.Busy = false
        end
    end)
end

-- Noclip
local NoclipConn = nil
local NoclipOriginal = {}
local NoclipParts = {}
function Paw.RefreshNoclipParts()
    NoclipParts = {}
    local char = Paw.GetCharacter()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then table.insert(NoclipParts, part) end
    end
end
function Paw.SetNoclip(on)
    Config.Noclip = on and true or false
    if NoclipConn then
        pcall(function() NoclipConn:Disconnect() end)
        NoclipConn = nil
    end
    if not on then
        local char = Paw.GetCharacter()
        if char then
            for _, part in ipairs(NoclipParts) do
                if part:IsA("BasePart") then
                    pcall(function()
                        if NoclipOriginal[part] ~= nil then
                            part.CanCollide = NoclipOriginal[part]
                        end
                        NoclipOriginal[part] = nil
                    end)
                end
            end
        end
        NoclipOriginal = {}
        return
    end
    Paw.RefreshNoclipParts()
    NoclipConn = RunService.Stepped:Connect(function()
        if not Config.Noclip or HubInstance.stopped then return end
        for _, part in ipairs(NoclipParts) do
            if part and part.Parent and part:IsA("BasePart") then
                if NoclipOriginal[part] == nil then NoclipOriginal[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    end)
end

-- ESP
local ESPFolder = nil
local ESPConn = nil
function Paw.ClearESP()
    if ESPFolder then
        pcall(function() ESPFolder:Destroy() end)
        ESPFolder = nil
    end
end
function Paw.MakeBillboard(adornee, text, color)
    local bb = Instance.new("BillboardGui")
    bb.Name = "PawZESP"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 120, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = ESPFolder
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1, 0, 1, 0)
    lab.BackgroundTransparency = 1
    lab.Text = text
    lab.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lab.TextStrokeTransparency = 0.4
    lab.TextSize = 12
    lab.Font = Enum.Font.GothamBold
    lab.Parent = bb
    return bb
end
function Paw.RefreshESP()
    Paw.ClearESP()
    if not Config.ESP then return end
    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "PawZHubESP"
    ESPFolder.Parent = CoreGui
    local count = 0
    if Config.ESP_Players then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then Paw.MakeBillboard(hrp, plr.DisplayName or plr.Name, Color3.fromRGB(100, 200, 255)) end
            end
        end
    end
    if Config.ESP_Fruit then
        for _, f in ipairs(World.FruitSpawns or {}) do
            if count >= 80 then break end
            if f.Part and f.Part.Parent then Paw.MakeBillboard(f.Part, f.Name, Color3.fromRGB(255,200,80)); count += 1 end
        end
    end
    if Config.ESP_Chest then
        for _, c in ipairs(World.Chests or {}) do
            if count >= 100 then break end
            if c.Part and c.Part.Parent then Paw.MakeBillboard(c.Part, "Chest", Color3.fromRGB(180,255,120)); count += 1 end
        end
    end
    if Config.ESP_NPC then
        for _, q in ipairs(World.QuestNPCs or {}) do
            if count >= 110 then break end
            if q.Part and q.Part.Parent then Paw.MakeBillboard(q.Part, q.Name, Color3.fromRGB(220,180,255)); count += 1 end
        end
    end
    if Config.ESP then
        for _, entry in ipairs(Paw.RefreshEnemyCache()) do
            if count >= 140 then break end
            if entry.Root and entry.Humanoid and entry.Humanoid.Health > 0 then
                local label = entry.IsBoss and ("BOSS " .. entry.Name) or entry.Name
                Paw.MakeBillboard(entry.Root, label, entry.IsBoss and Color3.fromRGB(255,80,80) or Color3.fromRGB(255,255,200))
                count += 1
            end
        end
    end
end

function Paw.SetESP(on)
    Config.ESP = on and true or false
    if ESPConn then
        pcall(function() ESPConn:Disconnect() end)
        ESPConn = nil
    end
    Paw.ClearESP()
    if not on then return end
    Paw.RefreshESP()
    -- use a single Heartbeat throttle; no second background task.
    local last = 0
    ESPConn = RunService.Heartbeat:Connect(function()
        if not Config.ESP or HubInstance.stopped then return end
        local now = tick()
        if now - last < 2.5 then return end
        last = now
        pcall(Paw.RefreshESP)
    end)
end

-- Feature Engine (main loop)
-- Central primary-feature arbitration. Exactly one combat/movement pipeline owns each Heartbeat tick.
local PRIMARY_FEATURES = {
    { key = "AutoRaid",          name = "Auto Raid" },
    { key = "AutoFarmLevel",     name = "Auto Farm Level" },
    { key = "FruitSniper",       name = "Fruit Sniper" },
    { key = "AutoFarmFruit",     name = "Auto Farm Fruit" },
    { key = "AutoBoss",           name = "Auto Boss" },
    { key = "AutoEliteHunter",    name = "Auto Elite Hunter" },
    { key = "AutoCakePrince",     name = "Auto Cake Prince" },
    { key = "AutoBone",           name = "Auto Farm Bone" },
    { key = "AutoMaterial",       name = "Auto Material" },
    { key = "AutoSeaEvent",       name = "Auto Sea Events" },
    { key = "AutoMirage",         name = "Auto Mirage" },
    { key = "AutoKitsune",        name = "Auto Kitsune" },
    { key = "AutoFarmMastery",    name = "Auto Farm Mastery" },
    { key = "AutoAttack",         name = "Auto Attack" },
}

function Paw.ResolvePrimaryFeature(cfg)
    if type(cfg) ~= "table" then return nil end
    for _, item in ipairs(PRIMARY_FEATURES) do
        if cfg[item.key] then
            return item.key, item.name
        end
    end
    return nil
end

local PrimaryLifecycle = {}

local function RunPrimaryDisable(key)
    local item = PrimaryLifecycle[key]
    if item and item.onDisable then
        pcall(item.onDisable)
    end
    -- Always clear stale state machines when arbitration switches away from a mode.
    -- This is intentionally idempotent so repeated normalization cannot corrupt state.
    pcall(function()
        if key == "AutoRaid" and RaidAI then
            RaidAI.State = "IDLE"
            RaidAI.InRaid = false
            RaidAI.StateSince = 0
            RaidAI.LastStateChange = 0
            RaidAI.NoMobSince = 0
            RaidAI.ClearCount = 0
            RaidAI.LastJoin = 0
            RaidAI.LastNext = 0
            RaidAI.ActionAt = 0
        elseif key == "FruitSniper" or key == "AutoFarmFruit" then
            if FruitSniperAI then
                FruitSniperAI.State = "FIND"
                FruitSniperAI.StateSince = 0
                FruitSniperAI.TargetPart = nil
                FruitSniperAI.PickUntil = 0
                FruitSniperAI.StoreUntil = 0
                FruitSniperAI.PickedIds = {}
            end
        elseif key == "AutoFarmLevel" and LevelFarmAI then
            LevelFarmAI.State = "INIT"
            LevelFarmAI.StateSince = 0
            LevelFarmAI.StatusText = "Idle"
            LevelFarmAI.Target = nil
            LevelFarmAI.QuestGuideKey = nil
            LevelFarmAI.QuestProgress = 0
            LevelFarmAI.QuestGoal = 0
            LevelFarmAI.LastProgressAt = 0
            LevelFarmAI.ClaimVerifyUntil = 0
            LevelFarmAI.ClaimRequestedAt = 0
            LevelFarmAI.ClaimBlockedUntil = 0
            LevelFarmAI.RecoveryLevel = 0
            LevelFarmAI.SearchStartedAt = 0
            LevelFarmAI.StallCount = 0
        elseif key == "AutoBoss" and BossAI then
            BossAI.State = "FIND"
            BossAI.StateSince = 0
            BossAI.Current = nil
        elseif key == "AutoEliteHunter" and EliteAI then
            EliteAI.Current = nil
            EliteAI.LastQuest = 0
        elseif key == "AutoCakePrince" and CakeAI then
            CakeAI.State = "FARM_DOUGH"
            CakeAI.StateSince = 0
        elseif key == "AutoMaterial" and MaterialAI then
            MaterialAI.State = "GOTO"
            MaterialAI.StateSince = 0
        end
        -- Any primary can own Bring/Magnet. Always restore it when ownership changes.
        if HubInstance and HubInstance.RestoreBringState then
            pcall(HubInstance.RestoreBringState)
        end
        if FarmAI then
            FarmAI.CurrentTarget = nil
            FarmAI.StuckSince = 0
        end
    end)
end

function Paw.RegisterPrimaryLifecycle(key, onDisable)
    PrimaryLifecycle[key] = PrimaryLifecycle[key] or {}
    PrimaryLifecycle[key].onDisable = onDisable
end

function Paw.NormalizePrimaryFeatures(cfg, preferredKey)
    if type(cfg) ~= "table" then return nil end
    local active = nil
    if preferredKey and cfg[preferredKey] then
        active = preferredKey
    else
        for _, item in ipairs(PRIMARY_FEATURES) do
            if cfg[item.key] then
                active = item.key
                break
            end
        end
    end
    if active then
        for _, item in ipairs(PRIMARY_FEATURES) do
            if item.key ~= active and cfg[item.key] then
                cfg[item.key] = false
                RunPrimaryDisable(item.key)
            end
        end
    end
    return active
end

local SafeModeAI = { active = false, lastRetreat = 0, safePos = nil }

local FeatureEngine = {
    Running = false,
    FarmCount = 0,
    KillCount = 0,
    FruitCount = 0,
    _conn = nil,
    _lastAttack = 0,
    _lastSkill = 0,
    _lastFarm = 0,
    _lastEquip = 0,
    _lastQuest = 0,
    _lastKen = 0,
    _lastDodge = 0,
    _lastFruitInv = 0,
    _lastDialogue = 0,
    _lastIsland = 0,
    _lastRaid = 0,
    _lastNotify = 0,
    _lastTargetHP = nil,
}
function FeatureEngine:Start()
    self.Running = true
    Config.SniperHop = false -- never auto-hop fruit sniper
    if self._conn then return end
    -- reset farm anchor when starting a farm mode
    local hrp0 = Paw.GetHRP()
    if hrp0 then FarmAI.AnchorPos = hrp0.Position end

    self._conn = HubInstance:AddConnection(RunService.Heartbeat:Connect(function()
        if HubInstance.stopped or not self.Running then return end
        local cfg = Config
        local preferred = self._preferredPrimaryKey
        self._preferredPrimaryKey = nil
        Paw.NormalizePrimaryFeatures(cfg, preferred)
        local now = tick()
        local hrp = Paw.GetHRP()
        if not hrp then return end

        --[[
          ƯU TIÊN FEATURE (mỗi tick chỉ 1 combat pipeline):
          1. SafeMode (HP thấp)
          2. Fruit Sniper / AutoFarmFruit (đang đuổi fruit)
          3. AutoFarmLevel (QUEST→KILL→CLAIM) — exclusive
          4. Boss / Elite / Cake / Bone / Material / Sea
          5. Mastery / AutoAttack fallback
          6. Side tasks: Quest-only, Chest, Ken, Dodge, Store, Raid
          KHÔNG tự hop trừ khi user bật flag tương ứng (BossHop/EliteHop…).
        ]]

        if cfg.SpeedEnabled then
            Paw.ApplyWalkSpeed()
        end

        local farming = false
        local stepBusy = false
        local primaryKey, primaryName = Paw.ResolvePrimaryFeature(cfg)
        local previousPrimary = self._lastPrimaryKey
        if primaryKey ~= previousPrimary then
            -- If the old primary was toggled false before arbitration, it is no longer visible
            -- to NormalizePrimaryFeatures. Run its lifecycle cleanup explicitly.
            if previousPrimary and previousPrimary ~= primaryKey then
                pcall(RunPrimaryDisable, previousPrimary)
            end
            self._lastPrimaryKey = primaryKey
            if primaryKey and self._lastPrimaryToast ~= primaryKey then
                self._lastPrimaryToast = primaryKey
            elseif not primaryKey then
                self._lastPrimaryToast = nil
            end
        end
        local mode = "level"
        if primaryKey == "AutoBoss" then mode = "boss"
        elseif primaryKey == "AutoFarmMastery" then mode = "mastery"
        elseif primaryKey == "AutoFarmFruit" or primaryKey == "FruitSniper" then mode = "fruit"
        end

        -- SafeMode has absolute priority and must not allow any other movement pipeline
        -- to write CFrame in the same tick.
        if cfg.SafeMode then
            local hp = Paw.GetPlayerHP()
            if hp < 0.18 then
                if not SafeModeAI.active and now - (SafeModeAI.lastRetreat or 0) >= 3 then
                    SafeModeAI.lastRetreat = now
                    SafeModeAI.active = true
                    SafeModeAI.safePos = hrp.Position + Vector3.new(0, 20, 0)
                    -- SafeMode becomes the movement owner: release any mob locks first.
                    if HubInstance and HubInstance.RestoreBringState then
                        pcall(HubInstance.RestoreBringState)
                    end
                    if FarmAI then
                        FarmAI.CurrentTarget = nil
                        FarmAI.StuckSince = 0
                    end
                    pcall(function() hrp.CFrame = CFrame.new(SafeModeAI.safePos, SafeModeAI.safePos + hrp.CFrame.LookVector) end)
                elseif SafeModeAI.active and SafeModeAI.safePos then
                    pcall(function() hrp.CFrame = CFrame.new(SafeModeAI.safePos, SafeModeAI.safePos + hrp.CFrame.LookVector) end)
                end
                return
            elseif hp > 0.35 then
                SafeModeAI.active = false
                SafeModeAI.safePos = nil
                if FarmAI then
                    FarmAI.StuckSince = 0
                    FarmAI.LastPos = hrp.Position
                end
            end
        end

        -- Equip only for the selected primary combat pipeline. Side-task toggles should
        -- never force weapon swaps while another primary feature owns the tick.
        local needEquip = primaryKey ~= nil
        if needEquip and now - (self._lastEquip or 0) > (primaryKey == "AutoFarmMastery" and 0.9 or 2.0) then
            self._lastEquip = now
            pcall(Paw.EquipFarmWeapon, cfg)
        end

        -- Exactly ONE primary pipeline may act per heartbeat.
        if primaryKey == "AutoRaid" then
            local ok, busy = pcall(Paw.TryRaidTick, hrp, cfg, self)
            if ok and busy then stepBusy, farming = true, true end
        elseif primaryKey == "AutoFarmLevel" then
            local ok, res = pcall(Paw.TryLevelFarmTick, hrp, cfg, self)
            if ok and res then
                stepBusy, farming = true, true
            elseif not ok and now - (self._lastLFErr or 0) > 5 then
                self._lastLFErr = now
                warn("[PawZHub] LevelFarm:", res)
            end
        elseif primaryKey == "FruitSniper" or primaryKey == "AutoFarmFruit" then
            local ok, handling = pcall(Paw.TryFruitSniperTick, hrp, cfg, self)
            if ok and handling then
                stepBusy, farming = true, true
            elseif primaryKey == "AutoFarmFruit" then
                local farmCfg = Paw.ExpandFarmCfg(cfg, { minRange = 220, ownIsland = false })
                local target = Paw.SelectFarmTarget(farmCfg, "level")
                if target then
                    local root = Paw.GetRoot(target)
                    local hum = target:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health > 0 then
                        Paw.MoveToFarmSpot(hrp, target, root, farmCfg, Paw.UpdateStuck(hrp))
                        pcall(function() Paw.BringMobsToStack(hrp, farmCfg, target) end)
                        Paw.DoMeleeClick(cfg.FastAttack)
                        self.FarmCount = (self.FarmCount or 0) + 1
                        stepBusy, farming = true, true
                    end
                end
            end
        elseif primaryKey == "AutoBoss" then
            local ok, res = pcall(Paw.TryBossTick, hrp, cfg, self)
            if ok and res then stepBusy, farming = true, true end
        elseif primaryKey == "AutoEliteHunter" then
            local ok, res = pcall(Paw.TryEliteHunterTick, hrp, cfg, self)
            if ok and res then stepBusy, farming = true, true end
        elseif primaryKey == "AutoCakePrince" then
            local ok, res = pcall(Paw.TryCakeTick, hrp, cfg, self)
            if ok and res then stepBusy, farming = true, true end
        elseif primaryKey == "AutoBone" then
            local bone = Paw.FindEnemyByKeywords({ "skeleton", "zombie", "ghost", "bone", "reaper", "haunted" }, 2500)
            if bone and Paw.IsHostileMob(bone) then
                local root = Paw.GetRoot(bone)
                local hum = bone:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    stepBusy, farming = true, true
                    local farmCfg = Paw.ExpandFarmCfg(cfg, { minRange = 300, ownIsland = false })
                    Paw.MoveToFarmSpot(hrp, bone, root, farmCfg, false)
                    pcall(Paw.BringMobsToStack, hrp, farmCfg, bone)
                    Paw.AttackAOE(bone, cfg)
                    self.FarmCount = (self.FarmCount or 0) + 1
                end
            else
                local pos = Paw.FindIslandOrPartByKeys({ "haunted", "castle", "bone", "grave" })
                if pos and (hrp.Position - pos).Magnitude > 80 then
                    stepBusy = true
                    pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 12, 0)) end)
                end
            end
        elseif primaryKey == "AutoMaterial" then
            local ok, res = pcall(Paw.TryMaterialTick, hrp, cfg, self)
            if ok and res then stepBusy, farming = true, true end
        elseif primaryKey == "AutoSeaEvent" or primaryKey == "AutoMirage" or primaryKey == "AutoKitsune" then
            if now - (self._lastAdv or 0) > 0.15 then
                self._lastAdv = now
                local adv = Paw.TryAdvancedTarget(cfg)
                if adv then
                    stepBusy, farming = true, true
                    if typeof(adv) == "Vector3" then
                        if (hrp.Position - adv).Magnitude > 25 then
                            pcall(function() hrp.CFrame = CFrame.new(adv + Vector3.new(0, 10, 0)) end)
                        end
                    elseif typeof(adv) == "Instance" then
                        local root = Paw.GetRoot(adv)
                        local hum = adv:FindFirstChildOfClass("Humanoid")
                        if root and hum and hum.Health > 0 then
                            Paw.MoveToFarmSpot(hrp, adv, root, Paw.ExpandFarmCfg(cfg), false)
                            Paw.DoMeleeClick(true)
                            self.FarmCount = (self.FarmCount or 0) + 1
                        end
                    end
                end
            end
        elseif primaryKey == "AutoFarmMastery" or primaryKey == "AutoAttack" then
            if now - (self._lastFarm or 0) >= 0.1 then
                self._lastFarm = now
                local farmCfg = Paw.ExpandFarmCfg(cfg, {
                    minRange = primaryKey == "AutoFarmMastery" and 300 or 200,
                    ownIsland = cfg.OwnIslandOnly == true and primaryKey ~= "AutoFarmMastery" or false,
                })
                local target = Paw.SelectFarmTarget(farmCfg, mode)
                if FarmAI.CurrentTarget then
                    local hum = FarmAI.CurrentTarget:FindFirstChildOfClass("Humanoid")
                    local root = Paw.GetRoot(FarmAI.CurrentTarget)
                    if not hum or hum.Health <= 0 or not root or not FarmAI.CurrentTarget.Parent then
                        if self._lastTargetHP and self._lastTargetHP > 0 then
                            self.KillCount = (self.KillCount or 0) + 1
                        end
                        FarmAI.CurrentTarget = nil
                        self._lastTargetHP = nil
                    end
                end
                if target then
                    FarmAI.CurrentTarget = target
                    local root = Paw.GetRoot(target)
                    local hum = target:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health > 0 then
                        stepBusy, farming = true, true
                        self._lastTargetHP = hum.Health
                        Paw.MoveToFarmSpot(hrp, target, root, farmCfg, Paw.UpdateStuck(hrp))
                        pcall(function() Paw.BringMobsToStack(hrp, farmCfg, target) end)
                        self.FarmCount = (self.FarmCount or 0) + 1
                        local rate = Paw.GetAttackInterval(cfg)
                        if now - (self._lastAttack or 0) >= rate then
                            self._lastAttack = now
                            Paw.AttackAOE(target, cfg)
                        end
                        -- Skill đã nằm trong AttackAOE; chỉ burst thêm khi AutoSkill/Combo
                        local skillOn = cfg.AutoSkill or cfg.ComboMode
                        if skillOn and now - (self._lastSkill or 0) >= (cfg.ComboMode and 0.40 or 0.70) then
                            self._lastSkill = now
                            pcall(function() Paw.DoSkillBurst(cfg.ComboMode) end)
                        end
                        if cfg.AutoKen and now - (self._lastKen or 0) > 7 then
                            self._lastKen = now
                            task.spawn(function()
                                pcall(function()
                                    local vim = game:GetService("VirtualInputManager")
                                    if vim then
                                        vim:SendKeyEvent(true, Enum.KeyCode.J, false, game)
                                        task.wait(0.03)
                                        vim:SendKeyEvent(false, Enum.KeyCode.J, false, game)
                                    end
                                end)
                            end)
                        end
                    end
                else
                    FarmAI.CurrentTarget = nil
                    FarmAI.CacheAt = 0
                end
            end
        end

        -- Side-task scheduler: explicit handlers, independently throttled.
        -- Movement side-tasks never run while a primary pipeline owns the tick.
        local side = self._side or {}
        self._side = side
        local function due(key, interval)
            if now - (side[key] or 0) < interval then return false end
            side[key] = now
            return true
        end

        if cfg.AutoDodge and not primaryKey and due("dodge", 0.20) then
            pcall(Paw.TryAutoDodge)
        end
        if cfg.AutoKen and not primaryKey and due("ken", 1.0) then
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                if vim then
                    vim:SendKeyEvent(true, Enum.KeyCode.J, false, game)
                    task.wait(0.03)
                    vim:SendKeyEvent(false, Enum.KeyCode.J, false, game)
                end
            end)
        end
        if cfg.AutoSkill and not primaryKey and due("skill", 1.1) then
            pcall(function() task.spawn(function() Paw.DoSkillBurst(cfg.ComboMode) end) end)
        end
        if cfg.AutoObservation and due("observation", 1.5) then
            pcall(Paw.TryObservationHaki, cfg)
        end
        if cfg.AutoStats and due("stats", 2.0) then
            pcall(Paw.TryAutoStats)
        end
        if (cfg.AutoStoreFruit or cfg.AutoEatFruit) and due("fruitInv", 1.25) then
            pcall(Paw.TryStoreOrEatFruit, cfg)
        end
        if cfg.FruitNotify and due("fruitNotify", 2.0) then
            pcall(Paw.ScanFruitNotify)
        end
        if cfg.AutoDialogue and due("dialogue", 0.75) then
            pcall(Paw.TryAutoDialogue)
        end
        if cfg.AutoDetectSea and due("sea", 2.0) then
            pcall(Paw.UpdateCurrentSea, false)
        end

        if not stepBusy and due("movement", 0.9) then
            if cfg.AutoQuest then
                local ok, res = pcall(Paw.TryAutoQuest)
                if ok and res then stepBusy = true end
            elseif cfg.AutoChest then
                local ok, res = pcall(Paw.TryAutoChest, hrp, cfg)
                if ok and res then stepBusy = true end
            elseif cfg.AutoNextIsland then
                pcall(Paw.TryNextIsland)
                stepBusy = true
            end
        end

        -- Idle throttle: slow cache when nothing active
        if cfg.IdleThrottle and not farming and not cfg.AutoAttack then
            FarmAI.CacheTTL = 1.2
        else
            FarmAI.CacheTTL = 0.45
        end
    end))
end
function FeatureEngine:Stop()
    self.Running = false
    self._lastPrimaryKey = nil
    self._preferredPrimaryKey = nil
    if self._conn then
        pcall(function() self._conn:Disconnect() end)
        self._conn = nil
    end
    FarmAI.CurrentTarget = nil
    FarmAI.StuckSince = 0
    SafeModeAI.active = false
    SafeModeAI.safePos = nil

    -- Reset stateful feature machines so re-enabling a feature cannot resume a stale state.
    pcall(function()
        RaidAI.State = "IDLE"
        RaidAI.InRaid = false
        RaidAI.StateSince = 0
        RaidAI.LastStateChange = 0
        RaidAI.NoMobSince = 0
        RaidAI.ClearCount = 0
        RaidAI.LastJoin = 0
        RaidAI.LastNext = 0
        RaidAI.ActionAt = 0
    end)
    pcall(function()
        FruitSniperAI.State = "FIND"
        FruitSniperAI.StateSince = 0
        FruitSniperAI.TargetPart = nil
        FruitSniperAI.PickUntil = 0
        FruitSniperAI.StoreUntil = 0
        FruitSniperAI.PickedIds = {}
        FruitSniperAI.LastFound = 0
    end)
    pcall(function()
        EliteAI.Current = nil
        EliteAI.LastSeen = 0
        EliteAI.LastQuest = 0
        EliteAI.Cache = {}
        EliteAI.CacheUntil = 0
    end)
    pcall(function()
        BossAI.State = "FIND"
        BossAI.StateSince = 0
        BossAI.Current = nil
        BossAI.LastSeen = 0
    end)
    pcall(function()
        CakeAI.State = "FARM_DOUGH"
        CakeAI.StateSince = 0
        MaterialAI.State = "GOTO"
        MaterialAI.StateSince = 0
    end)
end
-- Central lifecycle gate for the Heartbeat feature engine.
-- IMPORTANT: only include features that are actually consumed by FeatureEngine:Start().
-- AntiAFK has its own Player.Idled/Heartbeat lifecycle and must NOT keep this engine alive.
function FeatureEngine:EnsureRunning()
    local cfg = Config
    Paw.NormalizePrimaryFeatures(cfg, self._preferredPrimaryKey)

    local any =
        -- Core farming / combat
        cfg.AutoFarmLevel or cfg.AutoFarmMastery or cfg.AutoFarmFruit
        or cfg.AutoAttack or cfg.AutoSkill or cfg.AutoKen or cfg.AutoDodge
        -- Modifier-only flags such as ComboMode/FastAttack do not start a primary pipeline by themselves.

        -- Quest / navigation / utility
        or cfg.AutoQuest or cfg.AutoDialogue or cfg.AutoNextIsland
        or cfg.AutoChest or cfg.AutoObservation or cfg.AutoStats
        or cfg.AutoStoreFruit or cfg.AutoEatFruit or cfg.FruitNotify

        -- Farming targets / events
        or cfg.AutoBoss or cfg.AutoEliteHunter or cfg.AutoCakePrince
        or cfg.AutoBone or cfg.AutoMaterial
        or cfg.AutoSeaEvent or cfg.AutoMirage or cfg.AutoKitsune
        or cfg.AutoRaid

        -- Engine-level movement/safety
        or cfg.SafeMode

        -- Fruit sniper is handled inside the same engine loop
        or cfg.FruitSniper

    if any then
        if not self.Running then
            self:Start()
        end
    elseif self.Running then
        -- Do not leave a Heartbeat connection alive after the last engine feature is disabled.
        self:Stop()
    end
end

-- reset island anchor when toggling Own Island
local _prevOwn = Config.OwnIslandOnly
HubInstance:AddConnection(RunService.Heartbeat:Connect(function()
    if HubInstance.stopped then return end
    if Config.OwnIslandOnly ~= _prevOwn then
        _prevOwn = Config.OwnIslandOnly
        local h = Paw.GetHRP()
        if h then FarmAI.AnchorPos = h.Position end
    end
end))

Paw.FeatureToggles = Paw.FeatureToggles or {}
function Paw.makeToggle(flag, onEnable, onDisable)
    local toggle = {}
    local function isPrimary()
        for _, item in ipairs(PRIMARY_FEATURES) do
            if item.key == flag then return true end
        end
        return false
    end
    local function stopInternal()
        if Config[flag] then Config[flag] = false end
        if isPrimary() then
            RunPrimaryDisable(flag) -- includes the registered onDisable exactly once
        elseif onDisable then
            pcall(onDisable)
        end
    end
    toggle.Toggle = function()
        if Config[flag] then
            stopInternal()
            if FeatureEngine and FeatureEngine._preferredPrimaryKey == flag then FeatureEngine._preferredPrimaryKey = nil end
        else
            Config[flag] = true
            if FeatureEngine and isPrimary() then FeatureEngine._preferredPrimaryKey = flag end
            if onEnable then pcall(onEnable) end
        end
        FeatureEngine:EnsureRunning()
    end
    toggle.Start = function()
        Config[flag] = true
        if FeatureEngine and isPrimary() then FeatureEngine._preferredPrimaryKey = flag end
        if onEnable then pcall(onEnable) end
        FeatureEngine:EnsureRunning()
    end
    toggle.Stop = function()
        stopInternal()
        if FeatureEngine and FeatureEngine._preferredPrimaryKey == flag then
            FeatureEngine._preferredPrimaryKey = nil
        end
        FeatureEngine:EnsureRunning()
    end
    Paw.FeatureToggles[flag] = toggle
    if onDisable and PrimaryLifecycle then
        Paw.RegisterPrimaryLifecycle(flag, onDisable)
    end
    return toggle
end

function Paw.SetPrimaryFeature(flag, enabled)
    if not Config[flag] and enabled then
        Config[flag] = true
        if FeatureEngine then FeatureEngine._preferredPrimaryKey = flag end
    elseif Config[flag] and not enabled then
        Config[flag] = false
        RunPrimaryDisable(flag)
        if FeatureEngine and FeatureEngine._preferredPrimaryKey == flag then
            FeatureEngine._preferredPrimaryKey = nil
        end
    else
        Config[flag] = enabled and true or false
        if enabled and FeatureEngine then FeatureEngine._preferredPrimaryKey = flag end
    end
    if FeatureEngine then FeatureEngine:EnsureRunning() end
end

function Paw.ReconcileRuntimeConfig()
    -- Hard reset runtime state first so loading false values cannot leave old
    -- connections/AI state alive. Config is then applied as the source of truth.
    pcall(function() if FeatureEngine then FeatureEngine:Stop() end end)
    pcall(function() if AntiAFK then AntiAFK:Stop() end end)
    pcall(function() if ServerHop then ServerHop:Stop() end end)
    pcall(function() if Paw.SetNoclip then Paw.SetNoclip(false) end end)
    pcall(function() if Paw.SetESP then Paw.SetESP(false) end end)
    pcall(function() if HubInstance.RestoreWalkSpeed then HubInstance.RestoreWalkSpeed() end end)

    local active = Paw.NormalizePrimaryFeatures(Config, nil)
    local toggle = active and Paw.FeatureToggles and Paw.FeatureToggles[active]
    if toggle then
        -- Gives custom primary features (notably Auto Farm Level) their full
        -- onEnable initialization after a config load.
        toggle.Start()
    else
        pcall(function() if FeatureEngine then FeatureEngine:EnsureRunning() end end)
    end

    if Config.AntiAFK then pcall(function() AntiAFK:Start() end) end
    if Config.AutoServerHop then pcall(function() ServerHop:Start() end) end
    if Config.SpeedEnabled then pcall(Paw.ApplyWalkSpeed) end
    if Config.Noclip then pcall(function() Paw.SetNoclip(true) end) end
    if Config.ESP then pcall(function() Paw.SetESP(true) end) end
    if FeatureEngine then FeatureEngine:EnsureRunning() end
end

local AutoFarmLevel = Paw.makeToggle("AutoFarmLevel", function()
    LevelFarmAI.State = "INIT"
    LevelFarmAI.StateSince = tick()
    LevelFarmAI.StatusText = "Starting…"
    LevelFarmAI.LastQuestTry = 0
    LevelFarmAI.LastClaimTry = 0
    LevelFarmAI.Target = nil
    LevelFarmAI.QuestGuideKey = nil
    LevelFarmAI.QuestProgress = 0
    LevelFarmAI.QuestGoal = 0
    LevelFarmAI.LastProgressAt = tick()
    LevelFarmAI.ClaimVerifyUntil = 0
    LevelFarmAI.ClaimRequestedAt = 0
    LevelFarmAI.ClaimBlockedUntil = 0
    LevelFarmAI.RecoveryLevel = 0
    LevelFarmAI.SearchStartedAt = 0
    LevelFarmAI.StallCount = 0
    FarmAI.CurrentTarget = nil
    LevelFarmAI._questGrace = nil
    FeatureEngine._savedLevelPrefs = FeatureEngine._savedLevelPrefs or {
        BringMobs = Config.BringMobs,
        FastAttack = Config.FastAttack,
        OwnIslandOnly = Config.OwnIslandOnly,
    }
    Config.BringMobs = FeatureEngine._savedLevelPrefs.BringMobs ~= false
    Config.FastAttack = true
    Config.OwnIslandOnly = false  -- farm level cần đi xa (Bandit/Jungle/...)
    Config.QuestByLevel = true
    local h = Paw.GetHRP()
    if h then FarmAI.AnchorPos = h.Position end
    pcall(function() Paw.EquipFarmWeapon(Config) end)
    -- TP ngay tới khu mob theo level
    local guide = Paw.GetLevelFarmGuide(Paw.GetPlayerLevel())
    if guide and h then
        local pos = guide.mobCF or guide.npcCF
        if pos then
            pcall(function() h.CFrame = pos * CFrame.new(0, 8, 6) end)
        end
    end
    Toast:Show("Auto Farm Level ON · hunting mobs", "ok")
end, function()
    LevelFarmAI.State = "INIT"
    LevelFarmAI.StateSince = 0
    LevelFarmAI.StatusText = "Idle"
    LevelFarmAI.Target = nil
    LevelFarmAI.QuestGuideKey = nil
    LevelFarmAI.QuestProgress = 0
    LevelFarmAI.QuestGoal = 0
    LevelFarmAI.LastProgressAt = 0
    LevelFarmAI.RecoveryLevel = 0
    LevelFarmAI.SearchStartedAt = 0
    LevelFarmAI.StallCount = 0
    FarmAI.CurrentTarget = nil
    if FeatureEngine._savedLevelPrefs then
        Config.BringMobs = FeatureEngine._savedLevelPrefs.BringMobs
        Config.FastAttack = FeatureEngine._savedLevelPrefs.FastAttack
        if FeatureEngine._savedLevelPrefs.OwnIslandOnly ~= nil then
            Config.OwnIslandOnly = FeatureEngine._savedLevelPrefs.OwnIslandOnly
        end
        FeatureEngine._savedLevelPrefs = nil
    end
    if HubInstance.RestoreBringState and Config.BringMobs == false then
        pcall(HubInstance.RestoreBringState)
    end
end)
local AutoFarmMastery = Paw.makeToggle("AutoFarmMastery")
local AutoFarmFruit = Paw.makeToggle("AutoFarmFruit")
local AutoAttack = Paw.makeToggle("AutoAttack")
local AutoSkill = Paw.makeToggle("AutoSkill")
local AutoKen = Paw.makeToggle("AutoKen", function()
    -- try equip Buso/Ken style ability if present
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim then
            vim:SendKeyEvent(true, Enum.KeyCode.J, false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, Enum.KeyCode.J, false, game)
        end
    end)
end)
local AutoDodge = Paw.makeToggle("AutoDodge")
local AutoStoreFruit = Paw.makeToggle("AutoStoreFruit")
local AutoEatFruit = Paw.makeToggle("AutoEatFruit")
local AutoQuest = Paw.makeToggle("AutoQuest")
local AutoRaid = Paw.makeToggle("AutoRaid")
local AutoBoss = Paw.makeToggle("AutoBoss")

-- Character respawn hooks
HubInstance:AddConnection(Player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Config.SpeedEnabled then Paw.ApplyWalkSpeed() end
    if Config.Noclip then Paw.SetNoclip(true) end
    if Config.ESP then Paw.SetESP(true) end
    FeatureEngine:EnsureRunning()
end))

HubInstance.SetNoclip = Paw.SetNoclip
HubInstance.SetESP = Paw.SetESP
HubInstance.ApplyWalkSpeed = Paw.ApplyWalkSpeed

-- ========== UI HELPERS ==========
function Paw.CreateElement(class, props)
    props = props or {}
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            pcall(function() obj[k] = v end)
        end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

function Paw.Tween(obj, props, duration, style)
    duration = duration or 0.3
    style = style or Enum.EasingStyle.Quad
    return TweenService:Create(obj, TweenInfo.new(duration, style, Enum.EasingDirection.Out), props):Play()
end

function Paw.AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = parent
    return corner
end

function Paw.AddStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.6
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- ========== CREATE PREMIUM GUI ==========
function Paw.GetUIParent()
    local parent = CoreGui
    pcall(function()
        if gethui then parent = gethui() end
    end)
    return parent
end

function Paw.ProtectGui(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
    pcall(function()
        if protect_gui then protect_gui(gui) end
    end)
    pcall(function()
        if fluxus and fluxus.protect_gui then fluxus.protect_gui(gui) end
    end)
end

function Paw.CreateGUI()
    local uiParent = Paw.GetUIParent()
    pcall(function()
        local old = uiParent:FindFirstChild("PawZHub")
        if old then old:Destroy() end
    end)
    pcall(function()
        if CoreGui:FindFirstChild("PawZHub") then CoreGui.PawZHub:Destroy() end
    end)
    pcall(function()
        local pg = Player:FindFirstChild("PlayerGui")
        if pg and pg:FindFirstChild("PawZHub") then pg.PawZHub:Destroy() end
    end)

    local ScreenGui = Paw.CreateElement("ScreenGui", {
        Name = "PawZHub",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = uiParent
    })
    Paw.ProtectGui(ScreenGui)
    pcall(function() ScreenGui:SetAttribute("PawZHubScript", true) end)
    HubInstance.ScreenGui = ScreenGui

    local WIN_W, WIN_H = 560, 580
    local Main = Paw.CreateElement("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.bg,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = ScreenGui
    })
    Paw.AddCorner(Main, 16)
    Paw.AddStroke(Main, Theme.border, 1, 0.35)

    local veil = Paw.CreateElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.bg,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = Main
    })
    Paw.AddCorner(veil, 16)

    -- HEADER
    local Header = Paw.CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = Main
    })
    local Logo = Paw.CreateElement("Frame", {
        Size = UDim2.new(0, 34, 0, 34),
        Position = UDim2.new(0, 14, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.card,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Header
    })
    Paw.AddCorner(Logo, 10)
    Paw.AddStroke(Logo, Theme.accent1, 1.2, 0.35)

    -- Paw logo (embedded pawzlogo.png via MaterializeLogoAsset)
    local LogoImg = Paw.CreateElement("ImageLabel", {
        Name = "LogoImage",
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "",
        ScaleType = Enum.ScaleType.Fit,
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        Parent = Logo
    })
    task.spawn(function()
        local asset = ""
        pcall(function() asset = Paw.MaterializeLogoAsset() or "" end)
        if type(asset) == "string" and asset ~= "" then
            LogoImg.Image = asset
            return
        end
        -- Fallback: mini drawn paw
        LogoImg.Visible = false
        local function dot(px, py, w, h)
            local f = Paw.CreateElement("Frame", {
                Size = UDim2.new(0, w, 0, h),
                Position = UDim2.new(0, px, 0, py),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Theme.accent1,
                BorderSizePixel = 0,
                Parent = Logo
            })
            Paw.AddCorner(f, 99)
            return f
        end
        dot(9, 10, 7, 9)
        dot(15, 7, 8, 10)
        dot(22, 7, 8, 10)
        dot(28, 10, 7, 9)
        local pad = Paw.CreateElement("Frame", {
            Size = UDim2.new(0, 16, 0, 13),
            Position = UDim2.new(0.5, 0, 0, 24),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.accent1,
            BorderSizePixel = 0,
            Parent = Logo
        })
        Paw.AddCorner(pad, 6)
    end)
    Paw.CreateElement("TextLabel", {
        Position = UDim2.new(0, 58, 0, 8),
        Size = UDim2.new(0, 260, 0, 20),
        BackgroundTransparency = 1,
        Text = "PawZHub",
        TextColor3 = Theme.text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header
    })
    Paw.CreateElement("TextLabel", {
        Position = UDim2.new(0, 58, 0, 28),
        Size = UDim2.new(0, 260, 0, 14),
        BackgroundTransparency = 1,
        Text = "Blox Fruits  ·  v" .. SCRIPT_VERSION,
        TextColor3 = Theme.textMuted,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header
    })

    local function HBtn(x, txt, bg, cb)
        local b = Paw.CreateElement("TextButton", {
            Size = UDim2.new(0, 32, 0, 32),
            Position = UDim2.new(1, x, 0, 10),
            BackgroundColor3 = bg,
            BackgroundTransparency = 0.1,
            Text = txt,
            TextColor3 = Theme.text,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            Parent = Header
        })
        Paw.AddCorner(b, 9)
        Paw.AddStroke(b, Theme.border, 1, 0.4)
        b.MouseButton1Click:Connect(cb)
        return b
    end
    HBtn(-46, "×", Theme.danger, function()
        HubInstance:ForceAllFeaturesOff(Config)
        pcall(function() if FeatureEngine then FeatureEngine:Stop() end end)
        Paw.Tween(Main, {Size = UDim2.new(0, 0, 0, 0)}, 0.22, Enum.EasingStyle.Back)
        task.wait(0.25)
        ScreenGui:Destroy()
    end)
    local uiMinimized = false
    local fullSize = Main.Size
    local MinBtn = HBtn(-86, "−", Theme.card, function() end) -- wired after UI built

    -- TAB BAR (scrollable for many tabs)
    local TabBar = Paw.CreateElement("ScrollingFrame", {
        Position = UDim2.new(0, 12, 0, 56),
        Size = UDim2.new(1, -24, 0, 34),
        BackgroundColor3 = Theme.card,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 2,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        Parent = Main
    })
    Paw.AddCorner(TabBar, 10)
    Paw.AddStroke(TabBar, Theme.border, 1, 0.45)
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = TabBar
    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 4)
    tabPad.PaddingRight = UDim.new(0, 4)
    tabPad.PaddingTop = UDim.new(0, 4)
    tabPad.Parent = TabBar

    local Pages = {}
    local TabBtns = {}
    local currentTab = "Home"

    local function ShowTab(name)
        currentTab = name
        for n, page in pairs(Pages) do
            page.Visible = (n == name)
            if n == name then
                page.CanvasPosition = Vector2.new(0, 0)
            end
        end
        for n, btn in pairs(TabBtns) do
            if n == name then
                TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                    BackgroundColor3 = Theme.accent1,
                    BackgroundTransparency = 0
                }):Play()
                btn.TextColor3 = Color3.fromRGB(0, 0, 0)
            else
                TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                    BackgroundColor3 = Theme.bgDark,
                    BackgroundTransparency = 0
                }):Play()
                btn.TextColor3 = Theme.textMuted
            end
        end
    end

    local tabNames = {"Home", "Farm", "Sea", "Raid", "Quest", "ESP", "Fruit", "TP"}
    local tabKeys = {
        Home = "tab_home", Farm = "tab_farm", Sea = "tab_sea",
        Raid = "tab_raid", Quest = "tab_quest", ESP = "tab_esp",
        Fruit = "tab_fruit", TP = "tab_tp"
    }

    for _, name in ipairs(tabNames) do
        local btn = Paw.CreateElement("TextButton", {
            Size = UDim2.new(0, 52, 0, 26),
            BackgroundColor3 = Theme.bgDark,
            BackgroundTransparency = 0.2,
            Text = (function()
                local k = tabKeys[name]
                local t = Paw.T(k)
                if t == k then return name end -- fallback: Home, Farm, Sea...
                return t
            end)(),
            TextColor3 = Theme.textSub,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            Parent = TabBar
        })
        Paw.AddCorner(btn, 8)
        btn.MouseEnter:Connect(function()
            if currentTab ~= name then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.cardHover}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if currentTab ~= name then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.bgDark}):Play()
            end
        end)
        btn.MouseButton1Click:Connect(function() ShowTab(name) end)
        TabBtns[name] = btn
        Paw.BindLang(btn, tabKeys[name])

        local page = Paw.CreateElement("ScrollingFrame", {
            Name = name .. "Page",
            Position = UDim2.new(0, 14, 0, 98),
            Size = UDim2.new(1, -28, 0, 420),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 2,
            ClipsDescendants = true,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.accent1,
            ScrollBarImageTransparency = 0.4,
            CanvasSize = UDim2.new(0, 0, 0, 600),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ElasticBehavior = Enum.ElasticBehavior.Never,
            Parent = Main
        })
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 4)
        pad.PaddingRight = UDim.new(0, 6)
        pad.PaddingTop = UDim.new(0, 2)
        pad.PaddingBottom = UDim.new(0, 24)
        pad.Parent = page
        Pages[name] = page
    end

    -- Help popup
    local helpPopup = nil
    local function HideFeatureHelp()
        if helpPopup and helpPopup.Parent then helpPopup:Destroy() end
        helpPopup = nil
    end

    local function ShowFeatureHelp(displayTitle, helpKey)
        HideFeatureHelp()
        local body = Paw.GetFeatureHelp(helpKey or displayTitle) or Paw.T("help_missing")
        local overlay = Paw.CreateElement("TextButton", {
            Name = "HelpOverlay",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.45,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 80,
            Parent = Main
        })
        Paw.AddCorner(overlay, 16)
        local card = Paw.CreateElement("Frame", {
            Size = UDim2.new(0, 320, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.card,
            BorderSizePixel = 0,
            ZIndex = 81,
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = overlay
        })
        Paw.AddCorner(card, 14)
        Paw.AddStroke(card, Theme.border, 1, 0.3)
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 16)
        pad.PaddingBottom = UDim.new(0, 16)
        pad.PaddingLeft = UDim.new(0, 16)
        pad.PaddingRight = UDim.new(0, 16)
        pad.Parent = card
        local lay = Instance.new("UIListLayout")
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Padding = UDim.new(0, 10)
        lay.Parent = card
        Paw.CreateElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Text = displayTitle,
            TextColor3 = Theme.text,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 82,
            LayoutOrder = 1,
            Parent = card
        })
        Paw.CreateElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = body,
            TextColor3 = Theme.textSub,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 82,
            LayoutOrder = 2,
            Parent = card
        })
        Paw.CreateElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = UserInputService.TouchEnabled and Paw.T("help_footer_mobile") or Paw.T("help_footer_pc"),
            TextColor3 = Theme.textMuted,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 82,
            LayoutOrder = 3,
            Parent = card
        })
        overlay.MouseButton1Click:Connect(HideFeatureHelp)
        helpPopup = overlay
    end

    local function MakeToggle(parent, y, titleKey, helpKey, getState, onToggle, accent)
        accent = accent or Theme.accent1
        helpKey = helpKey or titleKey
        local btn = Paw.CreateElement("TextButton", {
            Position = UDim2.new(0, 0, 0, y),
            Size = UDim2.new(1, -6, 0, 40),
            BackgroundColor3 = Theme.card,
            BackgroundTransparency = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = parent
        })
        Paw.AddCorner(btn, 10)
        local stroke = Paw.AddStroke(btn, Theme.border, 1, 0.45)

        local titleLab = Paw.CreateElement("TextLabel", {
            Position = UDim2.new(0, 14, 0, 0),
            Size = UDim2.new(1, -66, 1, 0),
            BackgroundTransparency = 1,
            Text = (function()
                local t = Paw.T(titleKey)
                if t == titleKey and helpKey and helpKey ~= titleKey then return helpKey end
                return t
            end)(),
            TextColor3 = Theme.text,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = btn
        })
        Paw.BindLang(titleLab, titleKey)

        local pill = Paw.CreateElement("Frame", {
            Size = UDim2.new(0, 40, 0, 22),
            Position = UDim2.new(1, -54, 0.5, -11),
            BackgroundColor3 = Theme.bgDark,
            BorderSizePixel = 0,
            Parent = btn
        })
        Paw.AddCorner(pill, 11)
        local knob = Paw.CreateElement("Frame", {
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = Color3.fromRGB(200, 200, 200),
            BorderSizePixel = 0,
            Parent = pill
        })
        Paw.AddCorner(knob, 8)

        local function refresh()
            local on = getState()
            if on then
                stroke.Color = accent
                stroke.Transparency = 0.25
                TweenService:Create(pill, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = accent
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {
                    Position = UDim2.new(1, -19, 0.5, -8),
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                }):Play()
            else
                stroke.Color = Theme.border
                stroke.Transparency = 0.5
                TweenService:Create(pill, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = Theme.bgDark
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {
                    Position = UDim2.new(0, 3, 0.5, -8),
                    BackgroundColor3 = Color3.fromRGB(140, 140, 140)
                }):Play()
            end
        end

        local pressToken = 0
        local longPressed = false

        btn.MouseButton1Click:Connect(function()
            if longPressed then longPressed = false return end
            TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Theme.cardHover}):Play()
            task.delay(0.08, function()
                if btn and btn.Parent then
                    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.card}):Play()
                end
            end)
            onToggle()
            refresh()
        end)

        btn.MouseButton2Click:Connect(function()
            ShowFeatureHelp(Paw.T(titleKey), helpKey)
        end)

        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                longPressed = false
                pressToken = pressToken + 1
                local my = pressToken
                task.delay(0.5, function()
                    if my == pressToken then
                        longPressed = true
                        ShowFeatureHelp(Paw.T(titleKey), helpKey)
                    end
                end)
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                pressToken = pressToken + 1
            end
        end)

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.cardHover}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.25}):Play()
        end)
        btn.MouseLeave:Connect(function()
            pressToken = pressToken + 1
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.card}):Play()
            refresh()
        end)
        refresh()
        return refresh
    end

    local function Section(parent, titleKey, y)
        local lab = Paw.CreateElement("TextLabel", {
            Position = UDim2.new(0, 0, 0, y),
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = Paw.T(titleKey),
            TextColor3 = Theme.textMuted,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = parent
        })
        Paw.BindLang(lab, titleKey)
    end


    local function NumRow(parent, yy, label, getV, setV, step, minV, maxV, fmt)
        if not parent then return end
        local card = Paw.CreateElement("Frame", {
            Position = UDim2.new(0, 0, 0, yy),
            Size = UDim2.new(1, -6, 0, 36),
            BackgroundColor3 = Theme.card,
            BorderSizePixel = 0,
            Parent = parent
        })
        Paw.AddCorner(card, 10)
        pcall(function() Paw.AddStroke(card, Theme.border, 1, 0.4) end)
        local lab = Paw.CreateElement("TextLabel", {
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0.55, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = tostring(label) .. ": " .. string.format(fmt or "%s", getV()),
            TextColor3 = Theme.text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = card
        })
        local function paint()
            pcall(function()
                lab.Text = tostring(label) .. ": " .. string.format(fmt or "%s", getV())
            end)
        end
        local function nb(txt, x, delta)
            local b = Paw.CreateElement("TextButton", {
                Position = UDim2.new(1, x, 0.5, -12),
                Size = UDim2.new(0, 28, 0, 24),
                BackgroundColor3 = Theme.bgDark,
                Text = txt,
                TextColor3 = Theme.text,
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
                Parent = card
            })
            Paw.AddCorner(b, 6)
            b.MouseButton1Click:Connect(function()
                pcall(function()
                    setV(math.clamp(getV() + delta, minV, maxV))
                    paint()
                end)
            end)
        end
        nb("−", -64, -step)
        nb("+", -32, step)
    end

    -- ========== TAB: HOME ==========
    do
        local p = Pages.Home
        local startTime = tick()

        local function DetectExecutor()
            local name = "Unknown"
            pcall(function()
                if identifyexecutor then name = tostring(identifyexecutor())
                elseif getexecutorname then name = tostring(getexecutorname())
                elseif syn and syn.protect_gui then name = "Synapse"
                elseif fluxus then name = "Fluxus"
                elseif KRNL_LOADED then name = "Krnl"
                end
            end)
            if name == "Unknown" or name == "" or name == "nil" then
                name = "Unknown / Local"
            end
            return name
        end
        local executorName = DetectExecutor()

        local function fmtTime(sec)
            sec = math.floor(sec)
            local h = math.floor(sec / 3600)
            local m = math.floor((sec % 3600) / 60)
            local s = sec % 60
            if h > 0 then return string.format("%dh %02dm", h, m) end
            return string.format("%dm %02ds", m, s)
        end

        local function fmtNum(n)
            n = tonumber(n) or 0
            if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
            if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
            if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
            return tostring(math.floor(n))
        end

        -- Read Blox Fruits player stats
        local function ReadPlayerStats()
            local level, beli, frag, fruit = "—", "—", "—", "—"
            pcall(function()
                local data = Player:FindFirstChild("Data")
                    or Player:FindFirstChild("PlayerData")
                    or Player:FindFirstChild("leaderstats")
                local function dig(parent, names)
                    if not parent then return nil end
                    for _, n in ipairs(names) do
                        local v = parent:FindFirstChild(n)
                        if v then
                            if typeof(v.Value) == "number" or typeof(v.Value) == "string" then
                                return v.Value
                            end
                        end
                    end
                    return nil
                end
                if data then
                    local lv = dig(data, { "Level", "level", "Lvl" })
                    local be = dig(data, { "Beli", "beli", "Money", "Cash" })
                    local fr = dig(data, { "Fragments", "Fragment", "fragments", "RaceFragments" })
                    if lv ~= nil then level = tostring(lv) end
                    if be ~= nil then beli = fmtNum(be) end
                    if fr ~= nil then frag = fmtNum(fr) end
                    local df = dig(data, { "DevilFruit", "Fruit", "CurrentFruit", "DF" })
                    if df and tostring(df) ~= "" and tostring(df) ~= "None" and tostring(df) ~= "nil" then
                        fruit = tostring(df)
                    end
                end
                -- held tool as fruit fallback
                local char = Player.Character
                if char then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        local n = tool.Name
                        local ln = string.lower(n)
                        if ln:find("fruit") or ln:find("buzo") or ln:find("-") then
                            fruit = n
                        end
                    end
                end
                -- backpack fruit
                if fruit == "—" then
                    local bp = Player:FindFirstChild("Backpack")
                    if bp then
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") then
                                local ln = string.lower(t.Name)
                                if ln:find("fruit") then
                                    fruit = t.Name
                                    break
                                end
                            end
                        end
                    end
                end
            end)
            if #fruit > 18 then fruit = fruit:sub(1, 16) .. "…" end
            return level, beli, frag, fruit
        end

        -- Profile card
        local profileCard = Paw.CreateElement("Frame", {
            Position = UDim2.new(0, 0, 0, 4),
            Size = UDim2.new(1, -6, 0, 100),
            BackgroundColor3 = Theme.card,
            BorderSizePixel = 0,
            Parent = p
        })
        Paw.AddCorner(profileCard, 12)
        Paw.AddStroke(profileCard, Theme.border, 1, 0.35)

        local avatar = Paw.CreateElement("ImageLabel", {
            Position = UDim2.new(0, 12, 0, 14),
            Size = UDim2.new(0, 60, 0, 60),
            BackgroundColor3 = Theme.bgDark,
            BorderSizePixel = 0,
            Image = "",
            ScaleType = Enum.ScaleType.Crop,
            Parent = profileCard
        })
        Paw.AddCorner(avatar, 30)
        Paw.AddStroke(avatar, Theme.accent1, 1.5, 0.35)
        pcall(function()
            avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(Player.UserId) .. "&w=150&h=150"
        end)

        Paw.CreateElement("TextLabel", {
            Position = UDim2.new(0, 84, 0, 10),
            Size = UDim2.new(1, -100, 0, 20),
            BackgroundTransparency = 1,
            Text = Player.DisplayName or Player.Name,
            TextColor3 = Theme.text,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = profileCard
        })
        Paw.CreateElement("TextLabel", {
            Position = UDim2.new(0, 84, 0, 30),
            Size = UDim2.new(1, -100, 0, 14),
            BackgroundTransparency = 1,
            Text = "@" .. Player.Name .. "  ·  ID " .. tostring(Player.UserId),
            TextColor3 = Theme.textSub,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = profileCard
        })
        local statusLine = Paw.CreateElement("TextLabel", {
            Position = UDim2.new(0, 84, 0, 48),
            Size = UDim2.new(1, -100, 0, 16),
            BackgroundTransparency = 1,
            Text = "Level —  ·  Beli —  ·  Fragments —",
            TextColor3 = Theme.accent1,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = profileCard
        })
        local fruitLine = Paw.CreateElement("TextLabel", {
            Position = UDim2.new(0, 84, 0, 66),
            Size = UDim2.new(1, -100, 0, 16),
            BackgroundTransparency = 1,
            Text = "Fruit: —",
            TextColor3 = Theme.textSub,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = profileCard
        })

        -- Engine status
        Section(p, "status", 114)
        local card = Paw.CreateElement("Frame", {
            Position = UDim2.new(0, 0, 0, 132),
            Size = UDim2.new(1, -6, 0, 52),
            BackgroundColor3 = Theme.card,
            BorderSizePixel = 0,
            Parent = p
        })
        Paw.AddCorner(card, 10)
        Paw.AddStroke(card, Theme.border, 1, 0.4)
        local dot = Paw.CreateElement("Frame", {
            Size = UDim2.new(0, 8, 0, 8),
            Position = UDim2.new(0, 14, 0, 14),
            BackgroundColor3 = Theme.textMuted,
            BorderSizePixel = 0,
            Parent = card
        })
        Paw.AddCorner(dot, 4)
        local st = Paw.CreateElement("TextLabel", {
            Position = UDim2.new(0, 30, 0, 8),
            Size = UDim2.new(1, -46, 0, 16),
            BackgroundTransparency = 1,
            Text = Paw.T("idle"),
            TextColor3 = Theme.text,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card
        })
        local sub = Paw.CreateElement("TextLabel", {
            Position = UDim2.new(0, 14, 0, 28),
            Size = UDim2.new(1, -28, 0, 16),
            BackgroundTransparency = 1,
            Text = "Farm 0 · Kill 0 · Fruit 0",
            TextColor3 = Theme.textSub,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card
        })

        -- Live stats: Uptime · FPS · Ping · Server · Map
        Section(p, "info", 194)
        local infoCard = Paw.CreateElement("Frame", {
            Position = UDim2.new(0, 0, 0, 212),
            Size = UDim2.new(1, -6, 0, 126),
            BackgroundColor3 = Theme.card,
            BorderSizePixel = 0,
            Parent = p
        })
        Paw.AddCorner(infoCard, 10)
        Paw.AddStroke(infoCard, Theme.border, 1, 0.4)
        local infoLabel = Paw.CreateElement("TextLabel", {
            Position = UDim2.new(0, 14, 0, 10),
            Size = UDim2.new(1, -28, 1, -20),
            BackgroundTransparency = 1,
            Text = "Loading...",
            TextColor3 = Theme.textSub,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Parent = infoCard
        })

        -- Home = info only (no Start Farm / quick action buttons)

        local fpsAcc, fpsFrames, fpsVal = 0, 0, 0
        HubInstance:AddConnection(RunService.RenderStepped:Connect(function(dt)
            if HubInstance.stopped then return end
            fpsAcc = fpsAcc + dt
            fpsFrames = fpsFrames + 1
            if fpsAcc >= 0.5 then
                fpsVal = math.floor(fpsFrames / fpsAcc + 0.5)
                fpsAcc, fpsFrames = 0, 0
            end
        end))

        local lastUi = 0
        HubInstance:AddConnection(RunService.Heartbeat:Connect(function()
            if HubInstance.stopped then return end
            local now = tick()
            if now - lastUi < 0.6 then return end
            lastUi = now

            local any = Config.AutoFarmLevel or Config.AutoFarmMastery or Config.AutoFarmFruit
                or Config.AutoAttack or Config.AutoSkill or Config.AutoKen
                or Config.AutoQuest or Config.AutoRaid or Config.AutoBoss
            dot.BackgroundColor3 = any and Theme.success or Theme.textMuted
            st.Text = any and Paw.T("running") or Paw.T("idle")
            sub.Text = string.format("Farm %d · Kill %d · Fruit %d",
                FeatureEngine.FarmCount or 0,
                FeatureEngine.KillCount or 0,
                FeatureEngine.FruitCount or 0)

            local level, beli, frag, fruit = ReadPlayerStats()
            statusLine.Text = "Level " .. level .. "  ·  Beli " .. beli .. "  ·  Fragments " .. frag
            fruitLine.Text = "Fruit: " .. fruit

            local ping = 0
            pcall(function() ping = math.floor(Player:GetNetworkPing() * 1000 + 0.5) end)
            local playersN = #Players:GetPlayers()
            local maxP = Players.MaxPlayers or "?"
            local eng = FeatureEngine.Running and "ON" or "OFF"

            local ws = World.Stats or {}
            local mapLine = World.Scanned
                and string.format("Map        E%d · I%d · Q%d · R%d",
                    ws.enemies or 0, ws.islands or 0, ws.quests or 0, ws.remotes or 0)
                or "Map        scanning..."
            local g = Paw.GetLevelFarmGuide(level)
            local guideKeys = g and table.concat(g.keys, "/") or "-"
            local seaLine = string.format("Sea %s · Guide %s", tostring(Config.CurrentSea or "?"), guideKeys)
            infoLabel.Text = table.concat({
                "Uptime     " .. fmtTime(now - startTime),
                "FPS        " .. tostring(fpsVal) .. "   ·   Ping " .. ping .. " ms",
                "Server     " .. playersN .. " / " .. tostring(maxP) .. " players",
                mapLine,
                seaLine,
                "Engine     " .. eng .. "   ·   " .. executorName,
                "Script     PawZHub v" .. SCRIPT_VERSION,
            }, "\n")
        end))

        -- Website (Home = info only)
        local webBtn = Paw.CreateElement("TextButton", {
            Position = UDim2.new(0, 0, 0, 350),
            Size = UDim2.new(1, -6, 0, 32),
            BackgroundColor3 = Theme.card,
            BorderSizePixel = 0,
            Text = "  Website  ·  getpawzhub.vercel.app",
            TextColor3 = Theme.accent1,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            Parent = p
        })
        Paw.AddCorner(webBtn, 10)
        Paw.AddStroke(webBtn, Theme.border, 1, 0.4)
        webBtn.MouseButton1Click:Connect(function()
            local url = WEBSITE_URL
            local ok = false
            pcall(function() if setclipboard then setclipboard(url); ok = true end end)
            pcall(function() if toclipboard then toclipboard(url); ok = true end end)
            Toast:Show(ok and "Website copied to clipboard" or url, "ok")
        end)

        Section(p, "features", 396)
        MakeToggle(p, 414, "anti_afk", "Anti AFK", function() return Config.AntiAFK end, function()
            Config.AntiAFK = not Config.AntiAFK
            if Config.AntiAFK then AntiAFK:Start() else AntiAFK:Stop() end
        end)
        MakeToggle(p, 462, "server_hop", "Server Hop", function() return Config.AutoServerHop end, function() ServerHop:Toggle() end)
        -- Speed Boost removed from Home (info-only tab)
        Paw.CreateElement("Frame", {
            Position = UDim2.new(0, 0, 0, 520),
            Size = UDim2.new(1, 0, 0, 12),
            BackgroundTransparency = 1,
            Parent = p
        })
    end

    -- ========== TAB: FARM ==========
    do
        local p = Pages.Farm
        local y = 0

        -- 1) Modes
        Section(p, "farming", y); y = y + 18
        MakeToggle(p, y, "auto_farm_level", "Auto Farm Level", function() return Config.AutoFarmLevel end, function() AutoFarmLevel:Toggle() end); y = y + 48
        MakeToggle(p, y, "auto_farm_mastery", "Auto Farm Mastery", function() return Config.AutoFarmMastery end, function() AutoFarmMastery:Toggle() end); y = y + 48
        MakeToggle(p, y, "auto_farm_fruit", "Auto Farm Fruit", function() return Config.AutoFarmFruit end, function() AutoFarmFruit:Toggle() end); y = y + 48
        MakeToggle(p, y, "auto_boss", "Auto Boss", function() return Config.AutoBoss end, function() AutoBoss:Toggle() end); y = y + 48
        MakeToggle(p, y, "auto_bone", "Auto Farm Bone", function() return Config.AutoBone end, function()
            Paw.SetPrimaryFeature("AutoBone", not Config.AutoBone)
            Toast:Show(Config.AutoBone and "Bone Farm ON" or "OFF", "ok")
        end); y = y + 48
        MakeToggle(p, y, "auto_attack", "Auto Attack", function() return Config.AutoAttack end, function() AutoAttack:Toggle() end); y = y + 48
        MakeToggle(p, y, "auto_skill", "Auto Skill", function() return Config.AutoSkill end, function() AutoSkill:Toggle() end); y = y + 56

        -- 2) Bring / Magnet
        Section(p, "bring_section", y); y = y + 18
        MakeToggle(p, y, "bring_mobs", "Bring Mobs", function() return Config.BringMobs == true end, function()
            Config.BringMobs = not Config.BringMobs
            if not Config.BringMobs and HubInstance.RestoreBringState then
                pcall(HubInstance.RestoreBringState)
            end
            Toast:Show(Config.BringMobs and "Bring Mobs ON" or "Bring Mobs OFF", "ok")
        end); y = y + 48
        MakeToggle(p, y, "bring_lock", "Bring Lock", function() return Config.BringLock ~= false end, function()
            Config.BringLock = not (Config.BringLock ~= false)
        end); y = y + 48
        NumRow(p, y, "Bring Range", function() return Config.BringRange or 120 end, function(v) Config.BringRange = math.floor(v) end, 10, 40, 300, "%d"); y = y + 40
        NumRow(p, y, "Bring Max", function() return Config.BringMax or 8 end, function(v) Config.BringMax = math.floor(v) end, 1, 1, 20, "%d"); y = y + 48

        -- 3) Targeting options
        Section(p, "target_opts", y); y = y + 18
        MakeToggle(p, y, "quest_by_level", "Quest By Level", function() return Config.QuestByLevel ~= false end, function()
            Config.QuestByLevel = not (Config.QuestByLevel ~= false)
            local g = Paw.GetLevelFarmGuide(Paw.GetPlayerLevel())
            if g then Toast:Show("Level guide: " .. table.concat(g.keys, "/"), "ok") end
        end); y = y + 48
        MakeToggle(p, y, "own_island", "Own Island Only", function() return Config.OwnIslandOnly ~= false end, function()
            Config.OwnIslandOnly = not (Config.OwnIslandOnly ~= false)
            local h = Paw.GetHRP()
            if h then FarmAI.AnchorPos = h.Position end
        end); y = y + 48
        MakeToggle(p, y, "prefer_nearest", "Prefer Nearest", function() return Config.PreferNearest ~= false end, function()
            Config.PreferNearest = not (Config.PreferNearest ~= false)
        end); y = y + 48
        MakeToggle(p, y, "prefer_xp", "Prefer Highest XP", function() return Config.PreferHighestXP == true end, function()
            Config.PreferHighestXP = not Config.PreferHighestXP
        end); y = y + 56

        -- 4) Weapon
        do
            local weapons = { "Melee", "Sword", "Gun", "Fruit" }
            local card = Paw.CreateElement("Frame", {
                Position = UDim2.new(0, 0, 0, y),
                Size = UDim2.new(1, -6, 0, 70),
                BackgroundColor3 = Theme.card,
                BorderSizePixel = 0,
                Parent = p
            })
            Paw.AddCorner(card, 10)
            Paw.AddStroke(card, Theme.border, 1, 0.4)
            Paw.CreateElement("TextLabel", {
                Position = UDim2.new(0, 12, 0, 6),
                Size = UDim2.new(1, -24, 0, 18),
                BackgroundTransparency = 1,
                Text = "Weapon / Fighting Style",
                TextColor3 = Theme.textSub,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card
            })
            local btns = {}
            local function paintWeapon()
                for name, b in pairs(btns) do
                    local on = Config.SelectedWeapon == name
                    b.BackgroundColor3 = on and Theme.accent1 or Theme.bgDark
                    b.TextColor3 = on and Color3.fromRGB(0, 0, 0) or Theme.text
                end
            end
            for i, name in ipairs(weapons) do
                local b = Paw.CreateElement("TextButton", {
                    Position = UDim2.new(0, 10 + (i - 1) * 88, 0, 30),
                    Size = UDim2.new(0, 82, 0, 28),
                    BackgroundColor3 = Theme.bgDark,
                    Text = name,
                    TextColor3 = Theme.text,
                    TextSize = 11,
                    Font = Enum.Font.GothamBold,
                    AutoButtonColor = false,
                    Parent = card
                })
                Paw.AddCorner(b, 8)
                b.MouseButton1Click:Connect(function()
                    Config.SelectedWeapon = name
                    paintWeapon()
                    Paw.EquipFarmWeapon(Config)
                    Toast:Show("Weapon: " .. name, "ok")
                end)
                btns[name] = b
            end
            paintWeapon()
            y = y + 80
        end

        -- 5) Range / speed / movement
        Section(p, "farm_tuning", y); y = y + 18
        MakeToggle(p, y, "fast_attack", "Fast Attack", function() return Config.FastAttack ~= false end, function()
            Config.FastAttack = not (Config.FastAttack ~= false)
            Toast:Show(Config.FastAttack and "Fast Attack ON" or "Fast Attack OFF", "ok")
        end); y = y + 48
        MakeToggle(p, y, "tween_farm", "Tween Farm", function() return Config.TweenFarm ~= false end, function()
            Config.TweenFarm = not (Config.TweenFarm ~= false)
            Toast:Show(Config.TweenFarm and "Tween Farm ON" or "Tween Farm OFF", "ok")
        end); y = y + 48
        NumRow(p, y, "Farm Range", function() return Config.FarmRange or 80 end, function(v) Config.FarmRange = math.floor(v) end, 10, 20, 200, "%d"); y = y + 40
        NumRow(p, y, "Farm Height", function() return Config.FarmHeight or 6 end, function(v) Config.FarmHeight = v end, 1, 2, 20, "%d"); y = y + 40
        NumRow(p, y, "Attack Speed", function() return Config.AttackSpeed or 1 end, function(v) Config.AttackSpeed = v end, 0.1, 0.5, 3.0, "%.1fx"); y = y + 48

        Paw.CreateElement("Frame", {
            Position = UDim2.new(0, 0, 0, y),
            Size = UDim2.new(1, 0, 0, 12),
            BackgroundTransparency = 1,
            Parent = p
        })
    end

    -- ========== TAB: SEA ==========
    do
        local p = Pages.Sea
        if p then
            local y = 0
            Section(p, "sea_events", y); y = y + 18
            MakeToggle(p, y, "auto_sea_event", "Auto Sea Events", function() return Config.AutoSeaEvent end, function()
                Paw.SetPrimaryFeature("AutoSeaEvent", not Config.AutoSeaEvent)
                FeatureEngine:EnsureRunning()
                Toast:Show(Config.AutoSeaEvent and "Sea Events ON" or "OFF", "ok")
            end); y = y + 48
            MakeToggle(p, y, "auto_leviathan", "Auto Leviathan", function() return Config.AutoLeviathan end, function()
                Config.AutoLeviathan = false
                Toast:Show("Auto Leviathan chưa có engine xử lý", "warn")
            end); y = y + 48
            MakeToggle(p, y, "auto_mirage", "Auto Mirage Island", function() return Config.AutoMirage end, function()
                Paw.SetPrimaryFeature("AutoMirage", not Config.AutoMirage)
                FeatureEngine:EnsureRunning()
            end); y = y + 48
            MakeToggle(p, y, "auto_kitsune", "Auto Kitsune Island", function() return Config.AutoKitsune end, function()
                Paw.SetPrimaryFeature("AutoKitsune", not Config.AutoKitsune)
                FeatureEngine:EnsureRunning()
            end); y = y + 56
            Paw.CreateElement("TextLabel", {
                Position = UDim2.new(0, 8, 0, y), Size = UDim2.new(1, -16, 0, 40),
                BackgroundTransparency = 1,
                Text = "Sea Beast · Terrorshark · Piranha · Ghost Ship\nMirage Gear · Kitsune Azure Flames",
                TextColor3 = Theme.textMuted, TextSize = 11, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = p
            })
        end
    end

    -- ========== TAB: RAID ==========
    do
        local p = Pages.Raid
        if p then
            local y = 0
            Section(p, "raid_boss", y); y = y + 18
            MakeToggle(p, y, "auto_raid", "Auto Raid / Dungeon", function() return Config.AutoRaid end, function()
                Paw.SetPrimaryFeature("AutoRaid", not Config.AutoRaid)
            end); y = y + 48
            MakeToggle(p, y, "raid_buy_chip", "Buy Raid Chip", function() return Config.RaidBuyChip end, function()
                Config.RaidBuyChip = not Config.RaidBuyChip
            end); y = y + 48
            MakeToggle(p, y, "raid_kill", "Raid Kill Mobs", function() return Config.RaidKill ~= false end, function()
                Config.RaidKill = not (Config.RaidKill ~= false)
            end); y = y + 48
            MakeToggle(p, y, "raid_next", "Raid Next Island", function() return Config.RaidNext ~= false end, function()
                Config.RaidNext = not (Config.RaidNext ~= false)
            end); y = y + 56
            Section(p, "race_v4", y); y = y + 18
            MakeToggle(p, y, "auto_trial", "Auto Trial (Race V4)", function() return Config.AutoTrial end, function()
                Config.AutoTrial = false
                Toast:Show("Auto Trial chưa có engine xử lý", "warn")
            end); y = y + 48
            MakeToggle(p, y, "auto_race_v4", "Train Race V4", function() return Config.AutoRaceV4 end, function()
                Config.AutoRaceV4 = false
                Toast:Show("Train Race V4 chưa có engine xử lý", "warn")
            end); y = y + 48
            MakeToggle(p, y, "auto_boss", "Auto Boss", function() return Config.AutoBoss end, function() AutoBoss:Toggle() end); y = y + 48
            MakeToggle(p, y, "auto_elite", "Auto Elite Hunter", function() return Config.AutoEliteHunter end, function()
                Paw.SetPrimaryFeature("AutoEliteHunter", not Config.AutoEliteHunter)
            end); y = y + 48
        end
    end

    -- ========== TAB: QUEST ==========
    do
        local p = Pages.Quest
        if p then
            local y = 0
            Section(p, "quest_legends", y); y = y + 18
            MakeToggle(p, y, "auto_saber", "Auto Saber Quest", function() return Config.AutoSaber end, function()
                Config.AutoSaber = false
                Toast:Show("Auto Saber chưa có engine xử lý", "warn")
            end); y = y + 48
            MakeToggle(p, y, "auto_cdk", "Auto CDK", function() return Config.AutoCDK end, function()
                Config.AutoCDK = false
                Toast:Show("Auto CDK chưa có engine xử lý", "warn")
            end); y = y + 48
            MakeToggle(p, y, "auto_soul_guitar", "Auto Soul Guitar", function() return Config.AutoSoulGuitar end, function()
                Config.AutoSoulGuitar = false
                Toast:Show("Auto Soul Guitar chưa có engine xử lý", "warn")
            end); y = y + 48
            MakeToggle(p, y, "auto_cake", "Auto Cake Prince", function() return Config.AutoCakePrince end, function()
                Paw.SetPrimaryFeature("AutoCakePrince", not Config.AutoCakePrince)
            end); y = y + 56
            Paw.CreateElement("TextLabel", {
                Position = UDim2.new(0, 8, 0, y), Size = UDim2.new(1, -16, 0, 40),
                BackgroundTransparency = 1,
                Text = "Saber · CDK · Soul Guitar · Cake Prince\n(Scythe / Indra via Auto Boss)",
                TextColor3 = Theme.textMuted, TextSize = 11, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = p
            })
        end
    end

    -- ========== TAB: ESP ==========
    do
        local p = Pages.ESP
        if p then
            local y = 0
            Section(p, "esp_section", y); y = y + 18
            MakeToggle(p, y, "esp", "ESP Master", function() return Config.ESP end, function()
                Paw.SetESP(not Config.ESP)
            end); y = y + 48
            MakeToggle(p, y, "esp_players", "ESP Players", function() return Config.ESP_Players ~= false end, function()
                Config.ESP_Players = not (Config.ESP_Players ~= false)
                if Config.ESP then Paw.RefreshESP() end
            end); y = y + 48
            MakeToggle(p, y, "esp_boss", "ESP Boss", function() return Config.ESP_Boss ~= false end, function()
                Config.ESP_Boss = not (Config.ESP_Boss ~= false)
                if Config.ESP then Paw.RefreshESP() end
            end); y = y + 48
            MakeToggle(p, y, "esp_fruit", "ESP Fruit", function() return Config.ESP_Fruit ~= false end, function()
                Config.ESP_Fruit = not (Config.ESP_Fruit ~= false)
                if Config.ESP then Paw.RefreshESP() end
            end); y = y + 48
            MakeToggle(p, y, "esp_chest", "ESP Chest", function() return Config.ESP_Chest end, function()
                Config.ESP_Chest = not Config.ESP_Chest
                if Config.ESP then Paw.RefreshESP() end
            end); y = y + 48
            MakeToggle(p, y, "esp_flower", "ESP Flower / Gear", function() return Config.ESP_Flower end, function()
                Config.ESP_Flower = not Config.ESP_Flower
                Config.ESP_Gear = Config.ESP_Flower
                if Config.ESP then Paw.RefreshESP() end
            end); y = y + 48
            MakeToggle(p, y, "noclip", "Noclip", function() return Config.Noclip end, function()
                Paw.SetNoclip(not Config.Noclip)
            end); y = y + 48
            MakeToggle(p, y, "safe_mode", "Safe Mode", function() return Config.SafeMode end, function()
                Config.SafeMode = not Config.SafeMode
                FeatureEngine:EnsureRunning()
            end); y = y + 48
        end
    end

    -- ========== TAB: FRUIT ==========
    do
        local p = Pages.Fruit
        if p then
            local y = 0
            Section(p, "fruits", y); y = y + 18
            MakeToggle(p, y, "auto_store", "Auto Store Fruit", function() return Config.AutoStoreFruit end, function() AutoStoreFruit:Toggle() end); y = y + 48
            MakeToggle(p, y, "fruit_notify", "Fruit Notify", function() return Config.FruitNotify end, function()
                Config.FruitNotify = not Config.FruitNotify
                FeatureEngine:EnsureRunning()
            end); y = y + 48
            MakeToggle(p, y, "fruit_sniper", "Auto Snipe Fruit", function() return Config.FruitSniper end, function()
                Paw.SetPrimaryFeature("FruitSniper", not Config.FruitSniper)
            end); y = y + 48
            MakeToggle(p, y, "auto_gacha", "Auto Gacha (Cousin)", function() return Config.AutoGacha end, function()
                Config.AutoGacha = false
                Toast:Show("Auto Gacha chưa có engine xử lý", "warn")
            end); y = y + 56
            local list = Config.SniperList or {}
            local textL = "Snipe priority:\n" .. table.concat(list, " · ")
            local card = Paw.CreateElement("Frame", {
                Position = UDim2.new(0, 0, 0, y), Size = UDim2.new(1, -6, 0, 72),
                BackgroundColor3 = Theme.card, BorderSizePixel = 0, Parent = p
            })
            Paw.AddCorner(card, 10)
            Paw.CreateElement("TextLabel", {
                Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 1, -16),
                BackgroundTransparency = 1, Text = textL, TextColor3 = Theme.textSub,
                TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Parent = card
            })
        end
    end

    -- ========== TAB: TP ==========
    do
        local p = Pages.TP
        if p then
            local y = 0
            Section(p, "server", y); y = y + 18
            MakeToggle(p, y, "anti_afk", "Anti AFK", function() return Config.AntiAFK end, function()
                if Config.AntiAFK then AntiAFK:Stop() else AntiAFK:Start() end
            end); y = y + 48
            MakeToggle(p, y, "hop_rejoin", "Hop Rejoin", function() return Config.HopRejoin ~= false end, function()
                Config.HopRejoin = not (Config.HopRejoin ~= false)
            end); y = y + 48
            MakeToggle(p, y, "fruit_hop", "Hop for Fruit", function() return Config.FruitHop end, function()
                Config.FruitHop = not Config.FruitHop
            end); y = y + 48
            MakeToggle(p, y, "boss_hop", "Hop for Boss", function() return Config.BossHop end, function()
                Config.BossHop = not Config.BossHop
            end); y = y + 56
            Section(p, "farm_settings", y); y = y + 18
            NumRow(p, y, "Tween Speed", function() return Config.TweenSpeed or 280 end, function(v) Config.TweenSpeed = math.floor(v) end, 20, 80, 500, "%d"); y = y + 40
            NumRow(p, y, "Farm Height", function() return Config.FarmHeight or 8 end, function(v) Config.FarmHeight = math.floor(v) end, 1, 0, 30, "%d"); y = y + 40
            NumRow(p, y, "Farm Range", function() return Config.FarmRange or 80 end, function(v) Config.FarmRange = math.floor(v) end, 10, 20, 400, "%d"); y = y + 48
            Section(p, "settings", y); y = y + 18
            MakeToggle(p, y, "language", "Language VI", function() return Config.Language == "vi" end, function()
                Config.Language = (Config.Language == "vi") and "en" or "vi"
                pcall(Paw.ApplyLanguage)
                Toast:Show("Lang: " .. Config.Language, "ok")
            end); y = y + 56
            local function cfgBtn(label, yy, cb)
                local b = Paw.CreateElement("TextButton", {
                    Position = UDim2.new(0, 0, 0, yy), Size = UDim2.new(1, -6, 0, 40),
                    BackgroundColor3 = Theme.card, Text = label, TextColor3 = Theme.text,
                    TextSize = 13, Font = Enum.Font.GothamBold, Parent = p
                })
                Paw.AddCorner(b, 10)
                b.MouseButton1Click:Connect(function() pcall(cb) end)
            end
            cfgBtn("Save Config", y, function() ConfigIO:Save() Toast:Show("Saved", "ok") end); y = y + 48
            cfgBtn("Load Config", y, function() ConfigIO:Load() Toast:Show("Loaded", "ok") end); y = y + 48
        end
    end

    -- Wire minimize + show Home on load
    fullSize = Main.Size
    MinBtn.MouseButton1Click:Connect(function()
        uiMinimized = not uiMinimized
        if uiMinimized then
            pcall(function()
                TabBar.Visible = false
                for _, pg in pairs(Pages) do
                    if typeof(pg) == "Instance" then pg.Visible = false end
                end
                fullSize = Main.Size
                Main.Size = UDim2.new(0, math.max(260, Header.AbsoluteSize.X), 0, 52)
                MinBtn.Text = "+"
            end)
        else
            pcall(function()
                TabBar.Visible = true
                Main.Size = fullSize
                MinBtn.Text = "−"
                ShowTab(currentTab or "Home")
            end)
        end
    end)
    ShowTab("Home")

    function ApplyUILayout()

        local scale = Config.UIScale or 1
        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        if isMobile then
            scale = math.clamp(scale * 0.92, 0.7, 1.1)
            WIN_W = math.floor(420 * scale)
            WIN_H = math.floor(520 * scale)
        else
            WIN_W = math.floor(560 * scale)
            WIN_H = math.floor(580 * scale)
        end
        FULL_SIZE = UDim2.new(0, WIN_W, 0, WIN_H)
        MINI_SIZE = UDim2.new(0, WIN_W, 0, 52)
        if not minOn then
            Main.Size = FULL_SIZE
        else
            Main.Size = MINI_SIZE
        end
        Main.BackgroundTransparency = Config.UIOpacity or 0
    end
    ApplyUILayout()

    -- Keybind
    local uiHidden = false
    HubInstance:AddConnection(UserInputService.InputBegan:Connect(function(input, gp)
        if HubInstance.stopped then return end
        if gp then return end
        if input.KeyCode == (Config.ToggleKey or Enum.KeyCode.RightControl) then
            uiHidden = not uiHidden
            Main.Visible = not uiHidden
            Toast:Show(uiHidden and Paw.T("toast_ui_hide") or Paw.T("toast_ui_show"), "info")
        end
    end))

    -- Drag
    local dragging, dragStart, startPos = false, nil, nil
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- ========== LOADING ANIMATION ==========
    local Load = Paw.CreateElement("Frame", {
        Name = "LoadOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.bg,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 50,
        Parent = Main
    })
    Paw.AddCorner(Load, 16)

    local stage = Paw.CreateElement("Frame", {
        Size = UDim2.new(0, 220, 0, 160),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 51,
        Parent = Load
    })

    local ring = Paw.CreateElement("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0, 36),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 51,
        Parent = stage
    })
    Paw.AddCorner(ring, 99)
    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = Theme.accent1
    ringStroke.Thickness = 1.5
    ringStroke.Transparency = 1
    ringStroke.Parent = ring

    local mark = Paw.CreateElement("Frame", {
        Size = UDim2.new(0, 56, 0, 52),
        Position = UDim2.new(0.5, 0, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        ZIndex = 52,
        Parent = stage
    })

    local function makeDot(px, py)
        local f = Paw.CreateElement("Frame", {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, px, 0, py),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.accent1,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 52,
            Parent = mark
        })
        Paw.AddCorner(f, 99)
        return f
    end

    local toeSpecs = {
        {x = 12, y = 14, w = 11, h = 14},
        {x = 22, y = 8,  w = 12, h = 15},
        {x = 34, y = 8,  w = 12, h = 15},
        {x = 44, y = 14, w = 11, h = 14},
    }
    local toes = {}
    for i, d in ipairs(toeSpecs) do
        local f = makeDot(d.x, d.y)
        toes[i] = {f = f, w = d.w, h = d.h}
    end
    local pad = makeDot(28, 36)
    Paw.AddCorner(pad, 12)

    local word = Paw.CreateElement("Frame", {
        Size = UDim2.new(0, 120, 0, 40),
        Position = UDim2.new(0.5, 0, 0, 72),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        ZIndex = 52,
        Parent = stage
    })
    local letters = {}
    local cellW = 40
    for i, ch in ipairs({"P", "a", "w"}) do
        local lab = Paw.CreateElement("TextLabel", {
            Size = UDim2.new(0, cellW, 1, 0),
            Position = UDim2.new(0, (i - 1) * cellW, 0, 0),
            BackgroundTransparency = 1,
            Text = ch,
            TextColor3 = Theme.text,
            TextTransparency = 1,
            TextSize = 28,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 52,
            Parent = word
        })
        letters[i] = lab
    end

    local under = Paw.CreateElement("Frame", {
        Size = UDim2.new(0, 0, 0, 2),
        Position = UDim2.new(0.5, 0, 0, 116),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.accent1,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 52,
        Parent = stage
    })
    Paw.AddCorner(under, 2)

    local status = Paw.CreateElement("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0.5, 0, 0.5, 88),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Theme.textMuted,
        TextTransparency = 1,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        ZIndex = 51,
        Parent = Load
    })

    local function tw(obj, props, dur, style)
        local t = TweenService:Create(
            obj,
            TweenInfo.new(dur or 0.3, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            props
        )
        t:Play()
        return t
    end

    task.spawn(function()
        local openTw = tw(Main, {Size = UDim2.new(0, WIN_W, 0, WIN_H)}, 0.42)
        openTw.Completed:Wait()
        task.wait(0.05)

        tw(ring, {Size = UDim2.new(0, 88, 0, 88)}, 0.45, Enum.EasingStyle.Quint)
        tw(ringStroke, {Transparency = 0.72}, 0.4)

        for _, idx in ipairs({1, 4, 2, 3}) do
            local t = toes[idx]
            tw(t.f, {
                Size = UDim2.new(0, t.w, 0, t.h),
                BackgroundTransparency = 0
            }, 0.26, Enum.EasingStyle.Back)
            task.wait(0.055)
        end

        tw(pad, {
            Size = UDim2.new(0, 28, 0, 24),
            BackgroundTransparency = 0
        }, 0.3, Enum.EasingStyle.Back)
        task.wait(0.15)

        for i, lab in ipairs(letters) do
            lab.Position = UDim2.new(0, (i - 1) * cellW, 0, 6)
            tw(lab, {
                TextTransparency = 0,
                Position = UDim2.new(0, (i - 1) * cellW, 0, 0)
            }, 0.28, Enum.EasingStyle.Quint)
            task.wait(0.08)
        end

        tw(under, {
            Size = UDim2.new(0, 72, 0, 2),
            BackgroundTransparency = 0
        }, 0.32, Enum.EasingStyle.Quint)
        task.wait(0.12)

        status.Text = "Ready"
        tw(status, {TextTransparency = 0}, 0.2)
        task.wait(0.3)

        tw(Load, {BackgroundTransparency = 1}, 0.25)
        tw(ringStroke, {Transparency = 1}, 0.2)
        for _, t in ipairs(toes) do
            tw(t.f, {BackgroundTransparency = 1}, 0.2)
        end
        tw(pad, {BackgroundTransparency = 1}, 0.2)
        tw(under, {BackgroundTransparency = 1}, 0.2)
        for _, lab in ipairs(letters) do
            tw(lab, {TextTransparency = 1}, 0.2)
        end
        tw(status, {TextTransparency = 1}, 0.2)
        task.wait(0.26)

        if Load and Load.Parent then
            Load:Destroy()
        end
    end)
end

Paw.CreateGUI()

HubInstance.Config = Config
HubInstance.FeatureEngine = FeatureEngine
HubInstance.ServerHop = ServerHop
HubInstance.AntiAFK = AntiAFK
HubInstance.World = World

-- Start with features off; user enables via UI
HubInstance:ForceAllFeaturesOff(Config)
pcall(function()
    if FeatureEngine and FeatureEngine.Stop then FeatureEngine:Stop() end
end)
pcall(function()
    if ServerHop then ServerHop.Active = false end
end)
pcall(function()
    Paw.SetNoclip(false)
    Paw.SetESP(false)
end)

-- Load map + dump remotes 1 lần khi chạy script
task.spawn(function()
    task.wait(0.5)
    pcall(function()
        World:Scan(false) -- trong Scan đã DumpRemotesToFile()
        Paw.UpdateCurrentSea(true)
    end)
end)

pcall(function()
    Toast:Show("PawZHub BF ready · scanning map + remotes...", "ok")
end)
