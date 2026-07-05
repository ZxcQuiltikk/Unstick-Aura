local Orion = getgenv().UI.Orion
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS = ReplicatedStorage:WaitForChild("GrabEvents")
local ExtendGrabLine = RS:WaitForChild("ExtendGrabLine")
local LocalPlayer = game:GetService("Players").LocalPlayer

local chatHistory = {}
local chatDropdown = nil
local lastSelected = ""

local function sendPacket(plainText)
    ExtendGrabLine:FireServer(plainText)
end

local Tabs = getgenv().UI.Tabs
local Sect = getgenv().UI.Sect

Sect.ChatSect = Tabs.ServerTab:AddSection({Name = "Chat", Side = "Left"})

Sect.ChatSect:AddTextbox({
    Name = "Chat",
    Default = "",
    TextDisappear = true,
    Callback = function(text)
        if text and text:match("%S") then
            sendPacket(text .. " //chat")
        end
    end
})

chatDropdown = Sect.ChatSect:AddDropdown({
    Name = "Chat Logs",
    Options = {},
    Multi = false,
    Default = "",
    MaxSize = 5,
    Search = true,
    Flag = "ChatLogs",
    Callback = function(selected)
        if selected and selected ~= "" and selected ~= lastSelected then
            lastSelected = selected

            pcall(function()
                if setclipboard then
                    setclipboard(selected)
                elseif toclipboard then
                    toclipboard(selected)
                end
            end)

            Orion:MakeNotification({
                Name = "Chat",
                Content = "Message copied",
                Image = "rbxassetid://3944703587",
                Time = 2,
                Sound = "rbxassetid://9120381235",
                SoundVolume = 0.3
            })
        end
    end
})

local GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents")
local OnReceiveMessage = GrabEvents:FindFirstChild("OnReceiveMessage")
local NetworkClient = GrabEvents:FindFirstChild("NetworkClient")

local function refreshDropdown()
    if chatDropdown and chatDropdown.Refresh then
        local options = {}
        for i = #chatHistory, 1, -1 do
            table.insert(options, chatHistory[i])
        end
        chatDropdown:Refresh(options, true)
    end
end

local function handleMessage(message, sender)
    if typeof(message) == "string" and message ~= "" then
        local cleanMessage = message:gsub(" //chat$", "")
        local senderName = "Unknown"
        
        if typeof(sender) == "Instance" and sender:IsA("Player") then
            senderName = sender.DisplayName
        end
        
        local logEntry = senderName .. ": " .. cleanMessage
        
        table.insert(chatHistory, logEntry)
        if #chatHistory > 20 then
            table.remove(chatHistory, 1)
        end
        
        refreshDropdown()
        
        Orion:MakeNotification({
            Name = "Chat",
            Content = logEntry,
            Image = "rbxassetid://3944703587",
            Time = 5,
            Sound = "rbxassetid://9120381235",
            SoundVolume = 0.5
        })
    end
end

local function processEvent(...)
    local args = {...}
    
    local sender = nil
    local message = nil
    
    if #args >= 2 and typeof(args[1]) == "Instance" and args[1]:IsA("Player") and typeof(args[2]) == "string" then
        sender = args[1]
        message = args[2]
    elseif #args >= 1 and typeof(args[1]) == "string" then
        message = args[1]
        sender = LocalPlayer
    end
    
    if message and typeof(message) == "string" and message:find(" //chat") then
        handleMessage(message, sender)
    end
end

if OnReceiveMessage then
    OnReceiveMessage.OnClientEvent:Connect(processEvent)
end

if NetworkClient then
    NetworkClient.OnClientEvent:Connect(processEvent)
end

local ChatEvent = ReplicatedStorage:FindFirstChild("ChatEvent")
if ChatEvent then
    ChatEvent.OnClientEvent:Connect(processEvent)
end

ExtendGrabLine.OnClientEvent:Connect(processEvent)
