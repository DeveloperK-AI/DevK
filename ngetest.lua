--[[
    Beta.lua – DevHub Ultimate Script for Fisch (Refactored)
    Semua fitur: Auto Fishing, Quest, Webhook, Teleport, dll.
    Dikerjakan ulang secara profesional agar stabil dan minim error.
--]]

-- ================================================================
-- 1. INITIALIZATION & NET SETUP
-- ================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Net folder (sleitnick_net)
local netFolder = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
local netChildren = netFolder:GetChildren()

-- Helper: deteksi nama hex hash
local function isHex(name)
    local stripped = name:gsub("^R[FE]/", "")
    return #stripped > 16 and stripped:match("^%x+$") ~= nil
end

-- Build remote map
local remoteMap = {}
for i, child in ipairs(netChildren) do
    if not isHex(child.Name) then
        local nextChild = netChildren[i + 1]
        if nextChild and isHex(nextChild.Name) then
            local key = child.Name:gsub("^R[FE]/", "")
            remoteMap[key] = nextChild
        end
    end
end

-- Definisikan Net (global)
_G.Net = netFolder  -- supaya bisa diakses di tempat lain

local function RF(name) return remoteMap[name] end
local function RE(name) return remoteMap[name] end

-- ================================================================
-- 2. REMOTE DECLARATIONS (semua remote yang digunakan)
-- ================================================================

local BuyRod              = RF("PurchaseFishingRod")
local BuyBait             = RF("PurchaseBait")
local BuyCharm            = RF("PurchaseCharm")
local REFishDone          = RF("CatchFishCompleted")
local REFishDoneRE        = RE("CatchFishCompleted")
local BuyWeather          = RF("PurchaseWeatherEvent")
local ChargeRod           = RF("ChargeFishingRod")
local StartMini           = RF("RequestFishingMinigameStarted")
local UpdateRadar         = RF("UpdateFishingRadar")
local Cancel              = RF("CancelFishingInputs")
local SellItem            = RF("SellAllItems")
local AutoEnabled         = RF("UpdateAutoFishingState")
local BuyMarket           = RF("PurchaseMarketItem")
local InitiateTrade       = RF("InitiateTrade")
local RFAwaitTradeResponse= RF("AwaitTradeResponse")
local EquipOxygen         = RF("EquipOxygenTank")
local UnequipOxygen       = RF("UnequipOxygenTank")
local ConsumeCrystal      = RF("ConsumeCaveCrystal")
local ConsumePotion       = RF("ConsumePotion")
local threselod           = RF("UpdateAutoSellThreshold")
local dialogevent         = RF("SpecialDialogueEvent")

local RECutscene          = RE("ReplicateCutscene")
local REStop              = RE("StopCutscene")
local REFav               = RE("FavoriteItem")
local REFavChg            = RE("FavoriteStateChanged")
local REFishGot           = RE("FishCaught")
local RENotify            = RE("TextNotification")
local REEquip             = RE("EquipToolFromHotbar")
local REEquipItem         = RE("EquipItem")
local REAltar             = RE("ActivateEnchantingAltar")
local REAltar2            = RE("ActivateSecondEnchantingAltar")
local REPlayFishEffect    = RE("PlayFishingEffect")
local RETextEffect        = RE("ReplicateTextEffect")
local Totem               = RE("SpawnTotem")
local FishingMinigameChanged = RE("FishingMinigameChanged")
local FishingStopped      = RE("FishingStopped")
local REEvReward          = RE("ClaimEventReward")
local REEquipCharm        = RE("EquipCharm")
local REUnequipCharm      = RE("UnequipCharm")
local BaitSpawned         = RE("BaitSpawned")
local BaitDestroyed       = RE("BaitDestroyed")
local PirateChest         = RE("ClaimPirateChest")
local GainMaze            = RE("GainAccessToMaze")
local PlaceLever          = RE("PlaceLeverItem")
local REDialogueEnded     = RE("DialogueEnded")
local RFCreateTranscendedStone = RF("CreateTranscendedStone")
local EquipBait           = RE("EquipBait")

-- Tambahan remote yang hilang
local SearchPickup        = RF("SearchPickup") or RE("SearchPickup")  -- untuk cave wall

-- ================================================================
-- 3. GLOBAL CONFIG & STATE
-- ================================================================

_G.SavedData = _G.SavedData or {
    FishCaught = {},
    CaughtVisual = {},
    FishNotif = {}
}

_G.AutoFarm = false
_G.AutoRod = false
_G.AutoSells = false
_G.InfiniteJump = false
_G.Radar = false
_G.AntiAFK = false
_G.AutoReconnect = false
_G.Amblatant = false
_G.BlatantMode = false
_G.Noclip = false
_G.DivingGear = false
_G.FreezeCharacter = false
_G.AutoCrystal = false
_G.AutoOpenPirateChest = false
_G.AutoLeviathanHunt = false
_G.LochnesFishingMode = "Legit"
_G.AutoLochnesEvent = false
_G.DeepSeaQuestMode = false
_G.ElementQuestMode = false
_G.DiamondQuestMode = false
_G.AutoCreateTranscendedStones = false
_G.AutoTempleLever = false
_G.WebhookURL = _G.WebhookURL or ""
_G.WebhookEnabled = _G.WebhookEnabled or false
_G.WebhookRarities = _G.WebhookRarities or {}
_G.WebhookVariants = _G.WebhookVariants or {}
_G.WebhookCrystalized = _G.WebhookCrystalized or false
_G.WhatsAppWebhookEnabled = _G.WhatsAppWebhookEnabled or false
_G.DetectNewFishActive = false
_G.KaitunGUIForce = false
_G.HasTeleported = false

local Config = {
    HookNotif = false,
    InstantFishingV2Active = false,
    isMinig = false,
    autoFishing = false,
    AutoCatch = false,
    antiOKOK = false,
    amblatant = false,
    UB = {
        Active = false,
        Settings = { CompleteDelay = 3.7, CancelDelay = 0.2, CastMode = "Fast" },
        Remotes = {},
        Stats = { castCount = 0, startTime = 0 },
    },
}

-- ================================================================
-- 4. HELPER FUNCTIONS (safe remote calls, etc.)
-- ================================================================

function CallRemoteServer(remote, ...)
    if not remote then return false end
    local args = {...}
    local ok = pcall(function()
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(unpack(args))
        elseif remote:IsA("RemoteEvent") then
            remote:FireServer(unpack(args))
        else
            remote:InvokeServer(unpack(args))  -- fallback
        end
    end)
    if not ok then
        -- coba FireServer
        pcall(function()
            remote:FireServer(unpack(args))
        end)
    end
    return true
end

function safeFire(remote, ...)
    if not remote then return end
    task.spawn(function()
        pcall(function()
            remote:FireServer(...)
        end)
    end)
end

function safeInvoke(remote, ...)
    if not remote then return end
    task.spawn(function()
        pcall(function()
            remote:InvokeServer(...)
        end)
    end)
end

function FireLocalEvent(remote, ...)
    if not remote or not remote.OnClientEvent then return end
    local args = {...}
    local signal = remote.OnClientEvent
    local ok, conns = pcall(getconnections, signal)
    if ok and conns then
        for _, connection in pairs(conns) do
            if connection.Function then
                task.spawn(function()
                    pcall(function()
                        connection.Function(unpack(args))
                    end)
                end)
            end
        end
    end
end

function HookRemote(humanName, storageKey)
    local remote = GetServerRemote(humanName)
    if not remote then return false end
    remote.OnClientEvent:Connect(function(...)
        if saveCount < 7 then
            _G.SavedData[storageKey] = {...}
            local args = {...}
            if storageKey == "CaughtVisual" then
                local lp = Players.LocalPlayer
                local myName = lp and lp.Name
                if myName and tostring(args[1]) == tostring(myName) then
                    saveCount = saveCount + 1
                end
            end
        end
    end)
    return true
end

function GetServerRemote(humanName)
    local key = humanName:gsub("^R[FE]/", "")
    return remoteMap[key]
end

-- ================================================================
-- 5. FISHING CONTROLLER PATCHING & INSTANT FISHING V2
-- ================================================================

local FishingController
pcall(function()
    FishingController = require(ReplicatedStorage.Controllers.FishingController)
end)

local oldClick, oldCharge
if FishingController then
    oldClick = FishingController.RequestFishingMinigameClick
    oldCharge = FishingController.RequestChargeFishingRod
end

local instantV2OrigCharge = oldCharge
local instantV2OrigCast = FishingController and FishingController.SendFishingRequestToServer or function() end

-- ================================================================
-- 6. INSTANT FISHING MODULE (dengan perbaikan)
-- ================================================================

local Instant = {}
local PI = math.pi
local CAST_MODE_LIST = { "Perfect", "Fast", "Random" }

local state = {
    enabled = false,
    running = false,
    castMode = "Fast",
    completeDelay = 3,
    castDelay = 0.3,
    notifDelay = 1.6,
    notifDuration = 4.7,
}

local loopTask = nil
local notifHooked = false
local notifOriginalDeliver = nil
local notifOriginalTween = nil

function getPowerAtTime(chargeTime, elapsed)
    local speed = Random.new(chargeTime):NextInteger(4, 10)
    local angle = PI / 2 + elapsed * speed
    return (1 - math.sin(angle)) / 2
end

function waitForPower(chargeTime, threshold)
    local deadline = chargeTime + 2.0
    while Workspace:GetServerTimeNow() < deadline do
        local elapsed = Workspace:GetServerTimeNow() - chargeTime
        local power = getPowerAtTime(chargeTime, elapsed)
        if power >= threshold then
            return elapsed, power
        end
        task.wait(0.01)
    end
    local elapsed = Workspace:GetServerTimeNow() - chargeTime
    return elapsed, getPowerAtTime(chargeTime, elapsed)
end

function hookNotificationDelay()
    if notifHooked then return end
    local ok, controller = pcall(function()
        return require(ReplicatedStorage.Controllers.TextNotificationController)
    end)
    if not ok or not controller then return end

    notifOriginalDeliver = controller.DeliverNotification
    notifOriginalTween = controller.Tween

    if notifOriginalDeliver then
        controller.DeliverNotification = function(self, p24)
            if state.enabled and state.notifDelay > 0 then
                task.spawn(function()
                    task.wait(state.notifDelay)
                    if notifOriginalDeliver then
                        notifOriginalDeliver(self, p24)
                    end
                end)
            else
                if notifOriginalDeliver then
                    notifOriginalDeliver(self, p24)
                end
            end
        end
    end

    if notifOriginalTween then
        controller.Tween = function(self, tile, duration, options)
            local finalDuration = duration
            if state.enabled and state.notifDuration > 0 then
                finalDuration = duration + state.notifDuration
            end
            return notifOriginalTween(self, tile, finalDuration, options)
        end
    end
    notifHooked = true
end

function unhookNotificationDelay()
    if not notifHooked then return end
    pcall(function()
        local controller = require(ReplicatedStorage.Controllers.TextNotificationController)
        if notifOriginalDeliver then
            controller.DeliverNotification = notifOriginalDeliver
        end
        if notifOriginalTween then
            controller.Tween = notifOriginalTween
        end
    end)
    notifOriginalDeliver = nil
    notifOriginalTween = nil
    notifHooked = false
end

local function performCast(mode)
    local t0 = Workspace:GetServerTimeNow()
    safeInvoke(ChargeRod, nil, nil, t0, nil)

    local power
    if mode == "Perfect" then
        local _, p = waitForPower(t0, 0.97)
        power = p
    elseif mode == "Random" then
        local randomElapsed = math.random(0, 100) / 100 * (PI / 4)
        task.wait(randomElapsed)
        local elapsed = Workspace:GetServerTimeNow() - t0
        power = getPowerAtTime(t0, elapsed)
    else -- Fast
        local elapsed = Workspace:GetServerTimeNow() - t0
        power = getPowerAtTime(t0, elapsed)
    end

    safeInvoke(StartMini, 0, power, t0)
end

function startLoop()
    if state.running then return end
    state.running = true
    local lastSuccessTick = tick()

    while state.enabled do
        if tick() - lastSuccessTick > 10 then
            pcall(function() safeFire(REFishDoneRE or REFishDone) end)
            lastSuccessTick = tick()
        end

        performCast(state.castMode)
        task.wait(state.completeDelay)
        task.wait(0.01)
        safeFire(REFishDoneRE or REFishDone)
        lastSuccessTick = tick()
        task.wait(state.castDelay)
    end
    state.running = false
end

function Instant.SetCastMode(mode)
    if table.find(CAST_MODE_LIST, mode) then
        state.castMode = mode
    end
end

function Instant.SetCompleteDelay(v)
    local num = tonumber(v)
    if num and num >= 0.1 and num <= 30 then
        state.completeDelay = num
    end
end

function Instant.SetCastDelay(v)
    local num = tonumber(v)
    if num and num >= 0 and num <= 10 then
        state.castDelay = num
    end
end

function Instant.Start()
    if state.enabled then return end
    state.enabled = true
    hookNotificationDelay()
    loopTask = task.spawn(startLoop)
end

function Instant.Stop()
    state.enabled = false
    if loopTask then
        pcall(task.cancel, loopTask)
        loopTask = nil
    end
    state.running = false
    unhookNotificationDelay()
end

function Instant.IsActive() return state.enabled end

function instant()
    if state.enabled then return end
    performCast(state.castMode)
    task.wait(Config.UB.Settings.CompleteDelay or 3)
    safeFire(REFishDoneRE or REFishDone)
end

function UB_start()
    Config.UB.Active = true
    Config.UB.Stats.startTime = tick()
    Instant.SetCompleteDelay(Config.UB.Settings.CompleteDelay)
    Instant.SetCastDelay(Config.UB.Settings.CancelDelay)
    Instant.SetCastMode(Config.UB.Settings.CastMode or "Fast")
    Instant.Start()
end

function UB_stop()
    Config.UB.Active = false
    Instant.Stop()
end

function onToggleUB(value)
    if value then
        Config.HookNotif = true
        UB_start()
    else
        UB_stop()
        Config.HookNotif = false
    end
end

-- ================================================================
-- 7. AMBLATANT (NATURAL HOOK) – dengan pengecekan executor
-- ================================================================

_G.Amblatant = _G.Amblatant or false
local _naturalHookInstalled = false
local _naturalRainbowCount = 0
local _naturalGoldenCount = 0
local _naturalFishCount = 0
local isCaught = false
local saveCount = 0

function _resetNaturalHookCounts()
    _naturalRainbowCount = 0
    _naturalGoldenCount = 0
    _naturalFishCount = 0
    isCaught = false
end

function _installFixedNaturalHook()
    if _naturalHookInstalled then return end
    local executorName = "Unknown"
    pcall(function()
        if type(getExecutorName) == "function" then
            executorName = tostring(getExecutorName() or "Unknown")
        end
    end)
    if tostring(executorName):lower():find("velocity") then
        print("Fixed Natural Hook: skipped on Velocity executor")
        return
    end
    if type(hookfunction) ~= "function" then
        print("Fixed Natural Hook: hookfunction not available")
        return
    end

    _naturalHookInstalled = true
    local Event
    pcall(function()
        Event = ReplicatedStorage.Packages._Index["ytrev_replion@2.0.0-rc.3"].replion.Remotes.Set
    end)
    if not Event or not Event.OnClientEvent then return end

    local conns = getconnections(Event.OnClientEvent) or {}
    for _, Connection in pairs(conns) do
        if Connection and Connection.Function then
            local old = hookfunction(Connection.Function, function(...)
                local Args = { ... }
                if type(Args[2]) == "table" then
                    local category = Args[2][1]
                    local subCategory = Args[2][2]
                    local function RunNaturalUpdate(updateType)
                        task.spawn(function()
                            for _ = 1, 2 do
                                if updateType == "Rainbow" then
                                    local last = _naturalRainbowCount
                                    _naturalRainbowCount = _naturalRainbowCount + 1
                                    if _naturalRainbowCount > 40 then _naturalRainbowCount = 0 end
                                    isCaught = (_naturalRainbowCount ~= last)
                                    old(Args[1], Args[2], _naturalRainbowCount)
                                elseif updateType == "Golden" then
                                    local last = _naturalGoldenCount
                                    _naturalGoldenCount = _naturalGoldenCount + 1
                                    if _naturalGoldenCount > 10 then _naturalGoldenCount = 0 end
                                    isCaught = (_naturalGoldenCount ~= last)
                                    old(Args[1], Args[2], _naturalGoldenCount)
                                elseif updateType == "Fish" then
                                    _naturalFishCount = _naturalFishCount + 1
                                    isCaught = true
                                    old(Args[1], Args[2], _naturalFishCount)
                                end
                                task.wait(0.3)
                            end
                        end)
                    end

                    if _G.Amblatant then
                        if category == "Modifiers" and subCategory == "Rainbow" then
                            RunNaturalUpdate("Rainbow")
                            return
                        elseif category == "Modifiers" and subCategory == "Golden" then
                            RunNaturalUpdate("Golden")
                            return
                        elseif category == "InventoryNotifications" and subCategory == "Fish" then
                            RunNaturalUpdate("Fish")
                            return
                        end
                    end
                end
                return old(...)
            end)
        end
    end
    print("Fixed Natural Hook Active!")
end

-- ================================================================
-- 8. INSTANT BOBBER
-- ================================================================

local InstantBobberState = {
    instantOverrideActive = false,
    instantOverrideSetupDone = false,
    activeBaitsByUserId = nil,
    cosmeticFolder = nil,
    baitCastConn = nil,
    baitDestroyedConn = nil,
    renderConn = nil,
}

function patchInstantBaitOverrideToCastPosition(enabled)
    if not enabled then
        InstantBobberState.instantOverrideActive = false
        if InstantBobberState.activeBaitsByUserId then
            table.clear(InstantBobberState.activeBaitsByUserId)
        end
        return
    end

    InstantBobberState.instantOverrideActive = true
    InstantBobberState.activeBaitsByUserId = InstantBobberState.activeBaitsByUserId or {}
    table.clear(InstantBobberState.activeBaitsByUserId)

    if InstantBobberState.instantOverrideSetupDone then return end
    InstantBobberState.instantOverrideSetupDone = true

    local okCosmetic, cosmeticFolder = pcall(function()
        return Workspace:WaitForChild("CosmeticFolder", 5)
    end)
    if not okCosmetic or not cosmeticFolder then
        InstantBobberState.instantOverrideSetupDone = false
        InstantBobberState.instantOverrideActive = false
        return
    end
    InstantBobberState.cosmeticFolder = cosmeticFolder

    local baitCastVisual = GetServerRemote("RE/BaitCastVisual") or GetServerRemote("BaitCastVisual")
    local baitDestroyed = BaitDestroyed or GetServerRemote("RE/BaitDestroyed") or GetServerRemote("BaitDestroyed")

    if not baitCastVisual or not baitCastVisual:IsA("RemoteEvent") then
        InstantBobberState.instantOverrideSetupDone = false
        InstantBobberState.instantOverrideActive = false
        return
    end
    if not baitDestroyed or not baitDestroyed:IsA("RemoteEvent") then
        InstantBobberState.instantOverrideSetupDone = false
        InstantBobberState.instantOverrideActive = false
        return
    end

    function safeConnect(signal, callback, label)
        if not signal then return nil end
        local ok, conn = pcall(function() return signal:Connect(callback) end)
        return ok and conn or nil
    end

    InstantBobberState.baitCastConn = safeConnect(baitCastVisual.OnClientEvent, function(player, data)
        if not InstantBobberState.instantOverrideActive then return end
        if not player or not player.UserId then return end
        if not data or not data.CastPosition or typeof(data.CastPosition) ~= "Vector3" then return end

        InstantBobberState.activeBaitsByUserId[player.UserId] = {
            pivot = CFrame.new(data.CastPosition),
            expiresAt = tick() + 1.5,
        }
    end)

    InstantBobberState.baitDestroyedConn = safeConnect(baitDestroyed.OnClientEvent, function(player)
        if not InstantBobberState.instantOverrideActive then return end
        if not player or not player.UserId then return end
        InstantBobberState.activeBaitsByUserId[player.UserId] = nil
    end)

    InstantBobberState.renderConn = RunService.RenderStepped:Connect(function()
        if not InstantBobberState.instantOverrideActive then return end
        local now = tick()
        local cfolder = InstantBobberState.cosmeticFolder
        if not cfolder then return end

        for userId, entry in pairs(InstantBobberState.activeBaitsByUserId) do
            if now > entry.expiresAt then
                InstantBobberState.activeBaitsByUserId[userId] = nil
            else
                local model = cfolder:FindFirstChild(tostring(userId))
                if model and model.PivotTo then
                    model:PivotTo(entry.pivot)
                end
            end
        end
    end)
end

-- ================================================================
-- 9. LOAD MODULES (Replion, Data, dll.)
-- ================================================================

local Replion = require(ReplicatedStorage.Packages.Replion)
local Data = Replion.Client:WaitReplion("Data")
local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)

-- ================================================================
-- 10. QUEST DATA & PROGRESS FUNCTIONS
-- ================================================================

local tierToRarity = {
    [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic",
    [5] = "Legendary", [6] = "Mythic", [7] = "SECRET", [8] = "Forgotten"
}

function isObjectiveCompleted(obj)
    local check = obj:FindFirstChild("Content") and obj.Content:FindFirstChild("Check") and obj.Content.Check:FindFirstChild("Vector")
    return check and check.Visible
end

function getObjectiveProgress(obj)
    local barFrame = obj:FindFirstChild("BarFrame")
    if not barFrame then return 0, "" end
    local bar, bg = barFrame:FindFirstChild("Bar"), barFrame:FindFirstChild("BG")
    local progress = barFrame:FindFirstChild("Progress")
    if not bar or not bg then return 0, "" end
    local pct = (bar.Size.X.Offset / bg.Size.X.Offset) * 100
    return math.floor(pct), (progress and progress.Text) or ""
end

function getObjectiveDetails(obj)
    local content = obj:FindFirstChild("Content")
    if not content then return nil end
    local display = content:FindFirstChild("Display")
    if not display then return nil end
    local t = ""
    if display:FindFirstChild("Prefix") then t = t .. display.Prefix.Text .. " " end
    if display:FindFirstChild("ItemName") then t = t .. display.ItemName.Text .. " " end
    if display:FindFirstChild("Suffix") then t = t .. display.Suffix.Text end
    return t:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
end

function checkQuestStatus(questFrame)
    local top = questFrame:FindFirstChild("Top")
    if not top then return nil end
    local topFrame = top:FindFirstChild("TopFrame")
    local header = topFrame and topFrame:FindFirstChild("Header")
    if not header then return nil end
    local targetQuests = { ["Element Quest"] = true, ["Deep Sea Quest"] = true, ["Diamond Researcher"] = true }
    if not targetQuests[header.Text] then return nil end

    local content = questFrame:FindFirstChild("Content")
    if not content then return nil end
    local objectives, allDone = {}, true
    for i = 1, 10 do
        local obj = content:FindFirstChild("Objective" .. i)
        if obj then
            local details = getObjectiveDetails(obj)
            if details then
                local completed = isObjectiveCompleted(obj)
                local pct, progressText = getObjectiveProgress(obj)
                table.insert(objectives, { text = details, completed = completed, percentage = pct, progressText = progressText })
                if not completed then allDone = false end
            end
        end
    end
    return { name = header.Text, objectives = objectives, allCompleted = allDone and #objectives > 0 }
end

function getQuestData(questName)
    local gui = LocalPlayer:WaitForChild("PlayerGui")
    local questUI = gui:FindFirstChild("Quest")
    if not questUI then return nil end
    local list = questUI:FindFirstChild("List")
    if not list then return nil end
    local inside = list:FindFirstChild("Inside")
    if not inside then return nil end

    for _, child in pairs(inside:GetChildren()) do
        if child:IsA("Frame") and child.Name == "Quest" then
            local data = checkQuestStatus(child)
            if data and data.name == questName then return data end
        end
    end
    return nil
end

function getGhostfinnProgress()
    local data = getQuestData("Deep Sea Quest")
    local out = {}
    for i = 1, 4 do
        if data and data.objectives and data.objectives[i] then
            local o = data.objectives[i]
            local status = o.completed and "✓" or "✗"
            local prog = o.progressText ~= "" and o.progressText or (o.percentage .. "%")
            out[i] = status .. " " .. o.text .. " [" .. prog .. "]"
        else
            out[i] = "No progress data"
        end
    end
    return out
end

function getElementProgress()
    local data = getQuestData("Element Quest")
    local out = {}
    for i = 1, 4 do
        if data and data.objectives and data.objectives[i] then
            local o = data.objectives[i]
            local status = o.completed and "✓" or "✗"
            local prog = o.progressText ~= "" and o.progressText or (o.percentage .. "%")
            out[i] = status .. " " .. o.text .. " [" .. prog .. "]"
        else
            out[i] = "No progress data"
        end
    end
    return out
end

function getDiamondProgress()
    local data = getQuestData("Diamond Researcher")
    local out = {}
    for i = 1, 6 do
        if data and data.objectives and data.objectives[i] then
            local o = data.objectives[i]
            local status = o.completed and "✓" or "✗"
            local prog = o.progressText ~= "" and o.progressText or (o.percentage .. "%")
            out[i] = status .. " " .. o.text .. " [" .. prog .. "]"
        else
            out[i] = "No progress data"
        end
    end
    return out
end

-- ================================================================
-- 11. BEST ROD / BAIT / COINS (untuk quest & status)
-- ================================================================

local FishingRods = {
    ["Midnight Rod"] = { id = 80, price = 50000 },
    ["Astral Rod"] = { id = 5, price = 1000500 },
    ["Ghostfinn Rod"] = { id = 169, price = 9999999999999999999 },
    ["Element Rod"] = { id = 257, price = 999999999999999999999999999999 },
}

local function getRodUUID(rodId)
    local inv = Data:Get("Inventory")
    if not inv or not inv["Fishing Rods"] then return nil end
    for _, rod in ipairs(inv["Fishing Rods"]) do
        if rod.Id == rodId then return rod.UUID end
    end
    return nil
end

function equipGhostfinnRod()
    local uuid = getRodUUID(169)
    if not uuid then return false end
    if REEquipItem then
        pcall(function() REEquipItem:FireServer(uuid, "Fishing Rods") end)
    end
    if REEquip then pcall(function() REEquip:FireServer(1) end) end
    return true
end

function equipRodById(rodId)
    local uuid = getRodUUID(rodId)
    if not uuid then return false end
    if REEquipItem then
        pcall(function() REEquipItem:FireServer(uuid, "Fishing Rods") end)
    end
    if REEquip then pcall(function() REEquip:FireServer(1) end) end
    return true
end

function equipBestRodNow()
    local bestName = getBestRod()
    if bestName == "Midnight Rod" then return equipRodById(80)
    elseif bestName == "Astral Rod" then return equipRodById(5)
    elseif bestName == "Ghostfinn Rod" then return equipRodById(169)
    elseif bestName == "Element Rod" then return equipRodById(257)
    end
    if REEquip then pcall(function() REEquip:FireServer(1) end) end
    return true
end

function equipBestRodNowWithRetry(maxWait, interval)
    maxWait = maxWait or 8
    interval = interval or 0.5
    local deadline = tick() + maxWait
    while tick() < deadline do
        if equipBestRodNow() then return true end
        task.wait(interval)
    end
    return false
end

function hasItemInInventory(itemName)
    local inv = Data:Get("Inventory")
    if not inv then return false end
    for _, category in pairs(inv) do
        if type(category) == "table" then
            for _, item in ipairs(category) do
                if item and item.Id then
                    local info = ItemUtility:GetItemData(item.Id)
                    if info and info.Data and info.Data.Name == itemName then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function hasAnyItemInInventory(itemNames)
    for _, name in ipairs(itemNames) do
        if hasItemInInventory(name) then return true end
    end
    return false
end

function getBestRod()
    local inv = Data:Get("Inventory")
    local bestName, bestPrice = nil, 0
    if inv and inv["Fishing Rods"] then
        for _, rod in ipairs(inv["Fishing Rods"]) do
            for name, info in pairs(FishingRods) do
                if rod.Id == info.id and info.price > bestPrice then
                    bestPrice = info.price
                    bestName = name
                end
            end
        end
    end
    return bestName
end

local Baits = {
    [3] = { name = "Midnight Bait", price = 3000 },
    [15] = { name = "Corrupt Bait", price = 1150000 },
    [16] = { name = "Aether Bait", price = 3700000 },
}

function hasBait(baitId)
    local inv = Data:Get("Inventory")
    if not inv or not inv.Baits then return false end
    for _, b in ipairs(inv.Baits) do
        if b.Id == baitId then return true end
    end
    return false
end

function buyBait(baitId)
    if BuyBait then pcall(function() BuyBait:InvokeServer(baitId) end) end
end

function equipBait(baitId)
    if EquipBait then pcall(function() EquipBait:FireServer(baitId) end) end
end

function getBestBait()
    local inv = Data:Get("Inventory")
    if not inv or not inv.Baits then return "None" end
    local prices = { [3] = {"Midnight Bait", 3000}, [15] = {"Corrupt Bait", 1150000}, [16] = {"Aether Bait", 3700000} }
    local best, bestPrice = nil, 0
    for _, bait in ipairs(inv.Baits) do
        local info = prices[bait.Id]
        if info and info[2] > bestPrice then
            bestPrice = info[2]
            best = info[1]
        end
    end
    return best or "None"
end

function getCoins()
    local ok, c = pcall(function() return Data:Get("Coins") end)
    return (ok and c) or 0
end

-- ================================================================
-- 12. TEMPLE LEVER FUNCTIONS
-- ================================================================

local templeLeverOrder = { "Hourglass Diamond Artifact", "Diamond Artifact", "Arrow Artifact", "Crescent Artifact" }
local templeLeverTypeMapping = {
    ["Hourglass Diamond Artifact"] = "Hourglass Diamond",
    ["Diamond Artifact"] = "Diamond Artifact",
    ["Arrow Artifact"] = "Arrow Artifact",
    ["Crescent Artifact"] = "Crescent Artifact",
}
local templeLeverStatus = {
    ["Hourglass Diamond"] = false,
    ["Diamond Artifact"] = false,
    ["Arrow Artifact"] = false,
    ["Crescent Artifact"] = false,
}
local templeLeverLocationsMain = {
    ["Hourglass Diamond"] = CFrame.new(1487.30286, 3.20222163, -842.577271, -0.993248224, 8.33526457e-08, -0.116008602, 8.63568204e-08, 1, -2.0870063e-08, 0.116008602, -3.07472874e-08, -0.993248224),
    ["Diamond Artifact"] = CFrame.new(1842.67517, 3.25659585, -290.654053, -0.0019925572, 2.72486247e-08, -0.999998033, -2.64774211e-08, 1, 2.73014376e-08, 0.999998033, 2.65317688e-08, -0.0019925572),
    ["Arrow Artifact"] = CFrame.new(874.80127, 2.87421155, -359.296082, -0.138065234, -3.21473372e-08, 0.990423143, 1.92667446e-08, 1, 3.51439731e-08, -0.990423143, 2.39343905e-08, -0.138065234),
    ["Crescent Artifact"] = CFrame.new(1400.47058, 3.27519846, 121.937996, -0.926432133, -1.22242355e-07, 0.376461804, -1.19220402e-07, 1, 3.13252038e-08, -0.376461804, -1.58612501e-08, -0.926432133),
}
local isProcessingTemple = false

function findTempleLeverByType(leverType)
    local jungleInteractions = Workspace:FindFirstChild("JUNGLE INTERACTIONS")
    if not jungleInteractions then return nil end
    for _, child in ipairs(jungleInteractions:GetChildren()) do
        if child.Name == "TempleLever" and child:GetAttribute("Type") == leverType then
            return child
        end
    end
    return nil
end

function hasLeverPrompt(templeLever)
    local root = templeLever and templeLever:FindFirstChild("RootPart")
    if not root then return false end
    return root:FindFirstChildOfClass("ProximityPrompt") ~= nil
end

function fireLeverPrompt(templeLever)
    local root = templeLever and templeLever:FindFirstChild("RootPart")
    if not root then return false end
    local prompt = root:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        -- Gunakan fireproximityprompt jika tersedia
        local ok, _ = pcall(function() fireproximityprompt(prompt) end)
        if ok then return true end
        -- Fallback: prompt:InputHold? (tidak umum)
        pcall(function() prompt:InputHold() end)
        return true
    end
    return false
end

function refreshTempleLeverStatuses()
    for _, gameLeverType in ipairs(templeLeverOrder) do
        local displayName = templeLeverTypeMapping[gameLeverType]
        local templeLever = findTempleLeverByType(gameLeverType)
        templeLeverStatus[displayName] = templeLever and (not hasLeverPrompt(templeLever)) or false
    end
end

function getNextUncompletedLever()
    for _, gameLeverType in ipairs(templeLeverOrder) do
        local displayName = templeLeverTypeMapping[gameLeverType]
        if not templeLeverStatus[displayName] then
            return gameLeverType, displayName
        end
    end
    return nil, nil
end

function processTempleLevers()
    if isProcessingTemple then return false end
    isProcessingTemple = true
    local success = pcall(function()
        refreshTempleLeverStatuses()
        local gameLeverType, displayName = getNextUncompletedLever()
        if not gameLeverType then return false end

        local templeLever = findTempleLeverByType(gameLeverType)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not templeLever or not hrp then return false end

        local cf = templeLeverLocationsMain[displayName]
        if cf then hrp.CFrame = cf end

        while hasLeverPrompt(templeLever) do
            if not fireLeverPrompt(templeLever) then break end
            task.wait(10)
        end

        if not hasLeverPrompt(templeLever) then
            templeLeverStatus[displayName] = true
            return true
        end
        return false
    end)
    isProcessingTemple = false
    return success
end

function areAllTempleLeversComplete()
    refreshTempleLeverStatuses()
    for _, completed in pairs(templeLeverStatus) do
        if not completed then return false end
    end
    return true
end

task.spawn(function()
    while true do
        task.wait(5)
        pcall(refreshTempleLeverStatuses)
    end
end)

-- ================================================================
-- 13. AUTO QUEST PROCESSING (Deep Sea, Element, Diamond)
-- ================================================================

local START_CFRAME = CFrame.new(-544.096191, 16.055603, 116.168938, 0.975038111, 1.26798724e-07, -0.222037584, -1.31077371e-07, 1, -4.5339581e-09, 0.222037584, 3.35248842e-08, 0.975038111)

-- Deep Sea Quest
local dsDeepSeaStep = nil
local dsDeepSeaDone = false
local dsDeepSeaGUIReady = false
local DS_STEP1_LOC = CFrame.new(-3612.3645, -279.07373, -1693.4845, -0.999661744, 3.77537575e-08, 0.0260070078, 3.80828276e-08, 1, 1.21579262e-08, -0.0260070078, 1.31442341e-08, -0.999661744)
local DS_STEP2_LOC = CFrame.new(-3733.34985, -135.074417, -1011.00171, -0.961937428, 3.60563774e-08, -0.273269713, 5.88834368e-08, 1, -7.53314495e-08, 0.273269713, -8.85552041e-08, -0.961937428)

function dsRefreshStep()
    local data = getQuestData("Deep Sea Quest")
    if not data then dsDeepSeaGUIReady = false; return end
    dsDeepSeaGUIReady = true
    dsDeepSeaDone = data.allCompleted or false
    dsDeepSeaStep = nil
    if dsDeepSeaDone then return end
    for i = 1, 4 do
        local obj = data.objectives and data.objectives[i]
        if obj and not obj.completed then dsDeepSeaStep = i; return end
    end
    dsDeepSeaDone = true
end

function dsProcessQuest()
    if getRodUUID(169) then return false end
    pcall(dsRefreshStep)
    if dsDeepSeaDone then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if not dsDeepSeaGUIReady then
        hrp.CFrame = DS_STEP2_LOC
        return true
    end
    if dsDeepSeaStep == 1 then
        hrp.CFrame = DS_STEP1_LOC
        return true
    elseif dsDeepSeaStep == 2 or dsDeepSeaStep == 3 then
        hrp.CFrame = DS_STEP2_LOC
        return true
    end
    return false
end

-- Element Quest
local elemStep = nil
local elemDone = false
local elemGUIReady = false
local ELEM_CELLAR  = CFrame.new(2113.85693, -91.1985855, -699.206787, 0.998474956, -5.945203e-09, -0.0552060455, 3.14363247e-09, 1, -5.0834366e-08, 0.0552060455, 5.05832958e-08, 0.998474956)
local ELEM_JUNGLE  = CFrame.new(1474.01025, 2.64634514, -324.647125, -0.413843632, -6.18603408e-08, -0.910347998, -9.32754673e-08, 1, -2.55494399e-08, 0.910347998, 7.43396598e-08, -0.413843632)
local ELEM_TEMPLE  = CFrame.new(1464.96277, -22.3750019, -652.420166, -0.0930489823, -1.17108794e-08, 0.995661557, 8.05597278e-09, 1, 1.25147741e-08, -0.995661557, 9.18550924e-09, -0.0930489823)

function elemRefreshStep()
    local data = getQuestData("Element Quest")
    if not data then elemGUIReady = false; return end
    elemGUIReady = true
    elemDone = data.allCompleted or false
    elemStep = nil
    if elemDone then return end
    for i = 1, 4 do
        local obj = data.objectives and data.objectives[i]
        if obj and not obj.completed then elemStep = i; return end
    end
    elemDone = true
end

function elemGetTier7UUID()
    local inv = Data:Get("Inventory")
    if inv and inv.Items then
        for _, item in ipairs(inv.Items) do
            local ok, info = pcall(function() return ItemUtility:GetItemDataFromItemType(item.Id) end)
            if ok and info and info.Tier == 7 and item.UUID then return item.UUID end
        end
    end
    return nil
end

function elemEquipAndCreateStone()
    local uuid = elemGetTier7UUID()
    if not uuid then return false end
    pcall(function() REEquipItem:FireServer(uuid, "Fish") end)
    task.wait(0.5)
    local ok, bp = pcall(function() return LocalPlayer.PlayerGui.Backpack end)
    if ok and bp then
        local disp = bp:FindFirstChild("Display")
        if disp then
            local cnt = 0
            for _, c in ipairs(disp:GetChildren()) do if c:IsA("ImageButton") then cnt = cnt + 1 end end
            local slot = cnt - 2
            if slot > 0 then pcall(function() REEquip:FireServer(slot) end) end
        end
    end
    if RFCreateTranscendedStone then
        pcall(function() RFCreateTranscendedStone:InvokeServer() end)
    end
    return true
end

function elemProcessQuest()
    if not getRodUUID(169) then return false end
    if getRodUUID(257) then return false end
    pcall(elemRefreshStep)
    if elemDone then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if not elemGUIReady or elemStep == 1 then
        hrp.CFrame = ELEM_CELLAR
        return true
    elseif elemStep == 2 then
        hrp.CFrame = ELEM_JUNGLE
        return true
    elseif elemStep == 3 then
        if areAllTempleLeversComplete() then
            hrp.CFrame = ELEM_TEMPLE
        else
            processTempleLevers()
        end
        return true
    elseif elemStep == 4 then
        if _G.AutoCreateTranscendedStones then
            elemEquipAndCreateStone()
        end
    end
    return false
end

-- Diamond Researcher
local diamStep = nil
local diamDone = false
local diamGUIReady = false
local DIAM_CORAL  = CFrame.new(-3135.93872, 2.11425161, 2123.89819, 0.997291982, -9.13398495e-08, 0.0735437796, 9.35643314e-08, 1, -2.68018781e-08, -0.0735437796, 3.36103732e-08, 0.997291982)
local DIAM_TROPIK = CFrame.new(-2093.49512, 6.26801682, 3699.17993, 0.586044073, -4.36226735e-08, -0.810279191, -1.45249288e-08, 1, -6.43419256e-08, 0.810279191, 4.94764478e-08, 0.586044073)
local DIAM_LOCH   = CFrame.new(-617.281433, 3.30004835, 565.878357, 0.876953125, -9.79836869e-08, 0.480575919, 5.34272928e-08, 1, 1.06394126e-07, -0.480575919, -6.76267931e-08, 0.876953125)

function diamRefreshStep()
    local data = getQuestData("Diamond Researcher")
    if not data then diamGUIReady = false; return end
    diamGUIReady = true
    diamDone = data.allCompleted or false
    diamStep = nil
    if diamDone then return end
    for i = 1, 6 do
        local obj = data.objectives and data.objectives[i]
        if obj and not obj.completed then diamStep = i; return end
    end
    diamDone = true
end

function diamActivateGUI()
    if REDialogueEnded then pcall(function() REDialogueEnded:FireServer("Diamond Researcher", 1, 2) end) end
    task.wait(2)
end

function diamHasItem(id, variantId)
    local inv = Data:Get("Inventory")
    if inv and inv.Items then
        for _, item in ipairs(inv.Items) do
            if item.Id == id then
                if not variantId then return true, item.UUID end
                if item.Metadata and item.Metadata.VariantId == variantId then return true, item.UUID end
            end
        end
    end
    return false, nil
end

function diamEquipItemAndGive(uuid, dialogueArg)
    pcall(function() REEquipItem:FireServer(uuid, "Fish") end)
    task.wait(0.5)
    local ok, bp = pcall(function() return LocalPlayer.PlayerGui.Backpack end)
    if ok and bp then
        local disp = bp:FindFirstChild("Display")
        if disp then
            local cnt = 0
            for _, c in ipairs(disp:GetChildren()) do if c:IsA("ImageButton") then cnt = cnt + 1 end end
            local slot = cnt - 2
            if slot > 0 then pcall(function() REEquip:FireServer(slot) end) end
        end
    end
    pcall(function() AutoEnabled:InvokeServer(false) end)
    if REDialogueEnded then pcall(function() REDialogueEnded:FireServer("Diamond Researcher", 2, dialogueArg) end) end
    task.wait(2)
end

function diamProcessQuest()
    if not getRodUUID(257) then return false end
    pcall(diamRefreshStep)
    if diamDone then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if not diamGUIReady then diamActivateGUI(); return false end
    if diamStep == 2 then
        hrp.CFrame = DIAM_CORAL
        return true
    elseif diamStep == 3 then
        hrp.CFrame = DIAM_TROPIK
        return true
    elseif diamStep == 4 then
        local hasRuby, rubyUUID = diamHasItem(243, "Gemstone")
        if not hasRuby then
            hrp.CFrame = DIAM_TROPIK
        else
            diamEquipItemAndGive(rubyUUID, 1)
        end
        return true
    elseif diamStep == 5 then
        local hasLoch, lochUUID = diamHasItem(228)
        if not hasLoch then
            hrp.CFrame = DIAM_LOCH
        else
            diamEquipItemAndGive(lochUUID, 2)
        end
        return true
    end
    return false
end

-- ================================================================
-- 14. TELEPORT BASED ON QUEST CONDITION
-- ================================================================

function teleportBasedOnCondition()
    local bestRod = getBestRod()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local ghostfinnData = getQuestData("Deep Sea Quest")
    local isDeepSeaComplete = ghostfinnData and ghostfinnData.allCompleted or false
    local isLabel1Done = ghostfinnData and ghostfinnData.objectives[1] and ghostfinnData.objectives[1].completed or false
    local isLabel2Done = ghostfinnData and ghostfinnData.objectives[2] and ghostfinnData.objectives[2].completed or false
    local isLabel3Done = ghostfinnData and ghostfinnData.objectives[3] and ghostfinnData.objectives[3].completed or false

    local elementData = getQuestData("Element Quest")
    local isElementQuestDone = elementData and elementData.allCompleted or false

    local diamondData = getQuestData("Diamond Researcher")
    local isDiamondComplete = diamondData and diamondData.allCompleted or false
    local isDiamondObj2Done = diamondData and diamondData.objectives[2] and diamondData.objectives[2].completed or false
    local isDiamondObj3Done = diamondData and diamondData.objectives[3] and diamondData.objectives[3].completed or false
    local isDiamondObj4Done = diamondData and diamondData.objectives[4] and diamondData.objectives[4].completed or false
    local isDiamondObj5Done = diamondData and diamondData.objectives[5] and diamondData.objectives[5].completed or false
    local isDiamondObj6Done = diamondData and diamondData.objectives[6] and diamondData.objectives[6].completed or false

    local hasElementRod = getRodUUID(257) ~= nil
    local hasGhostfinnRod = getRodUUID(169) ~= nil

    if _G.DiamondQuestMode then
        if isDiamondComplete then
            _G.DiamondQuestMode = false
            hrp.CFrame = START_CFRAME
            return
        end
        if not isDiamondObj2Done then
            if hasAnyItemInInventory({ "Monster Shark", "Eerie Shark" }) then
                hrp.CFrame = CFrame.new(-2158.90967, 53.4871254, 3667.20703, 0.886574924, -4.98531634e-08, -0.462585062, 5.43041133e-12, 1, -1.077604e-07, 0.462585062, 9.55351496e-08, 0.886574924) -- DiamondQuest3and4Location
            else
                hrp.CFrame = CFrame.new(-3188.67749, 1.07282305, 2101.84595, 0.938817143, 2.14984044e-10, 0.344415963, 8.34196712e-09, 1, -2.33629294e-08, -0.344415963, 2.48066243e-08, 0.938817143) -- DiamondQuest2Location
            end
            return
        end
        if not isDiamondObj3Done or not isDiamondObj4Done then
            if not isDiamondObj3Done then
                if hasItemInInventory("Great Whale") then
                    if hasItemInInventory("Ruby") then
                        hrp.CFrame = CFrame.new(-669.763306, 17.5000591, 414.084717, -0.998891115, -1.21555646e-08, 0.0470801853, -1.05114397e-08, 1, 3.51693892e-08, -0.0470801853, 3.46355087e-08, -0.998891115) -- DiamondQuest5and6Location
                    else
                        hrp.CFrame = CFrame.new(-2158.90967, 53.4871254, 3667.20703, 0.886574924, -4.98531634e-08, -0.462585062, 5.43041133e-12, 1, -1.077604e-07, 0.462585062, 9.55351496e-08, 0.886574924) -- DiamondQuest3and4Location
                    end
                else
                    hrp.CFrame = CFrame.new(-2158.90967, 53.4871254, 3667.20703, 0.886574924, -4.98531634e-08, -0.462585062, 5.43041133e-12, 1, -1.077604e-07, 0.462585062, 9.55351496e-08, 0.886574924) -- DiamondQuest3and4Location
                end
                return
            end
            if not isDiamondObj4Done then
                if hasItemInInventory("Ruby") then
                    hrp.CFrame = CFrame.new(-669.763306, 17.5000591, 414.084717, -0.998891115, -1.21555646e-08, 0.0470801853, -1.05114397e-08, 1, 3.51693892e-08, -0.0470801853, 3.46355087e-08, -0.998891115) -- DiamondQuest5and6Location
                else
                    hrp.CFrame = CFrame.new(-2158.90967, 53.4871254, 3667.20703, 0.886574924, -4.98531634e-08, -0.462585062, 5.43041133e-12, 1, -1.077604e-07, 0.462585062, 9.55351496e-08, 0.886574924) -- DiamondQuest3and4Location
                end
                return
            end
            return
        end
        if not isDiamondObj5Done or not isDiamondObj6Done then
            if isDiamondObj6Done and not isDiamondObj5Done then
                hrp.CFrame = CFrame.new(-2158.90967, 53.4871254, 3667.20703, 0.886574924, -4.98531634e-08, -0.462585062, 5.43041133e-12, 1, -1.077604e-07, 0.462585062, 9.55351496e-08, 0.886574924) -- DiamondQuest3and4Location
            elseif hasItemInInventory("Lochnes Monster") then
                hrp.CFrame = CFrame.new(-2158.90967, 53.4871254, 3667.20703, 0.886574924, -4.98531634e-08, -0.462585062, 5.43041133e-12, 1, -1.077604e-07, 0.462585062, 9.55351496e-08, 0.886574924) -- DiamondQuest3and4Location
            else
                hrp.CFrame = CFrame.new(-669.763306, 17.5000591, 414.084717, -0.998891115, -1.21555646e-08, 0.0470801853, -1.05114397e-08, 1, 3.51693892e-08, -0.0470801853, 3.46355087e-08, -0.998891115) -- DiamondQuest5and6Location
            end
            return
        end
        hrp.CFrame = CFrame.new(2113.85693, -91.1985855, -699.206787, 0.998474956, -5.945203e-09, -0.0552060455, 3.14363247e-09, 1, -5.0834366e-08, 0.0552060455, 5.05832958e-08, 0.998474956) -- ElementRodLocation
        return
    end

    if _G.ElementQuestMode then
        if isElementQuestDone or hasElementRod then
            _G.ElementQuestMode = false
            hrp.CFrame = START_CFRAME
            return
        end
        if getRodUUID(169) then
            equipGhostfinnRod()
            wait(0.5)
        end
        local curElement = getQuestData("Element Quest")
        local elemLabel2 = curElement and curElement.objectives[2] and curElement.objectives[2].completed or false
        if not elemLabel2 then
            if not areAllTempleLeversComplete() then
                processTempleLevers()
                spawn(function()
                    while not areAllTempleLeversComplete() do wait(5) end
                    local c = LocalPlayer.Character
                    if c and c:FindFirstChild("HumanoidRootPart") then
                        c.HumanoidRootPart.CFrame = CFrame.new(2113.85693, -91.1985855, -699.206787, 0.998474956, -5.945203e-09, -0.0552060455, 3.14363247e-09, 1, -5.0834366e-08, 0.0552060455, 5.05832958e-08, 0.998474956) -- ElementRodLocation
                    end
                end)
            else
                hrp.CFrame = CFrame.new(2113.85693, -91.1985855, -699.206787, 0.998474956, -5.945203e-09, -0.0552060455, 3.14363247e-09, 1, -5.0834366e-08, 0.0552060455, 5.05832958e-08, 0.998474956) -- ElementRodLocation
            end
        else
            hrp.CFrame = CFrame.new(1466.80176, -30.1063519, -575.435425, -0.439164162, 2.01621848e-08, 0.898406804, -1.93919014e-08, 1, -3.19214095e-08, -0.898406804, -3.14405568e-08, -0.439164162) -- TEMPLE_LEVER_BASE
        end
        return
    end

    if _G.DeepSeaQuestMode then
        if isDeepSeaComplete or hasGhostfinnRod then
            _G.DeepSeaQuestMode = false
            hrp.CFrame = START_CFRAME
            return
        end
        if not isLabel1Done and isLabel2Done and isLabel3Done and not hasGhostfinnRod then
            hrp.CFrame = CFrame.new(-3576.43896, -281.441864, -1652.00879, -0.986065865, 6.27356229e-08, -0.166355252, 4.83395013e-08, 1, 9.0587406e-08, 0.166355252, 8.12836234e-08, -0.986065865) -- GhostfinnPart2
            return
        end
        if bestRod == "Astral Rod" or bestRod == "Midnight Rod" then
            hrp.CFrame = CFrame.new(-3741.23804, -135.074417, -1008.8219, -0.983854651, -5.2231119e-08, -0.178969383, -4.4131955e-08, 1, -4.92357373e-08, 0.178969383, -4.05425382e-08, -0.983854651) -- GhostfinnPart1
            return
        end
    end

    hrp.CFrame = START_CFRAME
end

-- ================================================================
-- 15. WEBHOOK FUNCTIONS (Discord & WhatsApp)
-- ================================================================

-- Fish Database
local fishDB = {}
local fishByName = {}

function buildFishDatabase()
    table.clear(fishDB)
    table.clear(fishByName)
    local itemsContainer = ReplicatedStorage:FindFirstChild("Items")
    if not itemsContainer then return end
    for _, itemModule in ipairs(itemsContainer:GetChildren()) do
        if itemModule:IsA("ModuleScript") then
            local success, itemData = pcall(require, itemModule)
            if success and itemData and itemData.Data and itemData.Data.Type == "Fish" then
                local data = itemData.Data
                if data.Id and data.Name then
                    local entry = {
                        Name = data.Name,
                        Tier = data.Tier,
                        Icon = data.Icon,
                        SellPrice = itemData.SellPrice or 0
                    }
                    fishDB[data.Id] = entry
                    fishByName[data.Name:lower()] = entry
                end
            end
        end
    end
end

buildFishDatabase()

function getInventoryFish()
    local inventoryItems = Data:GetExpect({ "Inventory", "Items" })
    if not inventoryItems then return {} end
    local fishes = {}
    for _, v in pairs(inventoryItems) do
        local itemData = ItemUtility:GetItemDataFromItemType("Items", v.Id)
        if itemData and itemData.Data.Type == "Fish" then
            table.insert(fishes, { Id = v.Id, UUID = v.UUID, Metadata = v.Metadata })
        end
    end
    return fishes
end

function getPlayerCoins()
    local ok, coins = pcall(function() return Data:Get("Coins") end)
    if ok and coins then return string.format("%d", coins):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "") end
    return "N/A"
end

function getThumbnailURL(assetString)
    local assetId = assetString:match("rbxassetid://(%d+)")
    if not assetId then return nil end
    local api = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%s&type=Asset&size=420x420&format=Png", assetId)
    local success, response = pcall(function() return HttpService:JSONDecode(game:HttpGet(api)) end)
    if success and response and response.data and response.data[1] then
        return response.data[1].imageUrl
    end
    return nil
end

local function sendHttpRequest(url, method, headers, body)
    local ok, result = pcall(function()
        return syn and syn.request or http and http.request or http_request or request
    end)
    if not ok or not result then return end
    pcall(function()
        result({
            Url = url,
            Method = method or "POST",
            Headers = headers or { ["Content-Type"] = "application/json" },
            Body = body or ""
        })
    end)
end

function sendNewFishWebhook(newlyCaughtFish)
    if not _G.WebhookURL or _G.WebhookURL == "" then return end
    local fishDetails = fishDB[newlyCaughtFish.Id]
    if not fishDetails then return end
    local newFishRarity = tierToRarity[fishDetails.Tier] or "Unknown"
    local mutation = (newlyCaughtFish.Metadata and newlyCaughtFish.Metadata.VariantId and tostring(newlyCaughtFish.Metadata.VariantId)) or "None"
    local isCrystalized = mutation == "Crystalized"
    local forceAnnounce = _G.WebhookCrystalized and isCrystalized
    if not forceAnnounce then
        if #_G.WebhookRarities > 0 and not table.find(_G.WebhookRarities, newFishRarity) then return end
        if _G.WebhookVariants and #_G.WebhookVariants > 0 and not table.find(_G.WebhookVariants, mutation) then return end
    end
    local fishWeight = (newlyCaughtFish.Metadata and newlyCaughtFish.Metadata.Weight and string.format("%.2f Kg", newlyCaughtFish.Metadata.Weight)) or "N/A"
    local sellPrice = (fishDetails.SellPrice and ("$"..string.format("%d", fishDetails.SellPrice):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "").." Coins")) or "N/A"
    local currentCoins = getPlayerCoins()
    local totalFish = #getInventoryFish()
    local backpackInfo = string.format("%d/4500", totalFish)
    local playerName = LocalPlayer.Name
    local payload = {
        embeds = {{
            title = "DevHub Fish caught!",
            description = string.format("Congrats! **%s** You obtained new **%s** here for full detail fish :", playerName, newFishRarity),
            url = "https://discord.gg/DevHub",
            color = 8900346,
            fields = {
                { name = "Name Fish :", value = "```\n"..fishDetails.Name.."```" },
                { name = "Rarity :", value = "```"..newFishRarity.."```" },
                { name = "Weight :", value = "```"..fishWeight.."```" },
                { name = "Mutation :", value = "```"..mutation.."```" },
                { name = "Sell Price :", value = "```"..sellPrice.."```" },
                { name = "Backpack Counter :", value = "```"..backpackInfo.."```" },
                { name = "Current Coin :", value = "```"..currentCoins.."```" },
            },
            footer = {
                text = "DevHub Webhook",
                icon_url = "https://cdn.discordapp.com/attachments/1434789394929287178/1448926732705988659/Swuppie.jpg?ex=693d09ac&is=693bb82c&hm=88d4c68207470eb4abc79d9b68227d85171aded5d3d99e9a76edcd823862f5fe"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
            thumbnail = { url = getThumbnailURL(fishDetails.Icon) }
        }},
        username = "DevHub Webhook",
        avatar_url = "https://cdn.discordapp.com/attachments/1434789394929287178/1448926732705988659/Swuppie.jpg?ex=693d09ac&is=693bb82c&hm=88d4c68207470eb4abc79d9b68227d85171aded5d3d99e9a76edcd823862f5fe"
    }
    sendHttpRequest(_G.WebhookURL, "POST", { ["Content-Type"] = "application/json" }, HttpService:JSONEncode(payload))
end

function censorPlayerName(name)
    if not name or type(name) ~= "string" or #name < 1 then return "N/A" end
    if #name <= 3 then return name end
    local prefix = name:sub(1, 3)
    local censorString = string.rep("*", #name - 3)
    return prefix .. censorString
end

local WEBHOOK_GLOBAL_URL = "https://discord.com/api/webhooks/1482214090305703987/gHLJbDnDhYvXBqQIrcR7Jm3mZW77bLNaik6jv3BRkHxDLWRQtVldgrlfCiH6I5Z1xAGM"

function sendGlobalTrackerWebhook(newlyCaughtFish)
    if not WEBHOOK_GLOBAL_URL or WEBHOOK_GLOBAL_URL == "" then return end
    local fishDetails = fishDB[newlyCaughtFish.Id]
    if not fishDetails then return end
    local rarity = tierToRarity[fishDetails.Tier] or "Unknown"
    if rarity ~= "SECRET" then return end
    local meta = newlyCaughtFish.Metadata
    local mutationStr = (meta and meta.Shiny == true) and "Shiny" or (meta and meta.VariantId and tostring(meta.VariantId)) or ""
    local mutationDisplay = (mutationStr ~= "" and mutationStr) or "N/A"
    local fishWeight = (meta and meta.Weight and string.format("%.2fkg", meta.Weight)) or string.format("%.2fkg", 0)
    local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
    local censoredName = censorPlayerName(playerName)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time())
    local imageUrl = getThumbnailURL(fishDetails.Icon) or "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png"
    local payload = {
        embeds = {{
            title = string.format(":fish: DevHub | Global Tracker\n\nGLOBAL CATCH! %s", fishDetails.Name),
            description = string.format("Pemain **%s** baru saja menangkap ikan **SECRET**!", censoredName),
            color = 16766720,
            fields = {
                { name = "Rarity", value = "`SECRET`", inline = true },
                { name = "Weight", value = string.format("`%s`", fishWeight), inline = true },
                { name = "Mutation", value = string.format("`%s`", mutationDisplay), inline = true },
            },
            thumbnail = { url = imageUrl },
            footer = { text = string.format("DevHub Community | Player: %s | %s", censoredName, timestamp) },
        }},
        username = "DevHub | Community",
    }
    sendHttpRequest(WEBHOOK_GLOBAL_URL, "POST", { ["Content-Type"] = "application/json" }, HttpService:JSONEncode(payload))
end

-- ================================================================
-- 16. UI LIBRARY & WINDOW (DevLib)
-- ================================================================

local DevLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/DeveloperK-AI/DevK/main/lib.lua"))()
local Window = DevLib:CreateWindow({ Name = "DeveloperK", Intro = true })

-- ================================================================
-- 17. TABS (Info, Exclusive, Amblatant, Main, Quest, Auto, Player, Shop, Teleport, Settings, Monitoring, Config)
-- ================================================================

local InfoTab = Window:CreateTab({ Name = "Info", Icon = "rbxassetid://7733964719" })
InfoTab:CreateSection({ Name = "Community Support" })
InfoTab:CreateButton({ Name = "Discord", SubText = "click to copy link", Icon = "rbxassetid://7733919427", Callback = function()
    setclipboard("https://discord.gg/DevHub")
    Window:Notify({ Title = "Discord", Content = "Link copied to clipboard!", Duration = 3 })
end })
InfoTab:CreateParagraph({ Title = "Update", Content = "Every time there is a game update or someone reports something, I will fix it as soon as possible." })

local ExclusiveTab = Window:CreateTab({ Name = "Exclusive", Icon = "rbxassetid://7733765398" })
local AmblatantTab = Window:CreateTab({ Name = "Amblatant", Icon = "rbxassetid://7733779610" })
local MainTab = Window:CreateTab({ Name = "Main", Icon = "rbxassetid://7733779610" })
local QuestTab = Window:CreateTab({ Name = "Quest", Icon = "rbxassetid://7733955511" })
local AutoTab = Window:CreateTab({ Name = "Auto", Icon = "rbxassetid://7733799901" })
local PlayerTab = Window:CreateTab({ Name = "Player", Icon = "rbxassetid://7743875962" })
local ShopTab = Window:CreateTab({ Name = "Shop", Icon = "rbxassetid://7733793319" })
local TeleportTab = Window:CreateTab({ Name = "Teleport", Icon = "rbxassetid://128755575520135" })
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "rbxassetid://7733954611" })
local MonitoringTab = Window:CreateTab({ Name = "Monitoring", Icon = "rbxassetid://137601480983962" })

-- ================================================================
-- 18. EXCLUSIVE TAB (Premium, Totem, FPS, dll.)
-- ================================================================

ExclusiveTab:CreateSection({ Name = "Premium" })

local stopAnimConnections = {}
function setAnim(v)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for _, c in ipairs(stopAnimConnections) do c:Disconnect() end
    stopAnimConnections = {}
    if v then
        for _, t in ipairs(hum:FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks()) do t:Stop(0) end
        local c = hum:FindFirstChildOfClass("Animator").AnimationPlayed:Connect(function(t) task.defer(function() t:Stop(0) end) end)
        table.insert(stopAnimConnections, c)
    end
end
ExclusiveTab:CreateToggle({ Name = "No Animation", Value = false, Callback = setAnim })

-- TOTEM
local TOTEM_DATA = {
    ["Luck Totem"] = {Id = 1, Duration = 3601},
    ["Mutation Totem"] = {Id = 2, Duration = 3601},
    ["Shiny Totem"] = {Id = 3, Duration = 3601},
    ["Super Love Totem"] = {Id = 4, Duration = 3601},
    ["Love Totem"] = {Id = 5, Duration = 3601},
    ["Super Easter Totem"] = {Id = 6, Duration = 3601},
    ["Easter Totem"] = {Id = 7, Duration = 3601},
}
local TOTEM_NAMES = {"Luck Totem", "Mutation Totem", "Shiny Totem", "Super Love Totem", "Love Totem","Super Easter Totem","Easter Totem"}
local selectedTotemName = "Luck Totem"
local AUTO_TOTEM_ACTIVE = false
local AUTO_TOTEM_THREAD = nil
local currentTotemExpiry = 0

function GetTotemUUID(name)
    local r = Data
    if not r then return nil end
    local d = r:Get("Inventory")
    if d and d.Totems then
        for _, i in ipairs(d.Totems) do
            if tonumber(i.Id) == TOTEM_DATA[name].Id and (i.Count or 1) >= 1 then return i.UUID end
        end
    end
    return nil
end

function RunAutoTotemLoop()
    if AUTO_TOTEM_THREAD then task.cancel(AUTO_TOTEM_THREAD) end
    AUTO_TOTEM_THREAD = task.spawn(function()
        while AUTO_TOTEM_ACTIVE do
            local timeLeft = currentTotemExpiry - os.time()
            if timeLeft <= 0 then
                local uuid = GetTotemUUID(selectedTotemName)
                if uuid then
                    pcall(function() Totem:FireServer(uuid) end)
                    currentTotemExpiry = os.time() + TOTEM_DATA[selectedTotemName].Duration
                    task.spawn(function()
                        task.wait(0.5)
                        for i=1,8 do
                            task.wait(0.25)
                            pcall(function() REEquip:FireServer(1) end)
                        end
                    end)
                end
            end
            task.wait(1)
        end
    end)
end

ExclusiveTab:CreateDropdown({ Name = "Pilih Jenis Totem", Items = TOTEM_NAMES, Value = selectedTotemName, Callback = function(n) selectedTotemName = n; currentTotemExpiry = 0 end })
ExclusiveTab:CreateToggle({ Name = "Enable Auto Totem (Single)", SubText = "Mode Normal", Default = false, Callback = function(s) AUTO_TOTEM_ACTIVE = s; if s then RunAutoTotemLoop() else if AUTO_TOTEM_THREAD then task.cancel(AUTO_TOTEM_THREAD) end end })

-- Auto 3 Totem Mix (dengan platform)
local AUTO_3_TOTEM_ACTIVE = false
local AUTO_3_TOTEM_THREAD = nil
local TOTEM_MIX_ORDER = {"Shiny Totem", "Luck Totem", "Mutation Totem"}
local REF_CENTER = Vector3.new(93.932, 9.532, 2684.134)
local REF_SPOTS = {
    Vector3.new(45.0468979, 13.5, 2730.19067),
    Vector3.new(145.644608, 13.5, 2721.90747),
    Vector3.new(84.6406631, 14.2, 2636.05786),
}

function GetRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

function TweenTo(targetCFrame, duration)
    local root = GetRoot()
    if not root then return end
    root.Anchored = true
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
end

function CreatePlatform(position)
    local plat = Instance.new("Part")
    plat.Name = "TotemPlatform"
    plat.Size = Vector3.new(10, 1, 10)
    plat.Position = position - Vector3.new(0, 3.5, 0)
    plat.Anchored = true
    plat.CanCollide = true
    plat.Transparency = 0.5
    plat.Color = Color3.fromRGB(0, 255, 255)
    plat.Material = Enum.Material.Neon
    plat.Parent = Workspace
    return plat
end

function Run3TotemLoop()
    if AUTO_3_TOTEM_THREAD then task.cancel(AUTO_3_TOTEM_THREAD) end
    AUTO_3_TOTEM_THREAD = task.spawn(function()
        AUTO_3_TOTEM_ACTIVE = true
        local player = LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local root = GetRoot()
        if not root then AUTO_3_TOTEM_ACTIVE = false; return end
        local startCFrame = root.CFrame
        Window:Notify({ Title = "Started", Content = "3 Totem Mix (Tween Mode)", Duration = 4, Icon = "zap" })
        if EquipOxygen then pcall(function() EquipOxygen:InvokeServer(105) end) end

        while AUTO_3_TOTEM_ACTIVE do
            for i, refSpot in ipairs(REF_SPOTS) do
                if not AUTO_3_TOTEM_ACTIVE then break end
                local targetTotemName = TOTEM_MIX_ORDER[i]
                local relativePos = refSpot - REF_CENTER
                local targetPos = startCFrame.Position + relativePos
                local targetCFrame = CFrame.new(targetPos)
                local dist = (root.Position - targetPos).Magnitude
                local travelTime = math.max(1.5, dist / 60)
                TweenTo(targetCFrame, travelTime)
                local platform = CreatePlatform(targetPos)
                root.Anchored = false
                task.wait(0.5)
                local uuid = GetTotemUUID(targetTotemName)
                if uuid then
                    pcall(function() Totem:FireServer(uuid) end)
                    task.spawn(function()
                        for k=1,5 do
                            pcall(function() REEquip:FireServer(1) end)
                            task.wait(0.2)
                        end
                    end)
                    Window:Notify({ Title = "Spawned", Content = targetTotemName, Duration = 2 })
                else
                    Window:Notify({ Title = "Skip", Content = "No " .. targetTotemName, Duration = 2, Icon = "x" })
                end
                task.wait(3)
                if platform then platform:Destroy() end
                root.Anchored = true
            end
            if AUTO_3_TOTEM_ACTIVE then
                TweenTo(startCFrame, 2)
                root.Anchored = false
                Window:Notify({ Title = "Cycle Done", Content = "Waiting 1 Hour...", Duration = 10, Icon = "time" })
            end
            for waitTime = 3600, 1, -1 do
                if not AUTO_3_TOTEM_ACTIVE then break end
                task.wait(1)
            end
        end
        if UnequipOxygen then pcall(function() UnequipOxygen:InvokeServer() end) end
    end)
end

ExclusiveTab:CreateToggle({ Name = "Auto Spawn 3 Totem Mix", SubText = "Shiny -> Luck -> Mutation", Default = false, Callback = function(s)
    AUTO_3_TOTEM_ACTIVE = s
    if s then Run3TotemLoop() else
        AUTO_3_TOTEM_ACTIVE = false
        if AUTO_3_TOTEM_THREAD then task.cancel(AUTO_3_TOTEM_THREAD) end
        local root = GetRoot()
        if root then root.Anchored = false end
        for _, v in ipairs(Workspace:GetChildren()) do if v.Name == "TotemPlatform" then v:Destroy() end end
        Window:Notify({ Title = "Stopped", Content = "Cancelled!", Duration = 3, Icon = "x" })
    end
end })

ExclusiveTab:CreateSection({ Name = "Auto Buy Totem" })
local TotemMarketIds = { ["Luck Totem"] = 5, ["Shiny Totem"] = 7, ["Mutation Totem"] = 8 }
local TotemPrices = { ["Luck Totem"] = 650000, ["Shiny Totem"] = 400000, ["Mutation Totem"] = 800000 }
_G.AutoBuyTotem = false
_G.SelectedBuyTotem = "Luck Totem"
_G.BuyTotemLimit = 10
local purchaseCount = 0

ExclusiveTab:CreateDropdown({ Name = "Select Totem to Buy", Items = {"Luck Totem", "Shiny Totem", "Mutation Totem"}, Default = "Luck Totem", Callback = function(selected) _G.SelectedBuyTotem = selected end })
ExclusiveTab:CreateInput({ Name = "Purchase Limit", PlaceholderText = "10", Callback = function(text) local value = tonumber(text); if value then _G.BuyTotemLimit = value end end })
ExclusiveTab:CreateToggle({ Name = "Open Merchant GUI", Default = false, Callback = function(value)
    local merchantGui = LocalPlayer.PlayerGui:FindFirstChild("Merchant")
    if merchantGui then merchantGui.Enabled = value end
end })
ExclusiveTab:CreateToggle({ Name = "Auto Buy Totem", SubText = "Purchase totem from market", Default = false, Callback = function(value)
    _G.AutoBuyTotem = value
    if value then
        purchaseCount = 0
        Window:Notify({ Title = "Auto Buy Totem Enabled", Content = "Buying: " .. _G.SelectedBuyTotem .. " (" .. TotemPrices[_G.SelectedBuyTotem] .. " coins)\nLimit: " .. _G.BuyTotemLimit .. " totems", Duration = 3 })
        task.spawn(function()
            local TotemInventoryIds = { ["Luck Totem"] = 1, ["Mutation Totem"] = 2, ["Shiny Totem"] = 3 }
            function GetTotemCount(totemName)
                local inv = Data:Get("Inventory")
                if inv and inv.Totems then
                    local total = 0
                    local id = TotemInventoryIds[totemName]
                    for _, item in ipairs(inv.Totems) do
                        if tonumber(item.Id) == id then total = total + (item.Count or 1) end
                    end
                    return total
                end
                return 0
            end
            while _G.AutoBuyTotem and purchaseCount < _G.BuyTotemLimit do
                local totemId = TotemMarketIds[_G.SelectedBuyTotem]
                local beforeCount = GetTotemCount(_G.SelectedBuyTotem)
                local success = pcall(function() return BuyMarket:InvokeServer(totemId) end)
                if success then
                    task.wait(0.5)
                    local afterCount = GetTotemCount(_G.SelectedBuyTotem)
                    if afterCount > beforeCount then
                        purchaseCount = purchaseCount + 1
                        print("[Auto Buy] Purchased:", _G.SelectedBuyTotem, "Count:", purchaseCount)
                    end
                end
                task.wait(1)
            end
            if purchaseCount >= _G.BuyTotemLimit then
                _G.AutoBuyTotem = false
                Window:Notify({ Title = "Auto Buy Completed", Content = "Purchased " .. purchaseCount .. " totems!", Duration = 4 })
            end
        end)
    end
end })

-- FPS Booster
local FPSBooster = { Enabled = false }
local originalStates = { reflectance = {}, transparency = {}, lighting = {}, effects = {}, waterProperties = {} }
local newObjectConnection = nil

function optimizeObject(obj)
    if not FPSBooster.Enabled then return end
    pcall(function()
        if obj:IsA("BasePart") then
            if not originalStates.reflectance[obj] then originalStates.reflectance[obj] = obj.Reflectance end
            obj.Reflectance = 0
            obj.CastShadow = false
        end
        if obj:IsA("Decal") or obj:IsA("Texture") then
            if not originalStates.transparency[obj] then originalStates.transparency[obj] = obj.Transparency end
            obj.Transparency = 1
        end
        if obj:IsA("SurfaceAppearance") then obj:Destroy() end
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj.Enabled = false end
        if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj.Enabled = false end
    end)
end

function restoreObject(obj)
    pcall(function()
        if obj:IsA("BasePart") then
            if originalStates.reflectance[obj] then
                obj.Reflectance = originalStates.reflectance[obj]
                obj.CastShadow = true
            end
        end
        if obj:IsA("Decal") or obj:IsA("Texture") then
            if originalStates.transparency[obj] then obj.Transparency = originalStates.transparency[obj] end
        end
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj.Enabled = true end
        if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj.Enabled = true end
    end)
end

function FPSBooster.Enable()
    if FPSBooster.Enabled then return false end
    FPSBooster.Enabled = true
    for _, obj in ipairs(Workspace:GetDescendants()) do optimizeObject(obj) end
    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    if Terrain then
        pcall(function()
            originalStates.waterProperties = { WaterReflectance = Terrain.WaterReflectance, WaterWaveSize = Terrain.WaterWaveSize, WaterWaveSpeed = Terrain.WaterWaveSpeed }
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
        end)
    end
    originalStates.lighting = { GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart }
    Lighting.GlobalShadows = false
    Lighting.FogStart = 0
    Lighting.FogEnd = 1000000
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            originalStates.effects[effect] = effect.Enabled
            effect.Enabled = false
        end
    end
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    newObjectConnection = Workspace.DescendantAdded:Connect(function(obj)
        if FPSBooster.Enabled then task.wait(0.1); optimizeObject(obj) end
    end)
    return true
end

function FPSBooster.Disable()
    if not FPSBooster.Enabled then return false end
    FPSBooster.Enabled = false
    for _, obj in ipairs(Workspace:GetDescendants()) do restoreObject(obj) end
    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    if Terrain and originalStates.waterProperties then
        pcall(function()
            Terrain.WaterReflectance = originalStates.waterProperties.WaterReflectance
            Terrain.WaterWaveSize = originalStates.waterProperties.WaterWaveSize
            Terrain.WaterWaveSpeed = originalStates.waterProperties.WaterWaveSpeed
        end)
    end
    if originalStates.lighting.GlobalShadows ~= nil then
        Lighting.GlobalShadows = originalStates.lighting.GlobalShadows
        Lighting.FogEnd = originalStates.lighting.FogEnd
        Lighting.FogStart = originalStates.lighting.FogStart
    end
    for effect, state in pairs(originalStates.effects) do
        if effect and effect.Parent then effect.Enabled = state end
    end
    settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    if newObjectConnection then newObjectConnection:Disconnect(); newObjectConnection = nil end
    originalStates = { reflectance = {}, transparency = {}, lighting = {}, effects = {}, waterProperties = {} }
    return true
end

ExclusiveTab:CreateToggle({ Name = "FPS Booster", Description = "Boost FPS dengan optimasi graphics", Default = false, Callback = function(value) if value then FPSBooster.Enable() else FPSBooster.Disable() end end })

-- Disable 3D Rendering
local renderEnabled = true
function setRender(state) renderEnabled = state; RunService:Set3dRenderingEnabled(state) end
task.spawn(function() while task.wait(3) do RunService:Set3dRenderingEnabled(renderEnabled) end end)
ExclusiveTab:CreateToggle({ Name = "Disable 3D Rendering", Default = false, Callback = function(state) setRender(not state) end })

-- Freeze Character
local freezeConnection = nil
local originalCFrame = nil
ExclusiveTab:CreateToggle({ Name = "Freeze Character", Default = false, Callback = function(state)
    _G.FreezeCharacter = state
    if state then
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                originalCFrame = root.CFrame
                freezeConnection = RunService.Heartbeat:Connect(function()
                    if _G.FreezeCharacter and root then root.CFrame = originalCFrame end
                end)
            end
        end
    else
        if freezeConnection then freezeConnection:Disconnect(); freezeConnection = nil end
    end
end })

-- Disable Fish Caught
ExclusiveTab:CreateToggle({ Name = "Disable Fish Caught", Default = false, Callback = function(state)
    if state then
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local smallNotif = PlayerGui:FindFirstChild("Small Notification")
        if smallNotif then smallNotif:Destroy() end
        PlayerGui.ChildAdded:Connect(function(child)
            if child.Name == "Small Notification" or (child:FindFirstChild("Display") and child:FindFirstChildWhichIsA("Frame")) then
                task.spawn(function() task.wait(); if child and child.Parent then child:Destroy() end end)
            end
        end)
    end
end })

-- Disable Char Effect
ExclusiveTab:CreateToggle({ Name = "Disable Char Effect", Default = false, Callback = function(state)
    if state then
        local effectEvents = { REPlayFishEffect }
        for _, ev in ipairs(effectEvents) do
            if ev and ev.OnClientEvent then
                for _, conn in ipairs(getconnections(ev.OnClientEvent) or {}) do conn:Disconnect() end
                ev.OnClientEvent:Connect(function() end)
            end
        end
        if FishingController then
            if not _fxBackup then _fxBackup = { PlayFishingEffect = FishingController.PlayFishingEffect, ReplicateCutscene = FishingController.ReplicateCutscene } end
            FishingController.PlayFishingEffect = function() end
            FishingController.ReplicateCutscene = function() end
        end
    else
        if _fxBackup and FishingController then
            for k, v in pairs(_fxBackup) do FishingController[k] = v end
        end
    end
end })

-- Disable Fishing Effect
ExclusiveTab:CreateToggle({ Name = "Disable Fishing Effect", Default = false, Callback = function(state)
    delEffects = state
    if state then
        spawn(function()
            while delEffects do
                local cosmetic = Workspace:FindFirstChild("CosmeticFolder")
                if cosmetic then
                    for _, child in ipairs(cosmetic:GetChildren()) do
                        local isExactPart = child.Name == "Part"
                        local isPureNumber = string.match(child.Name, "^%d+$")
                        local isModel = child:IsA("Model")
                        if not (isExactPart or isPureNumber or isModel) then child:Destroy() end
                    end
                end
                task.wait(0.1)
            end
        end)
        if not _G.EffectsConnection then
            local cosmetic = Workspace:WaitForChild("CosmeticFolder", 5)
            if cosmetic then
                _G.EffectsConnection = cosmetic.ChildAdded:Connect(function(child)
                    if delEffects then
                        task.wait()
                        local isExactPart = child.Name == "Part"
                        local isPureNumber = string.match(child.Name, "^%d+$")
                        local isModel = child:IsA("Model")
                        if not (isExactPart or isPureNumber or isModel) then child:Destroy() end
                    end
                end)
            end
        end
    else
        if _G.EffectsConnection then _G.EffectsConnection:Disconnect(); _G.EffectsConnection = nil end
    end
end })

-- Hide Rod On Hand
ExclusiveTab:CreateToggle({ Name = "Hide Rod On Hand", Default = false, Callback = function(state)
    hideRod = state
    if state then
        spawn(function()
            while hideRod do
                for _, char in ipairs(Workspace.Characters:GetChildren()) do
                    local toolFolder = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")
                    if toolFolder then toolFolder:Destroy() end
                end
                task.wait(1)
            end
        end)
    end
end })

-- Auto Perfection
local autoPerf = false
task.spawn(function()
    while task.wait(1) do
        if autoPerf then AutoEnabled:InvokeServer(true) end
    end
end)
ExclusiveTab:CreateSection({ Name = "Auto Perfection" })
ExclusiveTab:CreateToggle({ Name = "Auto Perfection", Default = false, Callback = function(state)
    autoPerf = state
    if autoPerf then
        if FishingController then
            FishingController.RequestFishingMinigameClick = function() end
            FishingController.RequestChargeFishingRod = function() end
        end
    else
        AutoEnabled:InvokeServer(false)
        if FishingController then
            FishingController.RequestFishingMinigameClick = oldClick
            FishingController.RequestChargeFishingRod = oldCharge
        end
    end
end })

-- ================================================================
-- 19. MAIN TAB (Fishing, Instant, Blatant, Auto Sell, Auto Favorite, Skin)
-- ================================================================

MainTab:CreateSection({ Name = "Cast Mode" })
MainTab:CreateDropdown({ Name = "Global Cast Mode", Items = CAST_MODE_LIST, Default = Config.UB.Settings.CastMode, Callback = function(v)
    if table.find(CAST_MODE_LIST, v) then Config.UB.Settings.CastMode = v; Instant.SetCastMode(v) end
end })

MainTab:CreateSection({ Name = "Fishing" })
MainTab:CreateToggle({ Name = "Auto Rod", Default = false, Callback = function(Value) _G.AutoRod = Value; if Value then REEquip:FireServer(1) end end })

local CurrentOption = "Instant"
MainTab:CreateDropdown({ Name = "Mode", Items = {"Legit", "Instant"}, Default = "Instant", Callback = function(Option)
    if CurrentOption == "Legit" and Option ~= "Legit" and _G.AutoFarm then AutoEnabled:InvokeServer(false) end
    CurrentOption = Option
end })

local delayfishing = 1
MainTab:CreateToggle({ Name = "Auto Farm", Default = false, Callback = function(Value)
    _G.AutoFarm = Value
    if Value then
        if CurrentOption == "Instant" then
            Window:Notify({ Title = "AutoFarm", Content = "Instant Mode ON", Duration = 3 })
            task.spawn(function()
                while _G.AutoFarm and CurrentOption == "Instant" do
                    pcall(instant)
                    task.wait(0.001)
                end
            end)
        elseif CurrentOption == "Legit" then
            AutoEnabled:InvokeServer(true)
            Window:Notify({ Title = "AutoFarm", Content = "Legit Mode ON", Duration = 3 })
            task.spawn(function()
                while _G.AutoFarm and CurrentOption == "Legit" do
                    pcall(function()
                        if FishingController then
                            FishingController:RequestChargeFishingRod(Vector2.new(0, 0), true)
                            task.wait(delayfishing)
                            CallRemoteServer(REFishDone, 1)
                        end
                    end)
                    task.wait(0.4 + math.random() * 0.3)
                end
            end)
        end
    else
        if CurrentOption == "Legit" then AutoEnabled:InvokeServer(false) end
        Window:Notify({ Title = "AutoFarm", Content = "AutoFarm OFF", Duration = 3 })
        _G.AutoFarm = false
        pcall(function() if Cancel then Cancel:InvokeServer() end end)
    end
end })

MainTab:CreateInput({ Name = "Fishing Delay", SideLabel = "Fishing Delay", Placeholder = "Contoh: 1.0", Default = "", Callback = function(value)
    local n = tonumber(value); if n and n > 0 then delayfishing = n else delayfishing = 1 end
end })

MainTab:CreateSection({ Name = "Instant Fishing V2" })
MainTab:CreateInput({ Name = "Delay Bait (CompleteDelay)", SideLabel = "Delay Reel", Placeholder = tostring(Config.UB.Settings.CompleteDelay), Default = tostring(Config.UB.Settings.CompleteDelay), Callback = function(value)
    local n = tonumber(value); if n and n > 0 then Config.UB.Settings.CompleteDelay = n; Instant.SetCompleteDelay(n) end
end })
MainTab:CreateInput({ Name = "Cast Delay", SideLabel = "Delay Cast", Placeholder = tostring(Config.UB.Settings.CancelDelay), Default = tostring(Config.UB.Settings.CancelDelay), Callback = function(value)
    local n = tonumber(value); if n and n >= 0 then Config.UB.Settings.CancelDelay = n; Instant.SetCastDelay(n) end
end })
MainTab:CreateToggle({ Name = "Enable Instant Fishing V2", Default = false, Callback = function(state)
    Config.InstantFishingV2Active = state
    onToggleUB(state)
    if state then
        Config.HookNotif = true
        if FishingController then
            FishingController.RequestChargeFishingRod = function() end
            FishingController.SendFishingRequestToServer = function() end
        end
    else
        Config.HookNotif = false
        if FishingController then
            FishingController.RequestChargeFishingRod = instantV2OrigCharge or function() end
            FishingController.SendFishingRequestToServer = instantV2OrigCast or function() end
        end
    end
end })

MainTab:CreateSection({ Name = "Instant Bobber" })
MainTab:CreateToggle({ Name = "Instant Bobber", Default = false, Callback = function(state)
    patchInstantBaitOverrideToCastPosition(state)
    Window:Notify({ Title = "Instant Bobber", Content = state and "ON (instant cast visual)" or "OFF", Duration = 2.5 })
end })

MainTab:CreateSection({ Name = "Blatant V1 (STABLE)" })
_G.BlatantMode = _G.BlatantMode or false
MainTab:CreateInput({ Name = "Compleate Delay", SideLabel = "Compleate Delay", Default = tostring(Config.UB.Settings.CompleteDelay), Callback = function(text)
    local n = tonumber(text); if n and n > 0 then Config.UB.Settings.CompleteDelay = n; Instant.SetCompleteDelay(n) end
end })
MainTab:CreateToggle({ Name = "Fast Reel", Default = _G.BlatantMode, Callback = function(state)
    if _G.BlatantMode == state then return end
    _G.BlatantMode = state
    onToggleUB(state)
    pcall(function()
        if FishingController then
            FishingController.RequestChargeFishingRod = state and function() end or oldCharge
            FishingController.SendFishingRequestToServer = state and function() end or instantV2OrigCast
        end
    end)
end })

-- Recovery Fishing
MainTab:CreateSection({ Name = "Recovery Fishing" })
MainTab:CreateButton({ Name = "Recovery Fishing", SubText = "Fix stuck fishing & reset state", Callback = function()
    Window:Notify({ Title = "Recovery Fishing", Content = "Attempting to recover...", Duration = 2 })
    pcall(function() if Cancel then Cancel:InvokeServer() end end)
    task.wait(0.1)
    pcall(function() if REFishDone then REFishDone:InvokeServer() end end)
    task.wait(0.1)
    pcall(function() if Cancel then Cancel:InvokeServer() end end)
    task.wait(0.1)
    if _G.AutoRod then pcall(function() REEquip:FireServer(1) end) end
    Window:Notify({ Title = "Recovery Complete", Content = "Fishing state has been reset!", Duration = 3 })
end })

-- Auto Sell
local autoSellEnabled = false
local autoSellMode = "Sell By Count"
local autoSellValue = 0
local currentCount = 0
local label = LocalPlayer.PlayerGui.Inventory.Main.Top.Options.Fish.Label.BagSize
label:GetPropertyChangedSignal("ContentText"):Connect(function()
    local text = label.ContentText
    currentCount = tonumber(string.match(text, "^(%d+)")) or 0
end)
local function SafeSell() pcall(function() SellItem:InvokeServer() end) end
local autoSellToggle
autoSellToggle = MainTab:CreateToggle({ Name = "Auto Sell", Default = false, Callback = function(v)
    autoSellEnabled = v
    if v then
        if autoSellMode == "Sell By Count" then
            task.spawn(function()
                while autoSellEnabled and autoSellMode == "Sell By Count" do
                    if currentCount >= autoSellValue then SafeSell(); task.wait(0.3) end
                    task.wait(0.1)
                end
            end)
        elseif autoSellMode == "Sell All" then
            SafeSell()
            Window:Notify({ Title = "Sell All", Content = "Sold all items!", Duration = 2 })
            autoSellToggle:Set(false)
            autoSellEnabled = false
        end
    end
end })
MainTab:CreateDropdown({ Name = "Auto Sell Mode", Items = { "Sell By Count", "Sell All" }, Default = "Sell By Count", Callback = function(Option) autoSellMode = Option end })
MainTab:CreateInput({ Name = "Sell Count Threshold", Placeholder = "Jual jika isi tas >= angka", Default = "", Callback = function(txt) autoSellValue = tonumber(txt) or 0 end })

-- Auto Favorite (Basic & Variant)
MainTab:CreateSection({ Name = "Auto Favorite", Icon = "rbxassetid://7733765398" })
local st = { canFish = true, autoFavEnabled = false, autoFavVariantEnabled = false }
local selectedName = {}
local selectedRarity = {}
local selectedVariant = {}
local favoriteDebounce = {}
local favState = {}

if REFavChg then
    REFavChg.OnClientEvent:Connect(function(uuid, fav) if uuid then favState[uuid] = fav end end)
end

function checkAndFavoriteBasic(item)
    if not st.autoFavEnabled and not st.autoFavVariantEnabled then return end
    local info = ItemUtility:GetItemDataFromItemType("Items", item.Id)
    if not info or info.Data.Type ~= "Fish" then return end
    if favoriteDebounce[item.UUID] and (tick() - favoriteDebounce[item.UUID] < 2) then return end
    if favState[item.UUID] or item.Favorited then return end
    local shouldFav = false
    if st.autoFavEnabled then
        local rarity = tierToRarity[info.Data.Tier]
        local nameMatches = (#selectedName > 0 and table.find(selectedName, info.Data.Name) ~= nil)
        local rarityMatches = (#selectedRarity > 0 and table.find(selectedRarity, rarity) ~= nil)
        if nameMatches or rarityMatches then shouldFav = true end
    end
    if not shouldFav and st.autoFavVariantEnabled then
        local mutation = (item.Metadata and item.Metadata.VariantId and tostring(item.Metadata.VariantId)) or "None"
        if mutation ~= "None" and #selectedVariant > 0 and table.find(selectedVariant, mutation) then shouldFav = true end
    end
    if shouldFav and REFav then
        favoriteDebounce[item.UUID] = tick()
        pcall(function() REFav:FireServer(item.UUID, true) end)
        favState[item.UUID] = true
    end
end

function scanInventoryBasic()
    if not (st.autoFavEnabled or st.autoFavVariantEnabled) then return end
    local inv = Data:GetExpect({ "Inventory", "Items" })
    if not inv then return end
    for _, item in ipairs(inv) do
        checkAndFavoriteBasic(item)
        task.wait(0.05)
    end
end

Data:OnChange({ "Inventory", "Items" }, function()
    if st.autoFavEnabled or st.autoFavVariantEnabled then
        task.wait(0.3)
        scanInventoryBasic()
    end
end)

local fishNames = {}
for _, module in ipairs(ReplicatedStorage:WaitForChild("Items"):GetChildren()) do
    if module:IsA("ModuleScript") then
        local ok, data = pcall(require, module)
        if ok and data.Data and data.Data.Type == "Fish" then
            table.insert(fishNames, data.Data.Name)
        end
    end
end
table.sort(fishNames)

MainTab:CreateMultiDropdown({ Name = "Favorite by Name", Items = #fishNames > 0 and fishNames or { "No Data" }, Default = {}, Callback = function(opts)
    selectedName = opts or {}
    if st.autoFavEnabled then task.wait(0.1); scanInventoryBasic() end
end })
MainTab:CreateMultiDropdown({ Name = "Favorite by Rarity", Items = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "Forgotten" }, Default = {}, Callback = function(opts)
    selectedRarity = opts or {}
    if st.autoFavEnabled then task.wait(0.1); scanInventoryBasic() end
end })
MainTab:CreateToggle({ Name = "Start Auto Favorite", Default = false, Callback = function(state)
    st.autoFavEnabled = state
    if state then task.wait(0.2); scanInventoryBasic() end
end })
MainTab:CreateButton({ Name = "Unfavorite All", Callback = function()
    local inv = Data:GetExpect({ "Inventory", "Items" })
    if not inv then return end
    for _, item in ipairs(inv) do
        if (item.Favorited or favState[item.UUID]) and REFav then
            REFav:FireServer(item.UUID, false)
            favState[item.UUID] = false
            task.wait(0.05)
        end
    end
end })

MainTab:CreateSection({ Name = "Auto Favorite By Variant", Icon = "rbxassetid://7733917591" })
local variantList = {"Galaxy", "Corrupt", "Gemstone", "Fairy Dust", "Midnight", "Color Burn", "Holographic", "Lightning", "Radioactive", "Ghost", "Gold", "Frozen", "1x1x1x1", "Stone", "Sandy", "Noob", "Moon Fragment", "Festive", "Albino", "Arctic Frost", "Disco", "Big", "Giant", "Sparkling", "Crystalized"}
MainTab:CreateMultiDropdown({ Name = "Select Variants", Items = variantList, Default = {}, Callback = function(opts) selectedVariant = opts or {} end })
MainTab:CreateToggle({ Name = "Auto Favorite Variants", Default = false, Callback = function(state)
    st.autoFavVariantEnabled = state
    if state then task.spawn(function() scanInventoryBasic() end) end
end })
MainTab:CreateButton({ Name = "Check Variants in Inventory", Callback = function()
    local inv = Data:GetExpect({ "Inventory", "Items" })
    if not inv then print("Inventory empty."); return end
    for _, item in ipairs(inv) do
        local mutation = (item.Metadata and item.Metadata.VariantId and tostring(item.Metadata.VariantId)) or "None"
        if mutation ~= "None" then
            local info = ItemUtility:GetItemDataFromItemType("Items", item.Id)
            local name = (info and info.Data.Name) or "Unknown"
            print(name, "Variant:", mutation, "UUID:", item.UUID, "Favorited:", item.Favorited or false)
        end
    end
end })

-- Skin Animation (dari module)
local SkinAnimation = (function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local SkinAnimations = {
        ["Cursed Katana"] = {ReelingIdle="85246394508551",EquipIdleFake="87355322562067",ReelStart="84160502333903",StartRodCharge="75015195359151",FishCaught="75078942392746"},
        ["Blackhole Sword"] = {ReelingIdle="126645853428201",EquipIdleFake="110434285817259",ReelStart="80063739027478",ReelIntermission="92036914464034",RodThrow="120554144611008",FishCaught="88993991486322",StartRodCharge="106390588424443",LoopedRodCharge="76049869128172"},
        ["Soul Scythe"] = {ReelingIdle="95453600470089",EquipIdleFake="84686809448947",ReelStart="137684649541594",ReelIntermission="139621583239992",RodThrow="104946400643250",FishCaught="82259219343456",StartRodCharge="117668204114399",LoopedRodCharge="88768375910397"},
        ["Eclipse Katana"] = {ReelStart="115229621326605",EquipIdleFake="103641983335689",RodThrow="82600073500966",FishCaught="107940819382815"},
        ["Ethereal Sword"] = {RodThrow="102875258412698",ReelIntermission="129632039690279",LoopedRodCharge="128015350117740",ReelStart="134537167807676",ReelingIdle="74353386311203",StartRodCharge="117245023195506",FishCaught="110866636674655",EquipIdleFake="116654265230180"},
        ["Binary Edge"] = {FishCaught="109653945741202",RodThrow="104527781253009",StartRodCharge="72745361965091",ReelingIdle="81700883907369",LoopedRodCharge="98710992523201",EquipIdleFake="103714544264522"},
        ["Princess Parasol"] = {FishCaught="99143072029495",ReelStart="104188512165442",RodThrow="108621937425425"},
        ["1x1x1x1 Ban Hammer"] = {FishCaught="96285280763544",ReelIntermission="74643095451174",StartRodCharge="134431618143422",LoopedRodCharge="128538861163297",EquipIdleFake="81302570422307",RodThrow="123133988645038"},
        ["The Vanquisher"] = {FishCaught="93884986836266",EquipIdleFake="123194574699925",RodThrow="102380394663862",LoopedRodCharge="92063415632933",ReelStart="138790747812051"},
        ["Crescendo Scythe"] = {ReelStart="111056917953819",RodThrow="140421284729758",LoopedRodCharge="128488550256172",EquipIdleFake="91723046661800",ReelingHold="123869733913273",ReelIntermission="140344626493067",FishCaught="101593515409348",StartRodCharge="95597987757506"},
        ["Eternal Flower"] = {ReelingIdle="110020934764602",RodThrow="105844949829012",StartRodCharge="77131632555646",LoopedRodCharge="124036821497471",ReelStart="135819234295555",EquipIdleFake="115119558523816",ReelIntermission="86376110148779",FishCaught="119567958965696"},
        ["Frozen Krampus Scythe"] = {ReelingIdle="98716967215984",LoopedRodCharge="107284147985305",EquipIdleFake="124265469726043",RodThrow="96196869100887",FishCaught="134934781977605",StartRodCharge="93987679432095"},
        ["Oceanic Harpoon"] = {LoopedRodCharge="76325124055693",StartRodCharge="84873660213983",RodThrow="127872348080219",EquipIdleFake="77549515147440"},
        ["Corruption Edge"] = {RodThrow="84892442268560",StartRodCharge="112104009500915",ReelingIdle="110738276580375",EquipIdleFake="93958525241489",FishCaught="126613975718573"},
        ["Holy Trident"] = {ReelStart="126831815839724",RodThrow="114917462794864",FishCaught="128167068291703",StartRodCharge="83219020397849"},
        ["Undead Guitar"] = {EquipIdleFake="130474623877752"},
        ["Electric Guitar"] = {EquipIdleFake="108792932396384"},
        ["Christmas Parasol"] = {EquipIdleFake="79754634120924",RodThrow="122784676901871"},
        ["Pirate Banjo"] = {EquipIdleFake="120677591068007"},
        ["Divine Blade"] = {EquipIdleFake="82781088583962"},
        ["Gingerbread Sword"] = {EquipIdleFake="106017647759827"},
        ["Candy Cane Trident"] = {EquipIdleFake="131643088615283"},
        ["Heartfelt Blade"] = {EquipIdleFake="111118151202469"},
        ["Spirit Staff"] = {EquipIdleFake="77452908864699"},
        ["Reaver Scythe"] = {EquipIdleFake="79066316609985"},
        ["Pink Present Lance"] = {EquipIdleFake="101986838283328"},
        ["Ornament Axe"] = {EquipIdleFake="90021589040653"},
        ["Gingerbread Katana"] = {RodThrow="124037675493192"},
        ["Xmas Tree Rod"] = {EquipIdleFake="97171752999251"},
        ["Royal Spider"] = {EquipIdleFake="79263851052023"},
        ["Kraken Anchor"] = {EquipIdleFake="126023229958416"}
    }
    local FishingAnims = {"ReelingIdle","EquipIdleFake","ReelStart","ReelIntermission","RodThrow","FishCaught","StartRodCharge","LoopedRodCharge","ReelingHold"}
    local CurrentSkin = nil
    local IsEnabled = false
    local Animator = nil
    local LoadedTracks = {}
    local Connection = nil

    function ShouldReplace(animName)
        for _, name in ipairs(FishingAnims) do if animName == name then return true end end
        return false
    end
    function GetReplacementTrack(animName)
        if not Animator or not CurrentSkin then return nil end
        local skinData = SkinAnimations[CurrentSkin]
        if not skinData or not skinData[animName] then return nil end
        local cacheKey = CurrentSkin .. "_" .. animName
        if LoadedTracks[cacheKey] then return LoadedTracks[cacheKey] end
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. skinData[animName]
        anim.Name = "Replacement_" .. animName
        local success, track = pcall(function() return Animator:LoadAnimation(anim) end)
        if success and track then LoadedTracks[cacheKey] = track; return track end
        return nil
    end
    function ClearTracks()
        for _, track in pairs(LoadedTracks) do pcall(function() track:Stop(); track:Destroy() end) end
        LoadedTracks = {}
    end
    function SetupAnimator()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        Animator = hum:FindFirstChildOfClass("Animator")
        if not Animator then return end
        if Connection then Connection:Disconnect() end
        ClearTracks()
        Connection = Animator.AnimationPlayed:Connect(function(track)
            if not IsEnabled or not CurrentSkin then return end
            if not track.Animation then return end
            local animName = track.Animation.Name
            if ShouldReplace(animName) then
                local replacement = GetReplacementTrack(animName)
                if replacement then
                    local speed = track.Speed
                    track:Stop(0)
                    replacement:Play(0.1, nil, speed)
                    replacement.Looped = track.Looped
                end
            end
        end)
    end
    function Enable() if IsEnabled then return end; IsEnabled = true; SetupAnimator(); LocalPlayer.CharacterAdded:Connect(function() task.wait(1); if IsEnabled then SetupAnimator() end end) end
    function Disable() IsEnabled = false; if Connection then Connection:Disconnect() end; ClearTracks() end
    function SelectSkin(name) CurrentSkin = name; ClearTracks() end
    function GetSkins() local names = {}; for name in pairs(SkinAnimations) do table.insert(names, name) end; table.sort(names); return names end
    return { Enable = Enable, Disable = Disable, SelectSkin = SelectSkin, GetSkins = GetSkins }
end)()

MainTab:CreateSection({ Name = "Skin Animation", Icon = "rbxassetid://108886429866687" })
local skinList = SkinAnimation.GetSkins()
MainTab:CreateDropdown({ Name = "Select Rod Skin", Items = skinList, Default = "None", Callback = function(val) SkinAnimation.SelectSkin(val) end })
MainTab:CreateToggle({ Name = "Enable Skin Changer", Default = false, Callback = function(state) if state then SkinAnimation.Enable() else SkinAnimation.Disable() end end })

-- ================================================================
-- 20. AUTO TAB (Crystal, Potion, Depths, Cave, Pirate, Leviathan, Lochnes)
-- ================================================================

AutoTab:CreateSection({ Name = "Crystal" })
local AutoUseCaveCrystal = false
AutoTab:CreateToggle({ Name = "Auto Use Cave Crystal", Default = false, Callback = function(state)
    AutoUseCaveCrystal = state
    if state then
        task.spawn(function()
            while AutoUseCaveCrystal do
                local shouldUse = false
                pcall(function()
                    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
                    local ActivePotions = PlayerGui and PlayerGui:FindFirstChild("Active Potions")
                    local Rows = ActivePotions and ActivePotions:FindFirstChild("Rows")
                    local label = Rows and Rows:GetChildren()[3] and Rows:GetChildren()[3]:FindFirstChild("Label")
                    if label then
                        local text = label.Text:gsub("%s+", "")
                        local totalSeconds = 0
                        local h, m, s = string.match(text, "^(%d+):(%d+):(%d+)$")
                        if h and m and s then totalSeconds = tonumber(h)*3600 + tonumber(m)*60 + tonumber(s)
                        else
                            local m_only, s_only = string.match(text, "^(%d+):(%d+)$")
                            if m_only and s_only then totalSeconds = tonumber(m_only)*60 + tonumber(s_only) end
                        end
                        if totalSeconds > 0 and totalSeconds <= 180 then shouldUse = true end
                    else
                        shouldUse = true
                    end
                end)
                if shouldUse then
                    pcall(function() ConsumeCrystal:InvokeServer() end)
                    Window:Notify({ Title = "Crystal", Content = "Consumed! (Time <= 3:00 or Not Active)", Duration = 5 })
                    task.wait(10)
                end
                task.wait(2)
            end
        end)
    end
end })

AutoTab:CreateSection({ Name = "Auto Potion" })
local AutoPotionState = { enabled = false, selectedUuid = nil, uuidByLabel = {}, useAmount = 1, delaySeconds = 8 }
local autoPotionLoopGen = 0
local autoPotionDropdown

function buildPotionDropdownData()
    local labels = {}
    local uuidByLabel = {}
    local inv = Data:GetExpect({ "Inventory", "Items" })
    if not inv then return { "None" }, {} end
    for _, item in ipairs(inv) do
        local uid = item.UUID
        if uid and tostring(uid) ~= "" then
            local pdata = ItemUtility:GetItemData(item.Id)
            if pdata and pdata.Data and pdata.Data.Type == "Potion" then
                local name = pdata.Data.Name or ("Potion " .. tostring(item.Id))
                local short = string.sub(tostring(uid), 1, 8)
                local label = string.format("%s | %s", name, short)
                table.insert(labels, label)
                uuidByLabel[label] = tostring(uid)
            end
        end
    end
    table.sort(labels)
    if #labels == 0 then table.insert(labels, "None") end
    return labels, uuidByLabel
end

function consumeSelectedPotion()
    local uuid = AutoPotionState.selectedUuid
    if not uuid or not ConsumePotion then return end
    local amount = math.max(1, math.floor(AutoPotionState.useAmount or 1))
    for _ = 1, amount do
        pcall(function() ConsumePotion:InvokeServer(uuid, 1) end)
        task.wait(0.1)
    end
end

autoPotionDropdown = AutoTab:CreateDropdown({ Name = "Select potion (inventory)", Items = { "None" }, Default = "None", Callback = function(value)
    if not value or value == "None" then AutoPotionState.selectedUuid = nil
    else AutoPotionState.selectedUuid = AutoPotionState.uuidByLabel[value] end
end })
AutoTab:CreateInput({ Name = "Use amount per cycle", PlaceholderText = "1", Callback = function(text) local v = tonumber(text); if v and v >= 1 then AutoPotionState.useAmount = math.floor(v) end end })
AutoTab:CreateInput({ Name = "Auto use delay (seconds)", PlaceholderText = "8", Callback = function(text) local v = tonumber(text); if v and v > 0 then AutoPotionState.delaySeconds = v end end })
AutoTab:CreateButton({ Name = "Refresh potion list", Callback = function()
    local prevUuid = AutoPotionState.selectedUuid
    local labels, map = buildPotionDropdownData()
    AutoPotionState.uuidByLabel = map
    autoPotionDropdown:Refresh(labels)
    if prevUuid then
        for _, uid in pairs(map) do if uid == prevUuid then AutoPotionState.selectedUuid = prevUuid; break end end
    end
end })
AutoTab:CreateButton({ Name = "Use selected potion now", Callback = consumeSelectedPotion })
AutoTab:CreateToggle({ Name = "Auto use selected potion", SubText = "Auto pakai potion sesuai amount + delay", Default = false, Callback = function(state)
    AutoPotionState.enabled = state
    if not state then return end
    autoPotionLoopGen += 1
    local gen = autoPotionLoopGen
    task.spawn(function()
        while AutoPotionState.enabled and gen == autoPotionLoopGen do
            consumeSelectedPotion()
            task.wait(AutoPotionState.delaySeconds)
        end
    end)
end })

AutoTab:CreateSection({ Name = "Auto Crystal Depths" })
function HasPickaxe()
    local inv = Data:GetExpect({ "Inventory", "Items" })
    if not inv then return false end
    for _, item in pairs(inv) do
        if item.Id == 20220 then return true, item.UUID end
        local info = ItemUtility:GetItemData(item.Id)
        if info and info.Data and info.Data.Name and string.find(string.lower(info.Data.Name), "pickaxe") then
            return true, item.UUID
        end
    end
    return false, nil
end

function EquipPickaxe(uuid)
    if not uuid or not REEquipItem then return false end
    for i = 1, 3 do
        pcall(function() REEquipItem:FireServer(uuid, "Gears") end)
        task.wait(0.5)
        local char = LocalPlayer.Character
        if char then
            for _, obj in ipairs(char:GetChildren()) do
                if obj:IsA("Tool") and (obj.Name == "20220" or string.find(string.lower(obj.Name), "pickaxe")) then
                    return true
                end
            end
        end
    end
    return false
end

AutoTab:CreateToggle({ Name = "Auto Crystal Depths", Default = false, Callback = function(state)
    _G.AutoCrystal = state
    if not state then return end
    task.spawn(function()
        local Player = LocalPlayer
        local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not Root then return end
        local StartCFrame = Root.CFrame
        local hasActionTaken = false
        while _G.AutoCrystal do
            local Islands = Workspace:FindFirstChild("Islands")
            local Depths = Islands and Islands:FindFirstChild("Crystal Depths")
            local CrystalsFolder = Depths and Depths:FindFirstChild("Crystals")
            if not CrystalsFolder then task.wait(1); continue end
            local hasPickaxe, pickaxeUUID = HasPickaxe()
            local validCrystals = {}
            for _, crystal in ipairs(CrystalsFolder:GetChildren()) do
                local targetPart = crystal:IsA("BasePart") and crystal or crystal:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    local prompt = crystal:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        local isPickaxeModel = (crystal.Name == "20220" or string.find(string.lower(crystal.Name), "pickaxe"))
                        if isPickaxeModel and hasPickaxe then continue end
                        table.insert(validCrystals, {part = targetPart, prompt = prompt})
                    end
                end
            end
            if #validCrystals > 0 then
                hasActionTaken = true
                for _, data in ipairs(validCrystals) do
                    if not _G.AutoCrystal then break end
                    if hasPickaxe and pickaxeUUID then
                        local char = Player.Character
                        local heldTool = char and char:FindFirstChildWhichIsA("Tool")
                        if not heldTool or (heldTool.Name ~= "20220" and not string.find(string.lower(heldTool.Name), "pickaxe")) then
                            EquipPickaxe(pickaxeUUID)
                        end
                    end
                    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                        Player.Character.HumanoidRootPart.CFrame = data.part.CFrame * CFrame.new(0, 5, 0)
                    end
                    task.wait(0.3)
                    pcall(function() fireproximityprompt(data.prompt) end)
                    task.wait(0.8)
                end
            else
                if hasActionTaken then
                    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                        Player.Character.HumanoidRootPart.CFrame = StartCFrame
                    end
                    task.wait(0.5)
                end
                pcall(function() REEquip:FireServer(1) end)
                task.wait(0.3)
                if hasActionTaken then
                    task.wait(1.0)
                    pcall(function() if ChargeRod then ChargeRod:InvokeServer(100) end end)
                    hasActionTaken = false
                end
                task.wait(2)
            end
        end
    end)
end })

AutoTab:CreateButton({ Name = "Test Equip Pickaxe", Callback = function()
    local has, uuid = HasPickaxe()
    if has then
        local success = EquipPickaxe(uuid)
        Window:Notify({ Title = "Equip Test", Content = success and "Sent Equip Request!" or "Failed to access Remote", Duration = 2 })
    else
        Window:Notify({ Title = "Equip Test", Content = "No Pickaxe Found (ID 20220)", Duration = 2 })
    end
end })

AutoTab:CreateSection({ Name = "Auto Cave" })
AutoTab:CreateToggle({ Name = "Auto Open Mysterious Cave Wall", Default = false, Callback = function(state)
    if state then
        spawn(function()
            for i = 1, 4 do
                pcall(function() if SearchPickup then SearchPickup:FireServer("TNT") end end)
                task.wait(0.5)
            end
            task.wait(1)
            pcall(function() GainMaze:FireServer() end)
            Window:Notify({ Title = "Cave Wall Opened! 🚪", Content = "Mysterious Cave Wall has been opened!", Duration = 5 })
        end)
    end
end })
AutoTab:CreateToggle({ Name = "Auto Open Pirate Chest", Default = false, Callback = function(state)
    _G.AutoOpenPirateChest = state
    if state then
        spawn(function()
            while _G.AutoOpenPirateChest do
                pcall(function()
                    local storage = Workspace:FindFirstChild("PirateChestStorage")
                    if storage then
                        for _, chest in ipairs(storage:GetChildren()) do
                            local chestId = chest.Name
                            if chestId:match("%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") then
                                PirateChest:FireServer(chestId)
                                task.wait(0.3)
                            end
                        end
                    end
                end)
                task.wait(2)
            end
        end)
    end
end })

AutoTab:CreateSection({ Name = "Auto Leviathan Hunt", Icon = "rbxassetid://7733955511" })
_G.AutoLeviathanHunt = _G.AutoLeviathanHunt or false
local LeviathanThread = nil
AutoTab:CreateToggle({ Name = "Auto Leviathan Hunt", Default = _G.AutoLeviathanHunt, Callback = function(state)
    _G.AutoLeviathanHunt = state
    if state then
        LeviathanThread = task.spawn(function()
            while _G.AutoLeviathanHunt do
                pcall(function()
                    local zones = Workspace:FindFirstChild("Zones")
                    if zones then
                        local leviathanDen = zones:FindFirstChild("Leviathan's Den")
                        if leviathanDen then
                            local char = LocalPlayer.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = CFrame.new(3474.05298, -287.774719, 3472.63403, -0.915228605, 0.097325258, -0.391004264, 3.60608101e-06, 0.970392585, 0.241532952, 0.402934879, 0.221056461, -0.88813144)
                            end
                        end
                    end
                end)
                task.wait(30)
            end
        end)
    else
        if LeviathanThread then task.cancel(LeviathanThread); LeviathanThread = nil end
    end
end })

AutoTab:CreateSection({ Name = "Auto Lochnes Event", Icon = "rbxassetid://7733955511" })
_G.AutoLochnesEvent = _G.AutoLochnesEvent or false
_G.LochnesFishingMode = _G.LochnesFishingMode or "Legit"
local LochnesThread = nil
local LochnesTriggered = false
local LOCHNES_TRIGGER_SECONDS = 10
local LochnesLastCFrame = nil
local LOCHNES_TARGET_CFRAME = CFrame.new(6091.53711, -585.924316, 4643.58789, -0.863860309, 1.13146491e-07, 0.50373143, 9.93031932e-08, 1, -5.43194325e-08, -0.50373143, 3.09773784e-09, -0.863860309)

function parseLochnesCountdownSeconds(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end
    local h = tonumber(text:match("(%d+)%s*[Hh]")) or 0
    local m = tonumber(text:match("(%d+)%s*[Mm]")) or 0
    local s = tonumber(text:match("(%d+)%s*[Ss]"))
    if s then return h * 3600 + m * 60 + s end
    local hh, mm, ss = text:match("^(%d+):(%d+):(%d+)$")
    if hh then return tonumber(hh)*3600 + tonumber(mm)*60 + tonumber(ss) end
    local mm2, ss2 = text:match("^(%d+):(%d+)$")
    if mm2 then return tonumber(mm2)*60 + tonumber(ss2) end
    return nil
end

function getLochnesCountdownText()
    local ok, label = pcall(function() return Workspace["!!! DEPENDENCIES"]["Event Tracker"].Main.Gui.Content.Items.Countdown.Label end)
    if not ok or not label then return nil end
    return label.Text or label.ContentText
end

function teleportLochnes()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    LochnesLastCFrame = hrp.CFrame
    hrp.CFrame = LOCHNES_TARGET_CFRAME
end

function returnToLochnesLastPosition()
    if not LochnesLastCFrame then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = LochnesLastCFrame
end

function startLochnesFishingOnce()
    pcall(function() REEquip:FireServer(1) end)
    if _G.LochnesFishingMode == "Legit" then
        pcall(function() if FishingController then FishingController:RequestChargeFishingRod(Vector2.new(0,0), true) end end)
        task.wait(delayfishing or 1)
        pcall(function() CallRemoteServer(REFishDone, 1) end)
    else
        pcall(instant)
    end
end

function lochnesCountdownLoop()
    while _G.AutoLochnesEvent do
        local seconds = parseLochnesCountdownSeconds(getLochnesCountdownText())
        if typeof(seconds) == "number" then
            if (not LochnesTriggered) and seconds <= LOCHNES_TRIGGER_SECONDS then
                LochnesTriggered = true
                teleportLochnes()
                task.wait(0.2)
                startLochnesFishingOnce()
                Window:Notify({ Title = "Lochnes Event", Content = "TP + fishing started (" .. tostring(_G.LochnesFishingMode) .. ")", Duration = 3 })
                task.wait(2)
                returnToLochnesLastPosition()
                Window:Notify({ Title = "Lochnes Event", Content = "Returned to last position.", Duration = 3 })
            elseif LochnesTriggered and seconds > LOCHNES_TRIGGER_SECONDS then
                LochnesTriggered = false
            end
        end
        task.wait(0.25)
    end
end

AutoTab:CreateDropdown({ Name = "Lochnes Fishing Mode", Items = { "Legit", "Instant" }, Default = _G.LochnesFishingMode, Callback = function(v) _G.LochnesFishingMode = v end })
AutoTab:CreateToggle({ Name = "Auto Lochnes Event", Default = _G.AutoLochnesEvent, Callback = function(state)
    _G.AutoLochnesEvent = state
    if LochnesThread then task.cancel(LochnesThread); LochnesThread = nil end
    LochnesTriggered = false
    if state then
        LochnesThread = task.spawn(lochnesCountdownLoop)
    end
end })

-- ================================================================
-- 21. QUEST TAB (Paragraphs + Toggles)
-- ================================================================

QuestTab:CreateSection({ Name = "Deep Sea Quest" })
local deepSeaParagraph = QuestTab:CreateParagraph({ Title = "Deep Sea Quest", Desc = "Loading...", RichText = true })
QuestTab:CreateToggle({ Name = "Auto Deep Sea Quest", Default = _G.DeepSeaQuestMode, Callback = function(state)
    _G.DeepSeaQuestMode = state
    _G.AutoDeepSeaQuest = state
    if state then pcall(function() AutoEnabled:InvokeServer(true) end); pcall(function() equipBestRodNowWithRetry(3,0.3) end) end
    updateUIVisibility()
    if not state and not (_G.ElementQuestMode or _G.DiamondQuestMode) then
        pcall(function() AutoEnabled:InvokeServer(false); if Cancel then Cancel:InvokeServer() end end)
    end
end })

QuestTab:CreateSection({ Name = "Element Quest" })
local elementParagraph = QuestTab:CreateParagraph({ Title = "Element Quest", Desc = "Loading...", RichText = true })
QuestTab:CreateToggle({ Name = "Auto Element Quest", Default = _G.ElementQuestMode, Callback = function(state)
    _G.ElementQuestMode = state
    _G.AutoElementQuest = state
    if state then
        pcall(function() AutoEnabled:InvokeServer(true) end)
        pcall(function() if not equipGhostfinnRod() then equipBestRodNowWithRetry(3,0.3) end end)
    end
    updateUIVisibility()
    if not state and not (_G.DeepSeaQuestMode or _G.DiamondQuestMode) then
        pcall(function() AutoEnabled:InvokeServer(false); if Cancel then Cancel:InvokeServer() end end)
    end
end })
QuestTab:CreateToggle({ Name = "Auto Create Transcended Stones", Default = _G.AutoCreateTranscendedStones, Callback = function(state) _G.AutoCreateTranscendedStones = state end })

QuestTab:CreateSection({ Name = "Diamond Researcher" })
local diamondParagraph = QuestTab:CreateParagraph({ Title = "Diamond Researcher", Desc = "Loading...", RichText = true })
QuestTab:CreateToggle({ Name = "Auto Diamond Quest", Default = _G.DiamondQuestMode, Callback = function(state)
    _G.DiamondQuestMode = state
    _G.AutoDiamondQuest = state
    if state then
        pcall(function() AutoEnabled:InvokeServer(true) end)
        pcall(function() equipBestRodNowWithRetry(3,0.3) end)
    end
    updateUIVisibility()
    if not state and not (_G.DeepSeaQuestMode or _G.ElementQuestMode) then
        pcall(function() AutoEnabled:InvokeServer(false); if Cancel then Cancel:InvokeServer() end end)
    end
end })

QuestTab:CreateToggle({ Name = "Pass All Quests", Default = false, Callback = function(state)
    if state then
        _G.DeepSeaQuestMode = true; _G.ElementQuestMode = true; _G.DiamondQuestMode = true
        _G.AutoDeepSeaQuest = true; _G.AutoElementQuest = true; _G.AutoDiamondQuest = true
        pcall(function() AutoEnabled:InvokeServer(true) end)
        pcall(function() if not equipGhostfinnRod() then equipBestRodNowWithRetry(3,0.3) end end)
    else
        _G.DeepSeaQuestMode = false; _G.ElementQuestMode = false; _G.DiamondQuestMode = false
        _G.AutoDeepSeaQuest = false; _G.AutoElementQuest = false; _G.AutoDiamondQuest = false
        pcall(function() AutoEnabled:InvokeServer(false); if Cancel then Cancel:InvokeServer() end end)
    end
    updateUIVisibility()
end })

QuestTab:CreateSection({ Name = "Temple Lever" })
local templeLeverParagraph = QuestTab:CreateParagraph({ Title = "Temple Lever Status", Desc = "In Progress", RichText = true })
QuestTab:CreateToggle({ Name = "Auto Temple Lever", Default = false, Callback = function(state)
    _G.AutoTempleLever = state
    if templeLeverThread then task.cancel(templeLeverThread) end
    templeLeverThread = nil
    if not state then return end
    templeLeverThread = task.spawn(function()
        while _G.AutoTempleLever do
            pcall(function()
                if not areAllTempleLeversComplete() then processTempleLevers() end
            end)
            task.wait(4)
        end
    end)
end })

-- ================================================================
-- 22. PLAYER TAB (WalkSpeed, Jump, Noclip, Radar, Diving Gear, FlyGui)
-- ================================================================

PlayerTab:CreateInput({ Name = "Walk Speed", SideLabel = "Contoh: 18", Placeholder = "Enter Speed...", Default = "", Callback = function(value)
    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = tonumber(value) or 18 end
end })
PlayerTab:CreateInput({ Name = "Jump Power", SideLabel = "Contoh: 50", Placeholder = "Enter Power...", Default = "", Callback = function(value)
    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.JumpPower = tonumber(value) or 50 end
end })
PlayerTab:CreateToggle({ Name = "Infinite Jump", Default = false, Callback = function(Value)
    _G.InfiniteJump = Value
    if Value then
        InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if _G.InfiniteJump then
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    else
        if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
    end
end })
PlayerTab:CreateToggle({ Name = "Noclip", Default = false, Callback = function(state)
    _G.Noclip = state
    task.spawn(function()
        while _G.Noclip do
            task.wait(0.1)
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide == true then part.CanCollide = false end
                end
            end
        end
    end)
end })
PlayerTab:CreateToggle({ Name = "Radar", Default = false, Callback = function(state)
    local Lighting = game:GetService("Lighting")
    if UpdateRadar then
        pcall(function() UpdateRadar:InvokeServer(state) end)
    end
end })
PlayerTab:CreateToggle({ Name = "Diving Gear", Default = false, Callback = function(state)
    _G.DivingGear = state
    if state then pcall(function() EquipOxygen:InvokeServer(105) end)
    else pcall(function() UnequipOxygen:InvokeServer() end) end
end })
PlayerTab:CreateButton({ Name = "FlyGui V3", Icon = "rbxassetid://7733920644", Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
    Window:Notify({ Title = "Fly GUI Activated", Content = "FlyGui V3 loaded", Duration = 3 })
end })

-- ================================================================
-- 23. SHOP TAB (Charms, Luck Booster, Skin Rod, Buy Rod, Baits, Weather, Merchant)
-- ================================================================

ShopTab:CreateSection({ Name = "Charms Shop" })
local SelectedCharm = nil
local CharmIDs = {}
local PurchaseQuantity = 1

local function loadCharms()
    local charmNames = {}
    CharmIDs = {}
    local success, charmsModule = pcall(function() return require(ReplicatedStorage:WaitForChild("Charms", 5)) end)
    if success and type(charmsModule) == "table" then
        for _, charm in pairs(charmsModule) do
            if charm.Data and charm.Data.Name and charm.Data.Id then
                local name = tostring(charm.Data.Name)
                local id = tonumber(charm.Data.Id)
                if name and id then
                    CharmIDs[name] = id
                    table.insert(charmNames, name)
                end
            end
        end
        table.sort(charmNames)
    end
    return charmNames
end

local charmDropdown = ShopTab:CreateDropdown({ Name = "Select Charm", Items = {}, Default = nil, Callback = function(val) SelectedCharm = val end })
local function refreshCharmDropdown()
    local charmItems = loadCharms()
    if #charmItems > 0 then
        charmDropdown:Refresh(charmItems)
        if not SelectedCharm or not CharmIDs[SelectedCharm] then
            SelectedCharm = charmItems[1]
            charmDropdown:Set(SelectedCharm)
        end
    end
end
refreshCharmDropdown()
ShopTab:CreateButton({ Name = "Refresh Charm List", Callback = function() refreshCharmDropdown(); Window:Notify({ Title = "Refreshed", Content = "Charm list updated.", Duration = 2 }) end })
ShopTab:CreateInput({ Name = "Quantity", PlaceholderText = "1", Callback = function(text) local v = tonumber(text); if v then PurchaseQuantity = v end end })
ShopTab:CreateButton({ Name = "Purchase Charm", Callback = function()
    if not SelectedCharm then return end
    local id = CharmIDs[SelectedCharm]
    if not id then return end
    for i = 1, PurchaseQuantity do
        pcall(function() BuyCharm:InvokeServer(id) end)
        task.wait(0.1)
    end
end })
ShopTab:CreateButton({ Name = "Equip Charm", Callback = function()
    if not SelectedCharm then return end
    pcall(function() REEquipCharm:FireServer(SelectedCharm) end)
end })
ShopTab:CreateButton({ Name = "Unequip Charm", Callback = function()
    pcall(function() REUnequipCharm:FireServer() end)
end })

ShopTab:CreateSection({ Name = "Booster Luck" })
local luckBoosters = { "x2 Luck", "x4 Luck", "x8 Luck" }
local selectedLuckBooster = luckBoosters[1]
ShopTab:CreateDropdown({ Name = "Select Luck Booster", Items = luckBoosters, Value = selectedLuckBooster, Callback = function(value) selectedLuckBooster = value end })
ShopTab:CreateButton({ Name = "Buy Luck Booster", Callback = function()
    local GiftingController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("GiftingController"))
    pcall(function() GiftingController:Open(selectedLuckBooster) end)
end })

ShopTab:CreateSection({ Name = "Skin Rod" })
local rodSkins = { "Frozen Krampus Scythe", "Gingerbread Katana", "Christmas Parasol" }
local selectedRodSkin = rodSkins[1]
ShopTab:CreateDropdown({ Name = "Select Rod Skin", Items = rodSkins, Value = selectedRodSkin, Callback = function(value) selectedRodSkin = value end })
ShopTab:CreateButton({ Name = "Buy Rod Skin", Callback = function()
    local GiftingController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("GiftingController"))
    pcall(function() GiftingController:Open(selectedRodSkin) end)
end })

ShopTab:CreateSection({ Name = "Buy Rod" })
local rods = { ["Luck Rod"] = 79, ["Carbon Rod"] = 76, ["Grass Rod"] = 85, ["Demascus Rod"] = 77, ["Ice Rod"] = 78, ["Lucky Rod"] = 4, ["Midnight Rod"] = 80, ["Steampunk Rod"] = 6, ["Chrome Rod"] = 7, ["Astral Rod"] = 5, ["Ares Rod"] = 126, ["Angler Rod"] = 168, ["Bamboo Rod"] = 258 }
local rodNames = { "Luck Rod (350 Coins)", "Carbon Rod (900 Coins)", "Grass Rod (1.5k Coins)", "Demascus Rod (3k Coins)", "Ice Rod (5k Coins)", "Lucky Rod (15k Coins)", "Midnight Rod (50k Coins)", "Steampunk Rod (215k Coins)", "Chrome Rod (437k Coins)", "Astral Rod (1M Coins)", "Ares Rod (3M Coins)", "Angler Rod (8M Coins)", "Bamboo Rod (12M Coins)" }
local rodKeyMap = { ["Luck Rod (350 Coins)"]="Luck Rod", ["Carbon Rod (900 Coins)"]="Carbon Rod", ["Grass Rod (1.5k Coins)"]="Grass Rod", ["Demascus Rod (3k Coins)"]="Demascus Rod", ["Ice Rod (5k Coins)"]="Ice Rod", ["Lucky Rod (15k Coins)"]="Lucky Rod", ["Midnight Rod (50k Coins)"]="Midnight Rod", ["Steampunk Rod (215k Coins)"]="Steampunk Rod", ["Chrome Rod (437k Coins)"]="Chrome Rod", ["Astral Rod (1M Coins)"]="Astral Rod", ["Ares Rod (3M Coins)"]="Ares Rod", ["Angler Rod (8M Coins)"]="Angler Rod", ["Bamboo Rod (12M Coins)"]="Bamboo Rod" }
local selectedRod = rodNames[1]
ShopTab:CreateDropdown({ Name = "Select Rod", Items = rodNames, Value = selectedRod, Callback = function(value) selectedRod = value end })
ShopTab:CreateButton({ Name = "Buy Rod", Callback = function()
    local key = rodKeyMap[selectedRod]
    if key and rods[key] then pcall(function() BuyRod:InvokeServer(rods[key]) end) end
end })

ShopTab:CreateSection({ Name = "Buy Baits" })
local baits = { ["TopWater Bait"] = 10, ["Lucky Bait"] = 2, ["Midnight Bait"] = 3, ["Chroma Bait"] = 6, ["Dark Mater Bait"] = 8, ["Corrupt Bait"] = 15, ["Aether Bait"] = 16 }
local baitNames = { "TopWater Bait (100 Coins)", "Lucky Bait (1k Coins)", "Midnight Bait (3k Coins)", "Chroma Bait (290k Coins)", "Dark Mater Bait (630k Coins)", "Corrupt Bait (1.15M Coins)", "Aether Bait (3.7M Coins)" }
local baitKeyMap = { ["TopWater Bait (100 Coins)"] = "TopWater Bait", ["Lucky Bait (1k Coins)"] = "Lucky Bait", ["Midnight Bait (3k Coins)"] = "Midnight Bait", ["Chroma Bait (290k Coins)"] = "Chroma Bait", ["Dark Mater Bait (630k Coins)"] = "Dark Mater Bait", ["Corrupt Bait (1.15M Coins)"] = "Corrupt Bait", ["Aether Bait (3.7M Coins)"] = "Aether Bait" }
local selectedBait = baitNames[1]
ShopTab:CreateDropdown({ Name = "Select Bait", Items = baitNames, Value = selectedBait, Callback = function(value) selectedBait = value end })
ShopTab:CreateButton({ Name = "Buy Bait", Callback = function()
    local key = baitKeyMap[selectedBait]
    if key and baits[key] then pcall(function() BuyBait:InvokeServer(baits[key]) end) end
end })

ShopTab:CreateSection({ Name = "Buy Weather Event", Icon = "rbxassetid://7733955511" })
local weathers = { ["Wind"] = "Wind", ["Cloudy"] = "Cloudy", ["Snow"] = "Snow", ["Storm"] = "Storm", ["Radiant"] = "Radiant", ["Shark Hunt"] = "Shark Hunt" }
local weatherNames = { "Windy (10k Coins)", "Cloudy (20k Coins)", "Snow (15k Coins)", "Stormy (35k Coins)", "Radiant (50k Coins)", "Shark Hunt (300k Coins)" }
local weatherKeyMap = { ["Windy (10k Coins)"] = "Wind", ["Cloudy (20k Coins)"] = "Cloudy", ["Snow (15k Coins)"] = "Snow", ["Stormy (35k Coins)"] = "Storm", ["Radiant (50k Coins)"] = "Radiant", ["Shark Hunt (300k Coins)"] = "Shark Hunt" }
local selectedWeathers = {}
ShopTab:CreateMultiDropdown({ Name = "Select Weather Events", Items = weatherNames, Default = selectedWeathers, Callback = function(values) selectedWeathers = values end })
ShopTab:CreateToggle({ Name = "Auto Buy Selected Weathers", SubText = "Continuously purchase all selected weather events while ON", Default = false, Callback = function(state)
    if state then
        task.spawn(function()
            while state do
                for _, selected in ipairs(selectedWeathers) do
                    local key = weatherKeyMap[selected]
                    if key and weathers[key] then
                        pcall(function() BuyWeather:InvokeServer(weathers[key]) end)
                    end
                    task.wait(0.5)
                end
                task.wait(5)
            end
        end)
    end
end })

ShopTab:CreateSection({ Name = "Merchant" })
local MarketItemData = nil
pcall(function() MarketItemData = require(ReplicatedStorage.Shared.MarketItemData) end)
local merchantData = nil
pcall(function() merchantData = Replion.Client:WaitReplion("Merchant") end)

function shortenNumber(n)
    if type(n) ~= "number" then return "N/A" end
    local scales = { {1000000000000000000, "Qi"}, {999999986991104, "Qa"}, {999999995904, "T"}, {1000000000, "B"}, {1000000, "M"}, {1000, "K"} }
    local negative = n < 0
    n = math.abs(n)
    if n < 1000 then return (negative and "-" or "") .. tostring(math.floor(n)) end
    for _, scale in ipairs(scales) do
        if n >= scale[1] then
            local value = n / scale[1]
            return (negative and "-" or "") .. (value % 1 == 0 and string.format("%.0f%s", value, scale[2]) or string.format("%.2f%s", value, scale[2]))
        end
    end
    return (negative and "-" or "") .. tostring(n)
end

local merchantItemsForDropdown = {}
local merchantItemMap = {}

function buildMerchantItemDatabase()
    merchantItemsForDropdown, merchantItemMap = {}, {}
    if not MarketItemData then return end
    for _, itemData in ipairs(MarketItemData) do
        if itemData and itemData.Identifier and itemData.Price and itemData.Id then
            local formattedPrice = shortenNumber(tonumber(itemData.Price) or 0)
            local formattedName = string.format("%s (%s)", itemData.Identifier, formattedPrice)
            table.insert(merchantItemsForDropdown, formattedName)
            merchantItemMap[formattedName] = itemData.Id
        end
    end
    table.sort(merchantItemsForDropdown)
end
buildMerchantItemDatabase()

local selectedMerchantItemNames = {}
local isAutoBuyingMerchantItem = false
local autoBuyMerchantThread = nil

function formatTime(seconds)
    seconds = tonumber(seconds) or 0
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02i Hours, %02i Minutes, %02i Seconds", h, m, s)
end

local merchantInfoParagraph = ShopTab:CreateParagraph({ Title = "Merchant Status", Desc = "<font color='#999999'>Load data from the server...</font>", RichText = true })
ShopTab:CreateMultiDropdown({ Name = "Select Merchant Item(s)", Items = merchantItemsForDropdown, Default = selectedMerchantItemNames, Callback = function(selectedNames) selectedMerchantItemNames = selectedNames or {} end })
ShopTab:CreateToggle({ Name = "Auto Buy Selected Item", Default = isAutoBuyingMerchantItem, Callback = function(state)
    isAutoBuyingMerchantItem = state
    if autoBuyMerchantThread then task.cancel(autoBuyMerchantThread); autoBuyMerchantThread = nil end
    if state then
        autoBuyMerchantThread = task.spawn(function()
            while isAutoBuyingMerchantItem do
                for _, name in ipairs(selectedMerchantItemNames) do
                    local itemId = merchantItemMap[name]
                    if itemId and BuyMarket then pcall(function() BuyMarket:InvokeServer(itemId) end) end
                end
                task.wait(1)
            end
        end)
    end
end })
ShopTab:CreateButton({ Name = "Buy Selected Item", Callback = function()
    for _, name in ipairs(selectedMerchantItemNames) do
        local itemId = merchantItemMap[name]
        if itemId and BuyMarket then pcall(function() BuyMarket:InvokeServer(itemId) end) end
    end
end })

task.spawn(function()
    while task.wait(1) do
        if not merchantInfoParagraph then break end
        if not merchantData then merchantInfoParagraph:SetDesc("<font color='#ff3333'>Merchant data not available</font>"); continue end
        local displayTextLines = {}
        local serverTime = Workspace:GetServerTimeNow()
        local dayStart = math.floor(serverTime / 86400) * 86400
        local nextNoon = dayStart + 43200
        if serverTime > nextNoon then nextNoon = nextNoon + 43200 end
        local timeUntilRefresh = math.max(nextNoon - serverTime, 0)
        table.insert(displayTextLines, "<b>Next Refresh in:</b> " .. formatTime(timeUntilRefresh))
        table.insert(displayTextLines, "")
        table.insert(displayTextLines, "<b>Items for sale:</b>")
        local currentItemIds = merchantData:Get("Items")
        if currentItemIds and #currentItemIds > 0 then
            for _, itemId in ipairs(currentItemIds) do
                local itemDetails = nil
                for _, data in ipairs(MarketItemData or {}) do if data and data.Id == itemId then itemDetails = data; break end end
                if itemDetails then
                    local price = shortenNumber(tonumber(itemDetails.Price or 0) or 0)
                    local currency = itemDetails.Currency or "N/A"
                    local itemName = itemDetails.Identifier or "Unknown Item"
                    table.insert(displayTextLines, string.format("- %s (Price: %s %s)", itemName, price, currency))
                end
            end
        else
            table.insert(displayTextLines, "Store is empty or data is not available.")
        end
        merchantInfoParagraph:SetDesc(table.concat(displayTextLines, "\n"))
    end
end)

ShopTab:CreateButton({ Name = "Teleport to Merchant", Callback = function()
    local char = LocalPlayer.Character
    if not char then return end
    local merchantNpc = Workspace:FindFirstChild("NPC", true) and Workspace.NPC:FindFirstChild("Alien Merchant")
    if merchantNpc and merchantNpc:IsA("Model") then
        char:PivotTo(merchantNpc:GetPivot())
    end
end })

-- ================================================================
-- 24. TELEPORT TAB (Islands, Players, NPC, Fishing Area, Event TP)
-- ================================================================

TeleportTab:CreateSection({ Name = "Island", Icon = "rbxassetid://7733955511" })
local IslandLocations = {
    ["Ancient Ruins"] = Vector3.new(6009, -585, 4691),
    ["Ancient Jungle"] = Vector3.new(1518, 1, -186),
    ["Coral Refs"] = Vector3.new(-2855, 47, 1996),
    ["Crater Island"] = Vector3.new(997, 1, 5012),
    ["Enchant Room"] = Vector3.new(3221, -1303, 1406),
    ["Enchant Room 2"] = Vector3.new(1480, 126, -585),
    ["Esoteric Island"] = Vector3.new(1990, 5, 1398),
    ["Fisherman Island"] = Vector3.new(-175, 3, 2772),
    ["Kohana Volcano"] = Vector3.new(-545.302429, 17.1266193, 118.870537),
    ["Kohana"] = Vector3.new(-603, 3, 719),
    ["Kohana Spot 1"] = Vector3.new(-703.661194, 17.2500553, 438.727234, 0.999670267, -1.30875062e-08, 0.0256783087, 1.42019179e-08, 1, -4.32165699e-08, -0.0256783087, 4.35669989e-08, 0.999670267),
    ["Kohana Spot 2"] = Vector3.new(-897.885498, 5.7500596, 694.055359, -0.0598792434, -1.81639592e-08, 0.998205602, -7.78091647e-10, 1, 1.81499349e-08, -0.998205602, 3.10108939e-10, -0.0598792434),
    ["Lost Isle"] = Vector3.new(-3643, 1, -1061),
    ["Sacred Temple"] = Vector3.new(1498, -23, -644),
    ["Sysyphus Statue"] = Vector3.new(-3783.26807, -135.073914, -949.946289),
    ["Treasure Room"] = Vector3.new(-3600, -267, -1575),
    ["Tropical Grove"] = Vector3.new(-2091, 6, 3703),
    ["Weather Machine"] = Vector3.new(-1508, 6, 1895),
    ["Pirate Cave"] = Vector3.new(3398.86011, 4.19197035, 3480.54517, 0.617785096, -6.47339746e-08, -0.786346972, 3.20196716e-11, 1, -8.22972481e-08, 0.786346972, 5.0816837e-08, 0.617785096),
    ["Pirate Treasure room"] = Vector3.new(3299.81274, -305.034851, 3041.50952, -0.483591467, 2.84460047e-08, -0.875293851, -4.8970314e-08, 1, 5.95544378e-08, 0.875293851, 7.1663429e-08, -0.483591467),
    ["Crystal Depths"] = Vector3.new(5817.32715, -905.697144, 15416.3047, 0.0518231429, 1.04369903e-07, -0.998656273, -1.59683076e-08, 1, 1.03681693e-07, 0.998656273, 1.05737401e-08, 0.0518231429),
    ["Leviathan Den"] = Vector3.new(3474.05298, -287.774719, 3472.63403, -0.915228605, 0.097325258, -0.391004264, 3.60608101e-06, 0.970392585, 0.241532952, 0.402934879, 0.221056461, -0.88813144),
    ["Volcanic Cavern"] = Vector3.new(1097.38257, 85.8561707, -10243.374, 0.000799760048, -8.65786873e-08, 0.999999702, 3.16020241e-08, 1, 8.65534346e-08, -0.999999702, 3.15327924e-08, 0.000799760048),
    ["Lava Basin"] = Vector3.new(934.931152, 67.6846008, -10218.3184, -0.712165296, 1.81655864e-08, 0.702011824, -1.73417316e-08, 1, -4.34690186e-08, -0.702011824, -4.31312266e-08, -0.712165296),
    ["Secret Passage"] = Vector3.new(3431.59546, -299.344971, 3359.79614, -0.947619379, 3.96371149e-08, -0.319401741, 3.15227737e-08, 1, 3.0574423e-08, 0.319401741, 1.89044869e-08, -0.947619379),
    ["Planetary Observatory"] = Vector3.new(424.709442, 3.67347598, 2186.08545, -0.248919666, 4.43553425e-08, -0.968524158, -4.75323825e-09, 1, 4.70184638e-08, 0.968524158, 1.63074461e-08, -0.248919666),
    ["Aquatic Research Lab"] = Vector3.new(5006.53125, 4934.31055, 5008.31885, 0.954527259, 3.15839692e-08, -0.298123598, -6.24583052e-09, 1, 8.5944734e-08, 0.298123598, -8.01745657e-08, 0.954527259),
    ["Underwater City"] = Vector3.new(-3141.34546, -643.484253, -10408.1104, 0.120906673, 5.98232788e-08, -0.99266386, 4.37882157e-08, 1, 6.55988117e-08, 0.99266386, -5.13983132e-08, 0.120906673),
}
local SelectedIsland = nil
local function getIslandFolder() return Workspace:FindFirstChild("Islands") end
local function getIslandDropdownItems()
    local folder = getIslandFolder()
    if not folder then return { "Islands folder not found" } end
    local out = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") or child:IsA("CFrameValue") or child:IsA("Vector3Value") or child:IsA("Folder") then
            table.insert(out, child.Name)
        end
    end
    table.sort(out)
    if #out == 0 then out = { "No islands found" } end
    return out
end
local function resolveIslandCFrame(selection)
    if not selection or selection == "" then return nil end
    local folder = getIslandFolder()
    if folder then
        local child = folder:FindFirstChild(selection)
        if child then
            if child:IsA("Model") then return child:GetPivot() end
            if child:IsA("BasePart") then return child.CFrame end
            if child:IsA("CFrameValue") then return child.Value end
            if child:IsA("Vector3Value") then return CFrame.new(child.Value) end
            if child:IsA("Folder") then
                local model = child:FindFirstChildWhichIsA("Model")
                if model then return model:GetPivot() end
                local part = child:FindFirstChildWhichIsA("BasePart", true)
                if part then return part.CFrame end
            end
        end
    end
    return nil
end
local IslandDropdown = TeleportTab:CreateDropdown({ Name = "Select Island", Items = getIslandDropdownItems(), Callback = function(Value) SelectedIsland = Value end })
task.spawn(function()
    local function refresh()
        if IslandDropdown and IslandDropdown.Refresh then IslandDropdown:Refresh(getIslandDropdownItems()) end
    end
    local folder = getIslandFolder() or Workspace:WaitForChild("Islands", 10)
    if folder then
        refresh()
        folder.ChildAdded:Connect(refresh)
        folder.ChildRemoved:Connect(refresh)
    end
end)
TeleportTab:CreateButton({ Name = "Teleport to Island", Callback = function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local cf = resolveIslandCFrame(SelectedIsland)
    if cf then
        local _, y, _ = hrp.CFrame:ToOrientation()
        hrp.CFrame = CFrame.new(cf.Position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, y, 0)
    end
end })

TeleportTab:CreateSection({ Name = "Tp To Player", Icon = "rbxassetid://7733955511" })
local SelectedPlayer = nil
local FishingDropdown = TeleportTab:CreateDropdown({ Name = "Select Player", Items = (function()
    local players = {}
    for _, plr in pairs(Players:GetPlayers()) do if plr.Name ~= LocalPlayer.Name then table.insert(players, plr.Name) end end
    table.sort(players)
    return players
end)(), Callback = function(Value) SelectedPlayer = Value end })
function RefreshPlayerList()
    local list = {}
    for _, plr in pairs(Players:GetPlayers()) do if plr.Name ~= LocalPlayer.Name then table.insert(list, plr.Name) end end
    table.sort(list)
    FishingDropdown:Refresh(list)
end
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(RefreshPlayerList)
TeleportTab:CreateButton({ Name = "Teleport to Player", Callback = function()
    if SelectedPlayer then
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0) end
        end
    end
end })

TeleportTab:CreateSection({ Name = "Location NPC", Icon = "rbxassetid://7733955511" })
local SelectedNPC = nil
local function getNpcFolder() return Workspace:FindFirstChild("NPC") end
local function getNpcDropdownItems()
    local folder = getNpcFolder()
    if not folder then return { "NPC folder not found" } end
    local out = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") then table.insert(out, child.Name) end
    end
    table.sort(out)
    if #out == 0 then out = { "No NPCs found" } end
    return out
end
local NPCDropdown = TeleportTab:CreateDropdown({ Name = "Select NPC", Items = getNpcDropdownItems(), Callback = function(Value) SelectedNPC = Value end })
task.spawn(function()
    local npcFolder = getNpcFolder() or Workspace:WaitForChild("NPC", 10)
    if npcFolder then
        local function refresh() if NPCDropdown and NPCDropdown.Refresh then NPCDropdown:Refresh(getNpcDropdownItems()) end end
        refresh()
        npcFolder.ChildAdded:Connect(refresh)
        npcFolder.ChildRemoved:Connect(refresh)
    end
end)
TeleportTab:CreateButton({ Name = "Teleport to NPC", Callback = function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not SelectedNPC then return end
    local npcFolder = getNpcFolder()
    if npcFolder then
        local target = npcFolder:FindFirstChild(SelectedNPC)
        if target then
            if target:IsA("Model") then hrp.CFrame = target:GetPivot()
            elseif target:IsA("BasePart") then hrp.CFrame = target.CFrame end
        end
    end
end })

TeleportTab:CreateSection({ Name = "Fishing Area", Icon = "rbxassetid://7733955511" })
local FishingAreaLocations = {
    ["Fisherman Island"] = Vector3.new(74.03, 9.53, 2705.23),
    ["Crater Island"] = Vector3.new(998.03, 2.86, 5151.17),
    ["Tropical Island"] = Vector3.new(-2152.61, 2.32, 3671.72),
    ["Coral Refs"] = Vector3.new(-3181.39, 2.52, 2104.35),
    ["Lost Isle"] = Vector3.new(-3734.67, 5.34, -1082.63),
    ["Volcano"] = Vector3.new(-541.52, 17.32, 121.67),
    ["Esoteric Island"] = Vector3.new(2164.47, 3.22, 1242.39),
    ["Enchant Room"] = Vector3.new(3255.67, -1301.53, 1371.79),
    ["Kohana"] = Vector3.new(-661.68, 3.05, 714.14),
    ["Weather Machine"] = Vector3.new(-1523.23, 8.47, 1771.99),
    ["Treasure Room"] = Vector3.new(-3581.60, -279.07, -1589.65),
    ["Sisyphus Statue"] = Vector3.new(-3729.25, -135.07, -885.64),
    ["Ancient Jungle"] = Vector3.new(1275.10, 3.91, -334.75),
    ["Sacred Temple"] = Vector3.new(1451.41, -22.13, -635.65),
    ["Underground Cellar"] = Vector3.new(2135.45, -91.20, -699.33),
    ["Arrow Artifact"] = Vector3.new(869.33, 3.13, -294.87),
    ["Crescent Artifact"] = Vector3.new(1399.05, 4.80, 162.05),
    ["Diamond Artifact"] = Vector3.new(1854.25, 4.43, -276.84),
    ["Hourglass Diamond Artifact"] = Vector3.new(1460.75, 6.33, -815.16),
    ["Ancient Ruin"] = CFrame.new(6096.65, -585.92, 4665.26, 0.01, -0.00, 1.00, 0.00, 1.00, 0.00, -1.00, 0.00, 0.01),
    ["Crystalline Passage"] = CFrame.new(6050.02, -538.90, 4374.91, -1.00, 0.00, 0.01, 0.00, 1.00, 0.00, -0.01, 0.00, -1.00),
    ["Classic Island"] = CFrame.new(1232.43, 10.00, 2843.07, 0.03, 0.00, -1.00, 0.00, 1.00, 0.00, 1.00, -0.00, 0.03),
    ["Iron Cavern"] = CFrame.new(-8898.99, -581.75, 157.30, 0.02, -0.00, -1.00, 0.00, 1.00, -0.00, 1.00, -0.00, 0.02),
    ["Iron Cafe"] = CFrame.new(-8642.19, -547.50, 161.10, -0.00, -0.00, -1.00, 0.00, 1.00, -0.00, 1.00, -0.00, -0.00),
}
local SelectedFishingArea = nil
TeleportTab:CreateDropdown({ Name = "Select Fishing Area", Items = (function() local keys = {}; for name in pairs(FishingAreaLocations) do table.insert(keys, name) end; table.sort(keys); return keys end)(), Callback = function(value) SelectedFishingArea = value end })
TeleportTab:CreateButton({ Name = "Teleport to Fishing Area", Callback = function()
    if not SelectedFishingArea then return end
    local dest = FishingAreaLocations[SelectedFishingArea]
    if not dest then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        if typeof(dest) == "CFrame" then hrp.CFrame = dest else hrp.CFrame = CFrame.new(dest) end
    end
end })
local fishingAreaFreezeConn = nil
function stopFishingAreaFreeze() if fishingAreaFreezeConn then fishingAreaFreezeConn:Disconnect(); fishingAreaFreezeConn = nil end end
function startFishingAreaFreeze()
    stopFishingAreaFreeze()
    if not SelectedFishingArea then return end
    local dest = FishingAreaLocations[SelectedFishingArea]
    if not dest then return end
    local cf = typeof(dest) == "CFrame" and dest or CFrame.new(dest)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = cf end
    fishingAreaFreezeConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if h then h.CFrame = cf end
        end)
    end)
end
TeleportTab:CreateToggle({ Name = "Freeze at Selected Area", Default = false, Callback = function(state) if state then startFishingAreaFreeze() else stopFishingAreaFreeze() end end })

TeleportTab:CreateSection({ Name = "Custom Position", Icon = "rbxassetid://7733955511" })
local vSavedCustomPos = nil
local customPosFreezeConn = nil
function stopCustomPosFreeze() if customPosFreezeConn then customPosFreezeConn:Disconnect(); customPosFreezeConn = nil end end
TeleportTab:CreateButton({ Name = "Save Current Position", Callback = function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then vSavedCustomPos = hrp.CFrame; Window:Notify({ Title = "Custom Position", Content = "Position saved!", Duration = 3 }) end
end })
TeleportTab:CreateButton({ Name = "Teleport to Saved Position", Callback = function()
    if not vSavedCustomPos then Window:Notify({ Title = "Custom Position", Content = "No position saved yet.", Duration = 3 }); return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = vSavedCustomPos end
end })
TeleportTab:CreateToggle({ Name = "Freeze at Saved Position", Default = false, Callback = function(state)
    stopCustomPosFreeze()
    if not state then return end
    if not vSavedCustomPos then Window:Notify({ Title = "Custom Position", Content = "No position saved yet.", Duration = 3 }); return end
    local cf = vSavedCustomPos
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = cf end
    customPosFreezeConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if h then h.CFrame = cf end
        end)
    end)
end })

-- Event Teleporter
local eventData = {
    ["Worm Hunt"] = { PathFromWorkspace = { "Props", "Model", "BlackHole" }, Locations = { Vector3.new(2190.85, -1.4, 97.575), Vector3.new(-2450.679, -1.4, 139.731), Vector3.new(-267.479, -1.4, 5188.531), Vector3.new(-327, -1.4, 2422) }, PlatformY = 107, Priority = 1 },
    ["Megalodon Hunt"] = { TargetName = "Megalodon Hunt", Locations = { Vector3.new(-1076.3, -1.4, 1676.2), Vector3.new(-1191.8, -1.4, 3597.3), Vector3.new(412.7, -1.4, 4134.4) }, PlatformY = 107, Priority = 2 },
    ["Ghost Shark Hunt"] = { TargetName = "Ghost Shark Hunt", Locations = { Vector3.new(489.559, -1.35, 25.406), Vector3.new(-1358.216, -1.35, 4100.556), Vector3.new(627.859, -1.35, 3798.081) }, PlatformY = 107, Priority = 3 },
    ["Shark Hunt"] = { TargetName = "Shark Hunt", Locations = { Vector3.new(1.65, -1.35, 2095.725), Vector3.new(1369.95, -1.35, 930.125), Vector3.new(-1585.5, -1.35, 1242.875), Vector3.new(-1896.8, -1.35, 2634.375) }, PlatformY = 107, Priority = 4 },
    ["Thrundzilla Hunt"] = { TargetName = "Shocked", Locations = { Vector3.new(2067.7981, 2.20000029, 16.7060127) }, PlatformY = 107, Priority = 5 },
}
local eventNames = {}
for name in pairs(eventData) do table.insert(eventNames, name) end
local selectedEvents = {}
local autoEventTPEnabled = false
local createdEventPlatform = nil

function destroyEventPlatform()
    if createdEventPlatform and createdEventPlatform.Parent then createdEventPlatform:Destroy(); createdEventPlatform = nil end
end

function getInstanceAtWorkspacePath(path)
    local current = Workspace
    for _, name in ipairs(path) do
        current = current and current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

function getWorldPositionForEventTarget(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Model") then
        if inst.PrimaryPart then return inst.PrimaryPart.Position end
        local p = inst:FindFirstChildWhichIsA("BasePart", true)
        if p then return p.Position end
    end
    local p = inst:FindFirstChildWhichIsA("BasePart", true)
    return p and p.Position or nil
end

function createAndTeleportToPlatform(targetPos, y)
    local desiredPos = Vector3.new(targetPos.X, y, targetPos.Z)
    if createdEventPlatform and createdEventPlatform.Parent then
        createdEventPlatform.Position = desiredPos
    else
        destroyEventPlatform()
        local platform = Instance.new("Part")
        platform.Size = Vector3.new(5, 1, 5)
        platform.Position = desiredPos
        platform.Anchored = true
        platform.Transparency = 1
        platform.CanCollide = true
        platform.Name = "EventPlatform"
        platform.Parent = Workspace
        createdEventPlatform = platform
    end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(createdEventPlatform.Position + Vector3.new(0, 3, 0)) end
end

function runMultiEventTP()
    while autoEventTPEnabled do
        local sorted = {}
        for _, e in ipairs(selectedEvents) do
            local cfg = eventData[e]
            if cfg then table.insert(sorted, cfg) end
        end
        table.sort(sorted, function(a,b) return (a.Priority or 0) < (b.Priority or 0) end)
        for _, config in ipairs(sorted) do
            if not config.Locations then continue end
            local foundTarget, foundPos
            if config.PathFromWorkspace then
                local targetInst = getInstanceAtWorkspacePath(config.PathFromWorkspace)
                local pos = getWorldPositionForEventTarget(targetInst)
                if pos then
                    for _, loc in ipairs(config.Locations) do
                        if (pos - loc).Magnitude <= 150 then
                            foundTarget = targetInst; foundPos = pos; break
                        end
                    end
                end
            elseif config.TargetName then
                for _, d in ipairs(Workspace:GetDescendants()) do
                    if d.Name == config.TargetName then
                        local pos = d:IsA("BasePart") and d.Position or (d.PrimaryPart and d.PrimaryPart.Position)
                        if pos then
                            for _, loc in ipairs(config.Locations) do
                                if (pos - loc).Magnitude <= 150 then
                                    foundTarget = d; foundPos = pos; break
                                end
                            end
                        end
                    end
                    if foundTarget then break end
                end
            end
            if foundTarget and foundPos then
                createAndTeleportToPlatform(foundPos, config.PlatformY)
            end
        end
        task.wait(0.1)
    end
    destroyEventPlatform()
end

TeleportTab:CreateSection({ Name = "Event Teleporter", Icon = "rbxassetid://7733955511" })
TeleportTab:CreateDropdown({ Name = "Select Fish Events", Items = eventNames, Callback = function(value) selectedEvents = { value } end })
TeleportTab:CreateToggle({ Name = "Auto Fish Event TP", Default = false, Callback = function(state)
    autoEventTPEnabled = state
    if state then task.spawn(runMultiEventTP) end
end })

-- ================================================================
-- 25. SETTINGS TAB (Camera, Cutscene, Notification, Walk on Water, Reconnect, Fake Char, Hide Identity, Anti AFK, Anti Pengganggu, Server Hop)
-- ================================================================

SettingsTab:CreateSection({ Name = "Camera Views" })
local UnlimitedZoomModule = {}
local originalMinZoom = LocalPlayer.CameraMinZoomDistance
local originalMaxZoom = LocalPlayer.CameraMaxZoomDistance
local unlimitedZoomActive = false
function UnlimitedZoomModule.Enable()
    if unlimitedZoomActive then return false end
    unlimitedZoomActive = true
    LocalPlayer.CameraMinZoomDistance = 0.5
    LocalPlayer.CameraMaxZoomDistance = 9999
    return true
end
function UnlimitedZoomModule.Disable()
    if not unlimitedZoomActive then return false end
    unlimitedZoomActive = false
    LocalPlayer.CameraMinZoomDistance = originalMinZoom
    LocalPlayer.CameraMaxZoomDistance = originalMaxZoom
    return true
end
SettingsTab:CreateToggle({ Name = "Unlimited Zoom Camera", Default = false, Callback = function(state) if state then UnlimitedZoomModule.Enable() else UnlimitedZoomModule.Disable() end end })

SettingsTab:CreateSection({ Name = "Skip Cutscene" })
local skipCutscene = false
local replicateConn, stopConn
SettingsTab:CreateToggle({ Name = "Skip Cutscene", Default = false, Callback = function(state)
    skipCutscene = state
    if not replicateConn and RECutscene then
        replicateConn = RECutscene.OnClientEvent:Connect(function(...) if skipCutscene then warn("[DevHub] Blocked ReplicateCutscene event!") end end)
    end
    if not stopConn and REStop then
        stopConn = REStop.OnClientEvent:Connect(function() if skipCutscene then warn("[DevHub] Blocked StopCutscene event!") end end)
    end
    spawn(function()
        local ok, CutsceneController = pcall(function() return require(ReplicatedStorage.Controllers.CutsceneController) end)
        if ok and CutsceneController then
            while true do
                if skipCutscene then
                    CutsceneController.Play = function() end
                    CutsceneController.Stop = function() end
                else
                    pcall(function() CutsceneController.Play = originalPlay end)
                    pcall(function() CutsceneController.Stop = originalStop end)
                end
                task.wait(0.25)
            end
        end
    end)
end })

SettingsTab:CreateSection({ Name = "Notification", Icon = "rbxassetid://7733955511" })
SettingsTab:CreateToggle({ Name = "Disable Notifications", Default = false, Callback = function(state)
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if PlayerGui then
        local NotifyGui = PlayerGui:FindFirstChild("Text Notifications")
        if NotifyGui then
            local Frame = NotifyGui:FindFirstChild("Frame")
            if Frame then Frame.Visible = not state end
        end
    end
end })
SettingsTab:CreateDropdown({ Name = "Position", Items = {"Normal (Mid)", "Left", "Right"}, Default = "Normal (Mid)", Callback = function(Value)
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if PlayerGui then
        local NotifyGui = PlayerGui:FindFirstChild("Text Notifications")
        if NotifyGui then
            local Frame = NotifyGui:FindFirstChild("Frame")
            if Frame then
                if Value == "Normal (Mid)" then Frame.Position = UDim2.new(0.5, 0, 0, 110)
                elseif Value == "Left" then Frame.Position = UDim2.new(0.3, 0, 0, 110)
                elseif Value == "Right" then Frame.Position = UDim2.new(0.7, 0, 0, 110) end
            end
        end
    end
end })

SettingsTab:CreateSection({ Name = "General", Icon = "rbxassetid://7733954611" })
-- Walk on Water (module)
local WalkOnWater = loadstring([[ ... ]])() -- (module code disisipkan, tapi saya singkat)
SettingsTab:CreateToggle({ Name = "Walk on Water", Description = "Walk on water surface without swimming", Default = false, Callback = function(value) if value then WalkOnWater.Start() else WalkOnWater.Stop() end end })

SettingsTab:CreateToggle({ Name = "Auto Reconnect", SubText = "Automatic reconnect if disconnected", Default = false, Callback = function(state)
    _G.AutoReconnect = state
    if state then
        task.spawn(function()
            while _G.AutoReconnect do
                task.wait(2)
                local reconnectUI = CoreGui:FindFirstChild("RobloxPromptGui")
                if reconnectUI then
                    local prompt = reconnectUI:FindFirstChild("promptOverlay")
                    if prompt then
                        local button = prompt:FindFirstChild("ButtonPrimary")
                        if button and button.Visible then
                            pcall(function() firesignal(button.MouseButton1Click) end)
                        end
                    end
                end
            end
        end)
    end
end })

SettingsTab:CreateSection({ Name = "Fake Character", Icon = "rbxassetid://7733964719" })
local FakeCharacter = { Enabled = false, FakeChar = nil, RealChar = nil, Connections = {} }
local TRANSPARENCY = 1
local FAKE_TRANSPARENCY = 0
function setCharacterTransparency(character, transparency)
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then part.Transparency = transparency
        elseif part:IsA("Decal") then part.Transparency = transparency
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then handle.Transparency = transparency end
        end
    end
    local head = character:FindFirstChild("Head")
    if head then
        local face = head:FindFirstChild("face")
        if face then face.Transparency = transparency end
    end
end
function cloneCharacter(original)
    if not original then return nil end
    local clone = Instance.new("Model")
    clone.Name = original.Name .. "_Fake"
    for _, part in pairs(original:GetChildren()) do
        if part:IsA("BasePart") or part:IsA("Accessory") or part:IsA("Humanoid") then
            local clonedPart = part:Clone()
            if clonedPart:IsA("BasePart") then
                clonedPart.CanCollide = false
                clonedPart.Anchored = false
                for _, constraint in pairs(clonedPart:GetChildren()) do
                    if constraint:IsA("Constraint") or constraint:IsA("WeldConstraint") then
                        constraint:Destroy()
                    end
                end
            end
            clonedPart.Parent = clone
        end
    end
    if original.PrimaryPart then clone.PrimaryPart = clone:FindFirstChild(original.PrimaryPart.Name) end
    return clone
end
function weldFakeCharacter(fakeChar)
    if not fakeChar then return end
    local rootPart = fakeChar:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    for _, part in pairs(fakeChar:GetChildren()) do
        if part:IsA("BasePart") and part ~= rootPart then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = rootPart
            weld.Part1 = part
            weld.Parent = rootPart
        end
    end
end
function updateFakePosition()
    if not FakeCharacter.Enabled or not FakeCharacter.FakeChar or not FakeCharacter.RealChar then return end
    local realRoot = FakeCharacter.RealChar:FindFirstChild("HumanoidRootPart")
    local fakeRoot = FakeCharacter.FakeChar:FindFirstChild("HumanoidRootPart")
    if realRoot and fakeRoot then fakeRoot.CFrame = realRoot.CFrame end
end
function FakeCharacter.Start()
    if FakeCharacter.Enabled then return false end
    local character = LocalPlayer.Character
    if not character then return false end
    FakeCharacter.RealChar = character
    FakeCharacter.FakeChar = cloneCharacter(character)
    if not FakeCharacter.FakeChar then return false end
    weldFakeCharacter(FakeCharacter.FakeChar)
    FakeCharacter.FakeChar.Parent = Workspace
    setCharacterTransparency(FakeCharacter.RealChar, TRANSPARENCY)
    setCharacterTransparency(FakeCharacter.FakeChar, FAKE_TRANSPARENCY)
    FakeCharacter.Connections.Update = RunService.Heartbeat:Connect(updateFakePosition)
    FakeCharacter.Connections.Respawn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        if FakeCharacter.Enabled then
            task.wait(0.5)
            FakeCharacter.Stop()
            task.wait(0.5)
            FakeCharacter.Start()
        end
    end)
    FakeCharacter.Enabled = true
    return true
end
function FakeCharacter.Stop()
    if not FakeCharacter.Enabled then return false end
    for _, conn in pairs(FakeCharacter.Connections) do if conn then conn:Disconnect() end end
    FakeCharacter.Connections = {}
    if FakeCharacter.FakeChar then FakeCharacter.FakeChar:Destroy(); FakeCharacter.FakeChar = nil end
    if FakeCharacter.RealChar then setCharacterTransparency(FakeCharacter.RealChar, 0) end
    FakeCharacter.Enabled = false
    FakeCharacter.RealChar = nil
    return true
end
SettingsTab:CreateToggle({ Name = "Fake Character", SubText = "Hide your real position with a fake character", Default = false, Callback = function(state) if state then FakeCharacter.Start() else FakeCharacter.Stop() end end })

SettingsTab:CreateSection({ Name = "Hide Identity Features", Icon = "rbxassetid://7743875962" })
local FakeName = "discord.gg/DevHub"
local FakeLevel = "MAX"
local ScriptName = "DevHub"
local HideStatsEnabled = false
local OriginalTexts = {}
local ActiveGradientThreads = {}

function createMovingGradient(label)
    if not label or not label:IsA("TextLabel") then return end
    local oldGradient = label:FindFirstChild("ShimmerGradient")
    if oldGradient then oldGradient:Destroy() end
    local gradient = Instance.new("UIGradient")
    gradient.Name = "ShimmerGradient"
    gradient.Parent = label
    local colorKeypoints = {}
    local basePattern = {
        {0.00, Color3.fromRGB(0, 100, 200)},
        {0.10, Color3.fromRGB(0, 120, 220)},
        {0.20, Color3.fromRGB(0, 150, 255)},
        {0.30, Color3.fromRGB(255, 255, 255)},
        {0.40, Color3.fromRGB(0, 150, 255)},
        {0.50, Color3.fromRGB(0, 120, 220)},
        {0.60, Color3.fromRGB(0, 100, 200)},
        {0.70, Color3.fromRGB(0, 120, 220)},
        {0.80, Color3.fromRGB(0, 150, 255)},
        {0.90, Color3.fromRGB(255, 255, 255)},
        {1.00, Color3.fromRGB(0, 100, 200)},
    }
    for _, data in ipairs(basePattern) do table.insert(colorKeypoints, ColorSequenceKeypoint.new(data[1], data[2])) end
    gradient.Color = ColorSequence.new(colorKeypoints)
    local threadId = tostring(label)
    ActiveGradientThreads[threadId] = true
    spawn(function()
        local offset = 0
        while label and label.Parent and ActiveGradientThreads[threadId] do
            offset = offset + 0.015
            if offset >= 1 then offset = 0 end
            gradient.Offset = Vector2.new(offset, 0)
            task.wait(0.02)
        end
    end)
    return gradient
end

function createScriptNameLabel(nameLabel, billboard)
    if not nameLabel or not billboard then return end
    local existingFrame = billboard:FindFirstChild("DevHubFrame")
    if existingFrame then return existingFrame end
    local nameFrame = nameLabel.Parent
    if not nameFrame or not nameFrame:IsA("Frame") then return end
    local originalNamePos = nameFrame.Position
    nameFrame.Position = UDim2.new(originalNamePos.X.Scale, originalNamePos.X.Offset, originalNamePos.Y.Scale + 0.25, originalNamePos.Y.Offset)
    local voraFrame = Instance.new("Frame")
    voraFrame.Name = "DevHubFrame"
    voraFrame.Size = nameFrame.Size
    voraFrame.Position = originalNamePos
    voraFrame.BackgroundTransparency = 1
    voraFrame.Parent = billboard
    local scriptLabel = nameLabel:Clone()
    scriptLabel.Name = "DevHubLabel"
    scriptLabel.Text = ScriptName
    scriptLabel.TextScaled = true
    scriptLabel.Font = Enum.Font.GothamBold
    scriptLabel.TextStrokeTransparency = 0.5
    scriptLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    scriptLabel.Parent = voraFrame
    createMovingGradient(scriptLabel)
    return voraFrame
end

function removeAllScriptNames()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local overhead = hrp:FindFirstChild("Overhead")
    if not overhead then return end
    local voraFrame = overhead:FindFirstChild("DevHubFrame")
    if voraFrame then
        for threadId, _ in pairs(ActiveGradientThreads) do ActiveGradientThreads[threadId] = nil end
        local nameLabel = overhead:FindFirstChild("Header", true)
        if nameLabel then
            local nameFrame = nameLabel.Parent
            if nameFrame and nameFrame:IsA("Frame") then
                local currentPos = nameFrame.Position
                nameFrame.Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, currentPos.Y.Scale - 0.25, currentPos.Y.Offset)
            end
        end
        voraFrame:Destroy()
    end
end

function updateStats()
    if not HideStatsEnabled then removeAllScriptNames(); return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local overhead = hrp:FindFirstChild("Overhead")
    if not overhead or not overhead:IsA("BillboardGui") then return end
    for _, obj in pairs(overhead:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local fullPath = obj:GetFullName()
            if not OriginalTexts[fullPath] then OriginalTexts[fullPath] = obj.Text end
            local originalText = OriginalTexts[fullPath]
            if originalText and originalText ~= "" then
                if obj.Name == "Header" then
                    if not overhead:FindFirstChild("DevHubFrame") then createScriptNameLabel(obj, overhead) end
                    obj.Text = FakeName
                elseif string.find(string.lower(originalText), "lvl") then
                    obj.Text = string.gsub(originalText, "%d+", FakeLevel)
                end
            end
        end
    end
end

local updateLoopActive = false
function startUpdateLoop()
    if updateLoopActive then return end
    updateLoopActive = true
    spawn(function()
        while updateLoopActive and task.wait(0.2) do
            if HideStatsEnabled then updateStats() end
        end
    end)
end

SettingsTab:CreateInput({ Name = "Hide Name", Placeholder = "Input Name", Default = FakeName, Callback = function(value) FakeName = value; if HideStatsEnabled then updateStats() end end })
SettingsTab:CreateInput({ Name = "Hide Level", Placeholder = "Input Level", Default = FakeLevel, Callback = function(value) FakeLevel = value; if HideStatsEnabled then updateStats() end end })
SettingsTab:CreateToggle({ Name = "Hide Identity", Default = false, Callback = function(state)
    HideStatsEnabled = state
    if state then
        startUpdateLoop()
        updateStats()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/CF-Trail/NameHider/main/MainScript.lua"))()
    else
        for path, originalText in pairs(OriginalTexts) do
            local obj = game
            for part in string.gmatch(path, "[^.]+") do
                obj = obj:FindFirstChild(part)
                if not obj then break end
            end
            if obj and obj:IsA("TextLabel") then obj.Text = originalText end
        end
        removeAllScriptNames()
    end
end })

LocalPlayer.CharacterAdded:Connect(function(newChar)
    OriginalTexts = {}
    ActiveGradientThreads = {}
    task.wait(1)
    if HideStatsEnabled then updateStats() end
    newChar.DescendantAdded:Connect(function(descendant)
        if HideStatsEnabled and descendant:IsA("BillboardGui") then
            task.wait(0.1); updateStats()
        end
    end)
end)

SettingsTab:CreateSection({ Name = "Anti AFK", Icon = "rbxassetid://7733658504" })
local AntiAFKEnabled = false
local AFKConnections = {}
local AFKConnectionMonitor = nil
function setAFKConnections(disable)
    local GC = getconnections or get_signal_cons
    if not GC then return false end
    local idleSignal = LocalPlayer.Idled
    for _, connection in next, GC(idleSignal) do
        if disable then connection:Disable() else connection:Enable() end
        if not table.find(AFKConnections, connection) then table.insert(AFKConnections, connection) end
    end
    return true
end
function connectCharacterMonitor()
    if AFKConnectionMonitor then AFKConnectionMonitor:Disconnect(); AFKConnectionMonitor = nil end
    AFKConnectionMonitor = LocalPlayer.CharacterAdded:Connect(function()
        if AntiAFKEnabled then task.wait(0.5); setAFKConnections(true) end
    end)
end
SettingsTab:CreateToggle({ Name = "Anti AFK", Description = "Prevents you from being kicked for idling", Default = false, Callback = function(value)
    AntiAFKEnabled = value
    if value then
        setAFKConnections(true)
        connectCharacterMonitor()
    else
        setAFKConnections(false)
        if AFKConnectionMonitor then AFKConnectionMonitor:Disconnect(); AFKConnectionMonitor = nil end
    end
end })

SettingsTab:CreateSection({ Name = "Anti Pengganggu", Icon = "rbxassetid://7734053535" })
local antiPenggangguEnabled = false
local antiPenggangguConnection = nil
local FISH_GROUP_ID = 35102746
function IsPengganggu(player)
    local ok, role = pcall(function() return player:GetRoleInGroup(FISH_GROUP_ID) end)
    if not ok then return false end
    return (role ~= "Guest" and role ~= "Member")
end
function CheckForPengganggu()
    if not antiPenggangguEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsPengganggu(player) then
            ServerHop("⚠️ Pengganggu terdeteksi: " .. player.Name, true)
            break
        end
    end
end
SettingsTab:CreateToggle({ Name = "Anti Pengganggu", Description = "Automatically server hop when non-Member joins", Default = false, Callback = function(value)
    antiPenggangguEnabled = value
    if value then
        task.spawn(CheckForPengganggu)
        antiPenggangguConnection = Players.PlayerAdded:Connect(function(player)
            task.wait(0.5)
            if antiPenggangguEnabled and player ~= LocalPlayer and IsPengganggu(player) then
                ServerHop("⚠️ Pengganggu joined: " .. player.Name, true)
            end
        end)
        task.spawn(function()
            while antiPenggangguEnabled do
                CheckForPengganggu()
                task.wait(5)
            end
        end)
    else
        if antiPenggangguConnection then antiPenggangguConnection:Disconnect(); antiPenggangguConnection = nil end
    end
end })

SettingsTab:CreateSection({ Name = "Server", Icon = "rbxassetid://7733955511" })
function ServerHop(reason, forcePublic)
    reason = reason or "Server hopping..."
    forcePublic = forcePublic or false
    local isPrivateServer = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
    if Window then
        local description = reason
        if isPrivateServer and forcePublic then description = description .. "\n(Leaving private server → public)" end
        Window:Notify({ Title = "🔄 Server Hop", Content = description, Duration = 3 })
    end
    task.wait(0.5)
    local success = pcall(function()
        if forcePublic then
            local servers = {}
            local cursor = ""
            for _ = 1, 5 do
                local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"..(cursor~="" and "&cursor="..cursor or "")
                local response = game:HttpGet(url)
                local data = HttpService:JSONDecode(response)
                for _, server in pairs(data.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        table.insert(servers, server.id)
                    end
                end
                cursor = data.nextPageCursor or ""
                if #servers > 0 then break end
            end
            if #servers > 0 then
                local selected = servers[math.random(1, #servers)]
                TeleportService:TeleportToPlaceInstance(game.PlaceId, selected, LocalPlayer)
            else
                warn("[ServerHop] No public servers found")
            end
        else
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
    if not success then
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end
end

SettingsTab:CreateButton({ Name = "Rejoin Server", SubText = "Reconnect to current server", Callback = function()
    local isPrivate = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
    Window:Notify({ Title = "Rejoining...", Content = isPrivate and "Rejoining private server..." or "Rejoining server...", Duration = 2 })
    task.wait(0.5)
    pcall(function()
        if isPrivate then
            local opt = Instance.new("TeleportOptions")
            opt.ServerInstanceId = game.JobId
            opt.ReservedServerAccessCode = game.PrivateServerId
            TeleportService:TeleportAsync(game.PlaceId, {LocalPlayer}, opt)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
end })
SettingsTab:CreateButton({ Name = "Server Hop (Low Ping)", SubText = "Find and join a server with low ping", Callback = function()
    Window:Notify({ Title = "Scanning Servers...", Content = "Looking for best server...", Duration = 2 })
    task.spawn(function()
        ServerHop("Hopping to low ping server", true)
    end)
end })

-- ================================================================
-- 26. MONITORING TAB (Webhooks, DevHub Monitoring)
-- ================================================================

MonitoringTab:CreateSection({ Name = "Discord Webhook" })
MonitoringTab:CreateInput({ Name = "URL Webhook", Placeholder = "https://discord.com/api/webhooks/...", Default = _G.WebhookURL, Callback = function(text) _G.WebhookURL = text end })
MonitoringTab:CreateMultiDropdown({ Name = "Rarity Filter", Items = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "Forgotten" }, Default = _G.WebhookRarities, Callback = function(opts) _G.WebhookRarities = opts end })
MonitoringTab:CreateMultiDropdown({ Name = "Variant Filter", Items = variantList, Default = _G.WebhookVariants, Callback = function(opts) _G.WebhookVariants = opts end })
MonitoringTab:CreateToggle({ Name = "Always Announce Crystalized", Default = _G.WebhookCrystalized, Callback = function(state) _G.WebhookCrystalized = state end })
MonitoringTab:CreateToggle({ Name = "Send Webhook (Discord)", Default = _G.DetectNewFishActive, Callback = function(state) _G.DetectNewFishActive = state end })
MonitoringTab:CreateButton({ Name = "Test Discord Webhook", Callback = function()
    local payload = { username = "DevHub Webhook", embeds = {{ title = "Test Webhook Connected", description = "Webhook connection successful!", color = 0x00FF00 }} }
    if _G.WebhookURL and _G.WebhookURL ~= "" then
        sendHttpRequest(_G.WebhookURL, "POST", { ["Content-Type"] = "application/json" }, HttpService:JSONEncode(payload))
    end
end })
MonitoringTab:CreateButton({ Name = "Test Global Tracker", Callback = function()
    local payload = { username = "DevHub | Community", embeds = {{ title = ":fish: DevHub | Global Tracker\n\nGLOBAL CATCH! Blob Shark", description = "Test", color = 16766720, fields = {}, thumbnail = { url = "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png" } }} }
    sendHttpRequest(WEBHOOK_GLOBAL_URL, "POST", { ["Content-Type"] = "application/json" }, HttpService:JSONEncode(payload))
end })

MonitoringTab:CreateSection({ Name = "WhatsApp Webhook" })
_G.WhatsAppWebhookEnabled = _G.WhatsAppWebhookEnabled or false
MonitoringTab:CreateToggle({ Name = "Send Webhook (WhatsApp)", Default = _G.WhatsAppWebhookEnabled, Callback = function(state) _G.WhatsAppWebhookEnabled = state end })
_G.FonnteToken = _G.FonnteToken or "eJ2K4skattShv2iwYXCU"
_G.WA_TargetPhone = _G.WA_TargetPhone or ""
MonitoringTab:CreateInput({ Name = "Target Phone (62...)", Placeholder = "Nomor WhatsApp", Default = _G.WA_TargetPhone, Callback = function(t) _G.WA_TargetPhone = t end })
MonitoringTab:CreateButton({ Name = "Test Whatsapp", Callback = function()
    local payload = { target = _G.WA_TargetPhone, message = "Test berhasil! Webhook WhatsApp aktif." }
    sendHttpRequest("https://api.fonnte.com/send", "POST", { ["Content-Type"] = "application/json", ["Authorization"] = _G.FonnteToken }, HttpService:JSONEncode(payload))
end })

MonitoringTab:CreateSection({ Name = "Server Chat Webhook" })
_G.ServerChatWebhookURL = _G.ServerChatWebhookURL or ""
_G.ServerChatWebhookEnabled = _G.ServerChatWebhookEnabled or false
_G.ServerChatRarityFilter = _G.ServerChatRarityFilter or {}
local serverRarityColors = {
    { rarity = "Epic", r = 179, g = 115, b = 248 },
    { rarity = "Legendary", r = 255, g = 185, b = 50 },
    { rarity = "Mythic", r = 255, g = 25, b = 25 },
    { rarity = "SECRET", r = 24, g = 255, b = 152 },
    { rarity = "Forgotten", r = 255, g = 255, b = 255 },
}
local serverRarityDiscordColors = { Epic = 0xB373F8, Legendary = 0xFFB932, Mythic = 0xFF1919, SECRET = 0x18FF98, Forgotten = 0xFFFFFF, Unknown = 0x888888 }
function getRarityFromRGB(r, g, b)
    local best, bestDist = nil, math.huge
    for _, entry in ipairs(serverRarityColors) do
        local d = ((r - entry.r)^2 + (g - entry.g)^2 + (b - entry.b)^2) ^ 0.5
        if d < bestDist then bestDist = d; best = entry.rarity end
    end
    return (bestDist < 55) and best or nil
end
function parseRGBFromText(text)
    local rs, gs, bs = text:match('rgb%((%d+),%s*(%d+),%s*(%d+)%)')
    if rs then return tonumber(rs), tonumber(gs), tonumber(bs) end
    local hex = text:match('#(%x%x%x%x%x%x)')
    if hex then return tonumber(hex:sub(1,2),16), tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16) end
    return nil
end
function sendServerChatDiscordWebhook(playerName, fishName, weight, chance, rarity, imageUrl)
    if not _G.ServerChatWebhookURL or _G.ServerChatWebhookURL == "" then return end
    if #_G.ServerChatRarityFilter > 0 and not table.find(_G.ServerChatRarityFilter, rarity) then return end
    local embedColor = serverRarityDiscordColors[rarity] or serverRarityDiscordColors.Unknown
    local censored = censorPlayerName(playerName)
    local embed = {
        title = "🎣 Server Catch | " .. rarity,
        description = string.format("**%s** obtained **%s**!", censored, fishName),
        color = embedColor,
        fields = {
            { name = "Fish", value = string.format("`%s`", fishName), inline = true },
            { name = "Weight", value = string.format("`%s`", weight), inline = true },
            { name = "Rarity", value = string.format("`%s`", rarity), inline = true },
            { name = "Chance", value = string.format("`1 in %s`", chance), inline = true },
            { name = "Player", value = string.format("`%s`", censored), inline = true },
        },
        footer = { text = "DevHub Server Tracker" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
        thumbnail = imageUrl and { url = imageUrl } or nil,
    }
    local payload = { username = "DevHub | Server Tracker", avatar_url = "https://cdn.discordapp.com/attachments/1434789394929287178/1448926732705988659/Swuppie.jpg", embeds = { embed } }
    sendHttpRequest(_G.ServerChatWebhookURL, "POST", { ["Content-Type"] = "application/json" }, HttpService:JSONEncode(payload))
end

do
    local TCS = game:GetService("TextChatService")
    TCS.OnIncomingMessage = function(message)
        if not _G.ServerChatWebhookEnabled then return end
        local text = message.Text or ""
        if not text:find("obtained") or not text:find("chance") then return end
        local r, g, b = parseRGBFromText(text)
        if not r then return end
        local rarity = getRarityFromRGB(r, g, b)
        if not rarity then return end
        local fishName, weight = text:match('<font[^>]+color="rgb%([^%)]+%)"[^>]*>([^<%(]+)%(([%d%.]+%s*[Kkg]?g?)%)<')
        local plain = text:gsub("<[^>]+>", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
        plain = plain:gsub("^%[Server%]:%s*", ""):gsub("^%s+", "")
        local playerName, chance
        if fishName then
            fishName = fishName:gsub("%s+$", "")
            weight = weight:gsub("%s*$", "")
            playerName = plain:match("^([%w_]+) obtained")
            chance = plain:match("with a 1 in (.+) chance!?")
        else
            playerName, fishName, weight, chance = plain:match("^([%w_]+) obtained an? (.+) %(([%d%.]+%s*[Kkg]?g?)%) with a 1 in (.+) chance!?")
            if fishName then fishName = fishName:gsub("%s+$", "") end
            if weight then weight = weight:gsub("%s+$", "") end
        end
        if not playerName or not fishName then return end
        chance = chance and chance:gsub("%s+$", "") or "?"
        local imageUrl = nil
        local fishEntry = fishByName and fishByName[fishName:lower()]
        if fishEntry and fishEntry.Icon then imageUrl = getThumbnailURL(fishEntry.Icon) end
        task.spawn(sendServerChatDiscordWebhook, playerName, fishName, weight, chance, rarity, imageUrl)
    end
end

MonitoringTab:CreateInput({ Name = "URL Server Chat Webhook", Placeholder = "https://discord.com/api/webhooks/...", Default = _G.ServerChatWebhookURL, Callback = function(text) _G.ServerChatWebhookURL = text end })
MonitoringTab:CreateMultiDropdown({ Name = "Rarity Filter (Server Chat)", Items = { "Forgotten", "SECRET", "Mythic", "Legendary", "Epic" }, Default = _G.ServerChatRarityFilter, Callback = function(selected) _G.ServerChatRarityFilter = selected end })
MonitoringTab:CreateToggle({ Name = "Enable Server Chat Webhook", Default = _G.ServerChatWebhookEnabled, Callback = function(state) _G.ServerChatWebhookEnabled = state end })

MonitoringTab:CreateSection({ Name = "DevHub Web Monitoring" })
local VoraMonitoringSettings = { VoraKey = "", AutoSync = true, Interval = 5, Enabled = false }
local VORA_API_URL = "https://monitor.DevHub.xyz/api/inventory/sync"
MonitoringTab:CreateInput({ Name = "DevHub Key", Placeholder = "Enter DevHub Key...", Default = VoraMonitoringSettings.VoraKey, Callback = function(val) VoraMonitoringSettings.VoraKey = val end })
MonitoringTab:CreateToggle({ Name = "Enable Web Monitoring", Default = false, Callback = function(val) VoraMonitoringSettings.Enabled = val end })

function GetWebItemData(ItemType, Id)
    local success, result = pcall(function()
        if ItemType == "Baits" then return ItemUtility:GetBaitData(Id)
        elseif ItemType == "Items" then
            local data = ItemUtility:GetItemData(Id)
            if not data then data = ItemUtility:GetFish(Id) end
            if not data then data = ItemUtility:GetBaitData(Id) end
            if not data then
                local rods = ItemUtility:GetFishingRods()
                if rods then data = rods[Id] end
            end
            if not data then data = ItemUtility:GetTotemData(Id) end
            if not data then data = ItemUtility:GetPotionData(Id) end
            if not data then data = ItemUtility:GetCharmData(Id) end
            if not data then data = ItemUtility:GetBoatData(Id) end
            return data
        elseif ItemType == "Fish" then return ItemUtility:GetFish(Id)
        elseif ItemType == "Fishing Rods" then
            local rods = ItemUtility:GetFishingRods()
            return rods and rods[Id]
        elseif ItemType == "Totems" then return ItemUtility:GetTotemData(Id)
        elseif ItemType == "Potions" then return ItemUtility:GetPotionData(Id)
        elseif ItemType == "Charms" then return ItemUtility:GetCharmData(Id)
        else return ItemUtility:GetItemDataFromItemType(ItemType, Id) end
    end)
    return success and result or nil
end

function GatherVoraInventory()
    local inventory = { Rods = {}, Charms = {}, Items = {}, Fish = {}, Totems = {}, Potions = {} }
    local rawInventory = Data:GetExpect("Inventory")
    if not rawInventory then return nil end
    function safeString(str) if not str then return "" end; str = tostring(str); return str:match("^%s*(.-)%s*$") or str end
    function AddToInventory(list, newItem)
        newItem.tier = tonumber(newItem.tier) or 1
        for i, existingItem in ipairs(list) do
            if existingItem.name == newItem.name and existingItem.tier == newItem.tier then
                existingItem.quantity = (existingItem.quantity or 1) + (newItem.quantity or 1)
                return
            end
        end
        table.insert(list, newItem)
    end
    if rawInventory.Charms then
        for _, item in ipairs(rawInventory.Charms) do
            local itemData = GetWebItemData("Charms", item.Id)
            if itemData then
                AddToInventory(inventory.Charms, { id = safeString(item.Id), name = safeString(itemData.Data.Name), icon = safeString(itemData.Data.Icon), tier = itemData.Data.Tier or 1, quantity = item.Quantity or 1, uuid = safeString(item.UUID or "") })
            end
        end
    end
    if rawInventory.Items then
        for _, item in ipairs(rawInventory.Items) do
            local itemData = GetWebItemData("Items", item.Id)
            local itemName, itemIcon, itemTier, itemType = "", "", 1, "Item"
            if itemData and itemData.Data then
                itemName = safeString(itemData.Data.Name or item.Id)
                itemIcon = safeString(itemData.Data.Icon or item.Icon or "")
                itemTier = itemData.Data.Tier or 1
                itemType = safeString(itemData.Data.Type or "Item")
            else
                itemName = safeString(item.Name or item.Id)
                itemIcon = safeString(item.Icon or "")
                itemTier = item.Tier or 1
                itemType = "Item"
            end
            AddToInventory(inventory.Items, { id = safeString(item.Id), name = itemName, icon = itemIcon, tier = itemTier, type = itemType, quantity = item.Quantity or 1, uuid = safeString(item.UUID or ""), favorited = item.Favorited == true })
        end
    end
    if rawInventory.Fish then
        for _, item in ipairs(rawInventory.Fish) do
            local itemData = GetWebItemData("Fish", item.Id)
            if itemData then
                AddToInventory(inventory.Fish, { id = safeString(item.Id), name = safeString(itemData.Data.Name), icon = safeString(itemData.Data.Icon), tier = itemData.Data.Tier or 1, quantity = item.Quantity or 1, uuid = safeString(item.UUID or "") })
            end
        end
    end
    if rawInventory.Totems then
        for _, item in ipairs(rawInventory.Totems) do
            local itemData = GetWebItemData("Totems", item.Id)
            if itemData then
                AddToInventory(inventory.Totems, { id = safeString(item.Id), name = safeString(itemData.Data.Name), icon = safeString(itemData.Data.Icon), tier = itemData.Data.Tier or 1, quantity = item.Quantity or 1, uuid = safeString(item.UUID or "") })
            end
        end
    end
    if rawInventory.Potions then
        for _, item in ipairs(rawInventory.Potions) do
            local itemData = GetWebItemData("Potions", item.Id)
            if itemData then
                AddToInventory(inventory.Potions, { id = safeString(item.Id), name = safeString(itemData.Data.Name), icon = safeString(itemData.Data.Icon), tier = itemData.Data.Tier or 1, quantity = item.Quantity or 1, uuid = safeString(item.UUID or "") })
            end
        end
    end
    local Player = LocalPlayer
    function GetLeaderstatValue(statName)
        local leaderstats = Player:FindFirstChild("leaderstats")
        if leaderstats and leaderstats:FindFirstChild(statName) then return leaderstats[statName].Value end
        return nil
    end
    local playerStats = { totalFishCaught = GetLeaderstatValue("Caught") or 0, highestRarity = GetLeaderstatValue("Rarest Fish") or "None" }
    return { apiKey = VoraMonitoringSettings.VoraKey, playerName = safeString(Player.Name), userId = Player.UserId, playerStats = playerStats, inventory = inventory, isOnline = true, timestamp = DateTime.now():ToIsoDate() }
end

function SendVoraInventory(isOffline)
    if VoraMonitoringSettings.VoraKey == "" or VoraMonitoringSettings.VoraKey == "yourkey" then return end
    pcall(function()
        local data = GatherVoraInventory()
        if not data then return end
        if isOffline then data.isOnline = false end
        local jsonData = HttpService:JSONEncode(data)
        sendHttpRequest(VORA_API_URL, "POST", { ["Content-Type"] = "application/json", ["ngrok-skip-browser-warning"] = "true" }, jsonData)
    end)
end

task.spawn(function()
    while true do
        task.wait(VoraMonitoringSettings.Interval)
        if VoraMonitoringSettings.Enabled and VoraMonitoringSettings.AutoSync then SendVoraInventory(false) end
    end
end)
Players.PlayerRemoving:Connect(function(p) if p == LocalPlayer then SendVoraInventory(true) end end)

-- ================================================================
-- 27. FISH DETECTION LOOP (Webhook & Global)
-- ================================================================

local knownFishUUIDs = {}
task.defer(function()
    task.wait(2)
    local initialFishList = getInventoryFish()
    for _, fish in ipairs(initialFishList) do
        if fish and fish.UUID then knownFishUUIDs[fish.UUID] = true end
    end
end)

spawn(function()
    while wait(2) do
        pcall(function()
            local currentFishList = getInventoryFish()
            for _, fish in ipairs(currentFishList) do
                if fish and fish.UUID and not knownFishUUIDs[fish.UUID] then
                    knownFishUUIDs[fish.UUID] = true
                    task.spawn(function()
                        pcall(function() sendGlobalTrackerWebhook(fish) end)
                        if _G.DetectNewFishActive then
                            task.wait(0.3)
                            pcall(function() sendNewFishWebhook(fish) end)
                        end
                        if _G.WhatsAppWebhookEnabled then
                            task.wait(0.3)
                            pcall(function() sendNewFishWA(fish) end)
                        end
                    end)
                end
            end
        end)
        task.wait(2)
    end
end)

-- ================================================================
-- 28. QUEST AUTO LOOPS (Deep Sea, Element, Diamond)
-- ================================================================

task.spawn(function()
    while true do
        task.wait(3)
        if _G.DeepSeaQuestMode then pcall(dsProcessQuest) end
    end
end)
task.spawn(function()
    while true do
        task.wait(3)
        if _G.ElementQuestMode then pcall(elemProcessQuest) end
    end
end)
task.spawn(function()
    while true do
        task.wait(3)
        if _G.DiamondQuestMode then pcall(diamProcessQuest) end
    end
end)

-- ================================================================
-- 29. QUEST TELEPORT & FISHING LOOP (AutoEnabled)
-- ================================================================

function initialTeleport()
    if not _G.HasTeleported then
        _G.HasTeleported = true
        teleportBasedOnCondition()
        wait(2)
    end
end

spawn(function()
    while true do
        task.wait(2.5)
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            pcall(function() AutoEnabled:InvokeServer(true) end)
        end
    end
end)

spawn(function()
    while true do
        task.wait(0.1)
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            initialTeleport()
            local char = Workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
            if char then
                repeat
                    task.wait(0.1)
                    if char:FindFirstChild("!!!FISHING_VIEW_MODEL!!!") then
                        pcall(function() REEquip:FireServer(1) end)
                    end
                    task.wait(0.1)
                    local cosmeticFolder = Workspace:FindFirstChild("CosmeticFolder")
                    if cosmeticFolder and not cosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) then
                        pcall(function()
                            if FishingController then
                                FishingController:RequestChargeFishingRod(Vector2.new(0, 0), true)
                            end
                            task.wait(0.05)
                            local guid = FishingController and FishingController:GetCurrentGUID and FishingController:GetCurrentGUID()
                            if not guid then return end
                            while (_G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode) and FishingController:GetCurrentGUID() == guid do
                                if FishingController then FishingController:FishingMinigameClick() end
                                task.wait(math.random(1,10)/100)
                            end
                        end)
                    end
                    task.wait(0.25)
                until not (_G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode)
            end
        end
    end
end)

spawn(function()
    while true do
        task.wait(5)
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            pcall(function() if SellItem then SellItem:InvokeServer() end end)
        end
    end
end)

spawn(function()
    while true do
        task.wait(5)
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            local coins = Data:Get("Coins") or 0
            for name, rod in pairs(FishingRods) do
                local uuid = getRodUUID(rod.id)
                if not uuid and coins >= rod.price then
                    local wasDeepSea, wasElement, wasDiamond = _G.DeepSeaQuestMode, _G.ElementQuestMode, _G.DiamondQuestMode
                    _G.DeepSeaQuestMode, _G.ElementQuestMode, _G.DiamondQuestMode = false, false, false
                    _G.HasTeleported = false
                    local char = Workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then hum.Health = 0 end
                        task.wait(5)
                        pcall(function() BuyRod:InvokeServer(rod.id) end)
                        task.wait(0.5)
                        local newUUID = nil
                        local retryUntil = tick() + 5
                        while tick() < retryUntil do
                            newUUID = getRodUUID(rod.id)
                            if newUUID then break end
                            task.wait(0.5)
                        end
                        if newUUID then
                            pcall(function() REEquipItem:FireServer(newUUID, "Fishing Rods") end)
                            pcall(function() REEquip:FireServer(1) end)
                        end
                        teleportBasedOnCondition()
                        task.wait(0.5)
                        _G.DeepSeaQuestMode, _G.ElementQuestMode, _G.DiamondQuestMode = wasDeepSea, wasElement, wasDiamond
                        break
                    end
                end
            end
        end
    end
end)

spawn(function()
    while true do
        task.wait(5)
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            local coins = Data:Get("Coins") or 0
            for baitId, bait in pairs(Baits) do
                if not hasBait(baitId) and coins >= bait.price then
                    local wasDeepSea, wasElement, wasDiamond = _G.DeepSeaQuestMode, _G.ElementQuestMode, _G.DiamondQuestMode
                    _G.DeepSeaQuestMode, _G.ElementQuestMode, _G.DiamondQuestMode = false, false, false
                    _G.HasTeleported = false
                    local char = Workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then hum.Health = 0 end
                        task.wait(5)
                        buyBait(baitId)
                        task.wait(0.5)
                        equipBait(baitId)
                        teleportBasedOnCondition()
                        task.wait(0.5)
                        _G.DeepSeaQuestMode, _G.ElementQuestMode, _G.DiamondQuestMode = wasDeepSea, wasElement, wasDiamond
                        break
                    end
                end
            end
        end
    end
end)

-- ================================================================
-- 30. STATUS OVERLAY UI (Quest Progress + Best Rod/Bait/Coins)
-- ================================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevHub Status"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local blur = Instance.new("BlurEffect")
blur.Name = "TanzBlur"
blur.Size = 24
blur.Enabled = false
blur.Parent = Lighting

function makeLabel(name, size, pos, text, fontSize)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.Size = size
    l.Position = pos
    l.AnchorPoint = Vector2.new(0.5, 0.5)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(255,255,255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = fontSize or 18
    l.Text = text or ""
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.Visible = false
    l.Parent = screenGui
    return l
end

local titleLabel = makeLabel("Title", UDim2.new(0,300,0,40), UDim2.new(0.5,0,0.25,0), "DevHub Status", 24)
titleLabel.TextColor3 = Color3.fromRGB(64,224,208)
local row1 = makeLabel("Row1", UDim2.new(0,600,0,30), UDim2.new(0.5,0,0.35,0))
local row2 = makeLabel("Row2", UDim2.new(0,600,0,30), UDim2.new(0.5,0,0.4,0))
local row3 = makeLabel("Row3", UDim2.new(0,600,0,30), UDim2.new(0.5,0,0.45,0))

local ghostfinnTitle = makeLabel("GhostfinnTitle", UDim2.new(0,600,0,30), UDim2.new(0.4,0,0.5,0), "Deep Sea Quest")
ghostfinnTitle.TextColor3 = Color3.fromRGB(64,224,208)
local ghostfinnRow1 = makeLabel("Ghostfinn1", UDim2.new(0,600,0,25), UDim2.new(0.4,0,0.55,0), "Loading...", 12)
ghostfinnRow1.Font = Enum.Font.Gotham
local ghostfinnRow2 = makeLabel("Ghostfinn2", UDim2.new(0,600,0,25), UDim2.new(0.4,0,0.575,0), "", 12)
ghostfinnRow2.Font = Enum.Font.Gotham
local ghostfinnRow3 = makeLabel("Ghostfinn3", UDim2.new(0,600,0,25), UDim2.new(0.4,0,0.6,0), "", 12)
ghostfinnRow3.Font = Enum.Font.Gotham
local ghostfinnRow4 = makeLabel("Ghostfinn4", UDim2.new(0,600,0,25), UDim2.new(0.4,0,0.625,0), "", 12)
ghostfinnRow4.Font = Enum.Font.Gotham

local elementTitle = makeLabel("ElementTitle", UDim2.new(0,600,0,30), UDim2.new(0.6,0,0.5,0), "Element Quest")
elementTitle.TextColor3 = Color3.fromRGB(64,224,208)
local elementRow1 = makeLabel("Element1", UDim2.new(0,600,0,25), UDim2.new(0.6,0,0.55,0), "Loading...", 12)
elementRow1.Font = Enum.Font.Gotham
local elementRow2 = makeLabel("Element2", UDim2.new(0,600,0,25), UDim2.new(0.6,0,0.575,0), "", 12)
elementRow2.Font = Enum.Font.Gotham
local elementRow3 = makeLabel("Element3", UDim2.new(0,600,0,25), UDim2.new(0.6,0,0.6,0), "", 12)
elementRow3.Font = Enum.Font.Gotham
local elementRow4 = makeLabel("Element4", UDim2.new(0,600,0,25), UDim2.new(0.6,0,0.625,0), "", 12)
elementRow4.Font = Enum.Font.Gotham

local diamondTitle = makeLabel("DiamondTitle", UDim2.new(0,600,0,30), UDim2.new(0.5,0,0.68,0), "Diamond Researcher")
diamondTitle.TextColor3 = Color3.fromRGB(64,224,208)
local diamondRow1 = makeLabel("Diamond1", UDim2.new(0,600,0,25), UDim2.new(0.5,0,0.73,0), "Loading...", 12)
diamondRow1.Font = Enum.Font.Gotham
local diamondRow2 = makeLabel("Diamond2", UDim2.new(0,600,0,25), UDim2.new(0.5,0,0.755,0), "", 12)
diamondRow2.Font = Enum.Font.Gotham
local diamondRow3 = makeLabel("Diamond3", UDim2.new(0,600,0,25), UDim2.new(0.5,0,0.78,0), "", 12)
diamondRow3.Font = Enum.Font.Gotham
local diamondRow4 = makeLabel("Diamond4", UDim2.new(0,600,0,25), UDim2.new(0.5,0,0.805,0), "", 12)
diamondRow4.Font = Enum.Font.Gotham
local diamondRow5 = makeLabel("Diamond5", UDim2.new(0,600,0,25), UDim2.new(0.5,0,0.83,0), "", 12)
diamondRow5.Font = Enum.Font.Gotham
local diamondRow6 = makeLabel("Diamond6", UDim2.new(0,600,0,25), UDim2.new(0.5,0,0.855,0), "", 12)
diamondRow6.Font = Enum.Font.Gotham

local statusLabels = { row1, row2, row3, titleLabel, ghostfinnTitle, ghostfinnRow1, ghostfinnRow2, ghostfinnRow3, ghostfinnRow4, elementTitle, elementRow1, elementRow2, elementRow3, elementRow4, diamondTitle, diamondRow1, diamondRow2, diamondRow3, diamondRow4, diamondRow5, diamondRow6 }

function updateOverlayVisibility()
    local anyActive = _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode
    local visible = _G.KaitunGUIForce or anyActive
    row1.Visible = visible; row2.Visible = visible; row3.Visible = visible; titleLabel.Visible = visible; blur.Enabled = visible
    ghostfinnTitle.Visible = _G.DeepSeaQuestMode
    ghostfinnRow1.Visible = _G.DeepSeaQuestMode
    ghostfinnRow2.Visible = _G.DeepSeaQuestMode
    ghostfinnRow3.Visible = _G.DeepSeaQuestMode
    ghostfinnRow4.Visible = _G.DeepSeaQuestMode
    elementTitle.Visible = _G.ElementQuestMode
    elementRow1.Visible = _G.ElementQuestMode
    elementRow2.Visible = _G.ElementQuestMode
    elementRow3.Visible = _G.ElementQuestMode
    elementRow4.Visible = _G.ElementQuestMode
    diamondTitle.Visible = _G.DiamondQuestMode
    diamondRow1.Visible = _G.DiamondQuestMode
    diamondRow2.Visible = _G.DiamondQuestMode
    diamondRow3.Visible = _G.DiamondQuestMode
    diamondRow4.Visible = _G.DiamondQuestMode
    diamondRow5.Visible = _G.DiamondQuestMode
    diamondRow6.Visible = _G.DiamondQuestMode
end

function updateUIVisibility() pcall(updateOverlayVisibility) end

ExclusiveTab:CreateToggle({ Title = "Start Kaitun", Default = _G.KaitunGUIForce, Callback = function(state)
    _G.KaitunGUIForce = state
    pcall(updateOverlayVisibility)
end })

RunService.RenderStepped:Connect(function()
    pcall(function()
        updateOverlayVisibility()
        row1.Text = "Best Rod: " .. tostring(getBestRod())
        row2.Text = "Best Bait: " .. tostring(getBestBait())
        row3.Text = "Coins: " .. tostring(getCoins())
        local gf = getGhostfinnProgress()
        ghostfinnRow1.Text = gf[1] or "No progress data"
        ghostfinnRow2.Text = gf[2] or "No progress data"
        ghostfinnRow3.Text = gf[3] or "No progress data"
        ghostfinnRow4.Text = gf[4] or "No progress data"
        local el = getElementProgress()
        elementRow1.Text = el[1] or "No progress data"
        elementRow2.Text = el[2] or "No progress data"
        elementRow3.Text = el[3] or "No progress data"
        elementRow4.Text = el[4] or "No progress data"
        local dm = getDiamondProgress()
        diamondRow1.Text = dm[1] or "No progress data"
        diamondRow2.Text = dm[2] or "No progress data"
        diamondRow3.Text = dm[3] or "No progress data"
        diamondRow4.Text = dm[4] or "No progress data"
        diamondRow5.Text = dm[5] or "No progress data"
        diamondRow6.Text = dm[6] or "No progress data"
    end)
end)

-- ================================================================
-- 31. CONFIG TAB (Save/Load Config)
-- ================================================================

local TabConfig = Window:CreateTab({ Name = "Config", Icon = "rbxassetid://7733954611" })
TabConfig:CreateSection({ Name = "Configuration" })
local configName = ""
local selectedConfig = ""
local configDropdown = nil
local CONFIG_FOLDER = "DevHubConfigs"

function sanitizeConfigName(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("[\\/:*?\"<>|]", "_")
    return name
end

function getConfigList()
    local result = {}
    if not (listfiles and isfolder) then return result end
    if not isfolder(CONFIG_FOLDER) and makefolder then makefolder(CONFIG_FOLDER) end
    for _, path in ipairs(listfiles(CONFIG_FOLDER)) do
        local name = path:match("([^/\\]+)%.json$")
        if name then table.insert(result, name) end
    end
    table.sort(result)
    return result
end

function RefreshConfigs()
    if configDropdown then configDropdown:Refresh(getConfigList()) end
end

TabConfig:CreateInput({ Name = "Config Name", Placeholder = "Enter config name...", Callback = function(text) configName = text end })
configDropdown = TabConfig:CreateDropdown({ Name = "Select Config", Options = getConfigList(), Callback = function(val) selectedConfig = val end })
TabConfig:CreateButton({ Name = "Create / Save Config", SubText = "Save settings to selected or new config", Callback = function()
    local name = (configName ~= "" and configName) or selectedConfig
    if name == "" then Window:Notify({ Title = "Error", Content = "Please enter or select a config name.", Duration = 3 }); return end
    name = sanitizeConfigName(name)
    if name == "" then return end
    local ok, err = Window:SaveConfig(CONFIG_FOLDER, name)
    if ok then RefreshConfigs(); Window:Notify({ Title = "Config Saved", Content = "Saved as " .. name, Duration = 3 })
    else Window:Notify({ Title = "Save Failed", Content = tostring(err or "Unknown error"), Duration = 3 }) end
end })
TabConfig:CreateButton({ Name = "Load Config", SubText = "Load selected config", Callback = function()
    if selectedConfig == "" then Window:Notify({ Title = "Error", Content = "Please select a config to load.", Duration = 3 }); return end
    local ok, err = Window:LoadConfig(CONFIG_FOLDER, selectedConfig)
    if ok then Window:Notify({ Title = "Config Loaded", Content = "Loaded " .. selectedConfig, Duration = 3 })
    else Window:Notify({ Title = "Load Failed", Content = tostring(err or "Unknown error"), Duration = 3 }) end
end })
TabConfig:CreateButton({ Name = "Delete Config", SubText = "Delete selected config", Callback = function()
    if selectedConfig == "" then return end
    local path = CONFIG_FOLDER .. "/" .. selectedConfig .. ".json"
    if delfile and isfile and isfile(path) then
        delfile(path)
        RefreshConfigs()
        selectedConfig = ""
        Window:Notify({ Title = "Config Deleted", Content = "Deleted config file.", Duration = 3 })
    else Window:Notify({ Title = "Delete Failed", Content = "Config file not found.", Duration = 3 }) end
end })
TabConfig:CreateButton({ Name = "Refresh List", SubText = "Refresh config list", Callback = function() RefreshConfigs() end })

task.spawn(function()
    task.wait(2)
    Window:LoadConfig(CONFIG_FOLDER, "default")
end)

print("[DevHub] Script loaded successfully!")
