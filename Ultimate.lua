 ReplicatedStorage = game:GetService("ReplicatedStorage")
    local netFolder = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
    local netChildren = netFolder:GetChildren()

    -- Deteksi nama hex hash (bukan nama plain)
    function isHex(name)
        local stripped = name:gsub("^R[FE]/", "")
        return #stripped > 16 and stripped:match("^%x+$") ~= nil
    end

    -- Build map: "ChargeFishingRod" -> actual hashed Instance
    local remoteMap = {}
    for i, child in ipairs(netChildren) do
        if not isHex(child.Name) then
            local next = netChildren[i + 1]
            if next and isHex(next.Name) then
                local key = child.Name:gsub("^R[FE]/", "")
                remoteMap[key] = next
            end
        end
    end

function RF(name) return remoteMap[name] end
function RE(name) return remoteMap[name] end

-- Amblatant support: cached remote data & local event re-fire
_G.SavedData = _G.SavedData or {
    FishCaught = {},
    CaughtVisual = {},
    FishNotif = {}
}

function FireLocalEvent(remote, ...)
    if not remote or not remote.OnClientEvent then return end
    local args = {...}
    local signal = remote.OnClientEvent
    for _, connection in pairs(getconnections(signal)) do
        if connection.Function then
            task.spawn(function()
                pcall(function()
                    connection.Function(unpack(args))
                end)
            end)
        end
    end
end

local saveCount = 0

function GetServerRemote(humanName)
    local key = humanName:gsub("^R[FE]/", "")
    return remoteMap[key]
end

function HookRemote(humanName, storageKey)
    local remote = GetServerRemote(humanName)
    if remote then
        remote.OnClientEvent:Connect(function(...)
            if saveCount < 7 then
                _G.SavedData[storageKey] = {...}
                local args = {...}
                if storageKey == "CaughtVisual" then
                    local lp = game:GetService("Players").LocalPlayer
                    local myName = lp and lp.Name
                    if myName and tostring(args[1]) == tostring(myName) then
                        saveCount = saveCount + 1
                    end
                end
            end
        end)
        return true
    end
    return false
end

BuyRod              = RF("PurchaseFishingRod")
BuyBait             = RF("PurchaseBait")
BuyCharm            = RF("PurchaseCharm")
REFishDone          = RF("CatchFishCompleted")
REFishDoneRE        = RE("CatchFishCompleted")
BuyWeather          = RF("PurchaseWeatherEvent")
ChargeRod           = RF("ChargeFishingRod")
StartMini           = RF("RequestFishingMinigameStarted")
UpdateRadar         = RF("UpdateFishingRadar")
Cancel              = RF("CancelFishingInputs")
SellItem            = RF("SellAllItems")
AutoEnabled         = RF("UpdateAutoFishingState")
BuyMarket           = RF("PurchaseMarketItem")
InitiateTrade       = RF("InitiateTrade")
RFAwaitTradeResponse = RF("AwaitTradeResponse")
EquipOxygen         = RF("EquipOxygenTank")
UnequipOxygen       = RF("UnequipOxygenTank")
ConsumeCrystal      = RF("ConsumeCaveCrystal")
ConsumePotion       = RF("ConsumePotion")
threselod           = RF("UpdateAutoSellThreshold")
dialogevent         = RF("SpecialDialogueEvent")

RECutscene          = RE("ReplicateCutscene")
REStop              = RE("StopCutscene")
REFav               = RE("FavoriteItem")
REFavChg            = RE("FavoriteStateChanged")
REFishGot           = RE("FishCaught")
RENotify            = RE("TextNotification")
REEquip             = RE("EquipToolFromHotbar")
REEquipItem         = RE("EquipItem")
REAltar             = RE("ActivateEnchantingAltar")
REAltar2            = RE("ActivateSecondEnchantingAltar")
REPlayFishEffect    = RE("PlayFishingEffect")
RETextEffect        = RE("ReplicateTextEffect")
Totem               = RE("SpawnTotem")
FishingMinigameChanged = RE("FishingMinigameChanged")
FishingStopped      = RE("FishingStopped")
REEvReward          = RE("ClaimEventReward")
REEquipCharm        = RE("EquipCharm")
REUnequipCharm      = RE("UnequipCharm")
BaitSpawned         = RE("BaitSpawned")
BaitDestroyed       = RE("BaitDestroyed")
PirateChest         = RE("ClaimPirateChest")
GainMaze            = RE("GainAccessToMaze")
PlaceLever          = RE("PlaceLeverItem")
REDialogueEnded      = RE("DialogueEnded")
RFCreateTranscendedStone = RF("CreateTranscendedStone")
EquipBait           = RE("EquipBait")

-- moons.lua: Config / Events / Tasks / needCast / skip / blatantFishCycleCount (FAST 3 KEDIP & UB)
Config = {
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
Tasks = {}
blatantFishCycleCount = 0
needCast = false
skip = false
Events = {}

function safeFire(func)
    task.spawn(function()
        pcall(func)
    end)
end

-- sleitnick_net often exposes RF/* as RemoteEvent; use FireServer in that case.
function CallRemoteServer(remote, ...)
    if not remote then return false end
    local ok
    if remote:IsA("RemoteFunction") then
        ok = select(1, pcall(function(...)
            remote:InvokeServer(...)
        end, ...))
    elseif remote:IsA("RemoteEvent") then
        ok = select(1, pcall(function(...)
            remote:FireServer(...)
        end, ...))
    else
        ok = select(1, pcall(function(...)
            remote:InvokeServer(...)
        end, ...))
        if not ok then
            ok = select(1, pcall(function(...)
                remote:FireServer(...)
            end, ...))
        end
    end
    return ok
end

Events.equip = GetServerRemote("RF/EquipToolFromHotbar")
Events.CancelFishingInputs = GetServerRemote("RF/CancelFishingInputs")
Events.charge = GetServerRemote("RF/ChargeFishingRod")
Events.minigame = GetServerRemote("RF/RequestFishingMinigameStarted")
Events.UpdateAutoFishingState = GetServerRemote("RF/UpdateAutoFishingState")

TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")
CoreGui = game:GetService("CoreGui")
Players = game:GetService("Players")
HttpService = game:GetService("HttpService")
Lighting = game:GetService("Lighting")
Terrain = workspace:FindFirstChildOfClass("Terrain")



-- Performance Optimization: Data Cache System
DataCache = {
    equipped = nil,
    rods = nil,
    inventory = nil,
    enchantStones = nil,
    lastUpdate = 0,
    cacheDuration = 3
}

function DataCache:Get(key)
    if tick() - self.lastUpdate > self.cacheDuration then
        self:Invalidate()
    end
    return self[key]
end

function DataCache:Set(key, value)
    self[key] = value
    self.lastUpdate = tick()
end

function DataCache:Invalidate()
    self.equipped = nil
    self.rods = nil
    self.inventory = nil
    self.enchantStones = nil
end

local DevLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/DeveloperK-AI/DevK/main/lib.lua"))()

 Window = DevLib:CreateWindow({
	Name = "DeveloperK",
	Intro = true
})



 InfoTab = Window:CreateTab({
	Name = "Info",
	Icon = "rbxassetid://7733964719"
})

InfoTab:CreateSection({
	Name = "Community Support"
})

InfoTab:CreateButton({
	Name = "Discord",
	SubText = "click to copy link",
	Icon = "rbxassetid://7733919427",
	Callback = function()
		setclipboard("https://discord.gg/DevHub")
		Window:Notify({
			Title = "Discord",
			Content = "Link copied to clipboard!",
			Duration = 3
		})
	end
})

InfoTab:CreateParagraph({
	Title = "Update",
	Content = "Every time there is a game update or someone reports something, I will fix it as soon as possible."
})

 ExclusiveTab = Window:CreateTab({
	Name = "Exclusive",
	Icon = "rbxassetid://7733765398"
})

 AmblatantTab = Window:CreateTab({
    Name = "Amblatant",
    Icon = "rbxassetid://7733779610"
})

 MainTab = Window:CreateTab({
	Name = "Main",
	Icon = "rbxassetid://7733779610"
})

 QuestTab = Window:CreateTab({
	Name = "Quest",
	Icon = "rbxassetid://7733955511"
})

 AutoTab = Window:CreateTab({
	Name = "Auto",
	Icon = "rbxassetid://7733799901"
})


 PlayerTab = Window:CreateTab({
	Name = "Player",
	Icon = "rbxassetid://7743875962"
})

 ShopTab = Window:CreateTab({
	Name = "Shop",
	Icon = "rbxassetid://7733793319"
})

ShopTab:CreateSection({ Name = "Charms Shop" })

-- [SECURITY] Semua variabel lokal
local SelectedCharm = nil
local CharmIDs = {}       -- map nama charm -> ID
local PurchaseQuantity = 1

-- Fungsi untuk memuat daftar charm dari game (tanpa fallback manual)
local function loadCharms()
    local charmNames = {}
    CharmIDs = {}

    local success, charmsModule = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("Charms", 5))
    end)

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
    else
        Window:Notify({
            Title = "Load Failed",
            Content = "Could not load charms from game. Press 'Refresh' to try again.",
            Duration = 5
        })
    end

    return charmNames
end

-- Dropdown charm (akan diisi ulang oleh fungsi update)
local charmDropdown = ShopTab:CreateDropdown({
    Name = "Select Charm",
    Items = {},  -- kosong dulu, diisi setelah load
    Default = nil,
    Callback = function(val)
        SelectedCharm = val
    end
})

-- Fungsi untuk memperbarui dropdown dengan daftar charm terbaru
local function refreshCharmDropdown()
    local charmItems = loadCharms()
    if #charmItems > 0 then
        charmDropdown:Refresh(charmItems)  -- Refresh() sudah ada di library dropdown
        if not SelectedCharm or not CharmIDs[SelectedCharm] then
            SelectedCharm = charmItems[1]
            charmDropdown:Set(SelectedCharm)
        end
    end
end

-- Tombol Refresh (selalu tampil, untuk memuat ulang charm)
ShopTab:CreateButton({
    Name = "Refresh Charm List",
    Callback = function()
        refreshCharmDropdown()
        Window:Notify({
            Title = "Refreshed",
            Content = "Charm list updated from game.",
            Duration = 2
        })
    end
})

-- Panggil pertama kali
refreshCharmDropdown()

-- Input quantity
ShopTab:CreateInput({
    Name = "Quantity",
    PlaceholderText = "1",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local val = tonumber(text)
        if val then PurchaseQuantity = val end
    end
})

-- Tombol Purchase
ShopTab:CreateButton({
    Name = "Purchase Charm",
    Callback = function()
        if not SelectedCharm then
            Window:Notify({ Title = "Error", Content = "No charm selected.", Duration = 3 })
            return
        end
        local id = CharmIDs[SelectedCharm]
        if not id then
            Window:Notify({ Title = "Error", Content = "Charm ID not found.", Duration = 3 })
            return
        end

        Window:Notify({
            Title = "Purchase",
            Content = "Buying " .. PurchaseQuantity .. " " .. SelectedCharm .. "...",
            Duration = 2
        })

        task.spawn(function()
            for i = 1, PurchaseQuantity do
                pcall(function()
                    CallRemoteServer(BuyCharm, id)  -- BuyCharm sudah local dari perbaikan sebelumnya
                end)
                task.wait(0.1)
            end
            Window:Notify({
                Title = "Done",
                Content = "Finished buying " .. SelectedCharm,
                Duration = 2
            })
        end)
    end
})

-- Tombol Equip
ShopTab:CreateButton({
    Name = "Equip Charm",
    Callback = function()
        if not SelectedCharm then return end
        pcall(function()
            REEquipCharm:FireServer(SelectedCharm)
        end)
        Window:Notify({
            Title = "Equip",
            Content = "Equipped " .. SelectedCharm,
            Duration = 2
        })
    end
})

-- Tombol Unequip
ShopTab:CreateButton({
    Name = "Unequip Charm",
    Callback = function()
        REUnequipCharm:FireServer()
        Window:Notify({
            Title = "Unequip",
            Content = "Unequipped Charm",
            Duration = 2
        })
    end
})


 TeleportTab = Window:CreateTab({
	Name = "Teleport",
	Icon = "rbxassetid://128755575520135"
})

 SettingsTab = Window:CreateTab({
	Name = "Settings",
	Icon = "rbxassetid://7733954611"
})

 MonitoringTab = Window:CreateTab({
	Name = "Monitoring",
	Icon = "rbxassetid://137601480983962"
})

getgenv().host = game:GetService("Players").LocalPlayer

 function applyZoom()
    host.CameraMaxZoomDistance = math.huge
    host.CameraMinZoomDistance = 0.1
end

applyZoom()

host.CharacterAdded:Connect(function()
    task.wait(0.1)
    applyZoom()
end)

ReplicatedStorage = game:GetService("ReplicatedStorage")
RunService = game:GetService("RunService")
-- Net already initialized
Replion = require(ReplicatedStorage.Packages.Replion)
FishingController = require(ReplicatedStorage.Controllers.FishingController)
ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
VendorUtility = require(ReplicatedStorage.Shared.VendorUtility)
 Data = Replion.Client:WaitReplion("Data")
 Client = require(ReplicatedStorage.Packages.Replion).Client
 dataStore = Client:WaitReplion("Data")
 Items = ReplicatedStorage:WaitForChild("Items")
 Players = game:GetService("Players")
 LocalPlayer = Players.LocalPlayer
 NetService = Net
 sellAllItems = SellItem
 enchan = REAltar
 oxygenRemote = UpdateOxygen
 radar = UpdateRadar
 autoon = AutoEnabled
 equipTool = REEquip
 CoreGui = game:GetService("CoreGui")
 tradeFunc = InitiateTrade
 RETextNotification = RENotify
 ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)


RE = {
    FavoriteItem = REFav,
    FavoriteStateChanged = REFavChg,
    FishingCompleted = REFishDone,
    FishCaught = REFishGot,
    EquipItem = REEquipItem,
    ActivateAltar = REAltar,
    EquipTool = REEquip,
    OpenPirateChest = PirateChest
}

equipItemRemote = RE.EquipItem or REEquipItem
equipToolRemote = RE.EquipTool or REEquip
activateAltarRemote = RE.ActivateAltar or REAltar

st = {
    canFish = true,
}

blockedFunctions = {
    "OnCooldown",
}

function patchFishingController()
     fishingModule = ReplicatedStorage.Controllers:FindFirstChild("FishingController")
    if not fishingModule then return end

     ok, FC = pcall(require, fishingModule)
    if not ok or type(FC) ~= "table" then return end

    for key, fn in pairs(FC) do
        if type(fn) == "function" and table.find(blockedFunctions, key) then
            FC[key] = function(...)
                return false
            end
        end
    end

end

patchFishingController()

-- Ultra Blatant 3N (moons.lua): simpan fungsi asli FishingController, stub di PC + mobile
local origUB3N_RequestChargeFishingRod, origUB3N_SendFishingRequestToServer
pcall(function()
    origUB3N_RequestChargeFishingRod = FishingController.RequestChargeFishingRod
    origUB3N_SendFishingRequestToServer = FishingController.SendFishingRequestToServer
end)

function applyUltraBlatant3NFishingControllerStub(enabled)
    if not origUB3N_RequestChargeFishingRod or not origUB3N_SendFishingRequestToServer then
        return
    end
    if enabled then
        FishingController.RequestChargeFishingRod = function(self, ...) end
        FishingController.SendFishingRequestToServer = function(self, ...) end
    else
        FishingController.RequestChargeFishingRod = origUB3N_RequestChargeFishingRod
        FishingController.SendFishingRequestToServer = origUB3N_SendFishingRequestToServer
    end
end

------------------ Variable ------------------------
_G.AutoFarm = false
_G.AutoRod = false
_G.AutoSells = false
_G.InfiniteJump = false
_G.Radar = false
_G.AntiAFK = false
_G.AutoReconnect = false
autoFavEnabled = false
_G.Amblatant = _G.Amblatant or false

-- Fixed Natural Hook Active (port from blatant.lua)
-- Meng-overwrite increment "1st fish/rainbow/golden" supaya terlihat natural.
 _naturalHookInstalled = false
 _naturalRainbowCount = 0
 _naturalGoldenCount = 0
 _naturalFishCount = 0
 isCaught = false

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
        Event = game:GetService("ReplicatedStorage").Packages._Index["ytrev_replion@2.0.0-rc.3"].replion.Remotes.Set
    end)
    if not Event or not Event.OnClientEvent then return end

    local conns = getconnections(Event.OnClientEvent) or {}
    for _, Connection in pairs(conns) do
        if Connection and Connection.Function then
            local old
            old = hookfunction(Connection.Function, function(...)
                local Args = { ... }

                if type(Args[2]) == "table" then
                    local category = Args[2][1]
                    local subCategory = Args[2][2]

                    function RunNaturalUpdate(updateType)
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

local delayfishing = 1

----------------------------------------------------------------
-- INSTANT FISH MODULE (IMPROVED)
----------------------------------------------------------------
local Instant = {}
local PI = math.pi
local CAST_MODE_LIST = { "Perfect", "Fast", "Random" }

-- Remote lokal (pastikan sudah ada dari deklarasi awal)
local RF_ChargeFishingRod = ChargeRod
local RE_CatchFishCompleted = REFishDoneRE or REFishDone
local RF_RequestFishingMinigameStarted = StartMini

-- State
local state = {
    enabled = false,
    running = false,
    castMode = "Fast",
    completeDelay = 3,
    castDelay = 0.3,
    notifDelay = 1.6,
    notifDuration = 4.7,
}

-- Task tracker
local loopTask = nil
local InstantTasks = {}
local notifHooked = false
local notifOriginalDeliver = nil
local notifOriginalTween = nil

-- ============================================
-- [IMPROVED] Helper: Perform a single cast (reuseable)
-- ============================================
local function performCast(mode)
    local t0 = workspace:GetServerTimeNow()
    safeInvoke(RF_ChargeFishingRod, nil, nil, t0, nil)

    local power
    if mode == "Perfect" then
        local _, p = waitForPower(t0, 0.97)
        power = p
    elseif mode == "Random" then
        local randomElapsed = math.random(0, 100) / 100 * (PI / 4)
        task.wait(randomElapsed)
        local elapsed = workspace:GetServerTimeNow() - t0
        power = getPowerAtTime(t0, elapsed)
    else -- Fast
        local elapsed = workspace:GetServerTimeNow() - t0
        power = getPowerAtTime(t0, elapsed)
    end

    safeInvoke(RF_RequestFishingMinigameStarted, 0, power, t0)
end

-- ============================================
-- [IMPROVED] waitForPower dengan timeout & RenderStepped
-- ============================================
function getPowerAtTime(chargeTime, elapsed)
    local speed = Random.new(chargeTime):NextInteger(4, 10)
    local angle = PI / 2 + elapsed * speed
    return (1 - math.sin(angle)) / 2
end

function waitForPower(chargeTime, threshold)
    local deadline = chargeTime + 2.0
    -- Gunakan RenderStepped untuk polling lebih efisien (tidak tidur 0.001 detik)
    while workspace:GetServerTimeNow() < deadline do
        local elapsed = workspace:GetServerTimeNow() - chargeTime
        local power = getPowerAtTime(chargeTime, elapsed)
        if power >= threshold then
            return elapsed, power
        end
        -- Jeda kecil agar tidak membekukan thread lain
        task.wait(0.01)  -- cukup 10ms, bukan 1ms
    end
    local elapsed = workspace:GetServerTimeNow() - chargeTime
    return elapsed, getPowerAtTime(chargeTime, elapsed)
end

-- ============================================
-- [IMPROVED] Notification Hook dengan Restore
-- ============================================
function hookNotificationDelay()
    if notifHooked then return end

    local ok, controller = pcall(function()
        return require(ReplicatedStorage.Controllers.TextNotificationController)
    end)
    if not ok or not controller then return end

    -- Simpan original
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

-- ============================================
-- Safe remote invocation (existing)
-- ============================================
function safeInvoke(remote, ...)
    if not remote then return end
    local args = { ... }
    task.spawn(function()
        pcall(function()
            remote:InvokeServer(unpack(args))
        end)
    end)
end

function safeFire(remote, ...)
    if not remote then return end
    task.spawn(function()
        pcall(function()
            remote:FireServer()
        end)
    end)
end

-- ============================================
-- [IMPROVED] Loop utama dengan pemantauan timeout
-- ============================================
function startLoop()
    if state.running then return end
    state.running = true

    -- Saat loop dimulai, reset timeout darurat
    local lastSuccessTick = tick()

    while state.enabled do
        -- Jika lebih dari 10 detik tanpa siklus sukses, paksa reset (hindari stuck)
        if tick() - lastSuccessTick > 10 then
            pcall(function() safeFire(RE_CatchFishCompleted) end)
            lastSuccessTick = tick()
        end

        performCast(state.castMode)

        task.wait(state.completeDelay)
        task.wait(0.01)

        safeFire(RE_CatchFishCompleted)
        lastSuccessTick = tick()

        task.wait(state.castDelay)
    end

    state.running = false
end

-- ============================================
-- [IMPROVED] Setter dengan validasi range
-- ============================================
function Instant.SetCastMode(mode)
    if table.find(CAST_MODE_LIST, mode) then
        state.castMode = mode
    end
end

function Instant.SetCompleteDelay(v)
    local num = tonumber(v)
    if num and num >= 0.1 and num <= 30 then  -- batas aman 0.1 – 30 detik
        state.completeDelay = num
    end
end

function Instant.SetCastDelay(v)
    local num = tonumber(v)
    if num and num >= 0 and num <= 10 then   -- batas aman 0 – 10 detik
        state.castDelay = num
    end
end

-- ============================================
-- Start / Stop dengan cleanup total
-- ============================================
function Instant.Start()
    if state.enabled then return end
    state.enabled = true
    hookNotificationDelay()
    loopTask = task.spawn(startLoop)
    table.insert(InstantTasks, loopTask)
end

function Instant.Stop()
    state.enabled = false
    if loopTask then
        pcall(task.cancel, loopTask)
        -- Hapus dari daftar
        for i, t in ipairs(InstantTasks) do
            if t == loopTask then
                table.remove(InstantTasks, i)
                break
            end
        end
        loopTask = nil
    end
    state.running = false
    unhookNotificationDelay()  -- pulihkan fungsi asli notifikasi
end

function Instant.IsActive()
    return state.enabled
end

-- ============================================
-- [IMPROVED] Fungsi instant() untuk panggilan satu kali
-- ============================================
function instant()
    if state.enabled then return end -- jangan ganggu loop yang sedang berjalan
    performCast(state.castMode)      -- pakai cast mode global
    task.wait(delayfishing)          -- delayfishing adalah variabel lokal dari Config
    safeFire(RE_CatchFishCompleted)
end

-- ============================================
-- Compatibility wrappers (tidak berubah)
-- ============================================
function CallFishDone(remote, ...)
    if not remote then return end
    local ok = pcall(function() remote:InvokeServer() end)
    if not ok then
        pcall(function() remote:FireServer() end)
    end
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

function startInstantFishingV2()
    UB_start()
end

function stopInstantFishingV2()
    UB_stop()
end

-- =============================
-- Instant Bobber (moons.lua: patchInstantBaitOverrideToCastPosition)
-- =============================
 InstantBobberState = {
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

    if InstantBobberState.instantOverrideSetupDone then
        return
    end
    InstantBobberState.instantOverrideSetupDone = true

    local okCosmetic, cosmeticFolder = pcall(function()
        return workspace:WaitForChild("CosmeticFolder", 5)
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
        if not signal then
            return nil
        end
        local ok, conn = pcall(function()
            return signal:Connect(callback)
        end)
        if not ok then
            return nil
        end
        return conn
    end

    InstantBobberState.baitCastConn = safeConnect(baitCastVisual.OnClientEvent, function(player, data)
        if not InstantBobberState.instantOverrideActive then
            return
        end
        if not player or not player.UserId then
            return
        end
        if not data or not data.CastPosition or typeof(data.CastPosition) ~= "Vector3" then
            return
        end

        InstantBobberState.activeBaitsByUserId[player.UserId] = {
            pivot = CFrame.new(data.CastPosition),
            expiresAt = tick() + 1.5,
        }
    end, "BaitCastVisual")

    InstantBobberState.baitDestroyedConn = safeConnect(baitDestroyed.OnClientEvent, function(player)
        if not InstantBobberState.instantOverrideActive then
            return
        end
        if not player or not player.UserId then
            return
        end
        InstantBobberState.activeBaitsByUserId[player.UserId] = nil
    end, "BaitDestroyed")

    InstantBobberState.renderConn = RunService.RenderStepped:Connect(function()
        if not InstantBobberState.instantOverrideActive then
            return
        end

        local now = tick()
        local cfolder = InstantBobberState.cosmeticFolder
        if not cfolder then
            return
        end

        for userId, entry in pairs(InstantBobberState.activeBaitsByUserId) do
            if now > entry.expiresAt then
                InstantBobberState.activeBaitsByUserId[userId] = nil
                continue
            end

            local model = cfolder:FindFirstChild(tostring(userId))
            if model and model.PivotTo then
                model:PivotTo(entry.pivot)
            end
        end
    end)
end


HttpService = game:GetService("HttpService")
ReplicatedStorage = game:GetService("ReplicatedStorage")
player = game.Players.LocalPlayer
ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
REFishCaught = REFishGot

_G.Wurl = _G.Wurl or ""
_G.WebhookEnabled = _G.WebhookEnabled or false
_G.WebhookURL = _G.WebhookURL or ""
_G.WebhookID = _G.WebhookID or ""
_G.WebhookSecret = _G.WebhookSecret or ""
_G.WebhookRarities = _G.WebhookRarities or {}

 req = (syn and syn.request) or (http and http.request) or http_request or request

function isValidWebhookURL(url)
    return string.find(url, "discord%.com") and string.find(url, "webhook")
end

function buildWebhookURL()
    return _G.WebhookURL
end

ExclusiveTab:CreateSection({ Name = "Premium" })

 stopAnimConnections = {}
 function setAnim(v)
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    for _, c in ipairs(stopAnimConnections) do c:Disconnect() end
    stopAnimConnections = {}

    if v then
        for _, t in ipairs(hum:FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks()) do
            t:Stop(0)
        end
        local c = hum:FindFirstChildOfClass("Animator").AnimationPlayed:Connect(function(t)
            task.defer(function() t:Stop(0) end)
        end)
        table.insert(stopAnimConnections, c)
    else
        for _, c in ipairs(stopAnimConnections) do c:Disconnect() end
        stopAnimConnections = {}
    end
end

ExclusiveTab:CreateToggle({
	Name = "No Animation",
    Value = false,
    Callback = setAnim
})

-- // TOTEM DATA
 TOTEM_DATA = {
    ["Luck Totem"] = {Id = 1, Duration = 3601},
    ["Mutation Totem"] = {Id = 2, Duration = 3601},
    ["Shiny Totem"] = {Id = 3, Duration = 3601},
    ["Super Love Totem"] = {Id = 4, Duration = 3601},
    ["Love Totem"] = {Id = 5, Duration = 3601},
    ["Super Easter Totem"] = {Id = 6, Duration = 3601},    
    ["Easter Totem"] = {Id = 7, Duration = 3601},
}
 TOTEM_NAMES = {"Luck Totem", "Mutation Totem", "Shiny Totem", "Super Love Totem", "Love Totem","Super Easter Totem","Easter Totem"}
 selectedTotemName = "Luck Totem"

-- // AUTO SINGLE TOTEM
 AUTO_TOTEM_ACTIVE = false
 AUTO_TOTEM_THREAD = nil
 currentTotemExpiry = 0

-- // GET TOTEM UUID
 function GetTotemUUID(name)
    local success, r = pcall(function()
        return require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
    end)
    if not success then return nil end
    local s, d = pcall(function() return r:GetExpect("Inventory") end)
    if s and d.Totems then 
        for _, i in ipairs(d.Totems) do 
            if tonumber(i.Id) == TOTEM_DATA[name].Id and (i.Count or 1) >= 1 then return i.UUID end 
        end 
    end
    return nil
end

-- // AUTO SINGLE TOTEM
 function RunAutoTotemLoop()
    if AUTO_TOTEM_THREAD then task.cancel(AUTO_TOTEM_THREAD) end
    AUTO_TOTEM_THREAD = task.spawn(function()
        while AUTO_TOTEM_ACTIVE do
            local timeLeft = currentTotemExpiry - os.time()
            if timeLeft <= 0 then
                local uuid = GetTotemUUID(selectedTotemName)
                if uuid then
                    -- Spawn totem
                    pcall(function() Totem:FireServer(uuid) end)
                    currentTotemExpiry = os.time() + TOTEM_DATA[selectedTotemName].Duration
                    
                    -- Re-equip rod setelah spawn totem (improved timing & retries)
                    task.spawn(function() 
                        task.wait(0.5) -- Delay awal lebih lama untuk memastikan totem sudah spawn
                        for i=1,8 do -- Lebih banyak retry untuk memastikan rod ter-equip
                            task.wait(0.25)
                            pcall(function() 
                                REEquip:FireServer(1) 
                            end)
                        end
                        -- Notifikasi bahwa rod sudah di-equip kembali
                        print("[Auto Totem] Rod re-equipped after spawning " .. selectedTotemName)
                    end)
                end
            end
            task.wait(1)
        end
    end)
end

ExclusiveTab:CreateDropdown({
	Name = "Pilih Jenis Totem",
    Items = {"Luck Totem", "Mutation Totem", "Shiny Totem","Super Love Totem", "Love Totem","Super Easter Totem","Easter Totem"},
    Value = selectedTotemName,
 Callback = function(n) 
        selectedTotemName = n
        currentTotemExpiry = 0 
    end 
})

ExclusiveTab:CreateToggle({
	Name = "Enable Auto Totem (Single)",
	SubText = "Mode Normal",
	Default = false,
	ConfigKey = "EnableAutoTotemSingle",
	 Callback = function(s) 
        AUTO_TOTEM_ACTIVE = s
        if s then RunAutoTotemLoop() else if AUTO_TOTEM_THREAD then task.cancel(AUTO_TOTEM_THREAD) end end 
    end 
})


-- ============================================
-- AUTO 3 TOTEM MIX (SHINY -> LUCK -> MUTATION) [TWEEN + PLATFORM]
-- ============================================

local AUTO_3_TOTEM_ACTIVE = false
local AUTO_3_TOTEM_THREAD = nil

-- Mixed Order: Spot 1=Shiny, Spot 2=Luck, Spot 3=Mutation
local TOTEM_MIX_ORDER = {"Shiny Totem", "Luck Totem", "Mutation Totem"}

-- 3 Spots Only
local REF_CENTER = Vector3.new(93.932, 9.532, 2684.134)
local REF_SPOTS = {
    Vector3.new(45.0468979, 13.5, 2730.19067),   -- 1
    Vector3.new(145.644608, 13.5, 2721.90747),   -- 2
    Vector3.new(84.6406631, 14.2, 2636.05786),   -- 3
}

TweenService = game:GetService("TweenService")
ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Net already initialized

function GetRoot()
    local player = game:GetService("Players").LocalPlayer
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

-- Helper: Tween Character to Target CFrame
function TweenTo(targetCFrame, duration)
    local root = GetRoot()
    if not root then return end
    
    -- Ensure Anchored for Tween
    root.Anchored = true
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
    -- Keep anchored until platform interaction
end

-- Helper: Create Temporary Platform
function CreatePlatform(position)
    local plat = Instance.new("Part")
    plat.Name = "TotemPlatform"
    plat.Size = Vector3.new(10, 1, 10)
    plat.Position = position - Vector3.new(0, 3.5, 0) -- Slightly below player
    plat.Anchored = true
    plat.CanCollide = true
    plat.Transparency = 0.5
    plat.Color = Color3.fromRGB(0, 255, 255)
    plat.Material = Enum.Material.Neon
    plat.Parent = workspace
    return plat
end

function Run3TotemLoop()
    if AUTO_3_TOTEM_THREAD then task.cancel(AUTO_3_TOTEM_THREAD) end
    
    AUTO_3_TOTEM_THREAD = task.spawn(function()
        AUTO_3_TOTEM_ACTIVE = true
        
        local player = game:GetService("Players").LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local root = GetRoot()
        
        if not root then 
            AUTO_3_TOTEM_ACTIVE = false
            return 
        end
        
        local startCFrame = root.CFrame
        Window:Notify({ Title = "Started", Content = "3 Totem Mix (Tween Mode)", Duration = 4, Icon = "zap" })
        
        -- Equip Oxygen Tank (Optional safety)
        local RF_EquipOxygenTank = EquipOxygen
        if RF_EquipOxygenTank then pcall(function() RF_EquipOxygenTank:InvokeServer(105) end) end

        -- PRIMARY LOOP: Runs indefinitely until toggled off
        while AUTO_3_TOTEM_ACTIVE do
            -- Loop through spots
            for i, refSpot in ipairs(REF_SPOTS) do
                if not AUTO_3_TOTEM_ACTIVE then break end
                
                local targetTotemName = TOTEM_MIX_ORDER[i]
                -- Calculate Adjust position relative to center
                local relativePos = refSpot - REF_CENTER
                local targetPos = startCFrame.Position + relativePos
                
                local targetCFrame = CFrame.new(targetPos)
                
                -- 1. Tween to Location
                local dist = (root.Position - targetPos).Magnitude
                local travelTime = math.max(1.5, dist / 60) -- Speed calc
                
                TweenTo(targetCFrame, travelTime)
                
                -- 2. Create Platform & Stand
                local platform = CreatePlatform(targetPos)
                root.Anchored = false -- Allow standing on platform
                
                task.wait(0.5) -- Stabilize
                
                -- 3. Spawn & Equip Totem
                local uuid = GetTotemUUID(targetTotemName)
                if uuid then
                    pcall(function() Totem:FireServer(uuid) end)
                    
                    -- Equip Loop
                    task.spawn(function() 
                        for k=1,5 do -- More attempts
                            pcall(function() REEquip:FireServer(1) end)
                            task.wait(0.2) 
                        end 
                    end)
                    Window:Notify({ Title = "Spawned", Content = targetTotemName, Duration = 2 })
                else
                    Window:Notify({ Title = "Skip", Content = "No " .. targetTotemName, Duration = 2, Icon = "x" })
                end
                
                task.wait(3) -- Wait for usage/interaction
                
                -- 4. Cleanup Platform & Prepare for next
                if platform then platform:Destroy() end
                root.Anchored = true -- Prepare for next tween
            end
            
            -- Return to Start Position
            if AUTO_3_TOTEM_ACTIVE then
                TweenTo(startCFrame, 2)
                root.Anchored = false
                Window:Notify({ Title = "Cycle Done", Content = "Waiting 1 Hour...", Duration = 10, Icon = "time" })
            end
            
            -- Wait 1 Hour (with breakdown for cancellation)
            for waitTime = 3600, 1, -1 do
                if not AUTO_3_TOTEM_ACTIVE then break end
                task.wait(1)
            end
        end
        
        -- Unequip Oxygen (When manually stopped)
        local RF_UnequipOxygenTank = UnequipOxygen
        if RF_UnequipOxygenTank then pcall(function() RF_UnequipOxygenTank:InvokeServer() end) end
    end)
end

ExclusiveTab:CreateToggle({
	Name = "Auto Spawn 3 Totem Mix",
    SubText = "Shiny -> Luck -> Mutation",
	Default = false,
    Callback = function(s)
        AUTO_3_TOTEM_ACTIVE = s
        if s then
            Run3TotemLoop()
        else
            AUTO_3_TOTEM_ACTIVE = false
            if AUTO_3_TOTEM_THREAD then task.cancel(AUTO_3_TOTEM_THREAD) end
            
            -- Cleanup if stopped mid-way
            local root = GetRoot()
            if root then root.Anchored = false end
            for _, v in ipairs(workspace:GetChildren()) do
                if v.Name == "TotemPlatform" then v:Destroy() end
            end
            
            Window:Notify({ Title = "Stopped", Content = "Cancelled!", Duration = 3, Icon = "x" })
        end
    end
})

ExclusiveTab:CreateSection({ Name = "Auto Buy Totem" })

-- ============================================
-- AUTO BUY TOTEM (MARKET PURCHASE)
-- ============================================

local TotemMarketIds = {
	["Luck Totem"] = 5,
	["Shiny Totem"] = 7,
	["Mutation Totem"] = 8
}

local TotemPrices = {
	["Luck Totem"] = 650000,
	["Shiny Totem"] = 400000,
	["Mutation Totem"] = 800000
}

_G.AutoBuyTotem = false
_G.SelectedBuyTotem = "Luck Totem"
_G.BuyTotemLimit = 10
local purchaseCount = 0

-- Dropdown untuk pilih totem
ExclusiveTab:CreateDropdown({
	Name = "Select Totem to Buy",
	Items = {"Luck Totem", "Shiny Totem", "Mutation Totem"},
	Default = "Luck Totem",
	Callback = function(selected)
		_G.SelectedBuyTotem = selected
		print("[Auto Buy] Selected totem:", selected, "Price:", TotemPrices[selected])
	end
})

-- Slider untuk batas pembelian
-- Input untuk batas pembelian
ExclusiveTab:CreateInput({
	Name = "Purchase Limit",
	PlaceholderText = "10",
	RemoveTextAfterFocusLost = false,
	Callback = function(text)
		local value = tonumber(text)
		if value then
			_G.BuyTotemLimit = value
			print("[Auto Buy] Purchase limit set to:", value)
		else
			warn("[Auto Buy] Invalid number entered for limit")
		end
	end
})

-- Button Open Merchant
-- Toggle Open Merchant
ExclusiveTab:CreateToggle({
	Name = "Open Merchant GUI",
	Default = false,
	Callback = function(value)
		local merchantGui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Merchant")
		if merchantGui then
			merchantGui.Enabled = value
			if value then
				Window:Notify({
					Title = "Merchant",
					Content = "Merchant GUI Opened!",
					Icon = "rbxassetid://7733920644",
					Duration = 3
				})
			end
		else
			Window:Notify({
				Title = "Error",
				Content = "Merchant GUI not found!",
				Icon = "rbxassetid://7733658504",
				Duration = 3
			})
		end
	end
})

-- Toggle Auto Buy Totem
ExclusiveTab:CreateToggle({
	Name = "Auto Buy Totem",
	SubText = "Purchase totem from market",
	Default = false,
	Callback = function(value)
		_G.AutoBuyTotem = value
		
		if value then
			purchaseCount = 0 -- Reset counter
			
			Window:Notify({
				Title = "Auto Buy Totem Enabled",
				Content = "Buying: " .. _G.SelectedBuyTotem .. " (" .. TotemPrices[_G.SelectedBuyTotem] .. " coins)\nLimit: " .. _G.BuyTotemLimit .. " totems",
				Icon = "rbxassetid://7733911621",
				Duration = 3
			})
			
			-- Auto buy loop
			task.spawn(function()
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local PurchaseRemote = BuyMarket
				
				-- Inventory IDs (different from Market IDs)
				local TotemInventoryIds = {
					["Luck Totem"] = 1,
					["Mutation Totem"] = 2,
					["Shiny Totem"] = 3
				}

				-- Function to check inventory count
				function GetTotemCount(totemName)
					local success, result = pcall(function()
						local Client = require(ReplicatedStorage.Packages.Replion).Client
						local dataStore = Client:WaitReplion("Data")
						local inventory = dataStore:GetExpect("Inventory")
						
						-- Get correct Inventory ID
						local inventoryId = TotemInventoryIds[totemName]
						
						if inventory and inventory.Totems then
							local totalCount = 0
							for _, item in ipairs(inventory.Totems) do
								-- Check by Inventory ID
								if tonumber(item.Id) == inventoryId then
									totalCount = totalCount + (item.Count or 1)
								end
							end
							return totalCount
						end
						return 0
					end)
					
					if not success then
						warn("[Auto Buy] GetTotemCount error:", result)
						return 0
					end
					
					return result or 0
				end
				
				while _G.AutoBuyTotem and purchaseCount < _G.BuyTotemLimit do
					local totemId = TotemMarketIds[_G.SelectedBuyTotem]
					local beforeCount = GetTotemCount(_G.SelectedBuyTotem)
					
					-- Try to purchase
					local success, result = pcall(function()
						return PurchaseRemote:InvokeServer(totemId)
					end)
					
					if success then
						if result then
							-- Wait a bit for inventory to update
							task.wait(0.5)
							
							-- Verify purchase by checking inventory
							local afterCount = GetTotemCount(_G.SelectedBuyTotem)
							
							if afterCount > beforeCount then
								purchaseCount = purchaseCount + 1
								print("[Auto Buy] ✓ Purchased:", _G.SelectedBuyTotem, "ID:", totemId, "Count:", purchaseCount .. "/" .. _G.BuyTotemLimit)
								print("[Auto Buy] Inventory:", afterCount, "totems")
							else
								warn("[Auto Buy] ⚠️ Purchase response OK but inventory not updated")
							end
						else
							warn("[Auto Buy] ✗ Purchase failed (not enough coins or error)")
						end
					else
						warn("[Auto Buy] Error:", result)
					end
					
					-- Wait before next purchase attempt
					task.wait(1)
				end
				
				-- Auto disable when limit reached
				if purchaseCount >= _G.BuyTotemLimit then
					_G.AutoBuyTotem = false
					Window:Notify({
						Title = "Auto Buy Completed",
						Content = "Purchased " .. purchaseCount .. " totems!\nAuto Buy disabled.",
						Icon = "rbxassetid://7733911621",
						Duration = 4
					})
				end
			end)
		else
			Window:Notify({
				Title = "Auto Buy Totem Disabled",
				Content = "Stopped auto buying totems\nPurchased: " .. purchaseCount .. " totems",
				Icon = "rbxassetid://7733911621",
				Duration = 2
			})
		end
	end
})

ExclusiveTab:CreateSection({ Name = "FPS Boost" })

-- ==============================================================
--                ⭐ FPS BOOSTER MODULE (OPTIMIZED) ⭐
--                    Ready untuk GUI Integration
-- ==============================================================

local FPSBooster = {}
FPSBooster.Enabled = false

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

-- Storage untuk restore
local originalStates = {
    reflectance = {},
    transparency = {},
    lighting = {},
    effects = {},
    waterProperties = {}
}

-- Connection untuk new objects
local newObjectConnection = nil

-- Fungsi untuk optimize single object
 function optimizeObject(obj)
    if not FPSBooster.Enabled then return end
    
    pcall(function()
        -- Optimize BasePart (Bangunan, model, dll)
        if obj:IsA("BasePart") then
            -- Simpan original states (JANGAN UBAH WARNA & MATERIAL)
            if not originalStates.reflectance[obj] then
                originalStates.reflectance[obj] = obj.Reflectance
            end
            
            -- Hapus reflections & shadows saja
            obj.Reflectance = 0
            obj.CastShadow = false
        end
        
        -- Matikan Decals & Textures
        if obj:IsA("Decal") or obj:IsA("Texture") then
            if not originalStates.transparency[obj] then
                originalStates.transparency[obj] = obj.Transparency
            end
            obj.Transparency = 1 -- Invisible
        end
        
        -- Matikan SurfaceAppearance (texture PBR)
        if obj:IsA("SurfaceAppearance") then
            obj:Destroy()
        end
        
        -- Matikan ParticleEmitter (debu, asap, dll)
        if obj:IsA("ParticleEmitter") then
            obj.Enabled = false
        end
        
        -- Matikan Trail effects
        if obj:IsA("Trail") then
            obj.Enabled = false
        end
        
        -- Matikan Beam effects
        if obj:IsA("Beam") then
            obj.Enabled = false
        end
        
        -- Matikan Fire, Smoke, Sparkles
        if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end)
end

-- Fungsi untuk restore single object
 function restoreObject(obj)
    pcall(function()
        if obj:IsA("BasePart") then
            if originalStates.reflectance[obj] then
                obj.Reflectance = originalStates.reflectance[obj]
                obj.CastShadow = true
            end
        end
        
        if obj:IsA("Decal") or obj:IsA("Texture") then
            if originalStates.transparency[obj] then
                obj.Transparency = originalStates.transparency[obj]
            end
        end
        
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = true
        end
        
        if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = true
        end
    end)
end

-- ============================================
-- MAIN ENABLE FUNCTION
-- ============================================
function FPSBooster.Enable()
    if FPSBooster.Enabled then
        return false, "Already enabled"
    end
    
    FPSBooster.Enabled = true
    
    -----------------------------------------
    -- 1. Optimize semua existing objects
    -----------------------------------------
    for _, obj in ipairs(workspace:GetDescendants()) do
        optimizeObject(obj)
    end
    
    -----------------------------------------
    -- 2. MATIKAN ANIMASI AIR (Terrain Water)
    -----------------------------------------
    if Terrain then
        pcall(function()
            -- Simpan water properties
            originalStates.waterProperties = {
                WaterReflectance = Terrain.WaterReflectance,
                WaterWaveSize = Terrain.WaterWaveSize,
                WaterWaveSpeed = Terrain.WaterWaveSpeed
            }
            
            -- Matikan animasi air (WARNA TETAP DEFAULT)
            Terrain.WaterWaveSize = 0 -- NO WAVES
            Terrain.WaterWaveSpeed = 0 -- NO ANIMATION
            Terrain.WaterReflectance = 0 -- NO REFLECTION
        end)
    end
    
    -----------------------------------------
    -- 3. Optimize Lighting (Hapus Shadows & Fog)
    -----------------------------------------
    originalStates.lighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart
    }
    
    Lighting.GlobalShadows = false -- NO SHADOWS
    Lighting.FogStart = 0
    Lighting.FogEnd = 1000000 -- NO FOG
    
    -----------------------------------------
    -- 4. Matikan Post-Processing Effects
    -----------------------------------------
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            originalStates.effects[effect] = effect.Enabled
            effect.Enabled = false
        end
    end
    
    -----------------------------------------
    -- 5. Set Render Quality ke MINIMUM
    -----------------------------------------
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    
    -----------------------------------------
    -- 6. Hook new objects yang spawn
    -----------------------------------------
    newObjectConnection = workspace.DescendantAdded:Connect(function(obj)
        if FPSBooster.Enabled then
            task.wait(0.1) -- Delay kecil
            optimizeObject(obj)
        end
    end)
    
    return true, "FPS Booster enabled"
end

-- ============================================
-- MAIN DISABLE FUNCTION
-- ============================================
function FPSBooster.Disable()
    if not FPSBooster.Enabled then
        return false, "Already disabled"
    end
    
    FPSBooster.Enabled = false
    
    -----------------------------------------
    -- 1. Restore semua objects
    -----------------------------------------
    for _, obj in ipairs(workspace:GetDescendants()) do
        restoreObject(obj)
    end
    
    -----------------------------------------
    -- 2. Restore Terrain Water
    -----------------------------------------
    if Terrain and originalStates.waterProperties then
        pcall(function()
            Terrain.WaterReflectance = originalStates.waterProperties.WaterReflectance
            Terrain.WaterWaveSize = originalStates.waterProperties.WaterWaveSize
            Terrain.WaterWaveSpeed = originalStates.waterProperties.WaterWaveSpeed
        end)
    end
    
    -----------------------------------------
    -- 3. Restore Lighting
    -----------------------------------------
    if originalStates.lighting.GlobalShadows ~= nil then
        Lighting.GlobalShadows = originalStates.lighting.GlobalShadows
        Lighting.FogEnd = originalStates.lighting.FogEnd
        Lighting.FogStart = originalStates.lighting.FogStart
    end
    
    -----------------------------------------
    -- 4. Restore Post-Processing
    -----------------------------------------
    for effect, state in pairs(originalStates.effects) do
        if effect and effect.Parent then
            effect.Enabled = state
        end
    end
    
    -----------------------------------------
    -- 5. Restore Render Quality
    -----------------------------------------
    settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    
    -----------------------------------------
    -- 6. Disconnect hook
    -----------------------------------------
    if newObjectConnection then
        newObjectConnection:Disconnect()
        newObjectConnection = nil
    end
    
    -- Clear original states
    originalStates = {
        reflectance = {},
        transparency = {},
        lighting = {},
        effects = {},
        waterProperties = {}
    }
    
    return true, "FPS Booster disabled"
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
function FPSBooster.IsEnabled()
    return FPSBooster.Enabled
end

-- ============================================
-- TOGGLE FOR GUI
-- ============================================
ExclusiveTab:CreateToggle({
    Name = "FPS Booster",
    Description = "Boost FPS dengan optimasi graphics (Hapus shadows, reflections, particles & effects)",
    Icon = "rbxassetid://11400562133",
    Default = false,
    Callback = function(value)
        if value then
            -- Enable FPS Booster
            local success, msg = FPSBooster.Enable()
        else
            -- Disable FPS Booster
            local success, msg = FPSBooster.Disable()
        end
    end,
})

ExclusiveTab:CreateSection({ Name = "Player Optimize" })

local freezeConnection
local originalCFrame

-- Services
RunService = game:GetService("RunService")
Players = game:GetService("Players")

-- State
renderEnabled = true

-- Logger
function log(msg)
    print("[Disable3D]", msg)
end

-- REAL disable function
function setRender(state)
    renderEnabled = state
    RunService:Set3dRenderingEnabled(state)
    log(state and "3D Rendering ENABLED" or "3D Rendering DISABLED")
end

-- Safety keep-alive (REAL disable)
task.spawn(function()
    while task.wait(3) do
        RunService:Set3dRenderingEnabled(renderEnabled)
    end
end)

-- Re-apply on respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    RunService:Set3dRenderingEnabled(renderEnabled)
    log("Re-applied after respawn")
end)

-- UI Toggle
ExclusiveTab:CreateToggle({
    Name = "Disable 3D Rendering",
    Default = false,
    Callback = function(state)
        -- state = true berarti DISABLE
        setRender(not state)
    end
})


ExclusiveTab:CreateToggle({
	Name = "Freeze Character",
	Default = false,
	 Callback = function(state)
        _G.FreezeCharacter = state
        if state then
            local character = game.Players.LocalPlayer.Character
            if character then
                local root = character:FindFirstChild("HumanoidRootPart")
                if root then
                    originalCFrame = root.CFrame
                    freezeConnection = game:GetService("RunService").Heartbeat:Connect(function()
                        if _G.FreezeCharacter and root then
                            root.CFrame = originalCFrame
                        end
                    end)
                end
            end
        else
            if freezeConnection then
                freezeConnection:Disconnect()
                freezeConnection = nil
            end
        end
    end
})


ExclusiveTab:CreateToggle({
	Name = "Disable Fish Caught",
	Default = false,
  Callback = function(state)
        disableNotifs = state
        
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

        if state then
            -- 1. Hapus yang sudah ada sekarang
            local smallNotif = PlayerGui:FindFirstChild("Small Notification")
            if smallNotif then
                smallNotif:Destroy()
            end

            -- 2. Auto-hapus setiap kali game coba spawn lagi
            PlayerGui.ChildAdded:Connect(function(child)
                if child.Name == "Small Notification" or 
                   (child:FindFirstChild("Display") and child:FindFirstChildWhichIsA("Frame")) then
                    task.spawn(function()
                        task.wait() -- tunggu 1 frame biar aman
                        if child and child.Parent then
                            child:Destroy()
                        end
                    end)
                end
            end)
        end
    end
})

ExclusiveTab:CreateToggle({
	Name = "Disable Char Effect",
	Default = false,
	   Callback = function(state)
        disableCharFx = state
        if state then
            local effectEvents = {
                REPlayFishEffect
            }

            for _, ev in ipairs(effectEvents) do
                if ev and ev.OnClientEvent then
                    for _, conn in ipairs(getconnections(ev.OnClientEvent)) do
                        conn:Disconnect()
                    end
                    ev.OnClientEvent:Connect(function() end)
                end
            end

            if FishingController then
                if not _fxBackup then
                    _fxBackup = {
                        PlayFishingEffect = FishingController.PlayFishingEffect,
                        ReplicateCutscene = FishingController.ReplicateCutscene
                    }
                end
                FishingController.PlayFishingEffect = function() end
                FishingController.ReplicateCutscene = function() end
            end
        else
            if _fxBackup then
                for k, v in pairs(_fxBackup) do
                    FishingController[k] = v
                end
            end
        end
    end
})


ExclusiveTab:CreateToggle({
	Name = "Disable Fishing Effect",
	Default = false,
	Callback = function(state)
        delEffects = state
        
        if state then
            -- Loop untuk menghapus efek yang sudah ada
            spawn(function()
                while delEffects do
                    local cosmetic = workspace:FindFirstChild("CosmeticFolder")
                    if cosmetic then
                        for _, child in ipairs(cosmetic:GetChildren()) do
                            local isExactPart   = child.Name == "Part"
                            local isPureNumber  = string.match(child.Name, "^%d+$")
                            local isModel       = child:IsA("Model")

                            -- Tidak hapus jika Part, angka murni, atau Model
                            if not (isExactPart or isPureNumber or isModel) then
                                child:Destroy()
                            end
                        end
                    end
                    task.wait(0.1) -- Optimized: Increased check interval to 5s (ChildAdded handles new items)
                end
            end)
            
            -- Single connection untuk child baru
            if not _G.EffectsConnection then
                local cosmetic = workspace:WaitForChild("CosmeticFolder", 5)
                if cosmetic then
                    _G.EffectsConnection = cosmetic.ChildAdded:Connect(function(child)
                        if delEffects then
                            task.wait()
                            local isExactPart  = child.Name == "Part"
                            local isPureNumber = string.match(child.Name, "^%d+$")
                            local isModel      = child:IsA("Model")

                            -- Tidak hapus jika Part, angka murni, atau Model
                            if not (isExactPart or isPureNumber or isModel) then
                                child:Destroy()
                            end
                        end
                    end)
                end
            end
        else
            if _G.EffectsConnection then
                _G.EffectsConnection:Disconnect()
                _G.EffectsConnection = nil
            end
        end
    end
})

ExclusiveTab:CreateToggle({
	Name = "Hide Rod On Hand",
	Default = false,
	   Callback = function(state)
        hideRod = state
        if state then
            spawn(function()
                while hideRod do
                    for _, char in ipairs(workspace.Characters:GetChildren()) do
                        local toolFolder = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")
                        if toolFolder then
                            toolFolder:Destroy()
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})


ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Net already initialized

FishingController = require(ReplicatedStorage.Controllers.FishingController)

oldClick = FishingController.RequestFishingMinigameClick
oldCharge = FishingController.RequestChargeFishingRod

-- FAST 3 KEDIP: HookNotif duration + FC stubs (semua platform, bukan hanya touch)
instantV2OrigCharge = FishingController.RequestChargeFishingRod
instantV2OrigCast = FishingController.SendFishingRequestToServer
if not instantV2OrigCast then
    instantV2OrigCast = function() end
end
pcall(function()
    local TextNotificationController = require(ReplicatedStorage.Controllers:WaitForChild("TextNotificationController"))
    local origDeliver = TextNotificationController.DeliverNotification
    TextNotificationController.DeliverNotification = function(self, data, ...)
        if Config.HookNotif and data then
            -- IFV2: 15 | Blatant V1 (Fast Reel): 7.5
            if Config.InstantFishingV2Active then
                data.CustomDuration = 15
            elseif _G.BlatantMode then
                data.CustomDuration = 7.5
            else
                data.CustomDuration = 15
            end
        end
        return origDeliver(self, data, ...)
    end
end)

local autoPerf = false

task.spawn(function()
    while task.wait(1) do -- Optimized: Reduced from tick to 1s to prevent ping spikes
        if autoPerf then
            AutoEnabled:InvokeServer(true)
        end
    end
end)

ExclusiveTab:CreateSection({ Name = "Auto Perfection" })

ExclusiveTab:CreateToggle({
	Name = "Auto Perfection",
	Default = false,
 Callback = function(state)
        autoPerf = state
        
        if autoPerf then
            FishingController.RequestFishingMinigameClick = function(...) end
            FishingController.RequestChargeFishingRod = function(...) end
            print("Auto Perfection ON — Click & Charge disabled")

        else
            AutoEnabled:InvokeServer(false)
            FishingController.RequestFishingMinigameClick = oldClick
            FishingController.RequestChargeFishingRod = oldCharge
            print("Auto Perfection OFF — Click & Charge restored")
        end
    end
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local httpRequest = syn and syn.request or http and http.request or http_request or (fluxus and fluxus.request) or
    request
if not httpRequest then return end


-- Perbaikan akhir untuk bagian Webhook Fish Caught (fix local registers error & deteksi lebih akurat)

-- Biar tidak declare local tidak perlu

fishDB = fishDB or {}
local rarityList = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "Forgotten" }
local variantList = {
    "Galaxy", "Corrupt", "Gemstone", "Fairy Dust", "Midnight",
    "Color Burn", "Holographic", "Lightning", "Radioactive",
    "Ghost", "Gold", "Frozen", "1x1x1x1", "Stone", "Sandy",
    "Noob", "Moon Fragment", "Festive", "Albino", "Arctic Frost", "Disco", "Big", "Giant", "Sparkling",
    "Crystalized"
}
local tierToRarity = {
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "SECRET",
    [8] = "Forgotten"
}
local knownFishUUIDs = {}

-- Pindah require ke dalam pcall biar aman & tidak pakai local di scope utama
pcall(function()
    local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
    local Replion = require(ReplicatedStorage.Packages.Replion)
    local DataService = Replion.Client:WaitReplion("Data")
    
    -- Simpan ke _G atau global kalau perlu dipakai di luar (webhook function)
    _G.ItemUtility = ItemUtility
    _G.DataService = DataService
end)

-- Function buildFishDatabase (sudah bagus, local di dalam loop aman karena per iteration)
fishByName = fishByName or {}

function buildFishDatabase()
    table.clear(fishDB)
    table.clear(fishByName)
    local itemsContainer = ReplicatedStorage:WaitForChild("Items")
    
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

-- Panggil sekali saat script load (atau saat event update kalau fish baru ditambah)
buildFishDatabase()

-- Di bagian lain webhook, pakai _G.ItemUtility & _G.DataService
-- Contoh di getInventoryFish():
function getInventoryFish()
    if not (_G.ItemUtility and _G.DataService) then return {} end
    local inventoryItems = _G.DataService:GetExpect({ "Inventory", "Items" })
    local fishes = {}
    for _, v in pairs(inventoryItems) do
        local itemData = _G.ItemUtility.GetItemDataFromItemType("Items", v.Id)
        if itemData and itemData.Data.Type == "Fish" then
            table.insert(fishes, { Id = v.Id, UUID = v.UUID, Metadata = v.Metadata })
        end
    end
    return fishes
end

-- Lakukan yang sama untuk function lain yang pakai ItemUtility/DataService

-- Tambahan: Kalau game update & tambah fish baru, panggil lagi buildFishDatabase()
-- Misal di spawn loop atau button refresh

function getPlayerCoins()
    if not DataService then return "N/A" end
    local success, coins = pcall(function() return DataService:Get("Coins") end)
    if success and coins then return string.format("%d", coins):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "") end
    return "N/A"
end

function getThumbnailURL(assetString)
    local assetId = assetString:match("rbxassetid://(%d+)")
    if not assetId then return nil end
    local api = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%s&type=Asset&size=420x420&format=Png",
        assetId)
    local success, response = pcall(function() return HttpService:JSONDecode(game:HttpGet(api)) end)
    return success and response and response.data and response.data[1] and response.data[1].imageUrl
end

function sendTestWebhook()
    if not httpRequest or not _G.WebhookURL or not _G.WebhookURL:match("discord.com/api/webhooks") then
        Window:Notify({ Title = "Error", Content = "Webhook URL Empty" })
        return
    end

    local payload = {
        username = "DevHub Webhook",
        avatar_url = "https://cdn.discordapp.com/attachments/1434789394929287178/1448926732705988659/Swuppie.jpg?ex=693d09ac&is=693bb82c&hm=88d4c68207470eb4abc79d9b68227d85171aded5d3d99e9a76edcd823862f5fe",
        embeds = {{
            title = "Test Webhook Connected",
            description = "Webhook connection successful!",
            color = 0x00FF00
        }}
    }

    pcall(function()
        httpRequest({
            Url = _G.WebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

function sendNewFishWebhook(newlyCaughtFish)
    if not httpRequest or not _G.WebhookURL or not _G.WebhookURL:match("discord.com/api/webhooks") then return end

    local newFishDetails = fishDB[newlyCaughtFish.Id]
    if not newFishDetails then return end

    local newFishRarity = tierToRarity[newFishDetails.Tier] or "Unknown"
    local mutation   = (newlyCaughtFish.Metadata and newlyCaughtFish.Metadata.VariantId and tostring(newlyCaughtFish.Metadata.VariantId)) or "None"

    local isCrystalized = mutation == "Crystalized"
    local forceAnnounce = _G.WebhookCrystalized and isCrystalized

    if not forceAnnounce then
        if #_G.WebhookRarities > 0 and not table.find(_G.WebhookRarities, newFishRarity) then return end
        if _G.WebhookVariants and #_G.WebhookVariants > 0 and not table.find(_G.WebhookVariants, mutation) then return end
    end

    local fishWeight = (newlyCaughtFish.Metadata and newlyCaughtFish.Metadata.Weight and string.format("%.2f Kg", newlyCaughtFish.Metadata.Weight)) or "N/A"
    local sellPrice  = (newFishDetails.SellPrice and ("$"..string.format("%d", newFishDetails.SellPrice):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "").." Coins")) or "N/A"
    local currentCoins = getPlayerCoins()

    local totalFishInInventory = #getInventoryFish()
    local backpackInfo = string.format("%d/4500", totalFishInInventory)

    local playerName = game.Players.LocalPlayer.Name

    local payload = {
        content = nil,
        embeds = {{
            title = "DevHub Fish caught!",
            description = string.format("Congrats! **%s** You obtained new **%s** here for full detail fish :", playerName, newFishRarity),
            url = "https://discord.gg/DevHub",
            color = 8900346,
            fields = {
                { name = "Name Fish :",        value = "```\n"..newFishDetails.Name.."```" },
                { name = "Rarity :",           value = "```"..newFishRarity.."```" },
                { name = "Weight :",           value = "```"..fishWeight.."```" },
                { name = "Mutation :",         value = "```"..mutation.."```" },
                { name = "Sell Price :",       value = "```"..sellPrice.."```" },
                { name = "Backpack Counter :", value = "```"..backpackInfo.."```" },
                { name = "Current Coin :",     value = "```"..currentCoins.."```" },
            },
            footer = {
                text = "DevHub Webhook",
                icon_url = "https://cdn.discordapp.com/attachments/1434789394929287178/1448926732705988659/Swuppie.jpg?ex=693d09ac&is=693bb82c&hm=88d4c68207470eb4abc79d9b68227d85171aded5d3d99e9a76edcd823862f5fe"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
            thumbnail = {
                url = getThumbnailURL(newFishDetails.Icon)
            }
        }},
        username = "DevHub Webhook",
        avatar_url = "https://cdn.discordapp.com/attachments/1434789394929287178/1448926732705988659/Swuppie.jpg?ex=693d09ac&is=693bb82c&hm=88d4c68207470eb4abc79d9b68227d85171aded5d3d99e9a76edcd823862f5fe",
        attachments = {}
    }

    pcall(function()
        httpRequest({
            Url = _G.WebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- Sensor nama player (sama seperti blade.lua CensorName)
 function censorPlayerName(name)
    if not name or type(name) ~= "string" or #name < 1 then return "N/A" end
    if #name <= 3 then return name end
    local prefix = name:sub(1, 3)
    local censorString = string.rep("*", #name - 3)
    return prefix .. censorString
end

local WEBHOOK_GLOBAL_URL = "https://discord.com/api/webhooks/1482214090305703987/gHLJbDnDhYvXBqQIrcR7Jm3mZW77bLNaik6jv3BRkHxDLWRQtVldgrlfCiH6I5Z1xAGM"

function sendGlobalTrackerWebhook(newlyCaughtFish)
    if not httpRequest or not WEBHOOK_GLOBAL_URL or WEBHOOK_GLOBAL_URL == "" then return end

    local fishDetails = fishDB[newlyCaughtFish.Id]
    if not fishDetails then return end

    local rarity = tierToRarity[fishDetails.Tier] or "Unknown"
    if rarity ~= "SECRET" then return end

    -- Mutation display sama blade.lua GetItemMutationString: Shiny dulu, lalu VariantId
    local meta = newlyCaughtFish.Metadata
    local mutationStr = (meta and meta.Shiny == true) and "Shiny" or (meta and meta.VariantId and tostring(meta.VariantId)) or ""
    local mutationDisplay = (mutationStr ~= "" and mutationStr) or "N/A"
    local fishWeight = (meta and meta.Weight and string.format("%.2fkg", meta.Weight)) or string.format("%.2fkg", 0)
    local playerName = game.Players.LocalPlayer.DisplayName or game.Players.LocalPlayer.Name
    local censoredName = censorPlayerName(playerName)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time())

    local imageUrl = getThumbnailURL(fishDetails.Icon) or "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png"
    local payload = {
        content = nil,
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
        attachments = {}
    }

    pcall(function()
        httpRequest({
            Url = WEBHOOK_GLOBAL_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

function sendTestGlobalWebhook()
    if not httpRequest or not WEBHOOK_GLOBAL_URL or WEBHOOK_GLOBAL_URL == "" then
        Window:Notify({ Title = "Error", Content = "Global Tracker Webhook URL tidak tersedia." })
        return
    end
    local playerName = game.Players.LocalPlayer.DisplayName or game.Players.LocalPlayer.Name
    local censoredName = censorPlayerName(playerName)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time())
    local testPayload = {
        content = nil,
        embeds = {{
            title = ":fish: DevHub | Global Tracker\n\nGLOBAL CATCH! Blob Shark",
            description = string.format("Pemain **%s** baru saja menangkap ikan **SECRET**! (TEST)", censoredName),
            color = 16766720,
            fields = {
                { name = "Rarity", value = "`SECRET`", inline = true },
                { name = "Weight", value = "`536.30kg`", inline = true },
                { name = "Mutation", value = "`N/A`", inline = true },
            },
            thumbnail = { url = "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png" },
            footer = { text = string.format("DevHub Community | Player: %s | %s", censoredName, timestamp) },
        }},
        username = "DevHub | Community",
        attachments = {}
    }
    pcall(function()
        local ok, err = pcall(function()
            httpRequest({
                Url = WEBHOOK_GLOBAL_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(testPayload)
            })
        end)
        if ok then
            Window:Notify({ Title = "Global Tracker", Content = "Test webhook terkirim!", Duration = 3 })
        else
            Window:Notify({ Title = "Error", Content = "Gagal kirim: " .. tostring(err), Duration = 4 })
        end
    end)
end


MonitoringTab:CreateSection({ Name = "Discord Webhook" })

MonitoringTab:CreateInput({
	Name = "URL Webhook",
	Placeholder = "https://discord.com/api/webhooks/...",
	Default = _G.WebhookURL or "",
    Callback = function(text)
        _G.WebhookURL = text
    end
})

MonitoringTab:CreateMultiDropdown({
	Name = "Rarity Filter",
	Items = rarityList,
    Default = _G.WebhookRarities or {},
    Callback = function(selected_options)
        _G.WebhookRarities = selected_options
    end
})

MonitoringTab:CreateMultiDropdown({
	Name = "Variant Filter",
	Items = variantList,
    Default = _G.WebhookVariants or {},
    Callback = function(selected_options)
        _G.WebhookVariants = selected_options
    end
})

MonitoringTab:CreateToggle({
    Name = "Always Announce Crystalized",
    Default = _G.WebhookCrystalized or false,
    Callback = function(state)
        _G.WebhookCrystalized = state
    end
})

MonitoringTab:CreateToggle({
	Name = "Send Webhook (Discord)",
    Default = _G.DetectNewFishActive or false,
    Callback = function(state)
        _G.DetectNewFishActive = state
    end
})

MonitoringTab:CreateButton({
	Name = "Test Discord Webhook",
	Icon = "rbxassetid://7733919427", 
    Callback = sendTestWebhook
})

MonitoringTab:CreateButton({
	Name = "Test Global Tracker",
	Icon = "rbxassetid://7733919427",
    Callback = sendTestGlobalWebhook
})

MonitoringTab:CreateSection({ Name = "WhatsApp Webhook" })

_G.WhatsAppWebhookEnabled = _G.WhatsAppWebhookEnabled or false
MonitoringTab:CreateToggle({
	Name = "Send Webhook (WhatsApp)",
	Default = _G.WhatsAppWebhookEnabled,
	Callback = function(state)
		_G.WhatsAppWebhookEnabled = state
	end
})

function sendFishToWhatsApp_API(fish)
    if not _G.WA_NumberID or _G.WA_NumberID == "" or
       not _G.WA_AccessToken or _G.WA_AccessToken == "" or
       not _G.WA_TargetPhone or _G.WA_TargetPhone == "" then
        warn("[DevHub WA] Missing WhatsApp API credentials")
        return
    end

    local fishInfo = fishDB[fish.Id]
    if not fishInfo then return end

    local rarity = tierToRarity[fishInfo.Tier] or "Unknown"
    if #_G.WebhookRarities > 0 and not table.find(_G.WebhookRarities, rarity) then
        return
    end

    local weight   = (fish.Metadata and fish.Metadata.Weight and string.format("%.2f Kg", fish.Metadata.Weight)) or "N/A"
    local mutation = (fish.Metadata and fish.Metadata.VariantId and tostring(fish.Metadata.VariantId)) or "None"
    local price    = (fishInfo.SellPrice and ("$"..fishInfo.SellPrice)) or "N/A"
    local coins    = getPlayerCoins()
    local totalFish = #getInventoryFish()

    local thumbnail = getThumbnailURL(fishInfo.Icon)
    if not thumbnail then return end

    local caption = string.format(
        "🎣 *New Fish Caught!*\n\n" ..
        "🐟 *Name:* %s\n" ..
        "⭐ *Rarity:* %s\n" ..
        "⚖️ *Weight:* %s\n" ..
        "🧬 *Mutation:* %s\n" ..
        "💰 *Sell Price:* %s\n" ..
        "🎒 *Backpack:* %d/4500\n" ..
        "🪙 *Coins:* %s\n\n" ..
        "— DevHub Auto Fishing",
        fishInfo.Name, rarity, weight, mutation, price, totalFish, coins
    )

    httpRequest({
        Url = "https://graph.facebook.com/v21.0/" .. _G.WA_NumberID .. "/messages",
        Method = "POST",
        Headers = {
            ["Authorization"] = "Bearer " .. _G.WA_AccessToken,
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            messaging_product = "whatsapp",
            to = _G.WA_TargetPhone,
            type = "image",
            image = {
                link = thumbnail,
                caption = caption
            }
        })
    })
end


_G.FonnteToken        = _G.FonnteToken or "eJ2K4skattShv2iwYXCU"        -- Token API Fonnte
_G.WA_TargetPhone     = _G.WA_TargetPhone or ""     -- Nomor tujuan WA (62xxxx)
_G.WA_NumberID        = _G.WA_NumberID or ""        -- WhatsApp Business Number ID
_G.WA_AccessToken     = _G.WA_AccessToken or ""     -- WhatsApp Business Access Token



function sendFonnteMessage(number, message, imageURL)
    local payload = {
        target = number,
        message = message,
        image = imageURL
    }

    httpRequest({
        Url = "https://api.fonnte.com/send",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = _G.FonnteToken
        },
        Body = HttpService:JSONEncode(payload)
    })
end
function sendNewFishWA(fish)
    -- This function calls sendFonnteMessage as per original logic
    local info = fishDB[fish.Id]
    if not info then return end

    local rarity = tierToRarity[info.Tier] or "Unknown"
    local variant  = (fish.Metadata and fish.Metadata.VariantId and tostring(fish.Metadata.VariantId)) or "None"

    local isCrystalized = variant == "Crystalized"
    local forceAnnounce = _G.WebhookCrystalized and isCrystalized

    if not forceAnnounce then
        if #_G.WebhookRarities > 0 and not table.find(_G.WebhookRarities, rarity) then
            return
        end
        if _G.WebhookVariants and #_G.WebhookVariants > 0 and not table.find(_G.WebhookVariants, variant) then
            return
        end
    end

    local weight   = (fish.Metadata and fish.Metadata.Weight and string.format("%.2f Kg", fish.Metadata.Weight)) or "N/A"
    local iconURL  = getThumbnailURL(info.Icon)
    local playerName = game.Players.LocalPlayer.Name

    local msg = "🐟 New Fish Caught 🐟\n" .. "*" .. playerName .. "*" .. " Has Caught An *".. rarity .."* Fish!!!\n\n" ..
                "• Name: " .. info.Name .. "\n" ..
                "• Rarity: " .. rarity .. "\n" ..
                "• Weight: " .. weight .. "\n" ..
                "• Variant: " .. variant .. "\n" ..
                "• Sell Price: " .. tostring(info.SellPrice)

    sendFonnteMessage(_G.WA_TargetPhone, msg, iconURL)
end

MonitoringTab:CreateInput({
	Name = "Target Phone (62...)",
	Placeholder = "Nomor WhatsApp",
    Default = _G.WA_TargetPhone,
    Callback = function(t)
        _G.WA_TargetPhone = t
    end
})

MonitoringTab:CreateButton({
	Name = "Test Whatsapp",
	Icon = "rbxassetid://7733919427", 
    Callback = function()
        sendFonnteMessage(_G.WA_TargetPhone, "Test berhasil! Webhook WhatsApp aktif.", nil)
    end
})

-- =========================================================================
-- SERVER CHAT WEBHOOK (ALL PLAYERS)
-- =========================================================================
MonitoringTab:CreateSection({ Name = "Server Chat Webhook" })

_G.ServerChatWebhookURL     = _G.ServerChatWebhookURL or ""
_G.ServerChatWebhookEnabled = _G.ServerChatWebhookEnabled or false
_G.ServerChatRarityFilter   = _G.ServerChatRarityFilter or {}

-- FishIt server message rarity colors
local serverRarityColors = {
    { rarity = "Epic",      r = 179, g = 115, b = 248 },  -- Purple  (confirmed)
    { rarity = "Legendary", r = 255, g = 185, b = 50  },  -- Yellow/Gold
    { rarity = "Mythic",    r = 255, g = 25,  b = 25  },  -- rgb(255,25,25) confirmed
    { rarity = "SECRET",    r = 24,  g = 255, b = 152 },  -- rgb(24,255,152) confirmed
    { rarity = "Forgotten", r = 255, g = 255, b = 255 },  -- White   (confirmed)
}

local serverRarityDiscordColors = {
    Epic      = 0xB373F8,  -- Purple
    Legendary = 0xFFB932,  -- Gold
    Mythic    = 0xFF1919,  -- rgb(255,25,25)
    SECRET    = 0x18FF98,  -- rgb(24,255,152)
    Forgotten = 0xFFFFFF,  -- White
    Unknown   = 0x888888,
}

 function getRarityFromRGB(r, g, b)
    local best, bestDist = nil, math.huge
    for _, entry in ipairs(serverRarityColors) do
        local d = ((r - entry.r)^2 + (g - entry.g)^2 + (b - entry.b)^2) ^ 0.5
        if d < bestDist then
            bestDist = d
            best = entry.rarity
        end
    end
    -- Threshold 55: tight enough to reject Common(94.6)/Rare(99.9) but still
    -- accepts genuine matches. Mythic<->SECRET gap is 61 so no cross-bleed.
    return (bestDist < 55) and best or nil
end

 function parseRGBFromText(text)
    local rs, gs, bs = text:match('rgb%((%d+),%s*(%d+),%s*(%d+)%)')
    if rs then return tonumber(rs), tonumber(gs), tonumber(bs) end
    local hex = text:match('#(%x%x%x%x%x%x)')
    if hex then
        return tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16)
    end
    return nil
end

 function sendServerChatDiscordWebhook(playerName, fishName, weight, chance, rarity, imageUrl)
    if not httpRequest then return end
    local url = _G.ServerChatWebhookURL or ""
    if not url:match("discord%.com/api/webhooks") then return end
    if _G.ServerChatRarityFilter and #_G.ServerChatRarityFilter > 0 then
        if not table.find(_G.ServerChatRarityFilter, rarity) then return end
    end
    local embedColor = serverRarityDiscordColors[rarity] or serverRarityDiscordColors.Unknown
    local censored = censorPlayerName(playerName)
    local embed = {
        title       = string.format("\xF0\x9F\x8E\xA3 Server Catch | %s", rarity),
        description = string.format("**%s** obtained **%s**!", censored, fishName),
        color       = embedColor,
        fields = {
            { name = "Fish",    value = string.format("`%s`", fishName),      inline = true },
            { name = "Weight",  value = string.format("`%s`", weight),        inline = true },
            { name = "Rarity",  value = string.format("`%s`", rarity),        inline = true },
            { name = "Chance",  value = string.format("`1 in %s`", chance),   inline = true },
            { name = "Player",  value = string.format("`%s`", censored),      inline = true },
        },
        footer    = { text = "DevHub Server Tracker" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
    }
    if imageUrl and imageUrl ~= "" then
        embed.thumbnail = { url = imageUrl }
    end
    local payload = {
        username   = "DevHub | Server Tracker",
        avatar_url = "https://cdn.discordapp.com/attachments/1434789394929287178/1448926732705988659/Swuppie.jpg?ex=693d09ac&is=693bb82c&hm=88d4c68207470eb4abc79d9b68227d85171aded5d3d99e9a76edcd823862f5fe",
        embeds = { embed }
    }
    pcall(function()
        httpRequest({
            Url     = url,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode(payload)
        })
    end)
end

-- Hook TextChatService to monitor all server fish catch messages
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
        -- Format: <font color="rgb(...)">FishName (weight)</font>
        -- Extract fish name + weight directly from inside the color tag (most accurate)
        local fishName, weight = text:match('<font[^>]+color="rgb%([^%)]+%)"[^>]*>([^<%(]+)%(([%d%.]+%s*[Kkg]?g?)%)<')
        if not fishName then
            -- Fallback: strip all tags and parse plain text
            fishName, weight = nil, nil
        end

        local plain = text:gsub("<[^>]+>", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
        plain = plain:gsub("^%[Server%]:%s*", ""):gsub("^%s+", "")

        local playerName, chance
        if fishName then
            fishName = fishName:gsub("%s+$", "")
            weight   = weight:gsub("%s*$", "")
            -- Only need player + chance from plain text
            playerName = plain:match("^([%w_]+) obtained")
            chance     = plain:match("with a 1 in (.+) chance!?")
        else
            playerName, fishName, weight, chance =
                plain:match("^([%w_]+) obtained an? (.+) %(([%d%.]+%s*[Kkg]?g?)%) with a 1 in (.+) chance!?")
            if fishName then fishName = fishName:gsub("%s+$", "") end
            if weight   then weight   = weight:gsub("%s+$", "") end
        end

        if not playerName or not fishName then return end
        chance = chance and chance:gsub("%s+$", "") or "?"
        local imageUrl = nil
        local fishEntry = fishByName and fishByName[fishName:lower()]
        if fishEntry and fishEntry.Icon then
            imageUrl = getThumbnailURL(fishEntry.Icon)
        end
        task.spawn(sendServerChatDiscordWebhook, playerName, fishName, weight, chance, rarity, imageUrl)
    end
end

MonitoringTab:CreateInput({
    Name        = "URL Server Chat Webhook",
    Placeholder = "https://discord.com/api/webhooks/...",
    Default     = _G.ServerChatWebhookURL or "",
    Callback    = function(text)
        _G.ServerChatWebhookURL = text
    end
})

MonitoringTab:CreateMultiDropdown({
    Name     = "Rarity Filter (Server Chat)",
    Items    = { "Forgotten", "SECRET", "Mythic", "Legendary", "Epic" },
    Default  = _G.ServerChatRarityFilter or {},
    Callback = function(selected)
        _G.ServerChatRarityFilter = selected
    end
})

MonitoringTab:CreateToggle({
    Name     = "Enable Server Chat Webhook",
    Default  = _G.ServerChatWebhookEnabled or false,
    Callback = function(state)
        _G.ServerChatWebhookEnabled = state
    end
})

-- =========================================================================
-- DevHub WEB MONITORING
-- =========================================================================
MonitoringTab:CreateSection({ Name = "DevHub Web Monitoring" })

local VoraMonitoringSettings = {
    VoraKey = "", -- Replace in UI
    AutoSync = true,
    Interval = 5,
    Enabled = false -- Master Toggle State
}

local VORA_API_URL = "https://monitor.DevHub.xyz/api/inventory/sync"

MonitoringTab:CreateInput({
    Name = "DevHub Key",
    Placeholder = "Enter DevHub Key...",
    Default = VoraMonitoringSettings.VoraKey,
    Callback = function(val)
        VoraMonitoringSettings.VoraKey = val
    end
})

MonitoringTab:CreateToggle({
    Name = "Enable Web Monitoring",
    Default = false,
    Callback = function(val)
        VoraMonitoringSettings.Enabled = val
    end
})

 function GetWebItemData(ItemType, Id)
    -- Reusing existing ItemUtility logic safely
    local success, result = pcall(function()
        local ItemUtility = require(game:GetService("ReplicatedStorage").Shared.ItemUtility)
        if ItemType == "Baits" then
            return ItemUtility:GetBaitData(Id)
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
        elseif ItemType == "Fish" then
            return ItemUtility:GetFish(Id)
        elseif ItemType == "Fishing Rods" then
            return ItemUtility:GetFishingRods() and ItemUtility:GetFishingRods()[Id]
        elseif ItemType == "Totems" then
            return ItemUtility:GetTotemData(Id)
        elseif ItemType == "Potions" then
            return ItemUtility:GetPotionData(Id)
        elseif ItemType == "Charms" then
            return ItemUtility:GetCharmData(Id)
        else
            return ItemUtility:GetItemDataFromItemType(ItemType, Id)
        end
    end)
    return success and result or nil
end

 function GatherVoraInventory()
    local inventory = {
        Rods = {},
        Charms = {},
        Items = {},
        Fish = {},
        Totems = {},
        Potions = {}
    }

    local Replion = require(game:GetService("ReplicatedStorage").Packages.Replion)
    local DataClient = Replion.Client:WaitReplion("Data")
    if not DataClient then return nil end
    
    local rawInventory = DataClient:GetExpect("Inventory")
    if not rawInventory then return nil end

     function safeString(str)
        if not str then return "" end
        str = tostring(str)
        return str:match("^%s*(.-)%s*$") or str
    end

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
                AddToInventory(inventory.Charms, {
                    id = safeString(item.Id),
                    name = safeString(itemData.Data.Name),
                    icon = safeString(itemData.Data.Icon),
                    tier = itemData.Data.Tier or 1,
                    quantity = item.Quantity or 1,
                    uuid = safeString(item.UUID or "")
                })
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

            AddToInventory(inventory.Items, {
                id = safeString(item.Id),
                name = itemName,
                icon = itemIcon,
                tier = itemTier,
                type = itemType,
                quantity = item.Quantity or 1,
                uuid = safeString(item.UUID or ""),
                favorited = item.Favorited == true
            })
        end
    end

    -- Process Fish
    if rawInventory.Fish then
        for _, item in ipairs(rawInventory.Fish) do
            local itemData = GetWebItemData("Fish", item.Id)
            if itemData then
                AddToInventory(inventory.Fish, {
                    id = safeString(item.Id),
                    name = safeString(itemData.Data.Name),
                    icon = safeString(itemData.Data.Icon),
                    tier = itemData.Data.Tier or 1,
                    quantity = item.Quantity or 1,
                    uuid = safeString(item.UUID or "")
                })
            end
        end
    end

    -- Process Totems, Potions...
    if rawInventory.Totems then
        for _, item in ipairs(rawInventory.Totems) do
            local itemData = GetWebItemData("Totems", item.Id)
            if itemData then
                AddToInventory(inventory.Totems, {
                    id = safeString(item.Id),
                    name = safeString(itemData.Data.Name),
                    icon = safeString(itemData.Data.Icon),
                    tier = itemData.Data.Tier or 1,
                    quantity = item.Quantity or 1,
                    uuid = safeString(item.UUID or "")
                })
            end
        end
    end

    if rawInventory.Potions then
        for _, item in ipairs(rawInventory.Potions) do
             local itemData = GetWebItemData("Potions", item.Id)
             if itemData then
                AddToInventory(inventory.Potions, {
                    id = safeString(item.Id),
                    name = safeString(itemData.Data.Name),
                    icon = safeString(itemData.Data.Icon),
                    tier = itemData.Data.Tier or 1,
                    quantity = item.Quantity or 1,
                    uuid = safeString(item.UUID or "")
                })
             end
        end
    end

    -- Player Stats
    local Player = game.Players.LocalPlayer
    
     function GetLeaderstatValue(statName)
        local leaderstats = Player:FindFirstChild("leaderstats")
        if leaderstats and leaderstats:FindFirstChild(statName) then
            return leaderstats[statName].Value
        end
        return nil
    end

    local playerStats = {
        totalFishCaught = GetLeaderstatValue("Caught") or 0,
        highestRarity = GetLeaderstatValue("Rarest Fish") or "None"
    }

    return {
        apiKey = VoraMonitoringSettings.VoraKey,
        playerName = safeString(Player.Name),
        userId = Player.UserId,
        playerStats = playerStats,
        inventory = inventory,
        isOnline = true, 
        timestamp = DateTime.now():ToIsoDate()
    }
end

 function SendVoraInventory(isOffline)
    if VoraMonitoringSettings.VoraKey == "yourkey" or VoraMonitoringSettings.VoraKey == "" then return end
    
    local success, err = pcall(function()
        local data = GatherVoraInventory()
        if not data then return end
        
        if isOffline then data.isOnline = false end

        local jsonData = HttpService:JSONEncode(data)
        
        -- Use httpRequest function defined earlier
        httpRequest({
            Url = VORA_API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["ngrok-skip-browser-warning"] = "true"
            },
            Body = jsonData
        })
    end)
end

-- Auto-sync loop for DevHub
task.spawn(function()
    while true do
        task.wait(VoraMonitoringSettings.Interval)
        if VoraMonitoringSettings.Enabled and VoraMonitoringSettings.AutoSync then
            SendVoraInventory(false)    
        end
    end
end)

-- Handle leaving
game:GetService("Players").PlayerRemoving:Connect(function(p)
    if p == game.Players.LocalPlayer then
        SendVoraInventory(true)
    end
end)

-- Defer initial fish scan to prevent CPU spike on load
task.defer(function()
    task.wait(2) -- Wait 2 seconds after load before scanning
    local initialFishList = getInventoryFish()
    for _, fish in ipairs(initialFishList) do
        if fish and fish.UUID then
            knownFishUUIDs[fish.UUID] = true
        end
    end
end)

-- Webhook detection loop (global tracker wajib terkirim seperti blade.lua, tidak tergantung toggle)
spawn(function()
    while wait(2) do
        pcall(function()
            local currentFishList = getInventoryFish()
            for _, fish in ipairs(currentFishList) do
                if fish and fish.UUID and not knownFishUUIDs[fish.UUID] then
                    knownFishUUIDs[fish.UUID] = true
                    task.spawn(function()
                        -- Global webhook: selalu kirim saat SECRET (sama seperti blade.lua)
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

MainTab:CreateSection({ Name = "Cast Mode" })

MainTab:CreateDropdown({
    Name = "Global Cast Mode",
    Items = CAST_MODE_LIST,
    Default = Config.UB.Settings.CastMode,
    Callback = function(v)
        if table.find(CAST_MODE_LIST, v) then
            Config.UB.Settings.CastMode = v
            Instant.SetCastMode(v)
        end
    end,
})

MainTab:CreateSection({ Name = "Fishing" })

MainTab:CreateToggle({
	Name = "Auto Rod",
	Default = false,
	  Callback = function(Value) 
        _G.AutoRod = Value
        if Value then
            equipTool:FireServer(1)
        else return end
    end
})

CurrentOption = "Instant"

MainTab:CreateDropdown({
	Name = "Mode",
	Items = {"Legit", "Instant"},
	Default = "Instant",
	Callback = function(Option)
        if CurrentOption == "Legit" and Option ~= "Legit" and _G.AutoFarm then
            AutoEnabled:InvokeServer(false)
        end
        CurrentOption = Option
    end
})

MainTab:CreateToggle({
	Name = "Auto Farm",
	Default = false,
	    Callback = function(Value)
        _G.AutoFarm = Value
        if Value then
            if CurrentOption == "Instant" then
                Window:Notify({
                    Title = "AutoFarm",
                    Content = "Instant Mode ON",
                    Duration = 3
                })
                task.spawn(function()
                    while _G.AutoFarm and CurrentOption == "Instant" do
                        pcall(instant)
                        task.wait(0.001)
                    end
                end)
            elseif CurrentOption == "Legit" then
                AutoEnabled:InvokeServer(true)
                Window:Notify({
                    Title = "AutoFarm",
                    Content = "Legit Mode ON",
                    Duration = 3
                })
                task.spawn(function()
                    while _G.AutoFarm and CurrentOption == "Legit" do
                        pcall(function()
                            FishingController:RequestChargeFishingRod(Vector2.new(0, 0), true)
                            task.wait(delayfishing)
                            CallFishDone(REFishDone, 1)
                        end)
                        task.wait(0.4 + math.random() * 0.3)
                    end
                end)
            end

        -- ======================= WHEN AUTOFARM TURNS OFF =======================
        else
            if CurrentOption == "Legit" then
                AutoEnabled:InvokeServer(false)
            end
            Window:Notify({
                Title = "AutoFarm",
                Content = "AutoFarm OFF",
                Duration = 3
            })

            _G.AutoFarm = false
            pcall(autooff)
            pcall(cancel)
        end
    end
})

MainTab:CreateInput({
	Name = "Fishing Delay",
	SideLabel = "Fishing Delay",
	Placeholder = "Contoh: 1.0",
	Default = "",
	Callback = function(value)
        local n = tonumber(value)
        if n and n > 0 then
            delayfishing = n
        else
            delayfishing = 1
        end
	end
})

MainTab:CreateSection({ Name = "Instant Fishing V2" })

MainTab:CreateInput({
    Name = "Delay Bait (CompleteDelay)",
    SideLabel = "Delay Reel",
    Placeholder = tostring(Config.UB.Settings.CompleteDelay),
    Default = tostring(Config.UB.Settings.CompleteDelay),
    Callback = function(value)
        local n = tonumber(value)
        if n and n > 0 then
            Config.UB.Settings.CompleteDelay = n
            Instant.SetCompleteDelay(n)
        end
    end,
})

MainTab:CreateInput({
    Name = "Cast Delay",
    SideLabel = "Delay Cast",
    Placeholder = tostring(Config.UB.Settings.CancelDelay),
    Default = tostring(Config.UB.Settings.CancelDelay),
    Callback = function(value)
        local n = tonumber(value)
        if n and n >= 0 then
            Config.UB.Settings.CancelDelay = n
            Instant.SetCastDelay(n)
        end
    end,
})

MainTab:CreateToggle({
    Name = "Enable Instant Fishing V2",
    Default = false,
    Callback = function(state)
        -- moons FAST 3 KEDIP: needCast, onToggleUB, lalu HookNotif + FC (desktop & mobile)
        needCast = true
        Config.InstantFishingV2Active = state
        onToggleUB(state)

        if state then
            Config.HookNotif = true
            FishingController.RequestChargeFishingRod = function(self, ...)
                return
            end
            FishingController.SendFishingRequestToServer = function(self, ...)
                return
            end
        else
            Config.HookNotif = false
            FishingController.RequestChargeFishingRod = function(self, ...)
                return instantV2OrigCharge(self, ...)
            end
            FishingController.SendFishingRequestToServer = function(self, ...)
                return instantV2OrigCast(self, ...)
            end
        end
    end,
})

-- =================
-- Instant Bobber UI
-- =================
MainTab:CreateSection({ Name = "Instant Bobber" })

MainTab:CreateToggle({
    Name = "Instant Bobber",
    Default = false,
    Callback = function(state)
        patchInstantBaitOverrideToCastPosition(state)
        Window:Notify({
            Title = "Instant Bobber",
            Content = state and "ON (instant cast visual — moons)" or "OFF",
            Duration = 2.5,
        })
    end,
})


-- =============================================================================
-- QUEST (Deep Sea / Element / Diamond) + AUTO TEMPLE LEVER
-- =============================================================================

QuestTab:CreateSection({ Name = "Quest" })


 GhostfinnPart1 = CFrame.new(-3741.23804, -135.074417, -1008.8219, -0.983854651, -5.2231119e-08, -0.178969383, -4.4131955e-08, 1, -4.92357373e-08, 0.178969383, -4.05425382e-08, -0.983854651)
 GhostfinnPart2 = CFrame.new(-3576.43896, -281.441864, -1652.00879, -0.986065865, 6.27356229e-08, -0.166355252, 4.83395013e-08, 1, 9.0587406e-08, 0.166355252, 8.12836234e-08, -0.986065865)

 DiamondQuest2Location = CFrame.new(-3188.67749, 1.07282305, 2101.84595, 0.938817143, 2.14984044e-10, 0.344415963, 8.34196712e-09, 1, -2.33629294e-08, -0.344415963, 2.48066243e-08, 0.938817143)
 DiamondQuest3and4Location = CFrame.new(-2158.90967, 53.4871254, 3667.20703, 0.886574924, -4.98531634e-08, -0.462585062, 5.43041133e-12, 1, -1.077604e-07, 0.462585062, 9.55351496e-08, 0.886574924)
 DiamondQuest5and6Location = CFrame.new(-669.763306, 17.5000591, 414.084717, -0.998891115, -1.21555646e-08, 0.0470801853, -1.05114397e-08, 1, 3.51693892e-08, -0.0470801853, 3.46355087e-08, -0.998891115)

 ElementRodLocation = CFrame.new(2113.85693, -91.1985855, -699.206787, 0.998474956, -5.945203e-09, -0.0552060455, 3.14363247e-09, 1, -5.0834366e-08, 0.0552060455, 5.05832958e-08, 0.998474956)

 TEMPLE_LEVER_BASE = CFrame.new(1466.80176, -30.1063519, -575.435425, -0.439164162, 2.01621848e-08, 0.898406804, -1.93919014e-08, 1, -3.19214095e-08, -0.898406804, -3.14405568e-08, -0.439164162)
 START_CFRAME = CFrame.new(-544.096191, 16.055603, 116.168938, 0.975038111, 1.26798724e-07, -0.222037584, -1.31077371e-07, 1, -4.5339581e-09, 0.222037584, 3.35248842e-08, 0.975038111)
local TempleLeverLocations = {
    ["Hourglass Diamond Artifact"] = TEMPLE_LEVER_BASE,
    ["Arrow Artifact"] = TEMPLE_LEVER_BASE,
    ["Diamond Artifact"] = TEMPLE_LEVER_BASE,
    ["Crescent Artifact"] = TEMPLE_LEVER_BASE,
}

local TARGET_QUESTS = { ["Element Quest"] = true, ["Deep Sea Quest"] = true, ["Diamond Researcher"] = true }

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
    if not TARGET_QUESTS[header.Text] then return nil end
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
    local gui = player:WaitForChild("PlayerGui")
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
    local out = {}
    local data = getQuestData("Deep Sea Quest")
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
    local out = {}
    local data = getQuestData("Element Quest")
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
    local out = {}
    local data = getQuestData("Diamond Researcher")
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

function getElementQuestProgress()
    local p = { "No progress data", "No progress data", "No progress data", "No progress data" }
    local data = getQuestData("Element Quest")
    if data and data.objectives then
        for i = 1, 4 do
            if data.objectives[i] then
                local o = data.objectives[i]
                p[i] = o.progressText ~= "" and o.progressText or (o.percentage .. "%")
            end
        end
    end
    return p
end

function isElementQuestComplete()
    local data = getQuestData("Element Quest")
    return data and data.allCompleted or false
end

function teleportTo(cf)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and cf then
        hrp.CFrame = cf
    end
end

-- =============================================================================
-- Kaitun helpers: best rod/bait/coins (ported from mainkaitun.lua)
-- =============================================================================
local FishingRods = {
    ["Midnight Rod"] = { id = 80, price = 50000 },
    ["Astral Rod"] = { id = 5, price = 1000500 },
    ["Ghostfinn Rod"] = { id = 169, price = 9999999999999999999 },
    ["Element Rod"] = { id = 257, price = 999999999999999999999999999999 },
}

function getRodUUID(rodId)
    local inv = dataStore and dataStore:Get("Inventory")
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
        pcall(function()
            REEquipItem:FireServer(uuid, "Fishing Rods")
        end)
    end
    -- Hotbar fallback (some clients require hotbar equip to take effect)
    if equipTool then
        pcall(function()
            equipTool:FireServer(1)
        end)
    end
    return true
end

-- Equip rod by item id (inventory rod id), not by display name.
function equipRodById(rodId)
    local uuid = getRodUUID(rodId)
    if not uuid then return false end
    if REEquipItem then
        pcall(function()
            REEquipItem:FireServer(uuid, "Fishing Rods")
        end)
    end
    -- Hotbar fallback
    if equipTool then
        pcall(function()
            equipTool:FireServer(1)
        end)
    end
    return true
end

-- Equip the current best rod from `getBestRod()` mapping.
function equipBestRodNow()
    local bestName = getBestRod and getBestRod() or nil
    if bestName == "Midnight Rod" then
        return equipRodById(80)
    elseif bestName == "Astral Rod" then
        return equipRodById(5)
    elseif bestName == "Ghostfinn Rod" then
        return equipRodById(169)
    elseif bestName == "Element Rod" then
        return equipRodById(257)
    end

    -- Fallback requested: if best rod is not detected, equip tool directly.
    if equipTool then
        pcall(function()
            equipTool:FireServer(1)
        end)
        return true
    end
    return false
end

-- Retry equip for a short time. This helps when server auto-enable
-- happens before `dataStore` inventory updates (UUID might be nil briefly).
function equipBestRodNowWithRetry(maxWaitSeconds, intervalSeconds)
    local maxWait = tonumber(maxWaitSeconds) or 8
    local interval = tonumber(intervalSeconds) or 0.5
    local deadline = tick() + maxWait
    local lastOk = false

    while tick() < deadline do
        local ok = equipBestRodNow()
        if ok then
            return true
        end
        lastOk = ok
        task.wait(interval)
    end

    return lastOk
end

function hasItemInInventory(itemName)
    local inv = dataStore and dataStore:Get("Inventory")
    if not inv then return false end

    local util = _G.ItemUtility or ItemUtility
    if not util or not util.GetItemData then return false end

    for _, category in pairs(inv) do
        if type(category) == "table" then
            for _, item in ipairs(category) do
                if item and item.Id then
                    local info = util:GetItemData(item.Id)
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
    local inv = dataStore and dataStore:Get("Inventory")
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

Baits = {
    [3] = { name = "Midnight Bait", price = 3000 },
    [15] = { name = "Corrupt Bait", price = 1150000 },
    [16] = { name = "Aether Bait", price = 3700000 },
}

function hasBait(baitId)
    local inv = dataStore and dataStore:Get("Inventory")
    if not inv or not inv.Baits then return false end
    for _, b in ipairs(inv.Baits) do
        if b.Id == baitId then return true end
    end
    return false
end

function buyBait(baitId)
    if BuyBait then
        pcall(function()
            BuyBait:InvokeServer(baitId)
        end)
    end
end

function equipBait(baitId)
    if EquipBait then
        pcall(function()
            EquipBait:FireServer(baitId)
        end)
    end
end

function getBestBait()
    local inv = dataStore and dataStore:Get("Inventory")
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
    local ok, c = pcall(function() return dataStore and dataStore:Get("Coins") end)
    return (ok and c) or 0
end

local templeLeverOrder = {
    "Hourglass Diamond Artifact",
    "Diamond Artifact",
    "Arrow Artifact",
    "Crescent Artifact",
}
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

function updateTempleLeverStatusText()
    local lines = {}
    for _, leverType in ipairs(templeLeverOrder) do
        local display = templeLeverTypeMapping[leverType]
        local done = templeLeverStatus[display]
        table.insert(lines, display .. ": " .. (done and "COMPLETED" or "NOT COMPLETED"))
    end
    if templeLeverParagraph and templeLeverParagraph.SetDesc then
        templeLeverParagraph:SetDesc(table.concat(lines, "\n"))
    end
end

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
        fireproximityprompt(prompt)
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
    updateTempleLeverStatusText()
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

    local ok, result = pcall(function()
        refreshTempleLeverStatuses()
        local gameLeverType, displayName = getNextUncompletedLever()
        if not gameLeverType then
            return false
        end

        local templeLever = findTempleLeverByType(gameLeverType)
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not templeLever or not hrp then
            return false
        end

        local cf = templeLeverLocationsMain[displayName]
        if cf then
            hrp.CFrame = cf
        end

        while hasLeverPrompt(templeLever) do
            if not fireLeverPrompt(templeLever) then break end
            task.wait(10)
        end

        if not hasLeverPrompt(templeLever) then
            templeLeverStatus[displayName] = true
            updateTempleLeverStatusText()
            return true
        end
        return false
    end)

    isProcessingTemple = false
    return ok and result or false
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

-- =============================================================================
-- STATUS OVERLAY UI (ported from CompleteDevHub/mainkaitun.lua)
-- - ScreenGui shows quest progress + best rod/bait/coins
-- - Visible when any quest mode is ON (or forced by toggle)
-- =============================================================================

PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
Lighting = game:GetService("Lighting")

screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevHub Status"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

blur = Instance.new("BlurEffect")
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
    l.TextColor3 = Color3.fromRGB(255, 255, 255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = fontSize or 18
    l.Text = text or ""
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.Visible = false
    l.Parent = screenGui
    return l
end

titleLabel = makeLabel("Title", UDim2.new(0, 300, 0, 40), UDim2.new(0.5, 0, 0.25, 0), "DevHub Status", 24)
titleLabel.TextColor3 = Color3.fromRGB(64, 224, 208)
titleLabel.TextScaled = true

row1 = makeLabel("Row1", UDim2.new(0, 600, 0, 30), UDim2.new(0.5, 0, 0.35, 0))
row2 = makeLabel("Row2", UDim2.new(0, 600, 0, 30), UDim2.new(0.5, 0, 0.4, 0))
row3 = makeLabel("Row3", UDim2.new(0, 600, 0, 30), UDim2.new(0.5, 0, 0.45, 0))

ghostfinnTitle = makeLabel("GhostfinnTitle", UDim2.new(0, 600, 0, 30), UDim2.new(0.4, 0, 0.5, 0), "Deep Sea Quest")
ghostfinnTitle.TextColor3 = Color3.fromRGB(64, 224, 208)

ghostfinnRow1 = makeLabel("Ghostfinn1", UDim2.new(0, 600, 0, 25), UDim2.new(0.4, 0, 0.55, 0), "Loading...", 12)
ghostfinnRow1.Font = Enum.Font.Gotham
ghostfinnRow2 = makeLabel("Ghostfinn2", UDim2.new(0, 600, 0, 25), UDim2.new(0.4, 0, 0.575, 0), "", 12)
ghostfinnRow2.Font = Enum.Font.Gotham
ghostfinnRow3 = makeLabel("Ghostfinn3", UDim2.new(0, 600, 0, 25), UDim2.new(0.4, 0, 0.6, 0), "", 12)
ghostfinnRow3.Font = Enum.Font.Gotham
ghostfinnRow4 = makeLabel("Ghostfinn4", UDim2.new(0, 600, 0, 25), UDim2.new(0.4, 0, 0.625, 0), "", 12)
ghostfinnRow4.Font = Enum.Font.Gotham

elementTitle = makeLabel("ElementTitle", UDim2.new(0, 600, 0, 30), UDim2.new(0.6, 0, 0.5, 0), "Element Quest")
elementTitle.TextColor3 = Color3.fromRGB(64, 224, 208)
elementRow1 = makeLabel("Element1", UDim2.new(0, 600, 0, 25), UDim2.new(0.6, 0, 0.55, 0), "Loading...", 12)
elementRow1.Font = Enum.Font.Gotham
elementRow2 = makeLabel("Element2", UDim2.new(0, 600, 0, 25), UDim2.new(0.6, 0, 0.575, 0), "", 12)
elementRow2.Font = Enum.Font.Gotham
elementRow3 = makeLabel("Element3", UDim2.new(0, 600, 0, 25), UDim2.new(0.6, 0, 0.6, 0), "", 12)
elementRow3.Font = Enum.Font.Gotham
elementRow4 = makeLabel("Element4", UDim2.new(0, 600, 0, 25), UDim2.new(0.6, 0, 0.625, 0), "", 12)
elementRow4.Font = Enum.Font.Gotham

diamondTitle = makeLabel("DiamondTitle", UDim2.new(0, 600, 0, 30), UDim2.new(0.5, 0, 0.68, 0), "Diamond Researcher")
diamondTitle.TextColor3 = Color3.fromRGB(64, 224, 208)
diamondRow1 = makeLabel("Diamond1", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.73, 0), "Loading...", 12)
diamondRow1.Font = Enum.Font.Gotham
diamondRow2 = makeLabel("Diamond2", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.755, 0), "", 12)
diamondRow2.Font = Enum.Font.Gotham
diamondRow3 = makeLabel("Diamond3", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.78, 0), "", 12)
diamondRow3.Font = Enum.Font.Gotham
diamondRow4 = makeLabel("Diamond4", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.805, 0), "", 12)
diamondRow4.Font = Enum.Font.Gotham
diamondRow5 = makeLabel("Diamond5", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.83, 0), "", 12)
diamondRow5.Font = Enum.Font.Gotham
diamondRow6 = makeLabel("Diamond6", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.855, 0), "", 12)
diamondRow6.Font = Enum.Font.Gotham

local statusLabels = {
    row1, row2, row3, titleLabel,
    ghostfinnTitle, ghostfinnRow1, ghostfinnRow2, ghostfinnRow3, ghostfinnRow4,
    elementTitle, elementRow1, elementRow2, elementRow3, elementRow4,
    diamondTitle, diamondRow1, diamondRow2, diamondRow3, diamondRow4, diamondRow5, diamondRow6,
}

_G.KaitunGUIForce = _G.KaitunGUIForce or false

function updateOverlayVisibility()
    local anyActive = _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode
    local visible = _G.KaitunGUIForce or anyActive

    -- Common rows (only when overlay is visible)
    row1.Visible = visible
    row2.Visible = visible
    row3.Visible = visible
    titleLabel.Visible = visible
    blur.Enabled = visible

    -- Quest-specific sections (only when each quest mode is active)
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

updateOverlayVisibility()

function isAnyQuestActive()
    return _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode
end

function updateUIVisibility()
    pcall(function()
        updateOverlayVisibility()
    end)
end

ExclusiveTab:CreateToggle({
    Title = "Start Kaitun",
    Default = _G.KaitunGUIForce,
    Callback = function(state)
        _G.KaitunGUIForce = state
        pcall(function()
            updateOverlayVisibility()
        end)
    end,
})

RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Prevent early-render nil crashes (labels & helper functions
        -- might be defined a few lines later in the script).
        if not (blur and titleLabel and row1 and row2 and row3
            and ghostfinnTitle and ghostfinnRow1 and ghostfinnRow2 and ghostfinnRow3 and ghostfinnRow4
            and elementTitle and elementRow1 and elementRow2 and elementRow3 and elementRow4
            and diamondTitle and diamondRow1 and diamondRow2 and diamondRow3 and diamondRow4 and diamondRow5 and diamondRow6
        ) then
            return
        end
        if type(getBestRod) ~= "function" or type(getBestBait) ~= "function" or type(getCoins) ~= "function" then
            return
        end
        if type(getGhostfinnProgress) ~= "function" or type(getElementProgress) ~= "function" or type(getDiamondProgress) ~= "function" then
            return
        end

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

-- =============================================================================
-- =============================================================================
-- QUEST PROCESS FUNCTIONS (ported from Main.lua, adapted for Vora.lua)
-- Handles: Deep Sea, Element, Diamond, Temple Lever auto-teleport + item actions
-- =============================================================================
_G.AutoDeepSeaQuest = _G.AutoDeepSeaQuest or _G.DeepSeaQuestMode or false
_G.AutoElementQuest = _G.AutoElementQuest or _G.ElementQuestMode or false
_G.AutoDiamondQuest = _G.AutoDiamondQuest or _G.DiamondQuestMode or false
_G.AutoCreateTranscendedStones = _G.AutoCreateTranscendedStones or false

-- ── Deep Sea Quest ─────────────────────────────────────────────────────────
local dsDeepSeaStep = nil
local dsDeepSeaDone = false
local dsDeepSeaGUIReady = false

local DS_STEP1_LOC = CFrame.new(-3612.3645, -279.07373, -1693.4845,
	-0.999661744, 3.77537575e-08, 0.0260070078, 3.80828276e-08, 1,
	1.21579262e-08, -0.0260070078, 1.31442341e-08, -0.999661744)
local DS_STEP2_LOC = CFrame.new(-3733.34985, -135.074417, -1011.00171,
	-0.961937428, 3.60563774e-08, -0.273269713, 5.88834368e-08, 1,
	-7.53314495e-08, 0.273269713, -8.85552041e-08, -0.961937428)

function dsRefreshStep()
	local data = pcall(function() return getQuestData("Deep Sea Quest") end) and getQuestData("Deep Sea Quest")
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
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	if not dsDeepSeaGUIReady then
		hrp.CFrame = DS_STEP2_LOC  -- Teleport to Sisyphus to init GUI
		return true
	end
	if dsDeepSeaStep == 1 then
		hrp.CFrame = DS_STEP1_LOC  -- Treasure Room (Rare/Epic)
		return true
	elseif dsDeepSeaStep == 2 or dsDeepSeaStep == 3 then
		hrp.CFrame = DS_STEP2_LOC  -- Sisyphus Statue (Mythic/Secret)
		return true
	end
	return false
end

-- ── Element Quest ──────────────────────────────────────────────────────────
local elemStep = nil
local elemDone = false
local elemGUIReady = false

local ELEM_CELLAR  = CFrame.new(2113.85693, -91.1985855, -699.206787,
	0.998474956, -5.945203e-09, -0.0552060455, 3.14363247e-09, 1,
	-5.0834366e-08, 0.0552060455, 5.05832958e-08, 0.998474956)
local ELEM_JUNGLE  = CFrame.new(1474.01025, 2.64634514, -324.647125,
	-0.413843632, -6.18603408e-08, -0.910347998, -9.32754673e-08, 1,
	-2.55494399e-08, 0.910347998, 7.43396598e-08, -0.413843632)
local ELEM_TEMPLE  = CFrame.new(1464.96277, -22.3750019, -652.420166,
	-0.0930489823, -1.17108794e-08, 0.995661557, 8.05597278e-09, 1,
	1.25147741e-08, -0.995661557, 9.18550924e-09, -0.0930489823)

function elemRefreshStep()
	local data = pcall(function() return getQuestData("Element Quest") end) and getQuestData("Element Quest")
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
	local inv = dataStore and dataStore:Get("Inventory")
	if inv and inv.Items then
		for _, item in ipairs(inv.Items) do
			local ok, info = pcall(function()
				return ItemUtility and ItemUtility.GetItemDataFromItemType(item.Id)
			end)
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
	local ok, bp = pcall(function() return player.PlayerGui.Backpack end)
	if ok and bp then
		local disp = bp:FindFirstChild("Display")
		if disp then
			local cnt = 0
			for _, c in ipairs(disp:GetChildren()) do if c:IsA("ImageButton") then cnt = cnt + 1 end end
			local slot = cnt - 2
			if slot > 0 then pcall(function() REEquip:FireServer(slot) end); task.wait(0.5) end
		end
	end
	if RFCreateTranscendedStone then
		pcall(function() RFCreateTranscendedStone:InvokeServer() end)
	end
	return true
end

function elemProcessQuest()
	if not getRodUUID(169) then return false end  -- Need Ghostfinn Rod first
	if getRodUUID(257) then return false end       -- Already have Element Rod
	pcall(elemRefreshStep)
	if elemDone then return false end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	if not elemGUIReady or elemStep == 1 then
		hrp.CFrame = ELEM_CELLAR   -- Underground Cellar (start quest / have Ghostfinn)
		return true
	elseif elemStep == 2 then
		hrp.CFrame = ELEM_JUNGLE   -- Ancient Jungle (SECRET fish)
		return true
	elseif elemStep == 3 then
		if areAllTempleLeversComplete() then
			hrp.CFrame = ELEM_TEMPLE   -- Sacred Temple (SECRET fish)
		else
			processTempleLevers()
		end
		return true
	elseif elemStep == 4 then
		if _G.AutoCreateTranscendedStones then
			elemEquipAndCreateStone()  -- Create Transcended Stones
		end
	end
	return false
end

-- ── Diamond Researcher Quest ────────────────────────────────────────────────
local diamStep = nil
local diamDone = false
local diamGUIReady = false

local DIAM_CORAL  = CFrame.new(-3135.93872, 2.11425161, 2123.89819,
	0.997291982, -9.13398495e-08, 0.0735437796, 9.35643314e-08, 1,
	-2.68018781e-08, -0.0735437796, 3.36103732e-08, 0.997291982)
local DIAM_TROPIK = CFrame.new(-2093.49512, 6.26801682, 3699.17993,
	0.586044073, -4.36226735e-08, -0.810279191, -1.45249288e-08, 1,
	-6.43419256e-08, 0.810279191, 4.94764478e-08, 0.586044073)
local DIAM_LOCH   = CFrame.new(-617.281433, 3.30004835, 565.878357,
	0.876953125, -9.79836869e-08, 0.480575919, 5.34272928e-08, 1,
	1.06394126e-07, -0.480575919, -6.76267931e-08, 0.876953125)

function diamRefreshStep()
	local data = pcall(function() return getQuestData("Diamond Researcher") end) and getQuestData("Diamond Researcher")
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
	local inv = dataStore and dataStore:Get("Inventory")
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
	local ok, bp = pcall(function() return player.PlayerGui.Backpack end)
	if ok and bp then
		local disp = bp:FindFirstChild("Display")
		if disp then
			local cnt = 0
			for _, c in ipairs(disp:GetChildren()) do if c:IsA("ImageButton") then cnt = cnt + 1 end end
			local slot = cnt - 2
			if slot > 0 then pcall(function() REEquip:FireServer(slot) end); task.wait(0.5) end
		end
	end
	pcall(function() AutoEnabled:InvokeServer(false) end)
	if REDialogueEnded then pcall(function() REDialogueEnded:FireServer("Diamond Researcher", 2, dialogueArg) end) end
	task.wait(2)
end

function diamProcessQuest()
	if not getRodUUID(257) then return false end  -- Need Element Rod first
	pcall(diamRefreshStep)
	if diamDone then return false end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	if not diamGUIReady then diamActivateGUI(); return false end
	if diamStep == 2 then
		hrp.CFrame = DIAM_CORAL    -- Coral Reefs (SECRET fish)
		return true
	elseif diamStep == 3 then
		hrp.CFrame = DIAM_TROPIK   -- Tropical Grove (SECRET fish)
		return true
	elseif diamStep == 4 then
		local hasRuby, rubyUUID = diamHasItem(243, "Gemstone")
		if not hasRuby then
			hrp.CFrame = DIAM_TROPIK  -- Fish for Mutated Ruby
		else
			diamEquipItemAndGive(rubyUUID, 1)  -- Give Ruby to Lary
		end
		return true
	elseif diamStep == 5 then
		local hasLoch, lochUUID = diamHasItem(228)
		if not hasLoch then
			hrp.CFrame = DIAM_LOCH    -- Fish for Lochness Monster
		else
			diamEquipItemAndGive(lochUUID, 2)  -- Give Lochness to Lary
		end
		return true
	end
	return false
end

-- ── Continuous process loops ────────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(3)
		if _G.DeepSeaQuestMode or _G.AutoDeepSeaQuest then
			pcall(dsProcessQuest)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(3)
		if _G.ElementQuestMode or _G.AutoElementQuest then
			pcall(elemProcessQuest)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(3)
		if _G.DiamondQuestMode or _G.AutoDiamondQuest then
			pcall(diamProcessQuest)
		end
	end
end)

-- QUEST TAB: Section per quest + paragraph per quest
-- =============================================================================

task.spawn(function()
    while true do
        -- Guard nil (QuestTab paragraphs or progress helpers may not be ready yet)
        if deepSeaParagraph and elementParagraph and diamondParagraph and templeLeverParagraph
            and type(getGhostfinnProgress) == "function"
            and type(getElementProgress) == "function"
            and type(getDiamondProgress) == "function"
            and type(areAllTempleLeversComplete) == "function"
        then
            pcall(function()
                local gf = getGhostfinnProgress()
                if gf then deepSeaParagraph:SetDesc(table.concat(gf, "\n")) end

                local el = getElementProgress()
                if el then elementParagraph:SetDesc(table.concat(el, "\n")) end

                local dm = getDiamondProgress()
                if dm then diamondParagraph:SetDesc(table.concat(dm, "\n")) end

                refreshTempleLeverStatuses()
            end)
        end
        task.wait(2)
    end
end)

QuestTab:CreateSection({ Name = "Deep Sea Quest" })
deepSeaParagraph = QuestTab:CreateParagraph({
    Title = "Deep Sea Quest",
    Desc = "Loading...",
    RichText = true
})


QuestTab:CreateToggle({
    Name = "Auto Deep Sea Quest",
    Default = _G.AutoDeepSeaQuest or _G.DeepSeaQuestMode or false,
    Callback = function(state)
        _G.DeepSeaQuestMode = state
        _G.AutoDeepSeaQuest = state

        if state then
            pcall(function()
                if AutoEnabled then AutoEnabled:InvokeServer(true) end
            end)
            pcall(function()
                equipBestRodNowWithRetry(3, 0.3)
            end)
        end

        updateUIVisibility()

        if not state and not isAnyQuestActive() then
            pcall(function()
                if AutoEnabled then AutoEnabled:InvokeServer(false) end
                if Cancel then Cancel:InvokeServer() end
            end)
        end
    end
})

QuestTab:CreateSection({ Name = "Element Quest" })
elementParagraph = QuestTab:CreateParagraph({
    Title = "Element Quest",
    Desc = "Loading...",
    RichText = true
})

QuestTab:CreateToggle({
    Name = "Auto Element Quest",
    Default = _G.AutoElementQuest or _G.ElementQuestMode or false,
    Callback = function(state)
        _G.ElementQuestMode = state
        _G.AutoElementQuest = state

        if state then
            pcall(function()
                if AutoEnabled then AutoEnabled:InvokeServer(true) end
            end)
            pcall(function()
                if not equipGhostfinnRod() then
                    equipBestRodNowWithRetry(3, 0.3)
                end
            end)
        end

        updateUIVisibility()

        if not state and not isAnyQuestActive() then
            pcall(function()
                if AutoEnabled then AutoEnabled:InvokeServer(false) end
                if Cancel then Cancel:InvokeServer() end
            end)
        end
    end
})

QuestTab:CreateToggle({
    Name = "Auto Create Transcended Stones",
    Default = _G.AutoCreateTranscendedStones or false,
    Callback = function(state)
        _G.AutoCreateTranscendedStones = state
    end
})

QuestTab:CreateSection({ Name = "Diamond Researcher" })
diamondParagraph = QuestTab:CreateParagraph({
    Title = "Diamond Researcher",
    Desc = "Loading...",
    RichText = true
})


QuestTab:CreateToggle({
    Name = "Auto Diamond Quest",
    Default = _G.AutoDiamondQuest or _G.DiamondQuestMode or false,
    Callback = function(state)
        _G.DiamondQuestMode = state
        _G.AutoDiamondQuest = state

        if state then
            pcall(function()
                if AutoEnabled then AutoEnabled:InvokeServer(true) end
            end)
            pcall(function()
                equipBestRodNowWithRetry(3, 0.3)
            end)
        end

        updateUIVisibility()

        if not state and not isAnyQuestActive() then
            pcall(function()
                if AutoEnabled then AutoEnabled:InvokeServer(false) end
                if Cancel then Cancel:InvokeServer() end
            end)
        end
    end
})

QuestTab:CreateToggle({
    Name = "Pass All Quests",
    Default = false,
    Callback = function(state)
        if state then
            _G.DeepSeaQuestMode = true
            _G.ElementQuestMode = true
            _G.DiamondQuestMode = true
            _G.AutoDeepSeaQuest = true
            _G.AutoElementQuest = true
            _G.AutoDiamondQuest = true
            pcall(function()
                if AutoEnabled then AutoEnabled:InvokeServer(true) end
            end)
            pcall(function()
                if not equipGhostfinnRod() then
                    equipBestRodNowWithRetry(3, 0.3)
                end
            end)
        else
            _G.DeepSeaQuestMode = false
            _G.ElementQuestMode = false
            _G.DiamondQuestMode = false
            _G.AutoDeepSeaQuest = false
            _G.AutoElementQuest = false
            _G.AutoDiamondQuest = false
            pcall(function()
                if AutoEnabled then AutoEnabled:InvokeServer(false) end
                if Cancel then Cancel:InvokeServer() end
            end)
        end
        updateUIVisibility()
    end,
})

QuestTab:CreateSection({ Name = "Temple Lever" })
templeLeverParagraph = QuestTab:CreateParagraph({
    Title = "Temple Lever Status",
    Desc = "In Progress",
    RichText = true
})

QuestTab:CreateToggle({
    Name = "Auto Temple Lever",
    Default = false,
    Callback = function(state)
        _G.AutoTempleLever = state
        if templeLeverThread then task.cancel(templeLeverThread) end
        templeLeverThread = nil
        if not state then return end

        templeLeverThread = task.spawn(function()
            while _G.AutoTempleLever do
                pcall(function()
                    if not areAllTempleLeversComplete() then
                        processTempleLevers()
                    end
                end)
                task.wait(4)
            end
        end)
    end
})

-- =============================================================================
-- LOOPS: PERIODIC TELEPORT, ONE-CLICK FISHING, SELL, BUY RODS/BAITS, RESPAWN
-- (ported style from FishItONLY/old.lua)
-- =============================================================================

function teleportBasedOnCondition()
    local bestRod = getBestRod()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    -- Get Deep Sea Quest progress
    local ghostfinnData = getQuestData("Deep Sea Quest")
    local isDeepSeaComplete = ghostfinnData and ghostfinnData.allCompleted or false
    local isLabel1Done = ghostfinnData and ghostfinnData.objectives[1] and ghostfinnData.objectives[1].completed or false
    local isLabel2Done = ghostfinnData and ghostfinnData.objectives[2] and ghostfinnData.objectives[2].completed or false
    local isLabel3Done = ghostfinnData and ghostfinnData.objectives[3] and ghostfinnData.objectives[3].completed or false

    -- Get Element Quest progress
    local elementData = getQuestData("Element Quest")
    local isElementQuestDone = elementData and elementData.allCompleted or false

    -- Get Diamond Quest progress
    local diamondData = getQuestData("Diamond Researcher")
    local isDiamondComplete = diamondData and diamondData.allCompleted or false
    local isDiamondObj1Done = diamondData and diamondData.objectives[1] and diamondData.objectives[1].completed or false
    local isDiamondObj2Done = diamondData and diamondData.objectives[2] and diamondData.objectives[2].completed or false
    local isDiamondObj3Done = diamondData and diamondData.objectives[3] and diamondData.objectives[3].completed or false
    local isDiamondObj4Done = diamondData and diamondData.objectives[4] and diamondData.objectives[4].completed or false
    local isDiamondObj5Done = diamondData and diamondData.objectives[5] and diamondData.objectives[5].completed or false
    local isDiamondObj6Done = diamondData and diamondData.objectives[6] and diamondData.objectives[6].completed or false

    -- ⭐ CHECK IF RODS EXISTS
    local hasElementRod = getRodUUID(257) ~= nil
    local hasGhostfinnRod = getRodUUID(169) ~= nil

    if _G.DiamondQuestMode then
        if isDiamondComplete then
            Window:Notify({
                Title = "Quest Complete!",
                Content = "Diamond Quest has been completed!\nAuto-farm disabled.",
                Duration = 10
            })
            _G.DiamondQuestMode = false
            updateUIVisibility()
            hrp.CFrame = START_CFRAME
            return
        end

        if not isDiamondObj2Done then
            if hasAnyItemInInventory({ "Monster Shark", "Eerie Shark" }) then
                hrp.CFrame = DiamondQuest3and4Location
            else
                hrp.CFrame = DiamondQuest2Location
            end
            return
        end

        if not isDiamondObj3Done or not isDiamondObj4Done then
            if not isDiamondObj3Done then
                if hasItemInInventory("Great Whale") then
                    if hasItemInInventory("Ruby") then
                        hrp.CFrame = DiamondQuest5and6Location
                    else
                        hrp.CFrame = DiamondQuest3and4Location
                    end
                else
                    hrp.CFrame = DiamondQuest3and4Location
                end
                return
            end

            if not isDiamondObj4Done then
                if hasItemInInventory("Ruby") then
                    hrp.CFrame = DiamondQuest5and6Location
                else
                    hrp.CFrame = DiamondQuest3and4Location
                end
                return
            end

            return
        end

        if not isDiamondObj5Done or not isDiamondObj6Done then
            if isDiamondObj6Done and not isDiamondObj5Done then
                hrp.CFrame = DiamondQuest3and4Location
            elseif hasItemInInventory("Lochnes Monster") then
                hrp.CFrame = DiamondQuest3and4Location
            else
                hrp.CFrame = DiamondQuest5and6Location
            end
            return
        end

        hrp.CFrame = ElementRodLocation
        return
    end

    if _G.ElementQuestMode then
        if isElementQuestDone or hasElementRod then
            Window:Notify({
                Title = "Quest Complete!",
                Content = "Element Quest has been completed!\nElement Rod obtained.\nAuto-farm disabled.",
                Duration = 10
            })
            _G.ElementQuestMode = false
            updateUIVisibility()
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
                    while not areAllTempleLeversComplete() do
                        wait(5)
                    end
                    local c = player.Character
                    if c and c:FindFirstChild("HumanoidRootPart") then
                        c.HumanoidRootPart.CFrame = ElementRodLocation
                    end
                end)
            else
                hrp.CFrame = ElementRodLocation
            end
        else
            hrp.CFrame = TEMPLE_LEVER_BASE
        end

        return
    end

    if _G.DeepSeaQuestMode then
        if isDeepSeaComplete or hasGhostfinnRod then
            Window:Notify({
                Title = "Quest Complete!",
                Content = "Deep Sea Quest has been completed!\nGhostfinn Rod obtained.\nAuto-farm disabled.",
                Duration = 10
            })
            _G.DeepSeaQuestMode = false
            updateUIVisibility()
            hrp.CFrame = START_CFRAME
            return
        end

        -- Deep Sea Quest phase 2 (belum dapat Ghostfinn Rod)
        if not isLabel1Done and isLabel2Done and isLabel3Done and not hasGhostfinnRod then
            hrp.CFrame = GhostfinnPart2
            return
        end

        -- Deep Sea Quest awal
        if bestRod == "Astral Rod" or bestRod == "Midnight Rod" then
            hrp.CFrame = GhostfinnPart1
            return
        end
    end

    hrp.CFrame = START_CFRAME
end

function initialTeleport()
    if not _G.HasTeleported then
        _G.HasTeleported = true
        teleportBasedOnCondition(getBestRod())
        wait(2)
    end
end

-- Keep AutoEnabled alive while any quest mode is active.
-- This prevents server-side toggles from dropping during long quest runs.
spawn(function()
    while true do
        task.wait(2.5)
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            pcall(function()
                if AutoEnabled then AutoEnabled:InvokeServer(true) end
            end)
        end
    end
end)

spawn(function()
    while true do
        task.wait(0.1)
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            initialTeleport()
            local char = workspace:FindFirstChild("Characters"):FindFirstChild(player.Name)
            if char then
                repeat
                    task.wait(0.1)
                    if char:FindFirstChild("!!!FISHING_VIEW_MODEL!!!") then
                        pcall(function()
                            REEquip:FireServer(1)
                        end)
                    end
                    task.wait(0.1)
                    local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
                    if cosmeticFolder and not cosmeticFolder:FindFirstChild(tostring(player.UserId)) then
                        pcall(function()
                            FishingController:RequestChargeFishingRod(Vector2.new(0, 0), true)
                            task.wait(0.05)
                            local guid = FishingController.GetCurrentGUID and FishingController:GetCurrentGUID()
                            if not guid then
                                return
                            end
                            while (_G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode) and FishingController:GetCurrentGUID() == guid do
                                FishingController:FishingMinigameClick()
                                task.wait(math.random(1, 10) / 100)
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
            pcall(function()
                SellItem:InvokeServer()
            end)
        end
    end
end)

spawn(function()
    while true do
        task.wait(5)
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            local success, coins = pcall(function()
                return dataStore:Get("Coins")
            end)
            coins = (success and coins) or 0

            for name, rod in pairs(FishingRods) do
                local uuid = getRodUUID(rod.id)
                if not uuid and coins >= rod.price then
                    print("[DevHub] Buying " .. name .. " (Price: " .. rod.price .. ")")
                    local wasDeepSea = _G.DeepSeaQuestMode
                    local wasElement = _G.ElementQuestMode
                    local wasDiamond = _G.DiamondQuestMode

                    _G.DeepSeaQuestMode = false
                    _G.ElementQuestMode = false
                    _G.DiamondQuestMode = false
                    _G.HasTeleported = false

                    local char = workspace:FindFirstChild("Characters"):FindFirstChild(player.Name)
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then hum.Health = 0 end
                        task.wait(5)

                        pcall(function()
                            BuyRod:InvokeServer(rod.id)
                        end)

                        task.wait(0.5)
                        local newUUID = nil
                        local retryUntil = tick() + 5
                        while tick() < retryUntil do
                            newUUID = getRodUUID(rod.id)
                            if newUUID then break end
                            task.wait(0.5)
                        end
                        if newUUID then
                            pcall(function()
                                REEquipItem:FireServer(newUUID, "Fishing Rods")
                            end)
                            if equipTool then
                                pcall(function()
                                    equipTool:FireServer(1)
                                end)
                            end
                            print("[DevHub] " .. name .. " equipped!")
                        end

                        teleportBasedOnCondition(getBestRod())
                        task.wait(0.5)

                        _G.DeepSeaQuestMode = wasDeepSea
                        _G.ElementQuestMode = wasElement
                        _G.DiamondQuestMode = wasDiamond
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
            local coins = 0
            pcall(function()
                coins = dataStore:Get("Coins") or 0
            end)

            for baitId, bait in pairs(Baits) do
                if not hasBait(baitId) and coins >= bait.price then
                    print("[DevHub] Buying " .. bait.name .. "...")
                    local wasDeepSea = _G.DeepSeaQuestMode
                    local wasElement = _G.ElementQuestMode
                    local wasDiamond = _G.DiamondQuestMode

                    _G.DeepSeaQuestMode = false
                    _G.ElementQuestMode = false
                    _G.DiamondQuestMode = false
                    _G.HasTeleported = false

                    local char = workspace:FindFirstChild("Characters"):FindFirstChild(player.Name)
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then hum.Health = 0 end
                        task.wait(5)

                        buyBait(baitId)
                        task.wait(0.5)
                        equipBait(baitId)

                        teleportBasedOnCondition(getBestRod())
                        task.wait(0.5)

                        _G.DeepSeaQuestMode = wasDeepSea
                        _G.ElementQuestMode = wasElement
                        _G.DiamondQuestMode = wasDiamond
                        break
                    end
                end
            end
        end
    end
end)

-- Respawn/recovery hook detection removed (no auto-respawn based on hook time).

MainTab:CreateSection({ Name = "Blatant V1 (STABLE)" })

_G.BlatantMode = _G.BlatantMode or false

MainTab:CreateInput({
    Name = "Compleate Delay",
    SideLabel = "Compleate Delay",
    Default = tostring(Config.UB.Settings.CompleteDelay),
    Callback = function(text)
        local n = tonumber(text)
        if n and n > 0 then
            Config.UB.Settings.CompleteDelay = n
            Instant.SetCompleteDelay(n)
        end
    end,
})

MainTab:CreateToggle({
    Name = "Fast Reel",
    Default = _G.BlatantMode,
    Callback = function(state)
        if _G.BlatantMode == state then return end
        _G.BlatantMode = state
        needCast = true
        if state then
            Protected = false
            FishingSession = FishingSession + 1
        end
        onToggleUB(state)
        applyUltraBlatant3NFishingControllerStub(state)
    end,
})

svc = {
    Players = game:GetService("Players"),
    RS = game:GetService("ReplicatedStorage"),
}

player = svc.Players.LocalPlayer
if not player.Character then player.CharacterAdded:Wait() end

-- Net already initialized

EquipTool  = REEquip
ChargeRod  = ChargeRod
StartMini  = StartMini
CatchFish  = REFishDone
CancelFish = Cancel

Protected = false
FishingSession = 0

_G.AutoEquip = true
_G.Speed = 0.07       
_G.LoopDelay = 0.25   
_G.AmSpeed = _G.AmSpeed or _G.Speed
_G.AmLoopDelay = _G.AmLoopDelay or _G.LoopDelay

function ToggleBlatant(value)
    if value then
        Protected = true
        FishingSession = FishingSession + 1
        local session = FishingSession
        task.spawn(BlatantSkipCycle, session)
    else
        Protected = false
        FishingSession = FishingSession + 1
    end
end

function IsSessionAlive(session)
    return FishingSession == session
end

function BlatantSkipCycle(session)
    if _G.AutoEquip then
        pcall(function()
            EquipTool:FireServer(1)
        end)
        task.wait(0.25)
    end

    while Protected and IsSessionAlive(session) do
        local speed = (_G.Amblatant and _G.AmSpeed) or _G.Speed
        local loopDelay = (_G.Amblatant and _G.AmLoopDelay) or _G.LoopDelay

        t = workspace:GetServerTimeNow()
        pcall(function()
            ChargeRod:InvokeServer(t)
        end)
        task.wait(speed)
        pcall(function()
            StartMini:InvokeServer(-1, 1, t)
        end)

        task.wait(speed)
        CallFishDone(CatchFish, 1)

        -- Amblatant: spam local fish events using cached data (disalin dari blatant.lua)
        if _G.Amblatant and _G.SavedData and _G.SavedData.FishCaught and isCaught then
            task.spawn(function ()
                task.wait(0.3)
                for _ = 1, 2 do
                    local xremote = GetServerRemote("RE/FishCaught")
                    if xremote then
                        FireLocalEvent(xremote, unpack(_G.SavedData.FishCaught))
                    end
                    xremote = GetServerRemote("RE/CaughtFishVisual")
                    if xremote and _G.SavedData.CaughtVisual then
                        FireLocalEvent(xremote, unpack(_G.SavedData.CaughtVisual))
                    end
                    xremote = GetServerRemote("RE/ObtainedNewFishNotification")
                    if xremote and _G.SavedData.FishNotif then
                        FireLocalEvent(xremote, unpack(_G.SavedData.FishNotif))
                        task.spawn(function()
                            for _ = 1, 2 do
                                task.wait(2)
                                FireLocalEvent(xremote, unpack(_G.SavedData.FishNotif))
                            end
                        end)
                    end
                end
            end)
            isCaught = false
        end
        task.wait(loopDelay)
    end
end

AmblatantTab:CreateSection({ Name = "AMBLATANT OR FAST FISHING" })

AmblatantTab:CreateToggle({
    Name = "Amblatant YTTA",
    SubText = "KASIH TAU TALONNN",
    Default = _G.Amblatant,
    Callback = function(state)
        _G.Amblatant = state
        if state then
            saveCount = 0
            _resetNaturalHookCounts()
            _installFixedNaturalHook()
            HookRemote("RE/FishCaught", "FishCaught")
            HookRemote("RE/CaughtFishVisual", "CaughtVisual")
            HookRemote("RE/ObtainedNewFishNotification", "FishNotif")
        end
        -- Samakan perilaku dengan onToggleUB di blatant.lua: start/stop loop utama
        ToggleBlatant(state)
    end,
})

AmblatantTab:CreateInput({
    Name = "Amblatant Speed",
    SideLabel = "Delay (s)",
    Default = tostring(_G.AmSpeed),
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then
            _G.AmSpeed = n
        end
    end,
})

AmblatantTab:CreateInput({
    Name = "Amblatant Loop Delay",
    SideLabel = "Loop Delay (s)",
    Default = tostring(_G.AmLoopDelay),
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then
            _G.AmLoopDelay = n
        end
    end,
})


MainTab:CreateSection({ Name = "Recovery Fishing" })

MainTab:CreateButton({
	Name = "Recovery Fishing",
	SubText = "Fix stuck fishing & reset state",
	Callback = function()
		-- Notify start
		Window:Notify({
			Title = "Recovery Fishing",
			Content = "Attempting to recover fishing state...",
			Duration = 2
		})
		
		-- Step 1: Cancel any active fishing
		pcall(function() 
			if cancelinput then 
				cancelinput:InvokeServer() 
			end
		end)
		task.wait(0.1)
		
		-- Step 2: Force complete any stuck fishing
		pcall(function() 
			if fishingcomplete then 
				fishingcomplete:InvokeServer() 
			end
		end)
		task.wait(0.1)
		
		-- Step 3: Cancel again to ensure clean state
		pcall(function() 
			if cancelinput then 
				cancelinput:InvokeServer() 
			end
		end)
		task.wait(0.1)
		
		-- Step 4: Reset fishing state
		if st then
			st.canFish = true
		end
		
		-- Step 5: Re-equip rod if AutoRod is enabled
		if _G.AutoRod then
			pcall(function()
				if equipTool then
					equipTool:FireServer(1)
				end
			end)
		end
		
		-- Notify success
		Window:Notify({
			Title = "Recovery Complete",
			Content = "Fishing state has been reset!",
			Duration = 3
		})
	end
})

-- ============================================
-- [SECURITY] State Auto Sell (lokal)
-- ============================================
local autoSellEnabled = false
local autoSellMode = "Sell By Count"   -- "Sell By Count" atau "Sell All"
local autoSellValue = 0                -- batas count
local currentCount = 0

-- Dapatkan label BagSize
local label = LocalPlayer.PlayerGui.Inventory.Main.Top.Options.Fish.Label.BagSize

label:GetPropertyChangedSignal("ContentText"):Connect(function()
    local text = label.ContentText
    currentCount = tonumber(string.match(text, "^(%d+)")) or 0
end)

-- Sell remote (sudah local dari sebelumnya)
local sellAllItems = SellItem

local function SafeSell()
    pcall(function()
        sellAllItems:InvokeServer()
    end)
end

-- Loop hanya untuk mode "Sell By Count"
local function AutoSellLoop()
    while autoSellEnabled and autoSellMode == "Sell By Count" do
        if currentCount >= autoSellValue then
            SafeSell()
            task.wait(0.3)
        end
        task.wait(0.1)
    end
end

local function StartAutoSell()
    if autoSellEnabled then return end
    autoSellEnabled = true
    if autoSellMode == "Sell By Count" then
        task.spawn(AutoSellLoop)
    elseif autoSellMode == "Sell All" then
        -- Langsung jual semua sekali, lalu matikan toggle
        SafeSell()
        Window:Notify({
            Title = "Sell All",
            Content = "Sold all items!",
            Duration = 2
        })
        -- Matikan toggle (jika kita punya referensi toggle)
        if autoSellToggle then
            autoSellToggle:Set(false)  -- metode dari DevLib
        end
        autoSellEnabled = false
    end
end

local function StopAutoSell()
    autoSellEnabled = false
end

-- Referensi toggle (disimpan setelah CreateToggle)
local autoSellToggle

autoSellToggle = MainTab:CreateToggle({
    Name = "Auto Sell",
    Default = false,
    Callback = function(v)
        if v then
            StartAutoSell()
        else
            StopAutoSell()
        end
    end
})

MainTab:CreateDropdown({
    Name = "Auto Sell Mode",
    Items = { "Sell By Count", "Sell All" },
    Default = "Sell By Count",
    Callback = function(Option)
        autoSellMode = Option
    end,
})

MainTab:CreateInput({
    Name = "Sell Count Threshold",
    Placeholder = "Jual jika isi tas >= angka",
    Default = "",
    Callback = function(txt)
        autoSellValue = tonumber(txt) or 0
    end,
})


--------------------------------------------------------------------------------
-- SECTION 1: AUTO FAVORITE (NAME & RARITY ONLY)
--------------------------------------------------------------------------------
MainTab:CreateSection({ Name = "Auto Favorite", Icon = "rbxassetid://7733765398" })

local REFishCaught = RE.FishCaught or REFishGot
local REFishingCompleted = RE.FishingCompleted or REFishDone

if REFishCaught then
    REFishCaught.OnClientEvent:Connect(function()
        st.canFish = true
    end)
end

-- if REFishingCompleted then
--     REFishingCompleted.OnClientEvent:Connect(function()
--         st.canFish = true
--     end)
-- end

tierToRarity = {
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "SECRET",
    [8] = "Forgotten"
}

fishNames = {}
for _, module in ipairs(Items:GetChildren()) do
    if module:IsA("ModuleScript") then
        local ok, data = pcall(require, module)
        if ok and data.Data and data.Data.Type == "Fish" then
            table.insert(fishNames, data.Data.Name)
        end
    end
end
table.sort(fishNames)

-- Ensure RE (RemoteEvents table) is defined
local RE = {}
pcall(function()
    local Net = Net
    RE.FavoriteItem = REFav
    RE.FavoriteStateChanged = REFavChg
end)

local favState = {}
local selectedName = {}
local selectedRarity = {}
local selectedVariant = {}
local favoriteDebounce = {}

if RE.FavoriteStateChanged then
    RE.FavoriteStateChanged.OnClientEvent:Connect(function(uuid, fav)
        if uuid then favState[uuid] = fav end
    end)
end

-- Function for Name & Rarity only
function checkAndFavoriteBasic(item)
    -- Check if ANY auto-fav system is valid
    if not st.autoFavEnabled and not st.autoFavVariantEnabled then return end
    
    local info = ItemUtility.GetItemDataFromItemType("Items", item.Id)
    if not info or info.Data.Type ~= "Fish" then return end

    -- Validation Debounce (Prevent looping/spamming same item)
    if favoriteDebounce[item.UUID] and (tick() - favoriteDebounce[item.UUID] < 2) then
        return
    end

    local isFav = favState[item.UUID] or item.Favorited or false
    if isFav then return end -- Already favorited

    local shouldFav = false

    -- 1. Check Name & Rarity Logic
    if st.autoFavEnabled then
        local rarity = tierToRarity[info.Data.Tier]
        local nameMatches = (#selectedName > 0 and table.find(selectedName, info.Data.Name) ~= nil)
        local rarityMatches = (#selectedRarity > 0 and table.find(selectedRarity, rarity) ~= nil)
        
        if nameMatches or rarityMatches then
            shouldFav = true
        end
    end

    -- 2. Check Variant Logic
    if not shouldFav and st.autoFavVariantEnabled then
        local mutation = (item.Metadata and item.Metadata.VariantId and tostring(item.Metadata.VariantId)) or "None"
        if mutation ~= "None" and #selectedVariant > 0 then
             if table.find(selectedVariant, mutation) then
                 shouldFav = true
             end
        end
    end

    -- Final Decision
    if shouldFav then
        -- Get RemoteEvent reference
        local FavoriteEvent = RE.FavoriteItem
        if not FavoriteEvent and NetService then
            FavoriteEvent = REFav
        end

        if FavoriteEvent then
            local infoName = info.Data.Name or "Fish"
            local mutation = (item.Metadata and item.Metadata.VariantId and tostring(item.Metadata.VariantId)) or "None"
            print("[AutoFav] ✅ Favoriting:", infoName, "| Variant:", mutation)
            
            favoriteDebounce[item.UUID] = tick() -- Set debounce
            
            local success, err = pcall(function()
                FavoriteEvent:FireServer(item.UUID, true)
            end)
            
            if success then
                favState[item.UUID] = true
            else
                warn("[AutoFav] ❌ Failed:", err)
            end
        end
    end
end

function scanInventoryBasic()
    if not (st.autoFavEnabled or st.autoFavVariantEnabled) then return end
    -- print("[AutoFav] 🔍 Scanning Inventory...")
    print("[AutoFav Basic] Names:", #selectedName > 0 and table.concat(selectedName, ", ") or "NONE")
    print("[AutoFav Basic] Rarities:", #selectedRarity > 0 and table.concat(selectedRarity, ", ") or "NONE")
    
    local inv = Data:GetExpect({ "Inventory", "Items" })
    if not inv then 
        warn("[AutoFav Basic] ❌ Inventory not found!")
        return 
    end
    
    local count = 0
    for _, item in ipairs(inv) do 
        local before = favState[item.UUID] or item.Favorited or false
        checkAndFavoriteBasic(item)
        local after = favState[item.UUID] or false
        if not before and after then count = count + 1 end
        task.wait(0.05)
    end
    
    print("[AutoFav Basic] ✅ Favorited:", count)
end

Data:OnChange({ "Inventory", "Items" }, function()
    if st.autoFavEnabled or st.autoFavVariantEnabled then 
        task.wait(0.3)
        scanInventoryBasic() 
    end
end)

MainTab:CreateMultiDropdown({
    Name = "Favorite by Name",
    Items = #fishNames > 0 and fishNames or { "No Data" },
    Default = {},
    Callback = function(opts)
        selectedName = opts or {}
        print("[AutoFav Basic] 📝 Names:", #selectedName > 0 and table.concat(selectedName, ", ") or "NONE")
        if st.autoFavEnabled then
            task.wait(0.1)
            scanInventoryBasic()
        end
    end
})

MainTab:CreateMultiDropdown({
    Name = "Favorite by Rarity",
    Items = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "Forgotten" },
    Default = {},
    Callback = function(opts)
        selectedRarity = opts or {}
        print("[AutoFav Basic] ⭐ Rarities:", #selectedRarity > 0 and table.concat(selectedRarity, ", ") or "NONE")
        if st.autoFavEnabled then
            task.wait(0.1)
            scanInventoryBasic()
        end
    end
})

MainTab:CreateToggle({
    Name = "Start Auto Favorite",
    Default = false,
    Callback = function(state)
        st.autoFavEnabled = state
        print("[AutoFav Basic] 🔄", state and "ENABLED" or "DISABLED")
        if st.autoFavEnabled then
            task.wait(0.2)
            scanInventoryBasic()
        end
    end
})

MainTab:CreateButton({
    Name = "Unfavorite All",
    Icon = "rbxassetid://7733919427", 
    Callback = function()
        print("[AutoFav] ♻️ Unfavoriting all...")
        local inv = Data:GetExpect({ "Inventory", "Items" })
        if not inv then return end
        
        local count = 0
        for _, item in ipairs(inv) do
            if (item.Favorited or favState[item.UUID]) and RE.FavoriteItem then
                RE.FavoriteItem:FireServer(item.UUID, false)
                favState[item.UUID] = false
                count = count + 1
                task.wait(0.05)
            end
        end
        print("[AutoFav] ✅ Unfavorited", count, "items.")
    end
})

--------------------------------------------------------------------------------
-- SECTION 2: AUTO FAVORITE BY VARIANT
--------------------------------------------------------------------------------
MainTab:CreateSection({ Name = "Auto Favorite By Variant", Icon = "rbxassetid://7733917591" })

-- local selectedVariant = {} (Moved to top)

local variantList = {
    "Galaxy", "Corrupt", "Gemstone", "Fairy Dust", "Midnight",
    "Color Burn", "Holographic", "Lightning", "Radioactive",
    "Ghost", "Gold", "Frozen", "1x1x1x1", "Stone", "Sandy",
    "Noob", "Moon Fragment", "Festive", "Albino", "Arctic Frost", "Disco", "Big", "Giant", "Sparkling",
    "Crystalized"
}

MainTab:CreateMultiDropdown({
    Name = "Select Variants",
    Items = variantList,
    Default = {},
    Callback = function(opts)
        selectedVariant = opts or {}
        print("[AutoFav Variant] 🌟 Selected:", #selectedVariant > 0 and table.concat(selectedVariant, ", ") or "NONE")
    end
})

MainTab:CreateToggle({
    Name = "Auto Favorite Variants",
    Default = false,
    Callback = function(state)
        st.autoFavVariantEnabled = state
        print("[AutoFav Variant] 🔄", state and "ENABLED" or "DISABLED")
        
        if state then
            task.spawn(function()
                scanInventoryBasic()
            end)
        end
    end
})

MainTab:CreateButton({
    Name = "Check Variants in Inventory",
    Callback = function()
        local inv = Data:GetExpect({ "Inventory", "Items" })
        if not inv then 
            print("Inventory empty or not loaded.")
            return 
        end
        print("========================================")
        print("=== CHECKING VARIANTS IN INVENTORY ===")
        print("========================================")
        local found = false
        for _, item in ipairs(inv) do
            local mutation = (item.Metadata and item.Metadata.VariantId and tostring(item.Metadata.VariantId)) or "None"
            if mutation ~= "None" then
                local info = ItemUtility.GetItemDataFromItemType("Items", item.Id)
                local name = (info and info.Data.Name) or "Unknown"
                print("📦", name)
                print("   Variant:", mutation)
                print("   UUID:", item.UUID)
                print("   Favorited:", item.Favorited or false)
                found = true
            end
        end
        if not found then
            print("❌ No items with variants found.")
        end
        print("========================================")
    end
})

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
    
    local FishingAnims = {"ReelingIdle", "EquipIdleFake", "ReelStart", "ReelIntermission", "RodThrow", "FishCaught", "StartRodCharge", "LoopedRodCharge", "ReelingHold"}
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
        if success and track then
            LoadedTracks[cacheKey] = track
            return track
        end
        return nil
    end
    
     function ClearTracks()
        for _, track in pairs(LoadedTracks) do pcall(function() track:Stop() track:Destroy() end) end
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
    
     function Enable()
        if IsEnabled then return end
        IsEnabled = true
        SetupAnimator()
        LocalPlayer.CharacterAdded:Connect(function()
             task.wait(1)
             if IsEnabled then SetupAnimator() end
        end)
    end
    
     function Disable()
        IsEnabled = false
        if Connection then Connection:Disconnect() end
        ClearTracks()
    end
    
     function SelectSkin(name)
        CurrentSkin = name
        ClearTracks()
    end
    
     function GetSkins()
        local names = {}
        for name in pairs(SkinAnimations) do table.insert(names, name) end
        table.sort(names)
        return names
    end
    
    return { Enable = Enable, Disable = Disable, SelectSkin = SelectSkin, GetSkins = GetSkins }
end)()

MainTab:CreateSection({ Name = "Skin Animation", Icon = "rbxassetid://108886429866687" })

local skinList = SkinAnimation.GetSkins()
MainTab:CreateDropdown({
    Name = "Select Rod Skin",
    Items = skinList,
    Default = "None",
    Callback = function(val)
        SkinAnimation.SelectSkin(val)
    end
})

MainTab:CreateToggle({
    Name = "Enable Skin Changer",
    Default = false,
    Callback = function(state)
        if state then
            SkinAnimation.Enable()
        else
            SkinAnimation.Disable()
        end
    end
})


AutoTab:CreateSection({ Name = "Crystal" })
local AutoUseCaveCrystal = false

AutoTab:CreateToggle({
    Name = "Auto Use Cave Crystal",
    Default = false,
    Callback = function(state)
        AutoUseCaveCrystal = state
        if state then
            task.spawn(function()
                while AutoUseCaveCrystal do
                    local shouldUse = false
                    
                    local success, err = pcall(function()
                        local Player = game:GetService("Players").LocalPlayer
                        local PlayerGui = Player:WaitForChild("PlayerGui", 5)
                        local ActivePotions = PlayerGui and PlayerGui:FindFirstChild("Active Potions")
                        local Rows = ActivePotions and ActivePotions:FindFirstChild("Rows")
                        
                        local label = nil
                        
                        if Rows then
                            local children = Rows:GetChildren()
                            -- Logic: User asked to check the 3rd child specifically
                            if #children >= 3 then
                                local row = children[3]
                                label = row and row:FindFirstChild("Label")
                            end
                        end
                        
                        if label then
                            local text = label.Text
                            -- Robust Time Parser
                            local totalSeconds = 0
                            -- Remove spaces
                            text = string.gsub(text, "%s+", "")
                            
                            -- Try H:M:S first (e.g. 1:00:00)
                            local h, m, s = string.match(text, "^(%d+):(%d+):(%d+)$")
                            if h and m and s then
                                totalSeconds = (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s)
                            else
                                -- Try M:S (e.g. 123:23 or 5:00)
                                local m_only, s_only = string.match(text, "^(%d+):(%d+)$")
                                if m_only and s_only then
                                    totalSeconds = (tonumber(m_only) * 60) + tonumber(s_only)
                                end
                            end
                            
                            if totalSeconds > 0 then
                                print("[AutoCrystal] Row 3 Time:", text, "=", totalSeconds, "s")
                                if totalSeconds <= 180 then -- 180s = 3 mins
                                    shouldUse = true
                                end
                            else
                                -- Parse failed or 0? 
                                print("[AutoCrystal] Could not parse time from:", text)
                            end
                        else
                            -- Label or 3rd Row doesn't exist -> Use
                             shouldUse = true
                             print("[AutoCrystal] Row 3 / Label missing. Consuming.")
                        end
                    end)
                    
                    if shouldUse then
                         ConsumeCrystal:InvokeServer()
                         Window:Notify({
                            Title = "Crystal",
                            Content = "Consumed! (Time <= 3:00 or Not Active)",
                            Duration = 5
                        })
                        task.wait(10) -- Wait a bit to allow UI to update
                    end
                    
                    task.wait(2) -- Check every 2 seconds
                end
            end)
        end
    end
})

----------------------------------------------------------------
-- Auto Use Potion (ConsumePotion UUID)
-- =============================
AutoTab:CreateSection({ Name = "Auto Potion" })

 AutoPotionState = {
    enabled = false,
    selectedUuid = nil,
    uuidByLabel = {},
    useAmount = 1,
    delaySeconds = 8,
}
 autoPotionLoopGen = 0

 function buildPotionDropdownData()
    local labels = {}
    local uuidByLabel = {}
    local ok, inv = pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local Client = require(RS.Packages.Replion).Client
        local dataStore = Client:WaitReplion("Data")
        -- Changed to GetExpect({ "Inventory", "Items" }) for compatibility
        return dataStore:GetExpect({ "Inventory", "Items" })
    end)
    if not ok or not inv then
        return { "None" }, {}
    end

    local itemUtility = require(game:GetService("ReplicatedStorage").Shared.ItemUtility)

    for _, item in ipairs(inv) do
        local uid = item.UUID
        if uid and tostring(uid) ~= "" then
            local pdata = itemUtility and itemUtility:GetItemData(item.Id)
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
    if #labels == 0 then
        table.insert(labels, "None")
    end
    return labels, uuidByLabel
end

function consumeSelectedPotion()
    local uuid = AutoPotionState.selectedUuid
    if not uuid then
        Window:Notify({
            Title = "Potions",
            Content = "Select potion dulu dari dropdown",
            Duration = 3,
        })
        return
    end
    if not ConsumePotion then
        warn("[AutoPotion] RF/ConsumePotion not found in net map")
        return
    end

    local amount = math.max(1, math.floor(tonumber(AutoPotionState.useAmount) or 1))
    for _ = 1, amount do
        pcall(function()
            -- Using CallRemoteServer for safer execution
            CallRemoteServer(ConsumePotion, uuid, 1)
        end)
        task.wait(0.1)
    end
end

 autoPotionDropdown = AutoTab:CreateDropdown({
    Name = "Select potion (inventory)",
    Items = { "None" },
    Default = "None",
    Callback = function(value)
        if not value or value == "None" then
            AutoPotionState.selectedUuid = nil
        else
            AutoPotionState.selectedUuid = AutoPotionState.uuidByLabel[value]
        end
    end,
})

AutoTab:CreateInput({
    Name = "Use amount per cycle",
    PlaceholderText = "1",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local value = tonumber(text)
        if value and value >= 1 then
            AutoPotionState.useAmount = math.floor(value)
        end
    end,
})

AutoTab:CreateInput({
    Name = "Auto use delay (seconds)",
    PlaceholderText = "8",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local value = tonumber(text)
        if value and value > 0 then
            AutoPotionState.delaySeconds = value
        end
    end,
})

AutoTab:CreateButton({
    Name = "Refresh potion list",
    Callback = function()
        local prevUuid = AutoPotionState.selectedUuid
        local labels, map = buildPotionDropdownData()
        AutoPotionState.uuidByLabel = map
        autoPotionDropdown:Refresh(labels)
        local hasPrev = false
        if prevUuid then
            for _, uid in pairs(map) do
                if uid == prevUuid then
                    hasPrev = true
                    break
                end
            end
        end
        if hasPrev then
            AutoPotionState.selectedUuid = prevUuid
        elseif AutoPotionState.selectedUuid == nil then
            local first = labels[1]
            if first and first ~= "None" and map[first] then
                AutoPotionState.selectedUuid = map[first]
            else
                AutoPotionState.selectedUuid = nil
            end
        else
            AutoPotionState.selectedUuid = nil
        end
        Window:Notify({
            Title = "Potions",
            Content = (#labels > 0 and labels[1] ~= "None") and ("Loaded " .. #labels .. " stack(s)") or "No potions in inventory",
            Duration = 3,
        })
    end,
})

AutoTab:CreateButton({
    Name = "Use selected potion now",
    Callback = function()
        consumeSelectedPotion()
    end,
})

AutoTab:CreateToggle({
    Name = "Auto use selected potion",
    SubText = "Auto pakai potion sesuai amount + delay",
    Default = false,
    Callback = function(state)
        AutoPotionState.enabled = state
        if not state then
            return
        end
        autoPotionLoopGen += 1
        local gen = autoPotionLoopGen
        local prevUuid = AutoPotionState.selectedUuid
        local labels, map = buildPotionDropdownData()
        AutoPotionState.uuidByLabel = map
        autoPotionDropdown:Refresh(labels)
        local hasPrev = false
        if prevUuid then
            for _, uid in pairs(map) do
                if uid == prevUuid then
                    hasPrev = true
                    break
                end
            end
        end
        if hasPrev then
            AutoPotionState.selectedUuid = prevUuid
        elseif AutoPotionState.selectedUuid == nil and labels[1] and labels[1] ~= "None" then
            AutoPotionState.selectedUuid = map[labels[1]]
        end
        task.spawn(function()
            while AutoPotionState.enabled and gen == autoPotionLoopGen do
                consumeSelectedPotion()
                task.wait(AutoPotionState.delaySeconds)
            end
        end)
    end,
})

AutoTab:CreateSection({ Name = "Auto Crystal Depths" })

-- Function to detect pickaxe in inventory
-- Function to detect pickaxe in inventory
function HasPickaxe()
    -- Ensure Data is loaded (Replion)
    local RS = game:GetService("ReplicatedStorage")
    local Replion = require(RS.Packages.Replion)
    local DataClient = Replion.Client:WaitReplion("Data")
    local ItemUtility = require(RS.Shared.ItemUtility)
    
    if not DataClient then return false, nil end
    
    local inventory = DataClient:GetExpect({ "Inventory", "Items" })
    if not inventory then return false, nil end
    
    for _, item in pairs(inventory) do
        -- Method 1: ID Check
        local isIdMatch = (item.Id == 20220)
        
        -- Method 2: Name Check
        local isNameMatch = false
        if ItemUtility then
             local info = ItemUtility:GetItemData(item.Id)
             if info and info.Data and info.Data.Name and string.find(string.lower(info.Data.Name), "pickaxe") then
                 isNameMatch = true
             end
        end
        
        if isIdMatch or isNameMatch then
            return true, item.UUID
        end
    end
    
    return false, nil
end

-- Function to equip pickaxe
function EquipPickaxe(uuid)
    local Player = game:GetService("Players").LocalPlayer
    local EquipItem = REEquipItem
    if not uuid then
        warn("[EquipPickaxe] UUID nil")
        return false
    end
    if not EquipItem then
        warn("[EquipPickaxe] RE/EquipItem missing")
        return false
    end

    function isPickaxeTool(tool)
        if not tool or not tool:IsA("Tool") then return false end
        if tool.Name == "20220" or string.find(string.lower(tool.Name), "pickaxe") then
            return true
        end
        local attrUuid = tool:GetAttribute("UUID")
        return attrUuid and tostring(attrUuid) == tostring(uuid)
    end

    function getEquippedTool()
        local char = Player.Character
        if not char then return nil end
        for _, obj in ipairs(char:GetChildren()) do
            if isPickaxeTool(obj) then
                return obj
            end
        end
        return nil
    end

    function getBackpackTool()
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return nil end
        for _, obj in ipairs(backpack:GetChildren()) do
            if isPickaxeTool(obj) then
                return obj
            end
        end
        return nil
    end

    if getEquippedTool() then
        return true
    end

    -- Follow moons.lua style: equip by UUID via RE/EquipItem with retries.
    for i = 1, 3 do
        pcall(function()
            EquipItem:FireServer(uuid, "Gears")
        end)
        task.wait(i == 1 and 0.5 or 0.35)

        if getEquippedTool() then
            return true
        end

        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local bpTool = getBackpackTool()
        if hum and bpTool then
            pcall(function()
                hum:EquipTool(bpTool)
            end)
            task.wait(0.15)
            if getEquippedTool() then
                return true
            end
        end
        task.wait(0.15)
    end

    return getEquippedTool() ~= nil
end

AutoTab:CreateToggle({
    Name = "Auto Crystal Depths",
    Default = false,
    Callback = function(state)
        _G.AutoCrystal = state
        if not state then return end
        
        task.spawn(function()
            local Player = game:GetService("Players").LocalPlayer
            local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not Root then return end
            
            local StartCFrame = Root.CFrame
            local hasActionTaken = false 
            
            while _G.AutoCrystal do
                local Islands = workspace:FindFirstChild("Islands")
                local Depths = Islands and Islands:FindFirstChild("Crystal Depths")
                local CrystalsFolder = Depths and Depths:FindFirstChild("Crystals")
                
                if not CrystalsFolder then 
                    task.wait(1)
                    continue 
                end
                
                local hasPickaxe, pickaxeUUID = HasPickaxe()
                local foundAny = false
                local validCrystals = {}

                -- First pass: find all valid crystals/items with enabled prompts
                for _, crystal in ipairs(CrystalsFolder:GetChildren()) do
                    local targetPart = crystal:IsA("BasePart") and crystal or crystal:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        local prompt = crystal:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            local isPickaxeModel = (crystal.Name == "20220" or string.find(string.lower(crystal.Name), "pickaxe"))
                            if isPickaxeModel and hasPickaxe then
                                continue
                            end
                            table.insert(validCrystals, {part = targetPart, prompt = prompt})
                        end
                    end
                end

                if #validCrystals > 0 then
                    foundAny = true
                    hasActionTaken = true

                    for _, data in ipairs(validCrystals) do
                        if not _G.AutoCrystal then break end
                        
                        -- EQUIP PICKAXE CHECK
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
                        fireproximityprompt(data.prompt)
                        task.wait(0.8)
                    end
                end
                
                if not foundAny then
                    -- If we moved/farmed, go back to start
                    if hasActionTaken then
                        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                            Player.Character.HumanoidRootPart.CFrame = StartCFrame
                        end
                        -- hasActionTaken = false -- MOVED TO BOTTOM for Recovery Fishing check
                        task.wait(0.5)
                    end
                    
                    -- ALWAYS Equip Rod (Slot 1) if no crystals found (Idle/Done)
                    local EquipHotbar = REEquip
                    
                    -- 1. Server Equip (Hotbar Slot 1)
                    if EquipHotbar then
                        pcall(function() 
                            EquipHotbar:FireServer(1) 
                        end)
                    elseif EquipTool then
                        pcall(function() EquipTool:InvokeServer(1) end)
                    end
                    
                    -- 2. Client Force Hold (Visual)
                    task.wait(0.3)
                    if Player.Character then
                        local Humanoid = Player.Character:FindFirstChild("Humanoid")
                        local Backpack = Player.Backpack
                        if Humanoid and Backpack then
                            -- Check if already holding a rod
                            local cur = Player.Character:FindFirstChildWhichIsA("Tool")
                            local holdingRod = cur and string.find(cur.Name, "Rod")
                            
                            if not holdingRod then
                                -- Find Rod in Backpack
                                for _, t in ipairs(Backpack:GetChildren()) do
                                    if t:IsA("Tool") and string.find(t.Name, "Rod") then
                                        Humanoid:EquipTool(t)
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    -- 3. Recovery Fishing (Start Casting) if we just returned
                    if hasActionTaken then
                         task.wait(1.0) -- Wait for equip animation
                         local ChargeRod = ChargeRod
                         if ChargeRod then
                              pcall(function()
                                  ChargeRod:InvokeServer(100)
                              end)
                         end
                         hasActionTaken = false -- Reset state after recovery
                    end
                    
                    task.wait(2)
                else
                    task.wait(0.5)
                end
            end
        end)
    end
})

AutoTab:CreateButton({
    Name = "Test Equip Pickaxe",
    Callback = function()
        local has, uuid = HasPickaxe()
        if has then
            print("[Test Equip] Found Pickaxe UUID:", uuid)
            local success = EquipPickaxe(uuid)
            if success then
                Window:Notify({
                    Title = "Equip Test",
                    Content = "Sent Equip Request!",
                    Duration = 2
                })
            else
                Window:Notify({
                    Title = "Equip Test",
                    Content = "Failed to access Remote",
                    Duration = 2
                })
            end
        else
            Window:Notify({
                Title = "Equip Test",
                Content = "No Pickaxe Found (ID 20220)",
                Duration = 2
            })
        end
    end
})


AutoTab:CreateSection({ Name = "Auto Cave", Icon = "rbxassetid://7733799901" })

AutoTab:CreateToggle({
	Name = "Auto Open Mysterious Cave Wall",
	Default = false,
	Callback = function(state)
        if state then
            spawn(function()
                -- Fire TNT event 4 times
                for i = 1, 4 do
                    local args = {
                        "TNT"
                    }
                    pcall(function()
                        SearchPickup:FireServer(unpack(args))
                    end)
                    task.wait(0.5)
                end
                
                -- Wait a bit then fire GainAccessToMaze
                task.wait(1)
                pcall(function()
                    GainMaze:FireServer()
                end)
                
                Window:Notify({
                    Title = "Cave Wall Opened! 🚪",
                    Content = "Mysterious Cave Wall has been opened!",
                    Duration = 5
                })
            end)
        end
    end
})

AutoTab:CreateToggle({
	Name = "Auto Open Pirate Chest",
	Default = false,
	Callback = function(state)
        _G.AutoOpenPirateChest = state
        
        if state then
            spawn(function()
                while _G.AutoOpenPirateChest do
                    pcall(function()
                        -- Get the remote event
                        local RE = PirateChest
                        
                        -- Find all pirate chests in PirateChestStorage
                        local chestsFound = 0
                        local pirateChestStorage = workspace:FindFirstChild("PirateChestStorage")
                        
                        if pirateChestStorage then
                            -- Get all children from PirateChestStorage
                            for _, chest in ipairs(pirateChestStorage:GetChildren()) do
                                -- Check if the chest name is a UUID format
                                local chestId = chest.Name
                                
                                if chestId:match("%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") then
                                    local args = { chestId }
                                    RE:FireServer(unpack(args))
                                    chestsFound = chestsFound + 1
                                    print("[DevHub] Claiming chest: " .. chestId)
                                    task.wait(0.3)
                                end
                            end
                            
                            if chestsFound > 0 then
                                print("[DevHub] Successfully claimed " .. chestsFound .. " pirate chests!")
                            else
                                print("[DevHub] No pirate chests found in PirateChestStorage")
                            end
                        else
                            print("[DevHub] PirateChestStorage not found in workspace")
                        end
                    end)
                    task.wait(2) -- Wait 2 seconds before scanning again
                end
            end)
            
            Window:Notify({
                Title = "Auto Pirate Chest ON! 🏴‍☠️",
                Content = "Auto claiming pirate chests enabled!",
                Duration = 4
            })
        else
            _G.AutoOpenPirateChest = false
            Window:Notify({
                Title = "Auto Pirate Chest OFF!",
                Content = "Auto claiming pirate chests disabled.",
                Duration = 3
            })
        end
    end
})


local function LoadStoneAndEnchantData()
    -- Reset
    STONE_IDS = {}
    STONE_NAMES = {}
    ENCHANT_ID_MAP = {}
    BASIC_ENCHANT_NAMES = {}
    EVOLVED_ENCHANT_NAMES = {}

    -- 1. Coba baca semua modul stone dari folder game
    local stoneFolder = ReplicatedStorage:FindFirstChild("Items")
    if stoneFolder then
        stoneFolder = stoneFolder:FindFirstChild("EnchantStones") or stoneFolder:FindFirstChild("EnchantStone")
    end
    -- Alternatif: bisa juga ReplicatedStorage.EnchantStones langsung
    if not stoneFolder then
        stoneFolder = ReplicatedStorage:FindFirstChild("EnchantStones")
    end

    if stoneFolder then
        for _, moduleScript in ipairs(stoneFolder:GetChildren()) do
            if moduleScript:IsA("ModuleScript") then
                local ok, data = pcall(require, moduleScript)
                if ok and type(data) == "table" and data.Data then
                    local name = data.Data.Name
                    local id = data.Data.Id
                    if name and id then
                        STONE_IDS[name] = id
                        table.insert(STONE_NAMES, name)

                        -- Ambil daftar enchant dari tabel 'Enchants' (jika ada)
                        if data.Enchants and type(data.Enchants) == "table" then
                            for enchantName, _ in pairs(data.Enchants) do
                                -- Hanya tambahkan jika belum ada di ENCHANT_ID_MAP
                                if not ENCHANT_ID_MAP[enchantName] then
                                    -- Coba dapatkan enchant ID dari ItemUtility
                                    local enchantId = nil
                                    pcall(function()
                                        local edata = ItemUtility:GetEnchantData(enchantName)
                                        if edata and edata.Data and edata.Data.Id then
                                            enchantId = edata.Data.Id
                                        end
                                    end)
                                    if enchantId then
                                        ENCHANT_ID_MAP[enchantName] = enchantId
                                    else
                                        -- Fallback: gunakan ID dari hardcode lama (jika ada)
                                        -- (hardcode lama akan diisi setelah blok ini)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 2. Fallback stone (jika belum ada)
    if not next(STONE_IDS) then
        STONE_IDS = {
            ["Enchant Stones"] = 10,
            ["Evolved Enchant Stone"] = 558,
            ["Runic Enchant Stone"] = 929   -- tambahan langsung
        }
        STONE_NAMES = {"Enchant Stones", "Evolved Enchant Stone", "Runic Enchant Stone"}
    else
        table.sort(STONE_NAMES)
        -- Pastikan setidaknya ada default yang kamu sebutkan (jika tidak terbaca)
        if not STONE_IDS["Runic Enchant Stone"] then
            STONE_IDS["Runic Enchant Stone"] = 929
            table.insert(STONE_NAMES, "Runic Enchant Stone")
            table.sort(STONE_NAMES)
        end
    end

    -- 3. Fallback enchant ID map (diisi dari hardcode lama, tapi hanya untuk enchant yang belum terisi)
    local hardcodedEnchants = {
        ["Big Hunter 1"] = 3,
        ["Cursed 1"] = 12,
        ["Empowered 1"] = 9,
        ["Glistening 1"] = 1,
        ["Gold Digger 1"] = 4,
        ["Leprechaun 1"] = 5,
        ["Leprechaun 2"] = 6,
        ["Mutation Hunter 1"] = 7,
        ["Mutation Hunter 2"] = 14,
        ["Prismatic 1"] = 13,
        ["Reeler 1"] = 2,
        ["Stargazer 1"] = 8,
        ["Stormhunter 1"] = 11,
        ["XPerienced 1"] = 10,
        ["SECRET Hunter"] = 16,
        ["Shark Hunter"] = 20,
        ["Shark Hunter I"] = 20,  -- mungkin sama
        ["Shark Hunter II"] = 20, -- mungkin beda, tapi kita samakan dulu
        ["Stargazer II"] = 17,
        ["Stormhunter II"] = 19,
        ["Mutation Hunter II"] = 14,
        ["Leprechaun II"] = 6,
        ["Reeler II"] = 21,
        ["Mutation Hunter III"] = 22,
        ["Fairy Hunter 1"] = 15,
        ["Glistening II"] = 1,    -- sesuaikan jika diperlukan
        ["XPerienced II"] = 10,
        ["Empowered II"] = 9,
        ["Cursed II"] = 12,
        ["FORGOTTEN Hunter"] = 23, -- id asumsi, cek nanti
    }

    for name, id in pairs(hardcodedEnchants) do
        if not ENCHANT_ID_MAP[name] then
            ENCHANT_ID_MAP[name] = id
        end
    end

    -- 4. Pisahkan basic vs evolved (kriteria: nama mengandung " 1" atau tier 1, atau tidak mengandung "II", "III", "SECRET", dll.)
    -- Untuk sementara, gunakan aturan sederhana: jika ada "II" atau "III" atau "SECRET" atau "FORGOTTEN" atau "Shark" -> evolved, selain itu basic.
    BASIC_ENCHANT_NAMES = {}
    EVOLVED_ENCHANT_NAMES = {}
    for name, _ in pairs(ENCHANT_ID_MAP) do
        if name:match("II") or name:match("III") or name:find("SECRET") or name:find("FORGOTTEN") or name:find("Shark") then
            table.insert(EVOLVED_ENCHANT_NAMES, name)
        else
            table.insert(BASIC_ENCHANT_NAMES, name)
        end
    end
    table.sort(BASIC_ENCHANT_NAMES)
    table.sort(EVOLVED_ENCHANT_NAMES)

    -- Pastikan SelectedStoneType dan target enchant tidak hilang
    if not STONE_IDS[SelectedStoneType] then
        SelectedStoneType = STONE_NAMES[1] or "Enchant Stones"
    end
    if not ENCHANT_ID_MAP[TargetEnchantBasic] then
        TargetEnchantBasic = BASIC_ENCHANT_NAMES[1]
    end
    if not ENCHANT_ID_MAP[TargetEnchantEvolved] then
        TargetEnchantEvolved = EVOLVED_ENCHANT_NAMES[1]
    end
end
------------------ Player Tab ------------------
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

PlayerTab:CreateInput({
	Name = "Walk Speed",
	SideLabel = "Contoh: 18",
	Placeholder = "Enter Speed...",
	Default = "",
	Callback = function(value)
        local hum = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = tonumber(value) or 18
        end
    end
})

PlayerTab:CreateInput({
	Name = "Jump Power",
	SideLabel = "Contoh: 50",
	Placeholder = "Enter Power...",
	Default = "",
	Callback = function(Text)
		local hum = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum.JumpPower = tonumber(value) or 50
        end
    end
})

local UserInputService = game:GetService("UserInputService")

PlayerTab:CreateToggle({
	Name = "Infinite Jump",
	Default = false,
 Callback = function(Value)
        _G.InfiniteJump = Value
        if Value then
            print("✅ Infinite Jump Active")
            InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
                if _G.InfiniteJump then
                    local character = Player.Character or Player.CharacterAdded:Wait()
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        else
            print("❌ Infinite Jump Inactive")
            end
        end
})

PlayerTab:CreateToggle({
	Name = "Noclip",
	Default = false,
	 Callback = function(state)
        _G.Noclip = state
        task.spawn(function()
            local Player = game:GetService("Players").LocalPlayer
            while _G.Noclip do
                task.wait(0.1)
                if Player.Character then
                    for _, part in pairs(Player.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide == true then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
    end
})

PlayerTab:CreateToggle({
	Name = "Radar",
	Default = false,
	   Callback = function(state)
        local Lighting = game:GetService("Lighting")
        local Replion = require(ReplicatedStorage.Packages.Replion).Client:GetReplion("Data")
        local NetFunction = UpdateRadar

        if Replion and NetFunction:InvokeServer(state) then
            local sound = require(ReplicatedStorage.Shared.Soundbook).Sounds.RadarToggle:Play()
            sound.PlaybackSpeed = 1 + math.random() * 0.3

            local c = Lighting:FindFirstChildWhichIsA("ColorCorrectionEffect")
            if c then
                require(ReplicatedStorage.Packages.spr).stop(c)

                local time = require(ReplicatedStorage.Controllers.ClientTimeController)
                local profile = time._getLightingProfile and time:_getLightingProfile() or {}
                local correction = profile.ColorCorrection or {}
                correction.Brightness = correction.Brightness or 0.04
                correction.TintColor = correction.TintColor or Color3.fromRGB(255,255,255)

                if state then
                    c.TintColor = Color3.fromRGB(42, 226, 118)
                    c.Brightness = 0.4
                else
                    c.TintColor = Color3.fromRGB(255, 0, 0)
                    c.Brightness = 0.2
                end

                require(ReplicatedStorage.Packages.spr).target(c, 1, 1, correction)
            end

            require(ReplicatedStorage.Packages.spr).stop(Lighting)
            Lighting.ExposureCompensation = 1
            require(ReplicatedStorage.Packages.spr).target(Lighting, 1, 2, {ExposureCompensation = 0})
        end
    end
})

PlayerTab:CreateToggle({
	Name = "Diving Gear",
	Default = false,
	 Callback = function(state)
        _G.DivingGear = state
        local RemoteFolder = Net
        if state then
            EquipOxygen:InvokeServer(105)
        else
            UnequipOxygen:InvokeServer()
        end
    end
})

PlayerTab:CreateButton({
	Name = "FlyGui V3",
	Icon = "rbxassetid://7733920644",
	 Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
        Notify("Fly GUI Activated")
    end
})

ShopTab:CreateSection({ Name = "Booster Luck" })

ReplicatedStorage = game:GetService("ReplicatedStorage")
GiftingController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("GiftingController"))

local luckBoosters = {
    "x2 Luck",
    "x4 Luck",
    "x8 Luck"
}

selectedLuckBooster = luckBoosters[1]

ShopTab:CreateDropdown({
	Name = "Select Luck Booster",
	Items = luckBoosters,
	Value = selectedLuckBooster,
	Callback = function(value)
		selectedLuckBooster = value
	end
})

ShopTab:CreateButton({
	Name = "Buy Luck Booster",
	Icon = "rbxassetid://7733920644",
	Callback = function()
		local success, err = pcall(function()
			GiftingController:Open(selectedLuckBooster)
		end)
		if success then
			Window:Notify({Title = "Luck Booster", Content = "Purchased " .. selectedLuckBooster .. "!", Duration = 3})
		else
			Window:Notify({Title = "Purchase Error", Content = tostring(err), Duration = 5})
		end
	end
})

ShopTab:CreateSection({ Name = "Skin Rod" })

rodSkins = {
    "Frozen Krampus Scythe",
    "Gingerbread Katana",
    "Christmas Parasol"
}

selectedRodSkin = rodSkins[1]

ShopTab:CreateDropdown({
	Name = "Select Rod Skin",
	Items = rodSkins,
	Value = selectedRodSkin,
	Callback = function(value)
		selectedRodSkin = value
	end
})

ShopTab:CreateButton({
	Name = "Buy Rod Skin",
	Icon = "rbxassetid://7733920644",
	Callback = function()
		local success, err = pcall(function()
			GiftingController:Open(selectedRodSkin)
		end)
		if success then
			Window:Notify({Title = "Rod Skin", Content = "Purchased " .. selectedRodSkin .. "!", Duration = 3})
		else
			Window:Notify({Title = "Purchase Error", Content = tostring(err), Duration = 5})
		end
	end
})

ShopTab:CreateSection({ Name = "Buy Rod" })

ReplicatedStorage = game:GetService("ReplicatedStorage")  
RFPurchaseFishingRod = BuyRod  

local rods = {  
    ["Luck Rod"] = 79,  
    ["Carbon Rod"] = 76,  
    ["Grass Rod"] = 85,
    ["Demascus Rod"] = 77,  
    ["Ice Rod"] = 78,  
    ["Lucky Rod"] = 4,  
    ["Midnight Rod"] = 80,  
    ["Steampunk Rod"] = 6,  
    ["Chrome Rod"] = 7,  
    ["Astral Rod"] = 5,  
    ["Ares Rod"] = 126,  
    ["Angler Rod"] = 168,
    ["Bamboo Rod"] = 258
}  

local rodNames = {  
    "Luck Rod (350 Coins)", "Carbon Rod (900 Coins)", "Grass Rod (1.5k Coins)", "Demascus Rod (3k Coins)",  
    "Ice Rod (5k Coins)", "Lucky Rod (15k Coins)", "Midnight Rod (50k Coins)", "Steampunk Rod (215k Coins)",  
    "Chrome Rod (437k Coins)", "Astral Rod (1M Coins)", "Ares Rod (3M Coins)", "Angler Rod (8M Coins)",
    "Bamboo Rod (12M Coins)"
}  

local rodKeyMap = {  
    ["Luck Rod (350 Coins)"]="Luck Rod",  
    ["Carbon Rod (900 Coins)"]="Carbon Rod",  
    ["Grass Rod (1.5k Coins)"]="Grass Rod",  
    ["Demascus Rod (3k Coins)"]="Demascus Rod",  
    ["Ice Rod (5k Coins)"]="Ice Rod",  
    ["Lucky Rod (15k Coins)"]="Lucky Rod",  
    ["Midnight Rod (50k Coins)"]="Midnight Rod",  
    ["Steampunk Rod (215k Coins)"]="Steampunk Rod",  
    ["Chrome Rod (437k Coins)"]="Chrome Rod",  
    ["Astral Rod (1M Coins)"]="Astral Rod",  
    ["Ares Rod (3M Coins)"]="Ares Rod",  
    ["Angler Rod (8M Coins)"]="Angler Rod",
    ["Bamboo Rod (12M Coins)"]="Bamboo Rod"
}  

local selectedRod = rodNames[1]  

ShopTab:CreateDropdown({
	Name = "Select Rod",
	  Items = rodNames,  
    Value = selectedRod,  
    Callback = function(value)  
        selectedRod = value  
    end  
})  


ShopTab:CreateButton({
	Name = "Buy Rod",
	Icon = "rbxassetid://7733920644",
	 Callback=function()  
        local key = rodKeyMap[selectedRod]  
        if key and rods[key] then  
            local success, err = pcall(function()  
                RFPurchaseFishingRod:InvokeServer(rods[key])  
            end)  
            if success then  
                Window:Notify({Title="Rod Purchase", Content="Purchased "..selectedRod, Duration=3})  
            else  
                Window:Notify({Title="Rod Purchase Error", Content=tostring(err), Duration=5})  
            end  
        end  
    end  
})

ShopTab:CreateSection({ Name = "Buy Baits" })

local ReplicatedStorage = game:GetService("ReplicatedStorage")  
local RFPurchaseBait = BuyBait  

local baits = {
    ["TopWater Bait"] = 10,
    ["Lucky Bait"] = 2,
    ["Midnight Bait"] = 3,
    ["Chroma Bait"] = 6,
    ["Dark Mater Bait"] = 8,
    ["Corrupt Bait"] = 15,
    ["Aether Bait"] = 16
}

local baitNames = {
    "TopWater Bait (100 Coins)",
    "Lucky Bait (1k Coins)",
    "Midnight Bait (3k Coins)",
    "Chroma Bait (290k Coins)",
    "Dark Mater Bait (630k Coins)",
    "Corrupt Bait (1.15M Coins)",
    "Aether Bait (3.7M Coins)"
}

local baitKeyMap = {
    ["TopWater Bait (100 Coins)"] = "TopWater Bait",
    ["Lucky Bait (1k Coins)"] = "Lucky Bait",
    ["Midnight Bait (3k Coins)"] = "Midnight Bait",
    ["Chroma Bait (290k Coins)"] = "Chroma Bait",
    ["Dark Mater Bait (630k Coins)"] = "Dark Mater Bait",
    ["Corrupt Bait (1.15M Coins)"] = "Corrupt Bait",
    ["Aether Bait (3.7M Coins)"] = "Aether Bait"
}

local selectedBait = baitNames[1]  

ShopTab:CreateDropdown({
	Name = "Select Bait",
	 Items = baitNames,  
    Value = selectedBait,  
    Callback = function(value)  
        selectedBait = value  
    end  
})  

ShopTab:CreateButton({
	Name = "Buy Bait",
	Icon = "rbxassetid://7733920644",
 Callback = function()  
        local key = baitKeyMap[selectedBait]  
        if key and baits[key] then  
            local success, err = pcall(function()  
                RFPurchaseBait:InvokeServer(baits[key])  
            end)  
            if success then  
                Window:Notify({Title = "Bait Purchase", Content = "Purchased " .. selectedBait, Duration = 3})  
            else  
                Window:Notify({Title = "Bait Purchase Error", Content = tostring(err), Duration = 5})  
            end  
        end  
    end  
})


ShopTab:CreateSection({ Name = "Buy Weather Event", Icon = "rbxassetid://7733955511" })

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RFPurchaseWeatherEvent = BuyWeather

-- Data cuaca
local weathers = {
    ["Wind"] = "Wind",
    ["Cloudy"] = "Cloudy",
    ["Snow"] = "Snow",
    ["Storm"] = "Storm",
    ["Radiant"] = "Radiant",
    ["Shark Hunt"] = "Shark Hunt"
}

-- Nama tampilan
local weatherNames = {
    "Windy (10k Coins)",
    "Cloudy (20k Coins)",
    "Snow (15k Coins)",
    "Stormy (35k Coins)",
    "Radiant (50k Coins)",
    "Shark Hunt (300k Coins)"
}

-- Mapping nama → key internal
local weatherKeyMap = {
    ["Windy (10k Coins)"] = "Wind",
    ["Cloudy (20k Coins)"] = "Cloudy",
    ["Snow (15k Coins)"] = "Snow",
    ["Stormy (35k Coins)"] = "Storm",
    ["Radiant (50k Coins)"] = "Radiant",
    ["Shark Hunt (300k Coins)"] = "Shark Hunt"
}

local selectedWeathers = {}
local autoBuyRunning = false

ShopTab:CreateMultiDropdown({
	Name = "Select Weather Events",
	Items = weatherNames,
    Default = selectedWeathers,
    Callback = function(values)
        selectedWeathers = values
        print("Selected:", table.concat(values, ", "))
    end
})


ShopTab:CreateToggle({
	Name = "Auto Buy Selected Weathers",
	SubText = "Continuously purchase all selected weather events while ON",
	Default = false,
 Callback = function(state)
        autoBuyRunning = state

        if state then
            if #selectedWeathers == 0 then
                Window:Notify({
                    Title = "⚠️ No Selection",
                    Content = "Please select at least one weather event before enabling.",
                    Duration = 3
                })
                autoBuyRunning = false
                return
            end

            Window:Notify({
                Title = "🌤️ Auto Buy Enabled",
                Content = "Auto-purchase started. It will keep buying until turned off.",
                Duration = 3
            })

            -- Jalankan loop di thread terpisah
            task.spawn(function()
                while autoBuyRunning do
                    for _, selected in ipairs(selectedWeathers) do
                        local key = weatherKeyMap[selected]
                        if key and weathers[key] then
                            local success, err = pcall(function()
                                RFPurchaseWeatherEvent:InvokeServer(weathers[key])
                            end)
                        else
                            Window:Notify({
                                Title = "⚠️ Invalid Weather",
                                Content = "Invalid selection: " .. tostring(selected),
                                Duration = 3
                            })
                        end
                        task.wait(0.5)
                    end

                    task.wait(5) -- Increased from 2s to 5s to reduce CPU usage
                end
            end)
        else
            Window:Notify({
                Title = "🛑 Auto Buy Disabled",
                Content = "Weather auto-purchase stopped.",
                Duration = 3
            })
        end
    end
})


-- ==================================================
-- Merchant (copied/adapted from `source of wishub/Main.lua`)
-- ==================================================
local MarketItemData = nil
pcall(function()
    MarketItemData = require(ReplicatedStorage.Shared.MarketItemData)
end)

local merchantData = nil
pcall(function()
    if Replion and Replion.Client then
        merchantData = Replion.Client:WaitReplion("Merchant")
    end
end)

function shortenNumber(n)
    if type(n) ~= "number" then return "N/A" end
    local scales = {
        { 1000000000000000000, "Qi" },
        { 999999986991104, "Qa" },
        { 999999995904, "T" },
        { 1000000000, "B" },
        { 1000000, "M" },
        { 1000, "K" }
    }
    local negative = n < 0
    n = math.abs(n)
    if n < 1000 then
        return (negative and "-" or "") .. tostring(math.floor(n))
    end
    for i = 1, #scales do
        local scale, label = scales[i][1], scales[i][2]
        if n >= scale then
            local value = n / scale
            if value % 1 == 0 then
                return (negative and "-" or "") .. string.format("%.0f%s", value, label)
            else
                return (negative and "-" or "") .. string.format("%.2f%s", value, label)
            end
        end
    end
    return (negative and "-" or "") .. tostring(n)
end

local merchantItemsForDropdown = {}
local merchantItemMap = {}

function buildMerchantItemDatabase()
    merchantItemsForDropdown, merchantItemMap = {}, {}
    if not MarketItemData then
        return
    end

    pcall(function()
        for _, itemData in ipairs(MarketItemData) do
            if itemData and itemData.Identifier and itemData.Price and itemData.Id then
                local formattedPrice = shortenNumber(tonumber(itemData.Price) or 0)
                local formattedName = string.format("%s (%s)", itemData.Identifier, formattedPrice)
                table.insert(merchantItemsForDropdown, formattedName)
                merchantItemMap[formattedName] = itemData.Id
            end
        end
        table.sort(merchantItemsForDropdown)
    end)
end

buildMerchantItemDatabase()

local selectedMerchantItemNames = {}
local isAutoBuyingMerchantItem = false
local autoBuyMerchantThread = nil

function getMarketDataFromId(itemId)
    if not MarketItemData then return nil end
    for _, itemData in ipairs(MarketItemData) do
        if itemData and itemData.Id == itemId then
            return itemData
        end
    end
    return nil
end

function formatTime(seconds)
    seconds = tonumber(seconds) or 0
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02i Hours, %02i Minutes, %02i Seconds", h, m, s)
end

ShopTab:CreateSection({ Name = "Merchant" })

local merchantInfoParagraph = ShopTab:CreateParagraph({
    Title = "Merchant Status",
    Desc = "<font color='#999999'>Load data from the server...</font>",
    RichText = true
})

ShopTab:CreateMultiDropdown({
    Name = "Select Merchant Item(s)",
    Items = merchantItemsForDropdown,
    Default = selectedMerchantItemNames,
    Callback = function(selectedNames)
        selectedMerchantItemNames = selectedNames or {}
    end
})

ShopTab:CreateToggle({
    Name = "Auto Buy Selected Item",
    Default = isAutoBuyingMerchantItem,
    Callback = function(state)
        isAutoBuyingMerchantItem = state
        if autoBuyMerchantThread then
            task.cancel(autoBuyMerchantThread)
            autoBuyMerchantThread = nil
        end

        if state then
            if #selectedMerchantItemNames == 0 then
                Window:Notify({
                    Title = "Merchant",
                    Content = "No items selected to auto-buy.",
                    Duration = 3
                })
                isAutoBuyingMerchantItem = false
                return
            end

            autoBuyMerchantThread = task.spawn(function()
                while isAutoBuyingMerchantItem do
                    for _, name in ipairs(selectedMerchantItemNames) do
                        local itemId = merchantItemMap[name]
                        if itemId and BuyMarket then
                            pcall(function()
                                BuyMarket:InvokeServer(itemId)
                            end)
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

ShopTab:CreateButton({
    Name = "Buy Selected Item",
    Callback = function()
        if #selectedMerchantItemNames == 0 then
            Window:Notify({
                Title = "Merchant",
                Content = "No items selected to buy.",
                Duration = 3
            })
            return
        end

        for _, name in ipairs(selectedMerchantItemNames) do
            local itemId = merchantItemMap[name]
            if itemId and BuyMarket then
                pcall(function()
                    BuyMarket:InvokeServer(itemId)
                end)
            end
        end

        Window:Notify({
            Title = "Merchant",
            Content = "Purchase attempt sent for selected items.",
            Duration = 3
        })
    end
})

task.spawn(function()
    while task.wait(1) do
        if not merchantInfoParagraph then
            break
        end

        if not merchantData then
            merchantInfoParagraph:SetDesc("<font color='#ff3333'>Merchant data not available</font>")
            continue
        end

        local displayTextLines = {}
        local serverTime = workspace:GetServerTimeNow()
        local dayStart = math.floor(serverTime / 86400) * 86400
        local nextNoon = dayStart + 43200
        if serverTime > nextNoon then
            nextNoon = nextNoon + 43200
        end
        local timeUntilRefresh = math.max(nextNoon - serverTime, 0)

        table.insert(displayTextLines, "<b>Next Refresh in:</b> " .. formatTime(timeUntilRefresh))
        table.insert(displayTextLines, "")
        table.insert(displayTextLines, "<b>Items for sale:</b>")

        local currentItemIds = merchantData:Get("Items")
        if currentItemIds and #currentItemIds > 0 then
            for _, itemId in ipairs(currentItemIds) do
                local itemDetails = getMarketDataFromId(itemId)
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

ShopTab:CreateButton({
    Name = "Teleport to Merchant",
    Callback = function()
        local character = LocalPlayer and LocalPlayer.Character
        if not character then
            warn("Character not found.")
            return
        end

        local merchantNpc = workspace:FindFirstChild("NPC", true) and workspace.NPC:FindFirstChild("Alien Merchant")
        if merchantNpc and merchantNpc:IsA("Model") then
            local merchantPivot = merchantNpc:GetPivot()
            character:PivotTo(merchantPivot)
        else
            warn("Merchant NPC not found.")
        end
    end
})

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

local function getIslandFolder()
    return workspace:FindFirstChild("Islands")
end

local function getIslandDropdownItems()
    local folder = getIslandFolder()
    if not folder then
        return { "Islands folder not found" }
    end

    local out = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") or child:IsA("CFrameValue") or child:IsA("Vector3Value") or child:IsA("Folder") then
            table.insert(out, child.Name)
        end
    end
    table.sort(out)
    if #out == 0 then
        return { "No islands found" }
    end
    return out
end

local function resolveCFrameFromInstance(inst)
    if not inst then return nil end

    if inst:IsA("Model") then
        return inst:GetPivot()
    end
    if inst:IsA("BasePart") then
        return inst.CFrame
    end
    if inst:IsA("CFrameValue") then
        return inst.Value
    end
    if inst:IsA("Vector3Value") then
        return CFrame.new(inst.Value)
    end
    if inst:IsA("Folder") then
        local model = inst:FindFirstChildWhichIsA("Model")
        if model then
            return model:GetPivot()
        end
        local part = inst:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.CFrame
        end
    end

    return nil
end

local function resolveIslandCFrame(selection)
    if not selection or selection == "" then return nil end

    local folder = getIslandFolder()
    if folder then
        local child = folder:FindFirstChild(selection)
        local cf = resolveCFrameFromInstance(child)
        if cf then return cf end
    end
    return nil
end

local IslandDropdown = TeleportTab:CreateDropdown({
	Name = "Select Island",
	 Items = getIslandDropdownItems(),
    Callback = function(Value)
        SelectedIsland = Value
    end
})

task.spawn(function()
    local function refresh()
        if IslandDropdown and IslandDropdown.Refresh then
            IslandDropdown:Refresh(getIslandDropdownItems())
        end
    end

    local folder = getIslandFolder()
    if not folder then
        for _ = 1, 20 do
            folder = getIslandFolder()
            if folder then break end
            task.wait(0.5)
        end
    end

    refresh()
    if folder then
        folder.ChildAdded:Connect(refresh)
        folder.ChildRemoved:Connect(refresh)
    end
end)

TeleportTab:CreateButton({
	Name = "Teleport to Island",
	Icon = "rbxassetid://7733920644",
	  Callback = function()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local cf = resolveIslandCFrame(SelectedIsland)
        if not cf then return end

        local _, y, _ = hrp.CFrame:ToOrientation()
        local dest = cf.Position + Vector3.new(0, 3, 0)
        hrp.CFrame = CFrame.new(dest) * CFrame.Angles(0, y, 0)
    end
})

TeleportTab:CreateSection({ Name = "Tp To Player", Icon = "rbxassetid://7733955511" })

local SelectedPlayer = nil

local FishingDropdown = TeleportTab:CreateDropdown({
	Name = "Select Player",
	Items = (function()
        local players = {}
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr.Name ~= Player.Name then
                table.insert(players, plr.Name)
            end
        end
        table.sort(players)
        return players
    end)(),
    Callback = function(Value)
        SelectedPlayer = Value
    end
})

function RefreshPlayerList()
    local list = {}
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr.Name ~= Player.Name then
            table.insert(list, plr.Name)
        end
    end
    table.sort(list)
    FishingDropdown:Refresh(list)
end

game.Players.PlayerAdded:Connect(RefreshPlayerList)
game.Players.PlayerRemoving:Connect(RefreshPlayerList)

TeleportTab:CreateButton({
	Name = "Teleport to Player",
	Icon = "rbxassetid://7733920644",
	 Callback = function()
        if SelectedPlayer then
            local target = game.Players:FindFirstChild(SelectedPlayer)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    Player.Character.HumanoidRootPart.CFrame =
                        target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
                end
            end
        end
    end
})

TeleportTab:CreateSection({ Name = "Location NPC", Icon = "rbxassetid://7733955511" })

local SelectedNPC = nil

local function getNpcFolder()
    return workspace:FindFirstChild("NPC")
end

local function getNpcDropdownItems()
    local folder = getNpcFolder()
    if not folder then
        return { "NPC folder not found" }
    end
    local out = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") then
            table.insert(out, child.Name)
        end
    end
    table.sort(out)
    if #out == 0 then
        return { "No NPCs found" }
    end
    return out
end

local NPCDropdown = TeleportTab:CreateDropdown({
	Name = "Select NPC",
	Items = getNpcDropdownItems(),
    Callback = function(Value)
        SelectedNPC = Value
    end
})

task.spawn(function()
    local npcFolder = getNpcFolder() or workspace:WaitForChild("NPC", 10)
    if not npcFolder then return end

    local function refresh()
        if NPCDropdown and NPCDropdown.Refresh then
            NPCDropdown:Refresh(getNpcDropdownItems())
        end
    end

    refresh()
    npcFolder.ChildAdded:Connect(refresh)
    npcFolder.ChildRemoved:Connect(refresh)
end)

TeleportTab:CreateButton({
	Name = "Teleport to NPC",
	Icon = "rbxassetid://7733920644",
	 Callback = function()
        local npcFolder = getNpcFolder()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not npcFolder or not hrp or not SelectedNPC then return end

        local target = npcFolder:FindFirstChild(SelectedNPC)
        if not target then return end

        if target:IsA("Model") then
            hrp.CFrame = target:GetPivot()
        elseif target:IsA("BasePart") then
            hrp.CFrame = target.CFrame
        end
    end
})

TeleportTab:CreateSection({ Name = "Fishing Area", Icon = "rbxassetid://7733955511" })

local FishingAreaLocations = {
    ["Fisherman Island"]           = Vector3.new(74.03, 9.53, 2705.23),
    ["Crater Island"]              = Vector3.new(998.03, 2.86, 5151.17),
    ["Tropical Island"]            = Vector3.new(-2152.61, 2.32, 3671.72),
    ["Coral Refs"]                 = Vector3.new(-3181.39, 2.52, 2104.35),
    ["Lost Isle"]                  = Vector3.new(-3734.67, 5.34, -1082.63),
    ["Volcano"]                    = Vector3.new(-541.52, 17.32, 121.67),
    ["Esoteric Island"]            = Vector3.new(2164.47, 3.22, 1242.39),
    ["Enchant Room"]               = Vector3.new(3255.67, -1301.53, 1371.79),
    ["Kohana"]                     = Vector3.new(-661.68, 3.05, 714.14),
    ["Weather Machine"]            = Vector3.new(-1523.23, 8.47, 1771.99),
    ["Treasure Room"]              = Vector3.new(-3581.60, -279.07, -1589.65),
    ["Sisyphus Statue"]            = Vector3.new(-3729.25, -135.07, -885.64),
    ["Ancient Jungle"]             = Vector3.new(1275.10, 3.91, -334.75),
    ["Sacred Temple"]              = Vector3.new(1451.41, -22.13, -635.65),
    ["Underground Cellar"]         = Vector3.new(2135.45, -91.20, -699.33),
    ["Arrow Artifact"]             = Vector3.new(869.33, 3.13, -294.87),
    ["Crescent Artifact"]          = Vector3.new(1399.05, 4.80, 162.05),
    ["Diamond Artifact"]           = Vector3.new(1854.25, 4.43, -276.84),
    ["Hourglass Diamond Artifact"] = Vector3.new(1460.75, 6.33, -815.16),
    ["Ancient Ruin"]               = CFrame.new(6096.65, -585.92, 4665.26, 0.01, -0.00, 1.00, 0.00, 1.00, 0.00, -1.00, 0.00, 0.01),
    ["Crystalline Passage"]        = CFrame.new(6050.02, -538.90, 4374.91, -1.00, 0.00, 0.01, 0.00, 1.00, 0.00, -0.01, 0.00, -1.00),
    ["Classic Island"]             = CFrame.new(1232.43, 10.00, 2843.07, 0.03, 0.00, -1.00, 0.00, 1.00, 0.00, 1.00, -0.00, 0.03),
    ["Iron Cavern"]                = CFrame.new(-8898.99, -581.75, 157.30, 0.02, -0.00, -1.00, 0.00, 1.00, -0.00, 1.00, -0.00, 0.02),
    ["Iron Cafe"]                  = CFrame.new(-8642.19, -547.50, 161.10, -0.00, -0.00, -1.00, 0.00, 1.00, -0.00, 1.00, -0.00, -0.00),
}

local SelectedFishingArea = nil

TeleportTab:CreateDropdown({
    Name = "Select Fishing Area",
    Items = (function()
        local keys = {}
        for name in pairs(FishingAreaLocations) do
            table.insert(keys, name)
        end
        table.sort(keys)
        return keys
    end)(),
    Callback = function(value)
        SelectedFishingArea = value
    end
})

TeleportTab:CreateButton({
    Name = "Teleport to Fishing Area",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        if not SelectedFishingArea then return end
        local dest = FishingAreaLocations[SelectedFishingArea]
        if not dest then return end
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if typeof(dest) == "CFrame" then
            hrp.CFrame = dest
        else
            hrp.CFrame = CFrame.new(dest)
        end
    end
})

local fishingAreaFreezeConn = nil

function stopFishingAreaFreeze()
    if fishingAreaFreezeConn then
        fishingAreaFreezeConn:Disconnect()
        fishingAreaFreezeConn = nil
    end
end

function startFishingAreaFreeze()
    stopFishingAreaFreeze()
    if not SelectedFishingArea then return end
    local dest = FishingAreaLocations[SelectedFishingArea]
    if not dest then return end
    local cf = typeof(dest) == "CFrame" and dest or CFrame.new(dest)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = cf end
    fishingAreaFreezeConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local h = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if h then h.CFrame = cf end
        end)
    end)
end

TeleportTab:CreateToggle({
    Name = "Freeze at Selected Area",
    Default = false,
    Callback = function(state)
        if state then
            startFishingAreaFreeze()
        else
            stopFishingAreaFreeze()
        end
    end
})

TeleportTab:CreateSection({ Name = "Custom Position", Icon = "rbxassetid://7733955511" })

local vSavedCustomPos = nil
local customPosFreezeConn = nil

function stopCustomPosFreeze()
    if customPosFreezeConn then
        customPosFreezeConn:Disconnect()
        customPosFreezeConn = nil
    end
end

TeleportTab:CreateButton({
    Name = "Save Current Position",
    Icon = "rbxassetid://7733955511",
    Callback = function()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            vSavedCustomPos = hrp.CFrame
            Window:Notify({ Title = "Custom Position", Content = "Position saved!", Duration = 3 })
        end
    end
})

TeleportTab:CreateButton({
    Name = "Teleport to Saved Position",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        if not vSavedCustomPos then
            Window:Notify({ Title = "Custom Position", Content = "No position saved yet.", Duration = 3 })
            return
        end
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = vSavedCustomPos end
    end
})

TeleportTab:CreateToggle({
    Name = "Freeze at Saved Position",
    Default = false,
    Callback = function(state)
        stopCustomPosFreeze()
        if not state then return end
        if not vSavedCustomPos then
            Window:Notify({ Title = "Custom Position", Content = "No position saved yet.", Duration = 3 })
            return
        end
        local cf = vSavedCustomPos
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = cf end
        customPosFreezeConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local h = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if h then h.CFrame = cf end
            end)
        end)
    end
})

-- Auto Leviathan Hunt (tab: Auto)
_G.AutoLeviathanHunt = _G.AutoLeviathanHunt or false
local LeviathanThread = nil

AutoTab:CreateSection({ Name = "Auto Leviathan Hunt", Icon = "rbxassetid://7733955511" })

AutoTab:CreateToggle({
	Name = "Auto Leviathan Hunt",
	Default = _G.AutoLeviathanHunt,
	ConfigKey = "AutoLeviathanHunt",
	Callback = function(state)
        _G.AutoLeviathanHunt = state
        
        if state then
            -- Start Leviathan Hunt loop
            LeviathanThread = task.spawn(function()
                while _G.AutoLeviathanHunt do
                    pcall(function()
                        local zones = workspace:FindFirstChild("Zones")
                        if zones then
                            local leviathanDen = zones:FindFirstChild("Leviathan's Den")
                            if leviathanDen then
                                -- Zone exists, teleport immediately
                                local character = game.Players.LocalPlayer.Character
                                if character and character:FindFirstChild("HumanoidRootPart") then
                                    local targetCFrame = CFrame.new(3474.05298, -287.774719, 3472.63403, -0.915228605, 0.097325258, -0.391004264, 3.60608101e-06, 0.970392585, 0.241532952, 0.402934879, 0.221056461, -0.88813144)
                                    character.HumanoidRootPart.CFrame = targetCFrame
                                    print("[Leviathan Hunt] ✓ Teleported to Leviathan's Den")
                                end
                            else
                                print("[Leviathan Hunt] Zone not found, waiting...")
                            end
                        end
                    end)
                    
                    -- Check every 30 seconds
                    task.wait(30)
                end
            end)
            
            Window:Notify({
                Title = "✓ Leviathan Hunt",
                Content = "Auto Leviathan Hunt enabled!",
                Duration = 3
            })
        else
            -- Stop Leviathan Hunt
            if LeviathanThread then
                task.cancel(LeviathanThread)
                LeviathanThread = nil
            end
            
            Window:Notify({
                Title = "✗ Leviathan Hunt",
                Content = "Auto Leviathan Hunt disabled!",
                Duration = 3
            })
        end
    end
})

-- ======================================================
-- Auto Lochnes Event (Countdown-based TP + Fishing)
-- Reads countdown from:
-- workspace["!!! DEPENDENCIES"]["Event Tracker"].Main.Gui.Content.Items.Countdown.Label
-- ======================================================
_G.AutoLochnesEvent = _G.AutoLochnesEvent or false
_G.LochnesFishingMode = _G.LochnesFishingMode or "Legit" -- "Legit" | "Instant"

 LochnesThread = nil
 LochnesTriggered = false
 LOCHNES_TRIGGER_SECONDS = 10
 LochnesLastCFrame = nil

 LOCHNES_TARGET_CFRAME = CFrame.new(
    6091.53711, -585.924316, 4643.58789,
    -0.863860309, 1.13146491e-07, 0.50373143,
    9.93031932e-08, 1, -5.43194325e-08,
    -0.50373143, 3.09773784e-09, -0.863860309
)

 function parseLochnesCountdownSeconds(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end

    -- Expected example: "3H 47M 8S"
    local h = tonumber(text:match("(%d+)%s*[Hh]")) or 0
    local m = tonumber(text:match("(%d+)%s*[Mm]")) or 0
    local s = tonumber(text:match("(%d+)%s*[Ss]"))
    if s then
        return h * 3600 + m * 60 + s
    end

    -- Fallback: "HH:MM:SS"
    local hh, mm, ss = text:match("^(%d+):(%d+):(%d+)$")
    if hh then
        return tonumber(hh) * 3600 + tonumber(mm) * 60 + tonumber(ss)
    end

    -- Fallback: "MM:SS"
    local mm2, ss2 = text:match("^(%d+):(%d+)$")
    if mm2 then
        return tonumber(mm2) * 60 + tonumber(ss2)
    end

    return nil
end

 function getLochnesCountdownText()
    local ok, label = pcall(function()
        return workspace["!!! DEPENDENCIES"]["Event Tracker"].Main.Gui.Content.Items.Countdown.Label
    end)
    if not ok or not label then return nil end

    local text = label.Text or label.ContentText
    return type(text) == "string" and text or tostring(text or "")
end

 function teleportLochnes()
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    -- Save current position before teleporting
    LochnesLastCFrame = hrp.CFrame
    hrp.CFrame = LOCHNES_TARGET_CFRAME
end

 function returnToLochnesLastPosition()
    if not LochnesLastCFrame then return end
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = LochnesLastCFrame
end

 function holdRod()
    -- Re-use existing rod equip remote (slot 1)
    pcall(function()
        if equipTool then
            equipTool:FireServer(1)
        end
    end)
end

 function startLochnesFishingOnce()
    holdRod()

    if _G.LochnesFishingMode == "Legit" then
        pcall(function()
            FishingController:RequestChargeFishingRod(Vector2.new(0, 0), true)
        end)
        task.wait(delayfishing or 1)
        pcall(function()
            CallFishDone(REFishDone, 1)
        end)
    else
        -- Instant mode: use existing helper
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
                Window:Notify({
                    Title = "Lochnes Event",
                    Content = "TP + fishing started (" .. tostring(_G.LochnesFishingMode) .. ")",
                    Duration = 3,
                    Icon = "fish"
                })
                -- Return to last saved position after fishing
                task.wait(2)
                returnToLochnesLastPosition()
                Window:Notify({
                    Title = "Lochnes Event",
                    Content = "Returned to last position.",
                    Duration = 3,
                    Icon = "rbxassetid://7733920644"
                })
            elseif LochnesTriggered and seconds > LOCHNES_TRIGGER_SECONDS then
                -- Countdown reset for the next event cycle
                LochnesTriggered = false
            end
        end

        task.wait(0.25)
    end
end

AutoTab:CreateSection({ Name = "Auto Lochnes Event", Icon = "rbxassetid://7733955511" })

AutoTab:CreateDropdown({
    Name = "Lochnes Fishing Mode",
    Items = { "Legit", "Instant" },
    Default = _G.LochnesFishingMode,
    Callback = function(v)
        _G.LochnesFishingMode = v
    end
})

AutoTab:CreateToggle({
    Name = "Auto Lochnes Event",
    Default = _G.AutoLochnesEvent,
    Callback = function(state)
        _G.AutoLochnesEvent = state

        if LochnesThread then
            task.cancel(LochnesThread)
            LochnesThread = nil
        end

        LochnesTriggered = false

        if state then
            Window:Notify({
                Title = "Auto Lochnes",
                Content = "Waiting for countdown <= " .. tostring(LOCHNES_TRIGGER_SECONDS) .. "s",
                Duration = 3,
                Icon = "time"
            })
            LochnesThread = task.spawn(lochnesCountdownLoop)
        end
    end
})

-- ⚙️ Auto Event TP System (Multi-select Dropdown + Spam Teleport)

local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
	character = c
	hrp = c:WaitForChild("HumanoidRootPart")
end)

-- Settings
local megCheckRadius = 150

-- Control states
local autoEventTPEnabled = false
local selectedEvents = {}
local createdEventPlatform = nil

-- Event configurations (with priority)
local eventData = {
	["Worm Hunt"] = {
		-- Langsung: Workspace → Props → Model → BlackHole (lebih spesifik dari scan "Model" di MENU RINGS)
		PathFromWorkspace = { "Props", "Model", "BlackHole" },
		Locations = {
			Vector3.new(2190.85, -1.4, 97.575), 
			Vector3.new(-2450.679, -1.4, 139.731), 
			Vector3.new(-267.479, -1.4, 5188.531),
			Vector3.new(-327, -1.4, 2422)
		},
		PlatformY = 107,
		Priority = 1,
		Icon = "fish"
	},
	["Megalodon Hunt"] = {
		TargetName = "Megalodon Hunt",
		Locations = {
			Vector3.new(-1076.3, -1.4, 1676.2),
			Vector3.new(-1191.8, -1.4, 3597.3),
			Vector3.new(412.7, -1.4, 4134.4),
		},
		PlatformY = 107,
		Priority = 2,
		Icon = "anchor"
	},
	["Ghost Shark Hunt"] = {
		TargetName = "Ghost Shark Hunt",
		Locations = {
			Vector3.new(489.559, -1.35, 25.406), 
			Vector3.new(-1358.216, -1.35, 4100.556), 
			Vector3.new(627.859, -1.35, 3798.081)
		},
		PlatformY = 107,
		Priority = 3,
		Icon = "fish"
	},
	["Shark Hunt"] = {
		TargetName = "Shark Hunt",
		Locations = {
			Vector3.new(1.65, -1.35, 2095.725),
			Vector3.new(1369.95, -1.35, 930.125),
			Vector3.new(-1585.5, -1.35, 1242.875),
			Vector3.new(-1896.8, -1.35, 2634.375)
		},
		PlatformY = 107,
		Priority = 4,
		Icon = "fish"
	},
    ["Thrundzilla Hunt"] = {
		TargetName = "Shocked",
		Locations = {
			Vector3.new(2067.7981, 2.20000029, 16.7060127),
		},
		PlatformY = 107,
		Priority = 5,
		Icon = "fish"
	},
}

local eventNames = {}
for name in pairs(eventData) do
	table.insert(eventNames, name)
end

-- Utility
 function destroyEventPlatform()
	if createdEventPlatform and createdEventPlatform.Parent then
		createdEventPlatform:Destroy()
		createdEventPlatform = nil
	end
end

function getInstanceAtWorkspacePath(pathNames)
	if type(pathNames) ~= "table" then return nil end
	local current = Workspace
	for _, name in ipairs(pathNames) do
		current = current and current:FindFirstChild(name)
		if not current then return nil end
	end
	return current
end

function getWorldPositionForEventTarget(inst)
	if not inst then return nil end
	if inst:IsA("BasePart") then
		return inst.Position
	end
	if inst:IsA("Model") then
		if inst.PrimaryPart then
			return inst.PrimaryPart.Position
		end
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
		-- Don't destroy unless we have to, actually create new if missing
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

	hrp.CFrame = CFrame.new(createdEventPlatform.Position + Vector3.new(0, 3, 0))
end

 function runMultiEventTP()
	selectedEvents = type(selectedEvents) == "table" and selectedEvents or {}

	while autoEventTPEnabled do
		local sorted = {}

		for _, e in ipairs(selectedEvents) do
			local cfg = eventData[e]
			if type(cfg) == "table" then
				table.insert(sorted, cfg)
			end
		end

		table.sort(sorted, function(a, b)
			return (a.Priority or 0) < (b.Priority or 0)
		end)

		for _, config in ipairs(sorted) do
			if type(config.Locations) ~= "table" then
				continue
			end

			local foundTarget, foundPos

			if config.PathFromWorkspace then
				local targetInst = getInstanceAtWorkspacePath(config.PathFromWorkspace)
				local pos = getWorldPositionForEventTarget(targetInst)
				if pos then
					for _, loc in ipairs(config.Locations) do
						if (pos - loc).Magnitude <= megCheckRadius then
							foundTarget = targetInst
							foundPos = pos
							break
						end
					end
				end
			elseif config.TargetName then
				-- Reverted to GetDescendants() like old code, but optimized to scan once per event type
				local searchTargets = Workspace:GetDescendants()

				for _, d in ipairs(searchTargets) do
					if d.Name == config.TargetName then
						local pos = d:IsA("BasePart") and d.Position
							or (d.PrimaryPart and d.PrimaryPart.Position)
						
						if pos then
							for _, loc in ipairs(config.Locations) do
								if (pos - loc).Magnitude <= megCheckRadius then
									foundTarget = d
									foundPos = pos
									break
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

TeleportTab:CreateDropdown({
	Name = "Select Fish Events",
	Items = eventNames,
	Callback = function(value)
		selectedEvents = { value } -- paksa jadi table
		print("[EventTP] Selected Event:", value)
	end
})


TeleportTab:CreateToggle({
	Name = "Auto Fish Event TP",
	Default = false,
	Callback = function(state)
		autoEventTPEnabled = state
		if state then
			task.spawn(runMultiEventTP)
		else
		end
	end
})

SettingsTab:CreateSection({ Name = "Camera Views" })

-- ============================================
-- UNLIMITED ZOOM TOGGLE IN SETTINGS TAB
-- ============================================

local UnlimitedZoomModule = {}

-- Services
local Players = game:GetService("Players")

-- Variables
local Player = Players.LocalPlayer

-- Save original zoom settings
local originalMinZoom = Player.CameraMinZoomDistance
local originalMaxZoom = Player.CameraMaxZoomDistance

-- State
local unlimitedZoomActive = false

-- ============================================
-- MAIN FUNCTIONS
-- ============================================

function UnlimitedZoomModule.Enable()
    if unlimitedZoomActive then return false end
    
    unlimitedZoomActive = true
    
    -- Remove zoom limits (character can still move)
    Player.CameraMinZoomDistance = 0.5
    Player.CameraMaxZoomDistance = 9999
    
    print("✅ Unlimited Zoom: ENABLED")
    print("📷 Scroll to zoom in/out without limits")
    print("🏃 Character can move normally")
    
    return true
end

function UnlimitedZoomModule.Disable()
    if not unlimitedZoomActive then return false end
    
    unlimitedZoomActive = false
    
    -- Restore original zoom limits
    Player.CameraMinZoomDistance = originalMinZoom
    Player.CameraMaxZoomDistance = originalMaxZoom
    
    print("🔴 Unlimited Zoom: DISABLED")
    print("📷 Zoom limits restored")
    
    return true
end

function UnlimitedZoomModule.IsActive()
    return unlimitedZoomActive
end

-- ============================================
-- CREATE TOGGLE IN SETTINGS TAB
-- ============================================

SettingsTab:CreateToggle({
    Name = "Unlimited Zoom Camera",
    Icon = "rbxassetid://7733799682", -- Camera icon
    Default = false,
    Callback = function(state)
        if state then
            UnlimitedZoomModule.Enable()
        else
            UnlimitedZoomModule.Disable()
        end
    end
})


SettingsTab:CreateSection({ Name = "Skip Cutscene" })

local skipCutscene = false
local replicateConn
local stopConn
local originalPlay
local originalStop
local hooked = false

SettingsTab:CreateToggle({
	Name = "Skip Cutscene",
	Default = false,
	  Callback = function(state)
        skipCutscene = state

        -- ===== Remote Events (connect sekali) =====
        if not replicateConn and RE.ReplicateCutscene then
            replicateConn = RE.ReplicateCutscene and RE.ReplicateCutscene.OnClientEvent:Connect(function(...)
                if skipCutscene then
                    warn("[DevHub] Blocked ReplicateCutscene event!")
                end
            end)
        end

        if not stopConn and RE.StopCutscene then
            stopConn = RE.StopCutscene and RE.StopCutscene.OnClientEvent:Connect(function()
                if skipCutscene then
                    warn("[DevHub] Blocked StopCutscene event!")
                end
            end)
        end

        -- ===== Controller (hook sekali doang) =====
        if hooked then return end
        hooked = true

        spawn(function()
            local ok, CutsceneController = pcall(function()
                return require(ReplicatedStorage.Controllers.CutsceneController)
            end)

            if not ok or not CutsceneController then
                warn("[DevHub] CutsceneController not found.")
                return
            end

            originalPlay = originalPlay or CutsceneController.Play
            originalStop = originalStop or CutsceneController.Stop

            -- monitor toggle
            while true do
                if skipCutscene then
                    CutsceneController.Play = function(...)
                        warn("[DevHub] Cutscene skipped (Play).")
                    end
                    CutsceneController.Stop = function(...)
                        warn("[DevHub] Cutscene skipped (Stop).")
                    end
                else
                    CutsceneController.Play = originalPlay
                    CutsceneController.Stop = originalStop
                end
                task.wait(0.25)
            end
        end)
    end
})


SettingsTab:CreateSection({ Name = "Notification", Icon = "rbxassetid://7733955511" })

SettingsTab:CreateToggle({
	Name = "Disable Notifications",
	Default = false,
	Callback = function(state)
		local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
		if PlayerGui then
			local NotifyGui = PlayerGui:FindFirstChild("Text Notifications")
			if NotifyGui then
				local Frame = NotifyGui:FindFirstChild("Frame")
				if Frame then
					Frame.Visible = not state
				end
			end
		end
	end
})

SettingsTab:CreateDropdown({
	Name = "Position",
	Items = {"Normal (Mid)", "Left", "Right"},
	Default = "Normal (Mid)",
	Callback = function(Value)
		local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
		if PlayerGui then
			local NotifyGui = PlayerGui:FindFirstChild("Text Notifications")
			if NotifyGui then
				local Frame = NotifyGui:FindFirstChild("Frame")
				if Frame then
					if Value == "Normal (Mid)" then
						Frame.Position = UDim2.new(0.5, 0, 0, 110)
					elseif Value == "Left" then
						Frame.Position = UDim2.new(0.3, 0, 0, 110)
					elseif Value == "Right" then
						Frame.Position = UDim2.new(0.7, 0, 0, 110)
					end
				end
			end
		end
	end
})

SettingsTab:CreateSection({ Name = "General", Icon = "rbxassetid://7733954611" })

-- ============================================
-- WALK ON WATER TOGGLE
-- ============================================

-- Load Walk on Water Module
local WalkOnWater = loadstring([[
-- ULTRA STABLE WALK ON WATER V3.2 (MODULE EDITION)
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local WalkOnWater = {
	Enabled = false,
	Platform = nil,
	AlignPos = nil,
	Connection = nil
}

local PLATFORM_SIZE = 14
local OFFSET = 3
local LAST_WATER_Y = nil

function GetCharacterReferences()
	local char = LocalPlayer.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end
	return char, humanoid, hrp
end

function ForceSurfaceLift()
	local _, humanoid, hrp = GetCharacterReferences()
	if not humanoid or not hrp then return end
	if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then return end
	
	for _ = 1, 60 do
		hrp.Velocity = Vector3.new(0, 80, 0)
		task.wait(0.03)
		if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then break end
	end
	hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
end

function GetWaterHeight()
	local _, _, hrp = GetCharacterReferences()
	if not hrp then return LAST_WATER_Y end
	
	local origin = hrp.Position + Vector3.new(0, 5, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { LocalPlayer.Character }
	params.IgnoreWater = false
	
	local result = Workspace:Raycast(origin, Vector3.new(0, -600, 0), params)
	if result then
		LAST_WATER_Y = result.Position.Y
		return LAST_WATER_Y
	end
	return LAST_WATER_Y
end

function CreatePlatform()
	if WalkOnWater.Platform then
		WalkOnWater.Platform:Destroy()
	end
	
	local p = Instance.new("Part")
	p.Size = Vector3.new(PLATFORM_SIZE, 1, PLATFORM_SIZE)
	p.Anchored = true
	p.CanCollide = true
	p.Transparency = 1
	p.CanQuery = false
	p.CanTouch = false
	p.Name = "WaterLockPlatform"
	p.Parent = Workspace
	WalkOnWater.Platform = p
end

function SetupAlign()
	local _, _, hrp = GetCharacterReferences()
	if not hrp then return false end
	
	if WalkOnWater.AlignPos then
		WalkOnWater.AlignPos:Destroy()
	end
	
	local att = hrp:FindFirstChild("RootAttachment")
	if not att then
		att = Instance.new("Attachment")
		att.Name = "RootAttachment"
		att.Parent = hrp
	end
	
	local ap = Instance.new("AlignPosition")
	ap.Attachment0 = att
	ap.MaxForce = math.huge
	ap.MaxVelocity = math.huge
	ap.Responsiveness = 200
	ap.RigidityEnabled = true
	ap.Parent = hrp
	WalkOnWater.AlignPos = ap
	return true
end

function Cleanup()
	if WalkOnWater.Connection then
		WalkOnWater.Connection:Disconnect()
		WalkOnWater.Connection = nil
	end
	if WalkOnWater.AlignPos then
		WalkOnWater.AlignPos:Destroy()
		WalkOnWater.AlignPos = nil
	end
	if WalkOnWater.Platform then
		WalkOnWater.Platform:Destroy()
		WalkOnWater.Platform = nil
	end
end

function WalkOnWater.Start()
	if WalkOnWater.Enabled then return end
	local char, humanoid, hrp = GetCharacterReferences()
	if not char or not humanoid or not hrp then return end
	
	ForceSurfaceLift()
	WalkOnWater.Enabled = true
	LAST_WATER_Y = nil
	CreatePlatform()
	
	if not SetupAlign() then
		WalkOnWater.Enabled = false
		Cleanup()
		return
	end
	
	WalkOnWater.Connection = RunService.Heartbeat:Connect(function()
		if not WalkOnWater.Enabled then return end
		local _, _, currentHRP = GetCharacterReferences()
		if not currentHRP then return end
		
		local waterY = GetWaterHeight()
		if not waterY then return end
		
		if WalkOnWater.Platform then
			WalkOnWater.Platform.CFrame = CFrame.new(
				currentHRP.Position.X,
				waterY - 0.5,
				currentHRP.Position.Z
			)
		end
		
		if WalkOnWater.AlignPos then
			WalkOnWater.AlignPos.Position = Vector3.new(
				currentHRP.Position.X,
				waterY + OFFSET,
				currentHRP.Position.Z
			)
		end
	end)
end

function WalkOnWater.Stop()
	WalkOnWater.Enabled = false
	Cleanup()
end

LocalPlayer.CharacterAdded:Connect(function()
	if WalkOnWater.Enabled then
		task.wait(0.5)
		Cleanup()
		WalkOnWater.Enabled = false
		WalkOnWater.Start()
	end
end)

return WalkOnWater
]])()

-- ============================================
-- TOGGLE
-- ============================================
SettingsTab:CreateToggle({
    Name = "Walk on Water",
    Description = "Walk on water surface without swimming",
    Icon = "rbxassetid://11400562133",
    Default = false,
    Callback = function(value)
        if value then
            WalkOnWater.Start()
        else
            WalkOnWater.Stop()
        end
    end,
})

SettingsTab:CreateToggle({
	Name = "Auto Reconnect",
	SubText = "Automatic reconnect if disconnected",
	Default = false,
	 Callback = function(state)
        _G.AutoReconnect = state
        if state then
            task.spawn(function()
                while _G.AutoReconnect do
                    task.wait(2)

                    local reconnectUI = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
                    if reconnectUI then
                        local prompt = reconnectUI:FindFirstChild("promptOverlay")
                        if prompt then
                            local button = prompt:FindFirstChild("ButtonPrimary")
                            if button and button.Visible then
                                firesignal(button.MouseButton1Click)
                            end
                        end
                    end
                end
            end)
        end
    end
})



-- ============================================
-- FAKE CHARACTER SYSTEM
-- ============================================
SettingsTab:CreateSection({ Name = "Fake Character", Icon = "rbxassetid://7733964719" })

local FakeCharacter = {}
FakeCharacter.Enabled = false
FakeCharacter.FakeChar = nil
FakeCharacter.RealChar = nil
FakeCharacter.Connections = {}

-- Configuration
local TRANSPARENCY = 1 -- Real character transparency (1 = invisible)
local FAKE_TRANSPARENCY = 0 -- Fake character transparency (0 = visible)

-- Helper: Make character parts transparent
 function setCharacterTransparency(character, transparency)
    if not character then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = transparency
        elseif part:IsA("Decal") then
            part.Transparency = transparency
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then
                handle.Transparency = transparency
            end
        end
    end
    
    -- Handle face
    local head = character:FindFirstChild("Head")
    if head then
        local face = head:FindFirstChild("face")
        if face then
            face.Transparency = transparency
        end
    end
end

-- Helper: Clone character
 function cloneCharacter(original)
    if not original then return nil end
    
    local clone = Instance.new("Model")
    clone.Name = original.Name .. "_Fake"
    
    -- Clone all parts
    for _, part in pairs(original:GetChildren()) do
        if part:IsA("BasePart") or part:IsA("Accessory") or part:IsA("Humanoid") then
            local clonedPart = part:Clone()
            
            -- Make cloned parts non-collidable
            if clonedPart:IsA("BasePart") then
                clonedPart.CanCollide = false
                clonedPart.Anchored = false
                
                -- Remove any welds/constraints
                for _, constraint in pairs(clonedPart:GetChildren()) do
                    if constraint:IsA("Constraint") or constraint:IsA("WeldConstraint") then
                        constraint:Destroy()
                    end
                end
            end
            
            clonedPart.Parent = clone
        end
    end
    
    -- Set primary part
    if original.PrimaryPart then
        clone.PrimaryPart = clone:FindFirstChild(original.PrimaryPart.Name)
    end
    
    return clone
end

-- Helper: Weld fake character parts together
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

-- Helper: Update fake character position
 function updateFakePosition()
    if not FakeCharacter.Enabled then return end
    if not FakeCharacter.FakeChar or not FakeCharacter.RealChar then return end
    
    local realRoot = FakeCharacter.RealChar:FindFirstChild("HumanoidRootPart")
    local fakeRoot = FakeCharacter.FakeChar:FindFirstChild("HumanoidRootPart")
    
    if realRoot and fakeRoot then
        fakeRoot.CFrame = realRoot.CFrame
    end
end

-- Start fake character
function FakeCharacter.Start()
    if FakeCharacter.Enabled then
        warn("[FakeChar] Already enabled")
        return false
    end
    
    local character = Players.LocalPlayer.Character
    if not character then
        warn("[FakeChar] No character found")
        return false
    end
    
    FakeCharacter.RealChar = character
    
    -- Create fake character
    FakeCharacter.FakeChar = cloneCharacter(character)
    if not FakeCharacter.FakeChar then
        warn("[FakeChar] Failed to clone character")
        return false
    end
    
    -- Setup fake character
    weldFakeCharacter(FakeCharacter.FakeChar)
    FakeCharacter.FakeChar.Parent = workspace
    
    -- Make real character invisible
    setCharacterTransparency(FakeCharacter.RealChar, TRANSPARENCY)
    
    -- Make fake character visible
    setCharacterTransparency(FakeCharacter.FakeChar, FAKE_TRANSPARENCY)
    
    -- Update loop
    FakeCharacter.Connections.Update = game:GetService("RunService").Heartbeat:Connect(updateFakePosition)
    
    -- Handle character respawn
    FakeCharacter.Connections.Respawn = Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
        if FakeCharacter.Enabled then
            task.wait(0.5)
            FakeCharacter.Stop()
            task.wait(0.5)
            FakeCharacter.Start()
        end
    end)
    
    FakeCharacter.Enabled = true
    print("[FakeChar] Fake character enabled")
    
    if Window then
        Window:Notify({
            Title = "✓ Fake Character",
            Content = "Fake character enabled!",
            Duration = 3
        })
    end
    
    return true
end

-- Stop fake character
function FakeCharacter.Stop()
    if not FakeCharacter.Enabled then
        warn("[FakeChar] Not enabled")
        return false
    end
    
    -- Disconnect all connections
    for _, connection in pairs(FakeCharacter.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    FakeCharacter.Connections = {}
    
    -- Remove fake character
    if FakeCharacter.FakeChar then
        FakeCharacter.FakeChar:Destroy()
        FakeCharacter.FakeChar = nil
    end
    
    -- Restore real character visibility
    if FakeCharacter.RealChar then
        setCharacterTransparency(FakeCharacter.RealChar, 0)
    end
    
    FakeCharacter.Enabled = false
    FakeCharacter.RealChar = nil
    
    print("[FakeChar] Fake character disabled")
    
    if Window then
        Window:Notify({
            Title = "✗ Fake Character",
            Content = "Fake character disabled!",
            Duration = 3
        })
    end
    
    return true
end

SettingsTab:CreateToggle({
    Name = "Fake Character",
    SubText = "Hide your real position with a fake character",
    Default = false,
    Callback = function(state)
        if state then
            FakeCharacter.Start()
        else
            FakeCharacter.Stop()
        end
    end
})

SettingsTab:CreateSection({ Name = "Hide Identity Features", Icon = "rbxassetid://7743875962" })

Players = game:GetService("Players")
Player = Players.LocalPlayer
Character = Player.Character or Player.CharacterAdded:Wait()

function getOverhead(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    return hrp:WaitForChild("Overhead")
end

overhead = getOverhead(Character)
header = overhead.Content.Header
levelLabel = overhead.LevelContainer.Label

defaultHeader = header.Text
defaultLevel = levelLabel.Text

-- Configuration Defaults
local FakeName = "discord.gg/DevHub"
local FakeLevel = "MAX"
local ScriptName = "DevHub"
local HideStatsEnabled = false

-- Storage
local OriginalTexts = {}
local ActiveGradientThreads = {}

-- Helper: Create Shimmer Gradient
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
        {0.30, Color3.fromRGB(255, 255, 255)}, -- Sparkle
        {0.40, Color3.fromRGB(0, 150, 255)},
        {0.50, Color3.fromRGB(0, 120, 220)},
        {0.60, Color3.fromRGB(0, 100, 200)},
        {0.70, Color3.fromRGB(0, 120, 220)},
        {0.80, Color3.fromRGB(0, 150, 255)},
        {0.90, Color3.fromRGB(255, 255, 255)}, -- Sparkle
        {1.00, Color3.fromRGB(0, 100, 200)},
    }
    
    for _, data in ipairs(basePattern) do
        table.insert(colorKeypoints, ColorSequenceKeypoint.new(data[1], data[2]))
    end
    
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

-- Helper: Create Script Name Label (DevHub)
function createScriptNameLabel(nameLabel, billboard)
    if not nameLabel or not billboard then return end
    
    local existingFrame = billboard:FindFirstChild("DevHubFrame")
    if existingFrame then return existingFrame end
    
    local nameFrame = nameLabel.Parent
    if not nameFrame or not nameFrame:IsA("Frame") then return end
    
    local originalNamePos = nameFrame.Position
    nameFrame.Position = UDim2.new(
        originalNamePos.X.Scale,
        originalNamePos.X.Offset,
        originalNamePos.Y.Scale + 0.25,
        originalNamePos.Y.Offset
    )
    
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

-- Helper: Remove Script Name Labels
function removeAllScriptNames()
    local character = Players.LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local overhead = hrp:FindFirstChild("Overhead")
    if not overhead then return end
    
    local voraFrame = overhead:FindFirstChild("DevHubFrame")
    if voraFrame then
        for threadId, _ in pairs(ActiveGradientThreads) do
            ActiveGradientThreads[threadId] = nil
        end
        
        local nameLabel = overhead:FindFirstChild("Header", true)
        if nameLabel then
            local nameFrame = nameLabel.Parent
            if nameFrame and nameFrame:IsA("Frame") then
                local currentPos = nameFrame.Position
                nameFrame.Position = UDim2.new(
                    currentPos.X.Scale,
                    currentPos.X.Offset,
                    currentPos.Y.Scale - 0.25,
                    currentPos.Y.Offset
                )
            end
        end
        voraFrame:Destroy()
    end
end

-- Helper: Update Stats logic
function updateStats()
    if not HideStatsEnabled then 
        removeAllScriptNames()
        return 
    end
    
    local character = Players.LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local overhead = hrp:FindFirstChild("Overhead")
    if not overhead or not overhead:IsA("BillboardGui") then return end
    
    for _, obj in pairs(overhead:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local fullPath = obj:GetFullName()
            if not OriginalTexts[fullPath] then
                OriginalTexts[fullPath] = obj.Text
            end
            
            local originalText = OriginalTexts[fullPath]
            if originalText and originalText ~= "" then
                if obj.Name == "Header" then
                    if not overhead:FindFirstChild("DevHubFrame") then
                        createScriptNameLabel(obj, overhead)
                    end
                    obj.Text = FakeName
                elseif string.find(string.lower(originalText), "lvl") then
                    obj.Text = string.gsub(originalText, "%d+", FakeLevel)
                end
            end
        end
    end
end

-- Auto-update loop
local updateLoopActive = false
function startUpdateLoop()
    if updateLoopActive then return end
    updateLoopActive = true
    spawn(function()
        while updateLoopActive and task.wait(0.2) do
            if HideStatsEnabled then
                updateStats()
            end
        end
    end)
end

SettingsTab:CreateInput({
	Name = "Hide Name",
	Placeholder = "Input Name",
	Default = FakeName,
    Callback = function(value)
        FakeName = value
        if HideStatsEnabled then updateStats() end
    end
})

SettingsTab:CreateInput({
	Name = "Hide Level",
	Placeholder = "Input Level",
	Default = FakeLevel,
    Callback = function(value)
        FakeLevel = value
        if HideStatsEnabled then updateStats() end
    end
})

SettingsTab:CreateToggle({
	Name = "Hide Identity",
	Default = false,
	Callback = function(state)
        HideStatsEnabled = state
        if state then
            startUpdateLoop()
            updateStats()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/CF-Trail/NameHider/main/MainScript.lua"))()
        else
            -- Restore original texts
            for path, originalText in pairs(OriginalTexts) do
                local obj = game
                for part in string.gmatch(path, "[^.]+") do
                    obj = obj:FindFirstChild(part)
                    if not obj then break end
                end
                if obj and obj:IsA("TextLabel") then
                    obj.Text = originalText
                end
            end
            removeAllScriptNames()
        end
    end
})

player.CharacterAdded:Connect(function(newChar)
    OriginalTexts = {}
    ActiveGradientThreads = {}
    task.wait(1)
    if HideStatsEnabled then
        updateStats()
    end
    
    -- Re-bind descendant monitor
    newChar.DescendantAdded:Connect(function(descendant)
        if HideStatsEnabled and descendant:IsA("BillboardGui") then
            task.wait(0.1)
            updateStats()
        end
    end)
end)

-- ============================================
-- CENTRALIZED SERVER HOP FUNCTION
-- ============================================

function ServerHop(reason, forcePublic)
	reason = reason or "Server hopping..."
	forcePublic = forcePublic or false
	
	-- Check if in private server (for notification only)
	local isPrivateServer = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
	
	-- Notify user
	if Window then
		local description = reason
		if isPrivateServer and forcePublic then
			description = description .. "\n(Leaving private server → public)"
		end
		
		Window:Notify({
			Title = "🔄 Server Hop",
			Content = description,
			Icon = "rbxassetid://7733920644",
			Duration = 3
		})
	end
	
	task.wait(0.5)

	
	local HttpService = game:GetService("HttpService")
	local TeleportService = game:GetService("TeleportService")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	
	local success, result = pcall(function()
		-- Try to get list of PUBLIC servers
		local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
		local response = game:HttpGet(url)
		local serverList = HttpService:JSONDecode(response)
		
		if serverList and serverList.data then
			-- Find best server (not current one, has space)
			for _, server in ipairs(serverList.data) do
				if server.id ~= game.JobId and server.playing < server.maxPlayers then
					print("[ServerHop] Found public server:", server.id)
					TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
					return true
				end
			end
		end
		
		-- No suitable server found
		warn("[ServerHop] No suitable public server found in list")
		return false
	end)
	
	-- If server list method failed, try fallback methods
	if not success or not result then
		warn("[ServerHop] Primary method failed, trying fallback...")
		print("[ServerHop] forcePublic =", forcePublic)
		print("[ServerHop] isPrivateServer =", isPrivateServer)
		
		-- If forcing public, use pagination to find available public servers
		if forcePublic then
			print("[ServerHop] Force public mode - using pagination to find servers...")
			
			local paginationSuccess = pcall(function()
				local servers = {}
				local cursor = ""
				local pageCount = 0
				local maxPages = 5 -- Limit to prevent infinite loop
				
				repeat
					pageCount = pageCount + 1
					local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
					if cursor ~= "" then
						url = url .. "&cursor=" .. cursor
					end
					
					print("[ServerHop] Fetching page", pageCount, "of servers...")
					local response = game:HttpGet(url)
					local serverData = HttpService:JSONDecode(response)
					
					for _, server in pairs(serverData.data) do
						if server.id ~= game.JobId and server.playing < server.maxPlayers then
							table.insert(servers, server.id)
							print("[ServerHop] Found available server:", server.id, "Players:", server.playing .. "/" .. server.maxPlayers)
						end
					end
					
					cursor = serverData.nextPageCursor or ""
				until #servers > 0 or cursor == "" or pageCount >= maxPages
				
				if #servers > 0 then
					-- Random select from available servers
					local selectedServer = servers[math.random(1, #servers)]
					print("[ServerHop] Selected random public server:", selectedServer, "from", #servers, "available")
					TeleportService:TeleportToPlaceInstance(game.PlaceId, selectedServer, LocalPlayer)
					return true
				else
					warn("[ServerHop] No available public servers found after checking", pageCount, "pages")
					return false
				end
			end)
			
			if paginationSuccess then
				print("[ServerHop] Successfully hopped to public server!")
				return
			end
			
			-- If pagination failed, show error - DO NOT use random Teleport!
			warn("[ServerHop] CRITICAL: Pagination failed, cannot find public server!")
			if Window then
				Window:Notify({
					Title = "❌ Server Hop Failed",
					Content = "Cannot find public servers.\nPlease try again later.",
					Icon = "rbxassetid://7733920644",
					Duration = 5
				})
			end
			return -- Abort hop to prevent going back to PS
		end
		
		-- If NOT forcing public (manual hop), allow rejoin fallback
		print("[ServerHop] Attempting fallback rejoin (forcePublic = false)")
		local rejoinSuccess = pcall(function()
			if isPrivateServer then
				-- Private server - rejoin same private
				warn("[ServerHop] Rejoining same private server")
				local teleportOptions = Instance.new("TeleportOptions")
				teleportOptions.ServerInstanceId = game.JobId
				teleportOptions.ReservedServerAccessCode = game.PrivateServerId
				TeleportService:TeleportAsync(game.PlaceId, {LocalPlayer}, teleportOptions)
			else
				-- Public server - rejoin via JobId
				print("[ServerHop] Rejoining same public server")
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
			end
		end)
		
		if rejoinSuccess then
			print("[ServerHop] Rejoin successful")
			return
		end
		
		-- Fallback 2: Only for manual hop - random public teleport
		warn("[ServerHop] Rejoin failed, using random public teleport")
		task.wait(0.5)
		pcall(function()
			print("[ServerHop] Executing random public teleport")
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end)
	end
end





SettingsTab:CreateSection({ Name = "Anti AFK", Icon = "rbxassetid://7733658504" })

-- ============================================
-- [SECURITY] State lokal untuk Anti AFK
-- ============================================
local AntiAFKEnabled = false  -- sesuai default UI
local antiAFKInitialized = false

-- Simpan daftar koneksi yang telah dimanipulasi agar bisa dikembalikan
local AFKConnections = {}
local AFKConnectionMonitor = nil  -- untuk mendeteksi koneksi baru setelah respawn

-- ============================================
-- Fungsi inti: Nonaktifkan atau aktifkan ulang semua koneksi Idled
-- ============================================
local function setAFKConnections(disable)
    local GC = getconnections or get_signal_cons
    if not GC then
        warn("[Anti AFK] getconnections not available")
        return false
    end

    local success = false
    local idleSignal = LocalPlayer.Idled

    -- Proses koneksi yang ada
    for _, connection in next, GC(idleSignal) do
        success = true
        if disable then
            connection:Disable()
        else
            connection:Enable()
        end
        -- Simpan untuk referensi nanti (hanya jika belum ada)
        if not table.find(AFKConnections, connection) then
            table.insert(AFKConnections, connection)
        end
    end

    return success
end

-- ============================================
-- Pemantau karakter: setiap respawn, terapkan ulang
-- ============================================
local function connectCharacterMonitor()
    if AFKConnectionMonitor then
        AFKConnectionMonitor:Disconnect()
        AFKConnectionMonitor = nil
    end

    AFKConnectionMonitor = LocalPlayer.CharacterAdded:Connect(function()
        if AntiAFKEnabled then
            task.wait(0.5)  -- tunggu sinyal siap
            setAFKConnections(true)
        end
    end)
end

-- Inisialisasi awal
if AntiAFKEnabled then
    setAFKConnections(true)
    connectCharacterMonitor()
end

-- ============================================
-- UI Toggle
-- ============================================
SettingsTab:CreateToggle({
    Name = "Anti AFK",
    Description = "Prevents you from being kicked for idling",
    Icon = "rbxassetid://7733658504",
    Default = false,
    Callback = function(value)
        AntiAFKEnabled = value
        if value then
            local success = setAFKConnections(true)
            if success then
                connectCharacterMonitor()
                print("[Anti AFK] Activated")
            else
                -- Fallback: gunakan cara lain jika getconnections tidak ada
                -- Beberapa executor bisa menggunakan setfflag atau Humanoid.Idle
                pcall(function()
                    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        -- Gunakan trik berbasis humanoid
                        humanoid.Idle:Connect(function()
                            -- Tidak melakukan apa-apa, mencegah idle
                        end)
                        print("[Anti AFK] Activated (Humanoid fallback)")
                    end
                end)
                Window:Notify({
                    Title = "Anti AFK",
                    Content = "Activated (fallback mode)",
                    Duration = 3
                })
            end
        else
            setAFKConnections(false)  -- pulihkan koneksi
            if AFKConnectionMonitor then
                AFKConnectionMonitor:Disconnect()
                AFKConnectionMonitor = nil
            end
            print("[Anti AFK] Deactivated")
        end
    end
})

SettingsTab:CreateSection({ Name = "Anti Pengganggu", Icon = "rbxassetid://7734053535" })

-- ============================================
-- [SECURITY] State lokal untuk Anti Pengganggu
-- ============================================
local antiPenggangguEnabled = false
local antiPenggangguConnection = nil
local FISH_GROUP_ID = 35102746

-- Fungsi aman untuk Server Hop (tanpa memerlukan _G atau global)
local function ForceServerHop(reason)
    if Window then
        Window:Notify({
            Title = "Server Hop",
            Content = reason or "Hopping...",
            Icon = "rbxassetid://7733920644",
            Duration = 3
        })
    end
    task.wait(0.5)
    -- Gunakan TeleportService yang sudah lokal di file utama
    local TeleportService = game:GetService("TeleportService")
    local LocalPlayer = Players.LocalPlayer
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- Cek apakah seorang player termasuk "pengganggu" (role selain Guest/Member)
local function IsPengganggu(player)
    local ok, role = pcall(function()
        return player:GetRoleInGroup(FISH_GROUP_ID)
    end)
    if not ok then return false end
    -- Hanya Guest dan Member yang tidak dianggap pengganggu, sisanya = pengganggu
    return (role ~= "Guest" and role ~= "Member")
end

-- Fungsi utama untuk memeriksa semua pemain dan melakukan hop jika ada pengganggu
local function CheckForPengganggu()
    if not antiPenggangguEnabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsPengganggu(player) then
            print("[Anti Pengganggu] Detected:", player.Name, "UserID:", player.UserId)
            ForceServerHop("⚠️ Pengganggu terdeteksi: " .. player.Name)
            break
        end
    end
end

-- ============================================
-- UI Toggle
-- ============================================
SettingsTab:CreateToggle({
    Name = "Anti Pengganggu",
    Description = "Automatically server hop when non-Member joins",
    Icon = "rbxassetid://7734053535",
    Default = false,
    Callback = function(value)
        antiPenggangguEnabled = value

        if value then
            Window:Notify({
                Title = "Anti Pengganggu Enabled",
                Content = "Avoiding all except Guest/Member",
                Icon = "rbxassetid://7734053535",
                Duration = 3
            })

            -- Jalankan pengecekan awal
            task.spawn(CheckForPengganggu)

            -- Pasang koneksi PlayerAdded
            if antiPenggangguConnection then
                antiPenggangguConnection:Disconnect()
            end
            antiPenggangguConnection = Players.PlayerAdded:Connect(function(player)
                task.wait(0.5)
                if antiPenggangguEnabled and player ~= LocalPlayer and IsPengganggu(player) then
                    print("[Anti Pengganggu] Joined:", player.Name, "UserID:", player.UserId)
                    ForceServerHop("⚠️ Pengganggu joined: " .. player.Name)
                end
            end)

            -- Loop pemantauan berkala
            task.spawn(function()
                while antiPenggangguEnabled do
                    CheckForPengganggu()
                    task.wait(5)
                end
            end)
        else
            -- Matikan
            if antiPenggangguConnection then
                antiPenggangguConnection:Disconnect()
                antiPenggangguConnection = nil
            end
            Window:Notify({
                Title = "Anti Pengganggu Disabled",
                Content = "No longer monitoring",
                Icon = "rbxassetid://7734053535",
                Duration = 2
            })
        end
    end
})
SettingsTab:CreateSection({ Name = "Server", Icon = "rbxassetid://7733955511" })

-- [SECURITY] State lokal untuk Server
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Fungsi untuk mendapatkan daftar server publik (jika executor mendukung HttpService)
local function getPublicServers(placeId, limit)
    limit = limit or 20
    local servers = {}
    
    -- Gunakan HttpService jika tersedia dan executor mengizinkan akses ke API Roblox
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=" .. limit
        local response = HttpService:RequestInternal({
            Url = url,
            Method = "GET"
        })
        return response
    end)
    
    if success and result and result.Success and result.Body then
        local data = HttpService:JSONDecode(result.Body)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing and server.maxPlayers and server.playing < server.maxPlayers then
                    table.insert(servers, {
                        jobId = server.id,
                        players = server.playing,
                        maxPlayers = server.maxPlayers,
                        ping = server.ping or nil  -- ping mungkin tidak selalu tersedia
                    })
                end
            end
        end
    end
    
    -- Jika tidak bisa mendapatkan daftar, fallback ke tabel kosong
    return servers
end

-- Fungsi untuk mengukur ping ke server tertentu (menggunakan trik sederhana)
local function pingServer(jobId)
    -- Di Roblox, kita tidak bisa ping langsung, tapi kita bisa estimasi dari respons API
    -- atau menggunakan trik TeleportService (tapi itu akan memutus koneksi).
    -- Untuk keperluan ini, kita akan menggunakan nilai acak sebagai fallback.
    return math.random(50, 300)  -- fallback, akan diganti dengan data asli jika API mendukung
end

-- Fungsi Server Hop dengan pilihan server berdasarkan ping rendah
local function serverHopLowPing(placeId, localPlayer)
    local servers = getPublicServers(placeId, 100)  -- ambil 100 server
    
    if #servers == 0 then
        -- Fallback: server hop biasa
        pcall(function()
            TeleportService:Teleport(placeId, localPlayer)
        end)
        return false, "No servers found, using normal hop"
    end
    
    -- Urutkan berdasarkan pemain (atau ping jika tersedia)
    table.sort(servers, function(a, b)
        -- Prioritaskan server dengan pemain lebih sedikit (agar lebih sepi)
        -- Jika ada data ping, gunakan itu
        if a.ping and b.ping then
            return a.ping < b.ping
        else
            return a.players < b.players
        end
    end)
    
    -- Pilih server pertama (terbaik)
    local bestServer = servers[1]
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, bestServer.jobId, localPlayer)
    end)
    
    if not success then
        -- Fallback ke teleport biasa
        pcall(function()
            TeleportService:Teleport(placeId, localPlayer)
        end)
        return false, "Best server failed, used normal hop"
    end
    
    return true, "Hopped to server with " .. bestServer.players .. " players"
end

-- Tombol Rejoin Server (perbaiki)
SettingsTab:CreateButton({
    Name = "Rejoin Server",
    SubText = "Reconnect to current server",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        local isPrivate = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
        local message = isPrivate and "Rejoining private server..." or "Rejoining server..."
        
        Window:Notify({
            Title = "Rejoining...",
            Content = message,
            Icon = "rbxassetid://7733920644",
            Duration = 2
        })
        
        task.wait(0.5)
        
        local success = pcall(function()
            if isPrivate then
                local teleportOptions = Instance.new("TeleportOptions")
                teleportOptions.ServerInstanceId = game.JobId
                teleportOptions.ReservedServerAccessCode = game.PrivateServerId
                TeleportService:TeleportAsync(game.PlaceId, {LocalPlayer}, teleportOptions)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
        
        if not success then
            task.wait(0.5)
            pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
        end
    end
})

-- Tombol Server Hop (dengan fitur pemindaian server rendah ping)
SettingsTab:CreateButton({
    Name = "Server Hop (Low Ping)",
    SubText = "Find and join a server with low ping",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        Window:Notify({
            Title = "Scanning Servers...",
            Content = "Looking for best server...",
            Duration = 2
        })
        
        -- Jalankan pemindaian di thread terpisah agar UI tidak freeze
        task.spawn(function()
            local success, msg = serverHopLowPing(game.PlaceId, LocalPlayer)
            if not success then
                Window:Notify({
                    Title = "Server Hop",
                    Content = msg or "Failed to hop",
                    Duration = 3
                })
            end
        end)
    end
})

local TabConfig = Window:CreateTab({
    Name = "Config",
    Icon = "rbxassetid://7733954611"
})

TabConfig:CreateSection({
    Name = "Configuration"
})

 configName = ""
 selectedConfig = ""
 configDropdown = nil
 CONFIG_FOLDER = "DevHubConfigs"

function sanitizeConfigName(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("[\\/:*?\"<>|]", "_")
    return name
end

function getConfigList()
    local result = {}
    if not (listfiles and isfolder) then
        return result
    end

    if not isfolder(CONFIG_FOLDER) and makefolder then
        makefolder(CONFIG_FOLDER)
    end

    for _, path in ipairs(listfiles(CONFIG_FOLDER)) do
        local name = path:match("([^/\\]+)%.json$")
        if name then
            table.insert(result, name)
        end
    end
    table.sort(result)
    return result
end

function RefreshConfigs()
    if configDropdown then
        configDropdown:Refresh(getConfigList())
    end
end

TabConfig:CreateInput({
    Name = "Config Name",
    Placeholder = "Enter config name...",
    Callback = function(text)
        configName = text
    end
})

configDropdown = TabConfig:CreateDropdown({
    Name = "Select Config",
    Options = getConfigList(),
    Callback = function(val)
        selectedConfig = val
    end
})

TabConfig:CreateButton({
    Name = "Create / Save Config",
    SubText = "Save settings to selected or new config",
    Callback = function()
        local name = (configName ~= "" and configName) or selectedConfig
        if name == "" then
             if Window and Window.Notify then
                Window:Notify({ Title = "Error", Content = "Please enter or select a config name.", Duration = 3 })
             end
             return
        end
        
        name = sanitizeConfigName(name)
        if name == "" then
            if Window and Window.Notify then
                Window:Notify({ Title = "Error", Content = "Invalid config name.", Duration = 3 })
            end
            return
        end

        local ok, err = Window:SaveConfig(CONFIG_FOLDER, name)
        if ok then
            RefreshConfigs()
            if Window and Window.Notify then
                Window:Notify({ Title = "Config Saved", Content = "Saved as " .. name, Duration = 3 })
            end
        elseif Window and Window.Notify then
            Window:Notify({ Title = "Save Failed", Content = tostring(err or "Unknown error"), Duration = 3 })
        end
    end
})

TabConfig:CreateButton({
    Name = "Load Config",
    SubText = "Load selected config",
    Callback = function()
        if selectedConfig == "" then
             if Window and Window.Notify then
                Window:Notify({ Title = "Error", Content = "Please select a config to load.", Duration = 3 })
             end
             return
        end

        local ok, err = Window:LoadConfig(CONFIG_FOLDER, selectedConfig)
        if ok then
            if Window and Window.Notify then
                Window:Notify({ Title = "Config Loaded", Content = "Loaded " .. selectedConfig, Duration = 3 })
            end
        elseif Window and Window.Notify then
            Window:Notify({ Title = "Load Failed", Content = tostring(err or "Unknown error"), Duration = 3 })
        end
    end
})

TabConfig:CreateButton({
    Name = "Delete Config",
    SubText = "Delete selected config",
    Callback = function()
        if selectedConfig == "" then return end
        local path = CONFIG_FOLDER .. "/" .. selectedConfig .. ".json"
        if delfile and isfile and isfile(path) then
            delfile(path)
            RefreshConfigs()
            selectedConfig = ""
            if Window and Window.Notify then
                Window:Notify({ Title = "Config Deleted", Content = "Deleted config file.", Duration = 3 })
            end
        elseif Window and Window.Notify then
            Window:Notify({ Title = "Delete Failed", Content = "Config file not found.", Duration = 3 })
        end
    end
})

TabConfig:CreateButton({
    Name = "Refresh List",
    SubText = "Refresh config list",
    Callback = function()
        RefreshConfigs()
    end
})

-- Auto Load Default Config
task.spawn(function()
    task.wait(2)
    Window:LoadConfig(CONFIG_FOLDER, "default")
end)
