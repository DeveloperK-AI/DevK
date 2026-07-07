-- ============================================
-- [SECURITY] Disguise Module (Professional Refactor)
-- ============================================
local Disguise = (function()
    -- Konfigurasi lokal (tidak lagi getgenv)
    local Config = {
        Headless = false,
        FakeDisplayName = "AmySchumer",
        FakeName = "redmiint8",
        FakeId = 13886182,
    }

    -- API untuk mengubah konfigurasi dari UI
    local function SetFakeDisplayName(name) Config.FakeDisplayName = tostring(name) end
    local function SetFakeName(name) Config.FakeName = tostring(name) end
    local function SetFakeId(id) Config.FakeId = tonumber(id) or Config.FakeId end
    local function SetHeadless(enabled) Config.Headless = enabled and true or false end

    -- State internal
    local isEnabled = false
    local disguiseConnection = nil
    local headlessConnection = nil
    local processedObjects = {}  -- untuk tracking objek yang sudah diproses

    -- Fungsi untuk memproses teks (mengganti nama/id/display)
    local function processText(text)
        if type(text) ~= "string" then return text end
        local newText = text
        -- Ganti dengan nama palsu jika ditemukan data asli (disimpan saat modul diaktifkan)
        if disguiseInfo then
            newText = string.gsub(newText, disguiseInfo.oldName, Config.FakeName)
            newText = string.gsub(newText, disguiseInfo.oldUserId, tostring(Config.FakeId))
            newText = string.gsub(newText, disguiseInfo.oldDisplayName, Config.FakeDisplayName)
        end
        return newText
    end

    -- Fungsi disguise karakter (dipanggil ulang saat respawn)
    local function disguiseCharacter(char, id)
        task.spawn(function()
            pcall(function()
                if not char or not char.Parent then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum then return end

                -- Ambil deskripsi target dengan retry
                local desc = nil
                local attempts = 0
                repeat
                    attempts = attempts + 1
                    pcall(function()
                        desc = Players:GetHumanoidDescriptionFromUserId(id)
                    end)
                    if not desc then task.wait(0.5) end
                until desc or attempts >= 10

                if not desc then
                    warn("[Disguise] Failed to get description for ID", id)
                    return
                end

                -- Simpan tinggi badan asli
                local humDesc = hum:FindFirstChildOfClass("HumanoidDescription")
                if humDesc then
                    desc.HeightScale = humDesc.HeightScale
                end

                -- Clone karakter untuk mengambil aset
                char.Archivable = true
                local disguiseClone = char:Clone()
                disguiseClone.Name = "DisguiseTemp"
                disguiseClone.Parent = workspace

                -- Hapus aksesori lama dari clone (kita hanya butuh yang dari ID baru)
                for _, item in ipairs(disguiseClone:GetChildren()) do
                    if item:IsA("Accessory") or item:IsA("ShirtGraphic") or item:IsA("Shirt") or item:IsA("Pants") then
                        item:Destroy()
                    end
                end

                -- Terapkan deskripsi baru ke clone
                disguiseClone.Humanoid:ApplyDescriptionClientServer(desc)

                -- Hapus item tubuh asli (kecuali yang dari inventory/armor)
                for _, item in ipairs(char:GetChildren()) do
                    if (item:IsA("Accessory") and item:GetAttribute("InvItem") == nil and item:GetAttribute("ArmorSlot") == nil) or
                       item:IsA("ShirtGraphic") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("BodyColors") then
                        item.Parent = game
                    end
                end

                -- Cegah item baru asli muncul
                disguiseConnection = char.ChildAdded:Connect(function(item)
                    if (item:IsA("Accessory") and item:GetAttribute("InvItem") == nil and item:GetAttribute("ArmorSlot") == nil) or
                       item:IsA("ShirtGraphic") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("BodyColors") then
                        if item:GetAttribute("Disguise") == nil then
                            repeat task.wait() item.Parent = game until item.Parent == game
                        end
                    end
                end)

                -- Pindahkan animasi dari clone ke asli
                if disguiseClone:FindFirstChild("Animate") then
                    for _, animObj in ipairs(disguiseClone.Animate:GetChildren()) do
                        animObj:SetAttribute("Disguise", true)
                        local realAnim = char.Animate:FindFirstChild(animObj.Name)
                        if animObj:IsA("StringValue") and realAnim then
                            realAnim.Parent = game
                            animObj.Parent = char.Animate
                        end
                    end
                end

                -- Pindahkan semua item dari clone ke karakter asli
                for _, item in ipairs(disguiseClone:GetChildren()) do
                    item:SetAttribute("Disguise", true)
                    if item:IsA("Accessory") then
                        -- Sambungkan weld ke bagian tubuh asli
                        for _, weld in ipairs(item:GetDescendants()) do
                            if weld:IsA("Weld") and weld.Part1 then
                                local realPart = char:FindFirstChild(weld.Part1.Name)
                                if realPart then weld.Part1 = realPart end
                            end
                        end
                        item.Parent = char
                    elseif item:IsA("ShirtGraphic") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("BodyColors") then
                        item.Parent = char
                    elseif item.Name == "Head" and item:FindFirstChildOfClass("SpecialMesh") then
                        local mesh = char.Head:FindFirstChildOfClass("SpecialMesh")
                        if mesh then mesh.MeshId = item:FindFirstChildOfClass("SpecialMesh").MeshId end
                    end
                end

                -- Pindahkan wajah
                local realFace = char:FindFirstChild("face", true)
                local cloneFace = disguiseClone:FindFirstChild("face", true)
                if realFace and cloneFace then
                    realFace.Parent = game
                    cloneFace.Parent = char.Head
                end

                -- Salin emote
                local emotes = desc:GetEmotes()
                local equippedEmotes = desc:GetEquippedEmotes()
                if emotes then hum.HumanoidDescription:SetEmotes(emotes) end
                if equippedEmotes then hum.HumanoidDescription:SetEquippedEmotes(equippedEmotes) end

                disguiseClone:Destroy()
            end)
        end)
    end

    -- Info karakter asli (disimpan saat modul diaktifkan)
    local disguiseInfo = nil

    -- Fungsi untuk memproses semua teks di game (sekali jalan dan hook)
    local function hookTextProcessing()
        -- Proses semua objek teks yang ada
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("TextBox") or obj:IsA("TextLabel") or obj:IsA("TextButton") then
                if not processedObjects[obj] then
                    processedObjects[obj] = true
                    obj.Text = processText(obj.Text)
                    obj.Name = processText(obj.Name)
                    obj.Changed:Connect(function(prop)
                        if prop == "Text" then
                            obj.Text = processText(obj.Text)
                        elseif prop == "Name" then
                            obj.Name = processText(obj.Name)
                        end
                    end)
                end
            end
        end

        -- Hook objek baru
        game.DescendantAdded:Connect(function(desc)
            if desc:IsA("TextBox") or desc:IsA("TextLabel") or desc:IsA("TextButton") then
                if not processedObjects[desc] then
                    processedObjects[desc] = true
                    desc.Text = processText(desc.Text)
                    desc.Name = processText(desc.Name)
                    desc.Changed:Connect(function(prop)
                        if prop == "Text" then
                            desc.Text = processText(desc.Text)
                        elseif prop == "Name" then
                            desc.Name = processText(desc.Name)
                        end
                    end)
                end
            end
        end)
    end

    -- Aktifkan modul
    local function Enable()
        if isEnabled then return end
        isEnabled = true

        -- Simpan identitas asli
        disguiseInfo = {
            oldName = LocalPlayer.Name,
            oldUserId = tostring(LocalPlayer.UserId),
            oldDisplayName = LocalPlayer.DisplayName,
        }

        -- Ubah tampilan nama di leaderboard/dll
        if Config.FakeDisplayName then
            LocalPlayer.DisplayName = Config.FakeDisplayName
        end
        if Config.FakeId then
            LocalPlayer.CharacterAppearanceId = Config.FakeId
        end

        -- Disguise karakter sekarang
        if LocalPlayer.Character then
            disguiseCharacter(LocalPlayer.Character, Config.FakeId)
        end

        -- Hook respawn
        LocalPlayer.CharacterAdded:Connect(function(char)
            if isEnabled then
                disguiseCharacter(char, Config.FakeId)
            end
        end)

        -- Headless mode
        if Config.Headless then
            headlessConnection = game:GetService("RunService").RenderStepped:Connect(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Head") then
                    char.Head.Transparency = 1
                    local decal = char.Head:FindFirstChildOfClass("Decal")
                    if decal then decal:Destroy() end
                end
            end)
        end

        -- Proses teks UI
        hookTextProcessing()
    end

    -- Nonaktifkan modul & bersihkan
    local function Disable()
        isEnabled = false

        -- Kembalikan nama asli
        if disguiseInfo then
            pcall(function() LocalPlayer.DisplayName = disguiseInfo.oldDisplayName end)
            pcall(function() LocalPlayer.CharacterAppearanceId = tonumber(disguiseInfo.oldUserId) end)
            disguiseInfo = nil
        end

        -- Putus koneksi
        if disguiseConnection then
            disguiseConnection:Disconnect()
            disguiseConnection = nil
        end
        if headlessConnection then
            headlessConnection:Disconnect()
            headlessConnection = nil
        end

        -- Kembalikan kepala
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Head") then
            char.Head.Transparency = 0
        end

        -- Bersihkan processedObjects (opsional)
        processedObjects = {}
    end

    -- API yang dikembalikan
    return {
        Enable = Enable,
        Disable = Disable,
        SetFakeDisplayName = SetFakeDisplayName,
        SetFakeName = SetFakeName,
        SetFakeId = SetFakeId,
        SetHeadless = SetHeadless,
        IsEnabled = function() return isEnabled end,
    }
end)()

-- ============================================
-- UI Integration (PlayerTab atau ExclusiveTab)
-- ============================================
PlayerTab:CreateSection({ Name = "Disguise" })

-- Input untuk identitas palsu
PlayerTab:CreateInput({
    Name = "Fake Display Name",
    Placeholder = "Enter fake display name",
    Default = "AmySchumer",
    Callback = function(val)
        Disguise.SetFakeDisplayName(val)
    end
})

PlayerTab:CreateInput({
    Name = "Fake Username",
    Placeholder = "Enter fake username",
    Default = "redmiint8",
    Callback = function(val)
        Disguise.SetFakeName(val)
    end
})

PlayerTab:CreateInput({
    Name = "Fake User ID",
    Placeholder = "Enter fake user ID",
    Default = "13886182",
    Callback = function(val)
        Disguise.SetFakeId(tonumber(val))
    end
})

PlayerTab:CreateToggle({
    Name = "Headless Mode",
    Default = false,
    Callback = function(val)
        Disguise.SetHeadless(val)
    end
})

PlayerTab:CreateToggle({
    Name = "Enable Disguise",
    Default = false,
    Callback = function(val)
        if val then
            Disguise.Enable()
        else
            Disguise.Disable()
        end
    end
})
