local Tabs = getgenv().UI.Tabs
local Sect = getgenv().UI.Sect

local RS = game:GetService("ReplicatedStorage")
local GrabEvents = RS:WaitForChild("GrabEvents")
local PlayerEvents = RS:WaitForChild("PlayerEvents")
local MenuToys = RS:WaitForChild("MenuToys")

local SNO = GrabEvents:WaitForChild("SetNetworkOwner")
local SPE = PlayerEvents:WaitForChild("StickyPartEvent")
local SpawnRemote = MenuToys:WaitForChild("SpawnToyRemoteFunction")
local DestroyRemote = MenuToys:WaitForChild("DestroyToy")

local lp = game.Players.LocalPlayer
local Grass = workspace.Map.AlwaysHereTweenedObjects.Ocean.Object.ObjectModel:GetChildren()[14]

Sect.FunLineSection:AddToggle({
    Name = "Break Ocean",
    Default = false,
    Callback = function(Value)
        _G.BreakOcean = Value

        if Value then
            if not Grass then
                warn("Grass (Ocean part) not found!")
                return
            end

            task.spawn(function()
                while _G.BreakOcean do
                    local char = lp.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if not root then 
                      task.wait(0.5) 
                      continue 
                    end

                    local spawnedFolder = workspace:FindFirstChild(lp.Name .. "SpawnedInToys")
                    if not spawnedFolder then 
                      task.wait(0.5) 
                      continue 
                    end

                    for i = 1, 11 do
                        if not _G.BreakOcean then break end

                        SpawnRemote:InvokeServer("NinjaShuriken", root.CFrame * CFrame.new(0, 3, -3), Vector3.new(0,0,0))
                        task.wait(0.035)

                        local shuriken = spawnedFolder:FindFirstChild("NinjaShuriken")
                        if shuriken then
                            shuriken.Name = "OceanBreaker"

                            local soundPart = shuriken:WaitForChild("SoundPart", 1)
                            local stickyPart = shuriken:WaitForChild("StickyPart", 1)

                            if soundPart and stickyPart then
                                -- Агрессивно забираем ownership
                                for _ = 1, 6 do
                                    local owner = soundPart:FindFirstChild("PartOwner")
                                    if owner and owner.Value == lp.Name then break end
                                    SNO:FireServer(soundPart, soundPart.CFrame)
                                    task.wait(0.025)
                                end
                    
                                SPE:FireServer(
                                    stickyPart,
                                    Grass,
                                    CFrame.new(0,0,0) * CFrame.Angles(0, math.rad(90), math.rad(90))
                                )
                            end
                        end
                        task.wait(0.08)
                    end

                    task.wait(0.4)
                end
            
                local spawnedFolder = workspace:FindFirstChild(lp.Name .. "SpawnedInToys")
                if spawnedFolder then
                    for _, v in pairs(spawnedFolder:GetChildren()) do
                        if v.Name == "OceanBreaker" then
                            pcall(function() DestroyRemote:FireServer(v) end)
                        end
                    end
                end
            end)
        end
    end
})
