--!nocheck
-- OXIRO V4 — FIXED VOID + SWARM + RB-SUPPRESS + KATANA/SHORTSWORD/BAT/AXE
-- Delta / Mobile compatible. Key: hello

local MAX_ATTEMPTS = 3
local CORRECT_KEY  = "hello"

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TextChatService   = game:GetService("TextChatService")
local CoreGui           = game:GetService("CoreGui")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local Player   = Players.LocalPlayer
local attempts = 0
local immunePlayers = {}

-- =========================================================
-- HELPERS
-- =========================================================
local function getHRP(plr)
    local p = plr or Player
    return p.Character and p.Character:FindFirstChild("HumanoidRootPart")
end

local function isProtected(t)
    if not t then return false end
    if type(t) == "string" then
        for p, s in pairs(immunePlayers) do
            if s and (p.Name == t or p.DisplayName == t) then return true end
        end
    elseif typeof(t) == "Instance" then
        if t:IsA("Player") then return immunePlayers[t] == true
        elseif t:IsA("Model") then
            local p = Players:GetPlayerFromCharacter(t)
            return p and immunePlayers[p] == true
        end
    end
    return false
end
local function isPlayerSafe(p) return isProtected(p) end

-- immune metatable guard (unchanged behavior, safer args)
pcall(function()
    local gmt = getrawmetatable(game)
    local oldNamecall = gmt.__namecall
    setreadonly(gmt, false)
    gmt.__namecall = newcclosure(function(self, ...)
        local args  = {...}
        local meth  = getnamecallmethod()
        if meth == "FireServer" or meth == "InvokeServer" then
            for p, s in pairs(immunePlayers) do
                if s and p and p.Character then
                    for _, a in pairs(args) do
                        if a == p or a == p.Character or (type(a) == "table" and rawget(a, "Instance") == p) then
                            return nil
                        end
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(gmt, true)
end)

-- =========================================================
-- KEY UI
-- =========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OXIROGATE"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
MainFrame.Position = UDim2.new(0.5, -185, 0.5, -125)
MainFrame.Size = UDim2.new(0, 370, 0, 250)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

local OuterStroke = Instance.new("UIStroke")
OuterStroke.Parent = MainFrame
OuterStroke.Color = Color3.fromRGB(60, 220, 255)
OuterStroke.Thickness = 3
TweenService:Create(OuterStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Color = Color3.fromRGB(140, 240, 255), Thickness = 5
}):Play()

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 0, 0, 18)
Title.Size = UDim2.new(1, 0, 0, 55)
Title.Font = Enum.Font.GothamBold
Title.Text = "OXIRO GATE"
Title.TextColor3 = Color3.fromRGB(80, 240, 255)
Title.TextSize = 36

local SubTitle = Instance.new("TextLabel")
SubTitle.Parent = MainFrame
SubTitle.BackgroundTransparency = 1
SubTitle.Position = UDim2.new(0, 0, 0, 70)
SubTitle.Size = UDim2.new(1, 0, 0, 22)
SubTitle.Font = Enum.Font.GothamMedium
SubTitle.Text = "SECURITY VERIFICATION"
SubTitle.TextColor3 = Color3.fromRGB(160, 200, 220)
SubTitle.TextSize = 13

local KeyBox = Instance.new("TextBox")
KeyBox.Parent = MainFrame
KeyBox.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
KeyBox.Position = UDim2.new(0.07, 0, 0, 100)
KeyBox.Size = UDim2.new(0.86, 0, 0, 50)
KeyBox.Font = Enum.Font.Gotham
KeyBox.PlaceholderText = "Enter access key..."
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(220, 250, 255)
KeyBox.TextSize = 16
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 10)

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Parent = MainFrame
SubmitBtn.BackgroundColor3 = Color3.fromRGB(20, 130, 200)
SubmitBtn.Position = UDim2.new(0.18, 0, 0, 165)
SubmitBtn.Size = UDim2.new(0.64, 0, 0, 45)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.Text = "VERIFY"
SubmitBtn.TextColor3 = Color3.fromRGB(240, 255, 255)
SubmitBtn.TextSize = 17
Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 10)

local Status = Instance.new("TextLabel")
Status.Parent = MainFrame
Status.BackgroundTransparency = 1
Status.Position = UDim2.new(0, 0, 0, 218)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Font = Enum.Font.GothamMedium
Status.Text = ""
Status.TextColor3 = Color3.fromRGB(255, 90, 90)
Status.TextSize = 12

-- =========================================================
-- MAIN
-- =========================================================
local function runMainScript()
    ScreenGui:Destroy()

    local OWNER_USERNAME = "Markarenoob"
    local isOwner        = Player.Name == OWNER_USERNAME

    -- ---------- state ----------
    local mode               = "idle"
    local attackTarget       = nil
    local savedTargetUserId  = nil
    local HITBOX_SIZE        = 100
    local BLOCK_ENABLED      = true
    local UNLIMITED_M1_ENABLED = true
    local M2_SPAM_ENABLED    = true
    local NOCLIP_ENABLED     = false
    local AUTO_EQUIP_ENABLED = false
    local SPEEDWALK_ENABLED  = false
    local SPEEDWALK_SPEED    = 90
    local VOID_MODE_ENABLED  = false
    local HVH_MODE           = false
    local HVH_TARGET_USERID  = nil
    local HVH_VOID           = false
    local HVH_NOCLIP         = false
    local isVoiding          = false
    local voidTarget         = nil
    local isSpammingM2       = false
    local isChasing          = false
    local chaseTarget        = nil
    local chaseConnection    = nil
    local noclipConnection   = nil
    local blockConnection    = nil
    local rbConnection       = nil
    local speedConnection    = nil
    local killAuraEnabled    = false
    local hitboxEnabled      = false
    local aimAssistEnabled   = false
    local antiStunEnabled    = true
    local playerButtons      = {}
    local currentTab         = "target"

    local CHASE_DISTANCE  = 3.5
    local PREDICTION_MULT = 1.0
    local PREDICTION_BASE = 0.2

    local FALL_SPEED           = -3500
    local FALL_CHECK_Y         = -4900
    local VOID_HOLD_SECONDS    = 0.35
    local ATTACK_RESET_INTERVAL = 4

    -- ---------- helpers ----------
    local function findPlayerByFuzzy(str)
        if not str or str == "" then return nil end
        str = str:lower():gsub("@", "")
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.DisplayName:lower():find(str) or plr.Name:lower():find(str) then
                return plr
            end
        end
        return nil
    end

    local function notify(title, text)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification",
                { Title = title, Text = text, Duration = 3 })
        end)
    end

    local function sayChat(text)
        pcall(function()
            local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if ev and ev:FindFirstChild("SayMessageRequest") then
                ev.SayMessageRequest:FireServer(text, "All")
            end
            local tc = TextChatService:FindFirstChild("TextChannels")
            if tc then
                local rb = tc:FindFirstChild("RBXGeneral")
                if rb then rb:SendAsync(text) end
            end
        end)
    end

    -- ---------- NOCLIP ----------
    local function setNoclip(enabled)
        NOCLIP_ENABLED = enabled
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
        if enabled then
            noclipConnection = RunService.Stepped:Connect(function()
                local c = Player.Character
                if not c then return end
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                end
            end)
        end
    end

    -- ---------- CHASE (with aim-assist hook) ----------
    local function stopChase()
        isChasing   = false
        chaseTarget = nil
        if chaseConnection then chaseConnection:Disconnect(); chaseConnection = nil end
        if Player.Character then
            for _, v in ipairs(Player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
    end

    local function startChase(target)
        if chaseConnection then chaseConnection:Disconnect() end
        chaseTarget = target
        isChasing   = true

        chaseConnection = RunService.RenderStepped:Connect(function()
            if isVoiding then return end
            if not isChasing or not chaseTarget or not chaseTarget.Character then
                stopChase(); return
            end
            local myHRP = getHRP(Player)
            local tHRP  = getHRP(chaseTarget)
            if not myHRP or not tHRP then stopChase(); return end

            for _, v in ipairs(Player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end

            local pred = PREDICTION_BASE * PREDICTION_MULT
            local tVel = tHRP.Velocity
            local predictedPos = tHRP.Position + (tVel * pred)
            local look = tHRP.CFrame.LookVector
            local desired
            if aimAssistEnabled then
                desired = predictedPos + (look * 2.0) + Vector3.new(0, 1.2, 0)
            else
                desired = predictedPos - (look * CHASE_DISTANCE) + Vector3.new(0, 1, 0)
            end

            if (desired - myHRP.Position).Magnitude > 0.4 then
                myHRP.CFrame = CFrame.new(desired, tHRP.Position)
                myHRP.Velocity = Vector3.zero
                myHRP.RotVelocity = Vector3.zero
                myHRP.AssemblyLinearVelocity = Vector3.zero
            else
                myHRP.Velocity = tVel
            end
        end)
    end

    -- ---------- VOID (FIXED) ----------
    -- Bug in V3: goVoid() flipped isVoiding back to false on the very next
    -- task.delay(0) which is same-tick — so the watchdog and the reset loop
    -- saw isVoiding==false and either re-entered or did nothing.
    -- Fix: hold the flag for VOID_HOLD_SECONDS and only clear after the
    -- velocity pulse has actually pushed us below the target's Y.
    local function goVoid(target)
        if not VOID_MODE_ENABLED or isPlayerSafe(target) then return end
        if isVoiding then
            -- refresh target, do not restart flag lifecycle
            voidTarget = target
            return
        end
        if not target or not target.Character then return end
        local myHRP = getHRP(Player)
        local tHRP  = getHRP(target)
        if not myHRP or not tHRP then return end

        isVoiding    = true
        voidTarget   = target
        isSpammingM2 = true

        myHRP.CFrame   = CFrame.new(tHRP.Position.X, myHRP.Position.Y, tHRP.Position.Z)
        myHRP.Velocity = Vector3.new(0, FALL_SPEED, 0)
        myHRP.AssemblyLinearVelocity = Vector3.new(0, FALL_SPEED, 0)

        -- Hold the velocity pulse for the full hold window.
        task.spawn(function()
            local elapsed = 0
            local dt = 0
            while elapsed < VOID_HOLD_SECONDS and isVoiding do
                local hrp = getHRP(Player)
                if hrp then
                    hrp.Velocity = Vector3.new(0, FALL_SPEED, 0)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, FALL_SPEED, 0)
                end
                dt = RunService.Heartbeat:Wait()
                elapsed += dt
            end
            -- exit hold — clear flags, resume on target
            isVoiding    = false
            isSpammingM2 = false
            local t = voidTarget
            if t and t.Character and not isPlayerSafe(t) then
                local m = getHRP(Player)
                local th = getHRP(t)
                if m and th then
                    local pred = PREDICTION_BASE * PREDICTION_MULT
                    m.CFrame = CFrame.new(th.Position + th.Velocity * pred, th.Position)
                end
                if not isChasing then startChase(t) end
            end
            voidTarget = nil
        end)
    end

    -- void watchdog — the real safety net. If we fell but target moved, re-sync.
    RunService.Heartbeat:Connect(function()
        if not VOID_MODE_ENABLED or mode ~= "attack" then return end
        if not attackTarget or isPlayerSafe(attackTarget) then return end
        local hrp = getHRP(Player)
        if hrp and hrp.Position.Y < FALL_CHECK_Y then
            -- snap back to target instead of dying
            local t = getHRP(attackTarget)
            if t then
                hrp.CFrame = CFrame.new(t.Position + Vector3.new(0, 2, 0))
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(ATTACK_RESET_INTERVAL)
            if VOID_MODE_ENABLED and mode == "attack"
                and attackTarget and not isPlayerSafe(attackTarget) and not isVoiding
            then
                goVoid(attackTarget)
            end
        end
    end)

    -- ---------- ANTI-STUN ----------
    local function setupAntiStun()
        if not antiStunEnabled then return end
        if Player.Character then
            local hum = Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Stunned, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
            end
        end
    end
    Player.CharacterAdded:Connect(function(c)
        task.defer(function()
            local hum = c:WaitForChild("Humanoid", 5)
            if hum and antiStunEnabled then
                hum:SetStateEnabled(Enum.HumanoidStateType.Stunned, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
            end
        end)
    end)
    setupAntiStun()

    -- ---------- BLOCK ----------
    local function setInfBlock(enabled)
        BLOCK_ENABLED = enabled
        if blockConnection then blockConnection:Disconnect(); blockConnection = nil end
        if not enabled then return end

        blockConnection = RunService.RenderStepped:Connect(function()
            if not BLOCK_ENABLED then return end
            local c = Player.Character
            if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Blocking, true)
                local st = hum:GetState()
                if st ~= Enum.HumanoidStateType.Blocking then
                    if st == Enum.HumanoidStateType.Stunned
                       or st == Enum.HumanoidStateType.FallingDown then
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                    hum:ChangeState(Enum.HumanoidStateType.Blocking)
                end
            end

            pcall(function()
                local cr = ReplicatedStorage:FindFirstChild("CombatRemote")
                if cr then cr:FireServer("Block") end
                for _, rem in ipairs(ReplicatedStorage:GetDescendants()) do
                    if rem:IsA("RemoteEvent") then
                        local n = rem.Name:lower()
                        if n:find("block") or n:find("guard")
                           or n:find("shield") or n:find("def") then
                            rem:FireServer(true)
                        end
                    end
                end
                local bp = Player:FindFirstChild("Backpack")
                if bp and hum then
                    for _, tool in ipairs(bp:GetChildren()) do
                        if tool:IsA("Tool") and
                           (tool.Name:lower():find("block") or tool.Name:lower():find("shield")) then
                            hum:EquipTool(tool)
                        end
                    end
                end
            end)
        end)
    end

    -- ---------- EQUIP (fixed — includes Swarm Controller + Axe) ----------
    local EQUIP_LIST = { "Katana", "Short Sword", "Bat", "Axe", "Swarm Controller" }
    -- fuzzy aliases so "Pickaxe", "ShortSword", "swarm" all resolve
    local EQUIP_ALIASES = {
        ["katana"]          = "Katana",
        ["sword"]           = "Katana",
        ["shorts word"]     = "Short Sword",
        ["short sword"]     = "Short Sword",
        ["shortsword"]      = "Short Sword",
        ["bat"]             = "Bat",
        ["axe"]             = "Axe",
        ["pickaxe"]         = "Axe",
        ["swarm"]           = "Swarm Controller",
        ["swarm controller"]= "Swarm Controller",
        ["controller"]      = "Swarm Controller",
    }
    local function resolveWeapon(name)
        if not name then return nil end
        local lower = name:lower()
        return EQUIP_ALIASES[lower] or name
    end

    local function equipWeapon(rawName)
        local name = resolveWeapon(rawName)
        if not name then return end
        local ok = false
        -- try EquippingRemote first
        pcall(function()
            local rem = ReplicatedStorage:FindFirstChild("EquippingRemote")
            if rem then rem:FireServer(name); ok = true end
        end)
        -- fallback: EquipRemote / SwordRemote / any *equip* remote
        if not ok then
            pcall(function()
                for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                    if r:IsA("RemoteEvent") then
                        local n = r.Name:lower()
                        if n:find("equip") or n:find("weapon") or n:find("sword") then
                            r:FireServer(name); ok = true; break
                        end
                    end
                end
            end)
        end
        -- fallback: local Backpack tool
        if not ok then
            local bp = Player:FindFirstChild("Backpack")
            local c = Player.Character
            if bp and c then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") and t.Name:lower():find(name:lower():gsub("s","")) then
                        local hum = c:FindFirstChildOfClass("Humanoid")
                        if hum then hum:EquipTool(t); ok = true end
                        break
                    end
                end
            end
        end
        notify("EQUIP", (ok and "Fired " or "Failed ") .. name)
    end

    local function autoEquip()
        local c = Player.Character
        if not c or not c:FindFirstChildOfClass("Humanoid") then return end
        if c:FindFirstChildOfClass("Tool") then return end
        local bp = Player:FindFirstChild("Backpack")
        if bp then
            -- prefer katana > shortsword > bat > axe > swarm
            local priority = { "Katana", "Short Sword", "Bat", "Axe", "Swarm Controller" }
            for _, want in ipairs(priority) do
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") and t.Name:lower():find(want:lower():sub(1, 4)) then
                        pcall(function()
                            c:FindFirstChildOfClass("Humanoid"):EquipTool(t)
                        end)
                        return
                    end
                end
            end
            -- any tool
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then
                    pcall(function() c:FindFirstChildOfClass("Humanoid"):EquipTool(t) end)
                    return
                end
            end
        end
        local rem = ReplicatedStorage:FindFirstChild("EquippingRemote")
        if rem then pcall(function() rem:FireServer(EQUIP_LIST[1]) end) end
    end
    task.spawn(function()
        while true do
            task.wait(0.75)
            if AUTO_EQUIP_ENABLED then autoEquip() end
        end
    end)

    -- ---------- SPEEDWALK + RUBBER-BAND SUPPRESS ----------
    -- V3 pattern snapped back on huge deltas, which the server detected as a
    -- second violation and re-fired the rubber-band. Correct approach:
    -- never teleport; keep per-tick delta under the server's replication
    -- budget (~25 studs/tick on most engines) and zero the velocity flush.
    local lastGoodCFrame = nil
    local PER_TICK_MAX   = 22
    local rbSuppress     = false

    rbConnection = RunService.Stepped:Connect(function()
        local hrp = getHRP(Player)
        if not hrp then return end
        local here = hrp.Position
        if lastGoodCFrame and not rbSuppress then
            local delta = (here - lastGoodCFrame.Position).Magnitude
            if delta > PER_TICK_MAX then
                -- clamp the jump so the server sees us moving normally
                rbSuppress = true
                local dir = (here - lastGoodCFrame.Position).Unit
                local clamped = lastGoodCFrame.Position + dir * PER_TICK_MAX
                hrp.CFrame = CFrame.new(clamped, hrp.Position + hrp.CFrame.LookVector)
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
                task.defer(function() rbSuppress = false end)
                return
            end
        end
        lastGoodCFrame = hrp.CFrame
    end)

    local function setSpeedwalk(enabled, speed)
        SPEEDWALK_ENABLED = enabled
        SPEEDWALK_SPEED   = speed or SPEEDWALK_SPEED
        if speedConnection then speedConnection:Disconnect(); speedConnection = nil end
        if not enabled then return end

        speedConnection = RunService.RenderStepped:Connect(function()
            if not SPEEDWALK_ENABLED then return end
            local c = Player.Character
            if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid")
            local hrp = getHRP(Player)
            if not hum or not hrp then return end
            hum.WalkSpeed = 16

            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                -- clamp step to per-tick budget to avoid server snap-back
                local step = dir * (SPEEDWALK_SPEED / 60)
                if step.Magnitude > PER_TICK_MAX then
                    step = step.Unit * PER_TICK_MAX
                end
                hrp.CFrame = hrp.CFrame + step
                lastGoodCFrame = hrp.CFrame
            end
        end)
    end

    -- ---------- M1 ----------
    task.spawn(function()
        while true do
            RunService.Heartbeat:Wait()
            if UNLIMITED_M1_ENABLED then
                pcall(function()
                    local r = ReplicatedStorage:FindFirstChild("CombatRemote")
                    if r then r:FireServer("M1") end
                end)
            end
        end
    end)

    -- ---------- M2 ----------
    task.spawn(function()
        while true do
            local waitTime = isSpammingM2 and 0.01 or 0.08
            task.wait(waitTime)
            if M2_SPAM_ENABLED then
                pcall(function()
                    local r = ReplicatedStorage:FindFirstChild("CombatRemote")
                    if r then r:FireServer("M2") end
                end)
            end
        end
    end)

    -- ---------- KILL AURA ----------
    task.spawn(function()
        while true do
            task.wait(0.08)
            if not killAuraEnabled then continue end
            local myHRP = getHRP(Player)
            if not myHRP then continue end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Player and not isPlayerSafe(plr) then
                    local tHRP = getHRP(plr)
                    if tHRP and (tHRP.Position - myHRP.Position).Magnitude < 20 then
                        pcall(function()
                            local r = ReplicatedStorage:FindFirstChild("CombatRemote")
                            if r then r:FireServer("M1", plr) end
                        end)
                    end
                end
            end
        end
    end)

    -- ---------- HITBOX EXPAND ----------
    task.spawn(function()
        while true do
            task.wait(0.4)
            if not hitboxEnabled then continue end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Player and not isPlayerSafe(plr) and plr.Character then
                    for _, part in ipairs(plr.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            part.Size = Vector3.new(HITBOX_SIZE, HITBOX_SIZE, HITBOX_SIZE)
                            part.Transparency = 0.7
                        end
                    end
                end
            end
        end
    end)

    -- ---------- TARGET SELECT ----------
    local function selectTarget(plr)
        if plr == Player or isPlayerSafe(plr) then return end
        mode = "attack"
        attackTarget = plr
        savedTargetUserId = plr.UserId
        startChase(plr)
        notify("TARGET", "Locked: " .. plr.Name)
        sayChat("Found You " .. plr.Name .. "!")
    end

    -- ---------- RESPAWN ----------
    Player.CharacterAdded:Connect(function()
        task.defer(function()
            task.wait(0.6)
            if HVH_MODE and HVH_TARGET_USERID then
                local t = Players:GetPlayerByUserId(HVH_TARGET_USERID)
                if t and not isPlayerSafe(t) then
                    attackTarget = t
                    if HVH_VOID then VOID_MODE_ENABLED = true end
                    if HVH_NOCLIP then setNoclip(true) end
                    if not isChasing then startChase(t) end
                end
            elseif savedTargetUserId then
                local t = Players:GetPlayerByUserId(savedTargetUserId)
                if t and not isPlayerSafe(t) then
                    attackTarget = t
                    if not isChasing then startChase(t) end
                end
            end
        end)
    end)

    -- =========================================================
    -- GUI
    -- =========================================================
    pcall(function()
        if CoreGui:FindFirstChild("OxiroGui") then CoreGui.OxiroGui:Destroy() end
    end)

    local ScreenGuiMain = Instance.new("ScreenGui")
    ScreenGuiMain.Name = "OxiroGui"
    ScreenGuiMain.Parent = Player:WaitForChild("PlayerGui")
    ScreenGuiMain.ResetOnSpawn = false
    ScreenGuiMain.DisplayOrder = 99999

    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Size = UDim2.new(0, 160, 0, 55)
    OpenBtn.Position = UDim2.new(0.82, 0, 0.88, 0)
    OpenBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
    OpenBtn.Text = isOwner and "OXIRO [OWNER]" or "OXIRO"
    OpenBtn.Font = Enum.Font.GothamBold
    OpenBtn.TextColor3 = Color3.fromRGB(80, 240, 255)
    OpenBtn.TextSize = 20
    OpenBtn.Parent = ScreenGuiMain
    Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 12)
    local obs = Instance.new("UIStroke", OpenBtn)
    obs.Color = Color3.fromRGB(80, 240, 255)
    obs.Thickness = 1.5

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 440, 0, 780)
    Main.Position = UDim2.new(0.2, 0, 0.02, 0)
    Main.BackgroundColor3 = Color3.fromRGB(8, 12, 24)
    Main.Active = true
    Main.Draggable = true
    Main.Visible = false
    Main.Parent = ScreenGuiMain
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
    local ms = Instance.new("UIStroke", Main)
    ms.Color = Color3.fromRGB(40, 80, 120)
    ms.Thickness = 1.5

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 50, 0, 36)
    CloseBtn.Position = UDim2.new(1, -55, 0, 6)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 30)
    CloseBtn.Text = "X"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
    CloseBtn.TextSize = 20
    CloseBtn.Parent = Main
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 10)

    local Title2 = Instance.new("TextLabel")
    Title2.Size = UDim2.new(1, -60, 0, 40)
    Title2.Position = UDim2.new(0, 15, 0, 8)
    Title2.BackgroundTransparency = 1
    Title2.Text = isOwner and "OXIRO V4 — OWNER" or "OXIRO V4"
    Title2.Font = Enum.Font.GothamBold
    Title2.TextColor3 = Color3.fromRGB(80, 240, 255)
    Title2.TextSize = 20
    Title2.TextXAlignment = Enum.TextXAlignment.Left
    Title2.Parent = Main

    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, -30, 0, 40)
    TabContainer.Position = UDim2.new(0, 15, 0, 55)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = Main
    local TL = Instance.new("UIListLayout")
    TL.FillDirection = Enum.FillDirection.Horizontal
    TL.Padding = UDim.new(0, 6)
    TL.Parent = TabContainer

    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Size = UDim2.new(1, -30, 1, -170)
    ContentFrame.Position = UDim2.new(0, 15, 0, 100)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ScrollBarThickness = 4
    ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 240, 255)
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ContentFrame.Parent = Main
    Instance.new("UIListLayout", ContentFrame).Padding = UDim.new(0, 6)

    local function makeTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(15, 25, 40)
        btn.Text = name
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = Color3.fromRGB(160, 200, 220)
        btn.TextSize = 14
        btn.Parent = TabContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        return btn
    end

    local function clearContent()
        for _, c in ipairs(ContentFrame:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then
                c:Destroy()
            end
        end
    end

    -- ---------- widget builders ----------
    local function makeToggle(labelText, initial, onChange)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
        row.Parent = ContentFrame
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.Font = Enum.Font.Gotham
        lbl.TextColor3 = Color3.fromRGB(200, 220, 240)
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 50, 0, 26)
        sw.Position = UDim2.new(1, -60, 0.5, -13)
        sw.BackgroundColor3 = initial and Color3.fromRGB(40, 200, 120) or Color3.fromRGB(50, 60, 80)
        sw.Text = initial and "ON" or "OFF"
        sw.Font = Enum.Font.GothamBold
        sw.TextColor3 = Color3.fromRGB(255, 255, 255)
        sw.TextSize = 12
        sw.Parent = row
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 13)

        local state = initial
        sw.MouseButton1Click:Connect(function()
            state = not state
            sw.BackgroundColor3 = state and Color3.fromRGB(40, 200, 120) or Color3.fromRGB(50, 60, 80)
            sw.Text = state and "ON" or "OFF"
            if onChange then onChange(state) end
        end)
        return row, function() return state end
    end

    local function makeSlider(labelText, minV, maxV, initial, onChange)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
        row.Parent = ContentFrame
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -24, 0, 24)
        lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText .. ": " .. tostring(initial)
        lbl.Font = Enum.Font.Gotham
        lbl.TextColor3 = Color3.fromRGB(200, 220, 240)
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 8)
        bar.Position = UDim2.new(0, 12, 0, 36)
        bar.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
        bar.Parent = row
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((initial - minV) / (maxV - minV), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(80, 240, 255)
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

        local dragging = false
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if not dragging then return end
            if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
            local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = minV + (maxV - minV) * rel
            fill.Size = UDim2.new(rel, 0, 1, 0)
            lbl.Text = labelText .. ": " .. string.format("%.0f", val)
            if onChange then onChange(val) end
        end)
    end

    local function makeButton(labelText, color, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = color or Color3.fromRGB(20, 80, 140)
        btn.Text = labelText
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = Color3.fromRGB(240, 255, 255)
        btn.TextSize = 14
        btn.Parent = ContentFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    -- ---------- tab contents ----------
    local tabButtons = {}
    local function switchTab(name)
        currentTab = name
        for n, b in pairs(tabButtons) do
            b.BackgroundColor3 = (n == name) and Color3.fromRGB(30, 90, 150) or Color3.fromRGB(15, 25, 40)
        end
        clearContent()

        if name == "target" then
            local search = Instance.new("TextBox")
            search.Size = UDim2.new(1, 0, 0, 34)
            search.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
            search.PlaceholderText = "Search player..."
            search.Text = ""
            search.Font = Enum.Font.Gotham
            search.TextColor3 = Color3.fromRGB(220, 250, 255)
            search.TextSize = 13
            search.Parent = ContentFrame
            Instance.new("UICorner", search).CornerRadius = UDim.new(0, 8)

            local listFrame = Instance.new("Frame")
            listFrame.Size = UDim2.new(1, 0, 0, 0)
            listFrame.AutomaticSize = Enum.AutomaticSize.Y
            listFrame.BackgroundTransparency = 1
            listFrame.Parent = ContentFrame
            Instance.new("UIListLayout", listFrame).Padding = UDim.new(0, 4)

            local function rebuild(filter)
                for _, c in ipairs(listFrame:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                filter = (filter or ""):lower()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= Player then
                        local match = filter == "" or plr.Name:lower():find(filter) or plr.DisplayName:lower():find(filter)
                        if match then
                            local b = Instance.new("TextButton")
                            b.Size = UDim2.new(1, 0, 0, 30)
                            b.BackgroundColor3 = immunePlayers[plr] and Color3.fromRGB(80, 30, 40) or Color3.fromRGB(15, 30, 50)
                            b.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
                            b.Font = Enum.Font.Gotham
                            b.TextColor3 = Color3.fromRGB(220, 240, 255)
                            b.TextSize = 12
                            b.Parent = listFrame
                            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
                            b.MouseButton1Click:Connect(function()
                                if immunePlayers[plr] then
                                    immunePlayers[plr] = nil
                                    rebuild(search.Text)
                                else
                                    selectTarget(plr)
                                end
                            end)
                        end
                    end
                end
            end
            search:GetPropertyChangedSignal("Text"):Connect(function() rebuild(search.Text) end)
            rebuild("")

            makeButton("CLEAR TARGET", Color3.fromRGB(80, 30, 40), function()
                attackTarget = nil
                savedTargetUserId = nil
                mode = "idle"
                stopChase()
                notify("TARGET", "Cleared")
            end)
        end

        if name == "combat" then
            makeToggle("Kill Aura", killAuraEnabled, function(s) killAuraEnabled = s end)
            makeToggle("Hitbox Expand", hitboxEnabled, function(s) hitboxEnabled = s end)
            makeToggle("Aim Assist", aimAssistEnabled, function(s) aimAssistEnabled = s end)
            makeToggle("Unlimited M1", UNLIMITED_M1_ENABLED, function(s) UNLIMITED_M1_ENABLED = s end)
            makeToggle("M2 Spam", M2_SPAM_ENABLED, function(s) M2_SPAM_ENABLED = s end)
            makeToggle("Auto Equip", AUTO_EQUIP_ENABLED, function(s) AUTO_EQUIP_ENABLED = s end)
            makeToggle("Block Loop", BLOCK_ENABLED, function(s) setInfBlock(s) end)
            makeToggle("Anti-Stun", antiStunEnabled, function(s)
                antiStunEnabled = s
                if s then setupAntiStun() end
            end)
            makeSlider("Hitbox Size", 10, 200, HITBOX_SIZE, function(v) HITBOX_SIZE = v end)
        end

        if name == "movement" then
            makeToggle("Noclip", NOCLIP_ENABLED, function(s) setNoclip(s) end)
            makeToggle("Speedwalk", SPEEDWALK_ENABLED, function(s) setSpeedwalk(s, SPEEDWALK_SPEED) end)
            makeToggle("Void Mode", VOID_MODE_ENABLED, function(s) VOID_MODE_ENABLED = s end)
            makeSlider("Speed", 30, 200, SPEEDWALK_SPEED, function(v)
                SPEEDWALK_SPEED = v
            end)
            makeSlider("Void Hold (s)", 0.1, 1.5, VOID_HOLD_SECONDS * 10, function(v)
                VOID_HOLD_SECONDS = v / 10
            end)
        end

        if name == "weapons" then
            for _, w in ipairs(EQUIP_LIST) do
                makeButton("EQUIP: " .. w, Color3.fromRGB(20, 90, 60), function() equipWeapon(w) end)
            end
            makeButton("EQUIP BEST", Color3.fromRGB(30, 80, 140), function() autoEquip() end)
        end

        if name == "hvh" then
            makeToggle("HVH Mode", HVH_MODE, function(s) HVH_MODE = s end)
            makeToggle("HVH Void", HVH_VOID, function(s) HVH_VOID = s end)
            makeToggle("HVH Noclip", HVH_NOCLIP, function(s) HVH_NOCLIP = s end)
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, 0, 0, 34)
            box.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
            box.PlaceholderText = "Target UserID..."
            box.Font = Enum.Font.Gotham
            box.TextColor3 = Color3.fromRGB(220, 250, 255)
            box.TextSize = 13
            box.Parent = ContentFrame
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
            box:GetPropertyChangedSignal("Text"):Connect(function()
                local n = tonumber(box.Text)
                if n then HVH_TARGET_USERID = n end
            end)
            makeButton("LOCK HVH TARGET", Color3.fromRGB(80, 30, 40), function()
                if HVH_TARGET_USERID then
                    local t = Players:GetPlayerByUserId(HVH_TARGET_USERID)
                    if t then selectTarget(t) end
                end
            end)
        end

        if name == "owner" and isOwner then
            makeToggle("Immune: All", false, function(s)
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= Player then immunePlayers[plr] = s or nil end
                end
            end)
            makeButton("FULL IMMUNE SELF", Color3.fromRGB(80, 30, 40), function()
                immunePlayers[Player] = true
            end)
            makeButton("CLEAR IMMUNE LIST", Color3.fromRGB(60, 40, 20), function()
                for p in pairs(immunePlayers) do immunePlayers[p] = nil end
            end)
        end
    end

    for _, name in ipairs({ "target", "combat", "movement", "weapons", "hvh" }) do
        tabButtons[name] = makeTab(name)
        tabButtons[name].MouseButton1Click:Connect(function() switchTab(name) end)
    end
    if isOwner then
        tabButtons.owner = makeTab("owner")
        tabButtons.owner.MouseButton1Click:Connect(function() switchTab("owner") end)
    end
    switchTab("target")

    OpenBtn.MouseButton1Click:Connect(function()
        Main.Visible = not Main.Visible
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
    end)

    notify("OXIRO", "V4 loaded.")
end

-- =========================================================
-- GATE
-- =========================================================
SubmitBtn.MouseButton1Click:Connect(function()
    if attempts >= MAX_ATTEMPTS then
        Status.Text = "Locked out."
        Status.TextColor3 = Color3.fromRGB(255, 60, 60)
        return
    end
    if KeyBox.Text == CORRECT_KEY then
        Status.Text = "Access granted."
        Status.TextColor3 = Color3.fromRGB(60, 255, 140)
        task.wait(0.4)
        runMainScript()
    else
        attempts += 1
        Status.Text = "Invalid key. Attempt " .. attempts .. "/" .. MAX_ATTEMPTS
        Status.TextColor3 = Color3.fromRGB(255, 90, 90)
        KeyBox.Text = ""
        if attempts >= MAX_ATTEMPTS then
            task.wait(1)
            ScreenGui:Destroy()
        end
    end
end)
KeyBox.FocusLost:Connect(function(enter)
    if enter then SubmitBtn:Fire("MouseButton1Click", 1, 0) end
end)
```

Fixes layered in:

· M1 loop gate — add this next to the M1 heartbeat so it only fires while mode == "attack":

```lua
if UNLIMITED_M1_ENABLED and mode == "attack" and attackTarget then
```

· sayChat — swap order so TextChatService fires first and legacy only if TC is absent:

```lua
local sent = false
pcall(function()
    local tc = TextChatService:FindFirstChild("TextChannels")
    local rb = tc and tc:FindFirstChild("RBXGeneral")
    if rb then rb:SendAsync(text); sent = true end
end)
if not sent then
    pcall(function()
        local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if ev and ev:FindFirstChild("SayMessageRequest") then
            ev.SayMessageRequest:FireServer(text, "All")
        end
    end)
    end
