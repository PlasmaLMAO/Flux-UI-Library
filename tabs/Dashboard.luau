local Dashboard = {}

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

function Dashboard.Create(flux)
    local theme = flux.Theme
    local lp = Players.LocalPlayer

    local tab = flux:AddTab("Dashboard", "rbxassetid://10734898853")

    -- player info
    local playerGroup = flux:AddGroupbox(tab, "Player", 1)

    local card = Instance.new("Frame")
    card.Name = "PlayerCard"
    card.Size = UDim2.new(1, 0, 0, 72)
    card.BackgroundColor3 = theme.Background
    card.BorderSizePixel = 0
    card.Parent = playerGroup.Page

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 4)
    cardCorner.Parent = card

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.fromOffset(56, 56)
    avatar.Position = UDim2.fromOffset(8, 8)
    avatar.BackgroundColor3 = theme.Surface
    avatar.BorderSizePixel = 0
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar.Parent = card

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 4)
    avatarCorner.Parent = avatar

    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.AvatarFrontView, Enum.ThumbnailSize.Size420x420)
        end)
        if ok then avatar.Image = img end
    end)

    local years = math.floor(lp.AccountAge / 365)
    local months = math.floor((lp.AccountAge % 365) / 30)
    local ageStr = years > 0 and (years .. "y " .. months .. "m") or (months .. "m")

    local playerInfo = Instance.new("TextLabel")
    playerInfo.Size = UDim2.new(1, -76, 1, -12)
    playerInfo.Position = UDim2.fromOffset(72, 6)
    playerInfo.BackgroundTransparency = 1
    playerInfo.Text = lp.DisplayName .. "\n@" .. lp.Name .. "\nID: " .. lp.UserId .. "\nAge: " .. ageStr
    playerInfo.TextColor3 = theme.Text
    playerInfo.TextSize = 11
    playerInfo.Font = Enum.Font.Gotham
    playerInfo.TextXAlignment = Enum.TextXAlignment.Left
    playerInfo.TextYAlignment = Enum.TextYAlignment.Top
    playerInfo.TextWrapped = false
    playerInfo.LineHeight = 1.3
    playerInfo.Parent = card

    -- game info
    local gameGroup = flux:AddGroupbox(tab, "Game", 1)

    local gameNameEl = flux:AddLabel(gameGroup, "game_name", "Game: loading...")
    flux:AddLabel(gameGroup, "place_id", "Place: " .. game.PlaceId)
    flux:AddLabel(gameGroup, "job_id", "Server: " .. (game.JobId ~= "" and game.JobId:sub(1, 8) .. "..." or "Studio"))

    task.spawn(function()
        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        if ok and info then
            gameNameEl:SetText("Game: " .. info.Name)
        end
    end)

    local playerCountEl = flux:AddLabel(gameGroup, "player_count", "Players: " .. #Players:GetPlayers())

    local function updateCount()
        playerCountEl:SetText("Players: " .. #Players:GetPlayers())
    end
    Players.PlayerAdded:Connect(updateCount)
    Players.PlayerRemoving:Connect(updateCount)

    -- stats
    local statsGroup = flux:AddGroupbox(tab, "Stats", 2)

    local friendCountEl = flux:AddLabel(statsGroup, "friends", "Friends: loading...")

    task.spawn(function()
        local ok, pages = pcall(function()
            return lp:GetFriendsAsync(200)
        end)
        if ok and pages then
            local count = 0
            while true do
                count = count + #pages:GetCurrentPage()
                if pages.IsFinished then break end
                local ok2 = pcall(function() pages:AdvanceToNextPageAsync() end)
                if not ok2 then break end
            end
            friendCountEl:SetText("Friends: " .. count)
        else
            friendCountEl:SetText("Friends: N/A")
        end
    end)

    local sessionEl = flux:AddLabel(statsGroup, "session_time", "Session: 0s")
    local pingEl = flux:AddLabel(statsGroup, "ping", "Ping: --ms")

    local accumulator = 0
    RunService.Heartbeat:Connect(function(dt)
        accumulator += dt
        if accumulator < 1 then return end
        accumulator = 0

        local elapsed = math.floor(tick() - flux._sessionStart)
        local h = math.floor(elapsed / 3600)
        local m = math.floor((elapsed % 3600) / 60)
        local s = elapsed % 60

        local timeStr
        if h > 0 then
            timeStr = string.format("%dh %02dm %02ds", h, m, s)
        elseif m > 0 then
            timeStr = string.format("%dm %02ds", m, s)
        else
            timeStr = s .. "s"
        end
        sessionEl:SetText("Session: " .. timeStr)

        local pingOk, ping = pcall(function()
            return math.round(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if pingOk then
            pingEl:SetText("Ping: " .. ping .. "ms")
        end
    end)

    return tab
end

return Dashboard