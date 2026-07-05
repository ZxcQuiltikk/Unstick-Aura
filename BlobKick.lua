local Tabs = getgenv().UI.Tabs
local Sect = getgenv().UI.Sect

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Heartbeat = RunService.Heartbeat
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local selectedTarget = nil
local kickLoopEnabled = false

local GE = ReplicatedStorage:WaitForChild("GrabEvents")
local SNO = GE:WaitForChild("SetNetworkOwner")
local CreateGrabLine = GE:WaitForChild("CreateGrabLine")
local DestroyGrabLine = GE:WaitForChild("DestroyGrabLine")

local function GetPlayerOptions()
    local options = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(options, player.Name .. " (" .. player.DisplayName .. ")")
        end
    end
    return options
end

local PlayerSelectDropdown
PlayerSelectDropdown = Sect.PlayersBlobSection:AddDropdown({
    Name = "Select Target",
    Options = GetPlayerOptions(),
    Default = "",
    Search = true,
    MaxSize = 6,
    Flag = "BlobPlayerDropdown",
    Callback = function(option)
        selectedTarget = option and option ~= "" and Players:FindFirstChild(option:match("^(.+)%s%(") or option) or nil
    end
})

Sect.PlayersBlobSection:AddButton({
    Name = "Refresh List",
    Callback = function()
        PlayerSelectDropdown:SetValues(GetPlayerOptions())
    end
})

local function updateDropdown()
    PlayerSelectDropdown:SetValues(GetPlayerOptions())
end

Players.PlayerAdded:Connect(updateDropdown)
Players.PlayerRemoving:Connect(updateDropdown)

task.spawn(function()
    while task.wait(4) do
        updateDropdown()
    end
end)

Sect.PlayersBlobSection:AddToggle({
    Name = "Loop Kick",
    Default = false,
    Flag = "LoopKick",
    Binded = true,
    DefaultBind = "",
    Settings = false,
    Callback = function(on)
        kickLoopEnabled = on

        if on and not selectedTarget then
            kickLoopEnabled = false
            return
        end

        local seat = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.SeatPart
        if on and (not seat or seat.Parent.Name ~= "CreatureBlobman") then
            kickLoopEnabled = false
            return
        end

        if not on then
            kickLoopEnabled = false
            return
        end

        task.spawn(function()
            local blob = seat.Parent
            local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
            local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")

            local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
            local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
            local R_Det = blob:FindFirstChild("RightDetector")
            local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld"))

            local SavedPos = blobRoot.CFrame
            local lockPos = SavedPos * CFrame.new(0, 19, 0)
            local packetCount = 0
            local wasDead = false

            local function TeleportToTarget()
                local tRoot = selectedTarget.Character and selectedTarget.Character:FindFirstChild("HumanoidRootPart")
                if tRoot and blobRoot then
                    blobRoot.CFrame = tRoot.CFrame
                    blobRoot.Velocity = Vector3.zero
                    if CG and R_Det then CG:FireServer(R_Det, tRoot, R_Weld) end
                    CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                    SNO:FireServer(tRoot, tRoot.CFrame)
                    task.wait(0.5)
                    blobRoot.CFrame = SavedPos
                    blobRoot.Velocity = Vector3.zero
                end
            end

            TeleportToTarget()

            while kickLoopEnabled and selectedTarget and selectedTarget.Parent do
                local tChar = selectedTarget.Character
                local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar and tChar:FindFirstChild("Humanoid")

                if not tHum or not tRoot then
                    Heartbeat:Wait()
                    continue
                end

                if tHum.Health > 0 and wasDead then
                    wasDead = false
                    TeleportToTarget()
                    Heartbeat:Wait()
                    continue
                end

                if tHum.Health <= 0 then
                    wasDead = true
                    Heartbeat:Wait()
                    continue
                end

                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero

                tRoot.CFrame = lockPos
                tRoot.Velocity = Vector3.zero
                tRoot.RotVelocity = Vector3.zero

                if tRoot.AssemblyLinearVelocity then
                    tRoot.AssemblyLinearVelocity = Vector3.zero
                    tRoot.AssemblyAngularVelocity = Vector3.zero
                end

                SNO:FireServer(tRoot, lockPos)

                packetCount = packetCount + 1
                if packetCount >= 2 then
                    packetCount = 0
                    tHum.PlatformStand = true
                    tHum.Sit = true

                    if R_Det then
                        local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                        if weld and CD then CD:FireServer(weld) end
                    end

                    DestroyGrabLine:FireServer(tRoot)
                    if R_Det and CG then CG:FireServer(R_Det, tRoot, R_Weld) end
                    CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                end

                Heartbeat:Wait()
            end

            kickLoopEnabled = false
            if blobRoot then
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
            end
        end)
    end
})
