--[[
Flux

Flux is a UI library built from the ground up, scripted entirely from scratch
by me (plasma). Every element, every animation, every system in here was written
by hand with no copy/paste from other libraries. If anything looks similar to
another library, thats coincidence.

Unlike Starlight which uses a Roblox model asset for its UI, Flux is pure Lua.
Everything is built in code. This means no asset IDs required, easier to maintain,
easier to fork, and it works without needing Roblox to serve a model at runtime.
https://docs.nebulasoftworks.xyz/starlight

I took inspiration from Starlight and Nebula Softworks' work (credit where its due,
their stuff is genuinely well designed) but the implementation here is my own.

For anyone reading through the source:
I hope you are able to use / read it well. I tried to make it as readible as I could.
You are allowed to modify any of this to your own needs, but Im not responsible for what you do with it.

Flux UI Library
by Plasma <3
--]]

local Flux = {}
Flux.__index = Flux

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

-- default theme, override any of these in Init()
Flux.Theme = {
    Background = Color3.fromRGB(18, 18, 18),
    Surface = Color3.fromRGB(26, 26, 26),
    Sidebar = Color3.fromRGB(14, 14, 14),
    Border = Color3.fromRGB(40, 40, 40),
    Text = Color3.fromRGB(210, 210, 210),
    TextMuted = Color3.fromRGB(90, 90, 90),
    Accent = Color3.fromRGB(255, 255, 255),
    Toggle_Off = Color3.fromRGB(50, 50, 50),
}

Flux.Config = {
    Name = "Flux",
    Version = "1.0.0",
    Keybind = Enum.KeyCode.RightShift,
    Width = 520,
    Height = 340,
    SidebarWidth = 38,
}

Flux._tabs = {}
Flux._activeTab = nil
Flux._gui = nil
Flux._window = nil
Flux._dragging = false
Flux._dragOffset = Vector2.new(0, 0)
Flux._sessionStart = tick()
Flux._elementRegistry = {} -- maps element instance name -> element object, used by config save/load
Flux._configFolder = nil

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

-- ─────────────────────────────────────────────
--  window construction
-- ─────────────────────────────────────────────

function Flux:_buildWindow()
    local existing = lp.PlayerGui:FindFirstChild("FluxUI")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "FluxUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    gui.Parent = (gethui and gethui()) or lp.PlayerGui
    self._gui = gui

    local window = Instance.new("Frame")
    window.Name = "Window"
    window.Size = UDim2.fromOffset(self.Config.Width, self.Config.Height)
    window.Position = UDim2.fromScale(0.5, 0.5)
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.BackgroundColor3 = self.Theme.Background
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.Parent = gui
    self._window = window

    local windowCorner = Instance.new("UICorner")
    windowCorner.CornerRadius = UDim.new(0, 6)
    windowCorner.Parent = window

    local windowStroke = Instance.new("UIStroke")
    windowStroke.Color = self.Theme.Border
    windowStroke.Thickness = 1
    windowStroke.Parent = window

    -- sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, self.Config.SidebarWidth, 1, 0)
    sidebar.BackgroundColor3 = self.Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 2
    sidebar.Parent = window

    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 6)
    sidebarCorner.Parent = sidebar

    -- covers the right rounded corners so the sidebar is flush on that side
    local sidebarFlush = Instance.new("Frame")
    sidebarFlush.Size = UDim2.new(0, 8, 1, 0)
    sidebarFlush.Position = UDim2.new(1, -8, 0, 0)
    sidebarFlush.BackgroundColor3 = self.Theme.Sidebar
    sidebarFlush.BorderSizePixel = 0
    sidebarFlush.ZIndex = 2
    sidebarFlush.Parent = sidebar

    local sidebarBorder = Instance.new("Frame")
    sidebarBorder.Name = "RightBorder"
    sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    sidebarBorder.Position = UDim2.new(1, 0, 0, 0)
    sidebarBorder.BackgroundColor3 = self.Theme.Border
    sidebarBorder.BorderSizePixel = 0
    sidebarBorder.ZIndex = 3
    sidebarBorder.Parent = sidebar

    -- tab icon list
    local tabList = Instance.new("Frame")
    tabList.Name = "TabList"
    tabList.Size = UDim2.new(1, 0, 1, -42)
    tabList.BackgroundTransparency = 1
    tabList.ClipsDescendants = true
    tabList.ZIndex = 2
    tabList.Parent = sidebar
    self._tabList = tabList

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.Padding = UDim.new(0, 2)
    tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Parent = tabList

    local tabListPadding = Instance.new("UIPadding")
    tabListPadding.PaddingTop = UDim.new(0, 8)
    tabListPadding.Parent = tabList

    -- settings icon pinned to the bottom of the sidebar
    local settingsPin = Instance.new("ImageButton")
    settingsPin.Name = "SettingsBtn"
    settingsPin.Size = UDim2.fromOffset(22, 22)
    settingsPin.Position = UDim2.new(0.5, -11, 1, -32)
    settingsPin.BackgroundTransparency = 1
    settingsPin.Image = "rbxassetid://7733960981"
    settingsPin.ImageColor3 = self.Theme.TextMuted
    settingsPin.ZIndex = 4
    settingsPin.Parent = sidebar
    self._settingsBtn = settingsPin

    -- content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -self.Config.SidebarWidth, 1, 0)
    content.Position = UDim2.fromOffset(self.Config.SidebarWidth, 0)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = window

    -- topbar (drag handle + tab title)
    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 34)
    topbar.BackgroundTransparency = 1
    topbar.Parent = content
    self._topbar = topbar

    local topbarLine = Instance.new("Frame")
    topbarLine.Size = UDim2.new(1, 0, 0, 1)
    topbarLine.Position = UDim2.new(0, 0, 1, -1)
    topbarLine.BackgroundColor3 = self.Theme.Border
    topbarLine.BorderSizePixel = 0
    topbarLine.Parent = topbar

    local tabTitle = Instance.new("TextLabel")
    tabTitle.Name = "TabTitle"
    tabTitle.Size = UDim2.new(1, -16, 1, 0)
    tabTitle.Position = UDim2.fromOffset(12, 0)
    tabTitle.BackgroundTransparency = 1
    tabTitle.Text = self.Config.Name
    tabTitle.TextColor3 = self.Theme.Text
    tabTitle.TextSize = 12
    tabTitle.Font = Enum.Font.GothamMedium
    tabTitle.TextXAlignment = Enum.TextXAlignment.Left
    tabTitle.Parent = topbar

    -- scrollable page container
    local pageContainer = Instance.new("ScrollingFrame")
    pageContainer.Name = "PageContainer"
    pageContainer.Size = UDim2.new(1, 0, 1, -34)
    pageContainer.Position = UDim2.fromOffset(0, 34)
    pageContainer.BackgroundTransparency = 1
    pageContainer.ScrollBarThickness = 2
    pageContainer.ScrollBarImageColor3 = self.Theme.Border
    pageContainer.BorderSizePixel = 0
    pageContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    pageContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pageContainer.Parent = content
    self._pageContainer = pageContainer

    -- dragging
    local mouse = lp:GetMouse()

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = true
            self._dragOffset = Vector2.new(
                mouse.X - window.AbsolutePosition.X,
                mouse.Y - window.AbsolutePosition.Y
            )
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if self._dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            window.Position = UDim2.fromOffset(
                mouse.X - self._dragOffset.X,
                mouse.Y - self._dragOffset.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = false
        end
    end)

    -- keybind toggle
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.Config.Keybind then
            gui.Enabled = not gui.Enabled
        end
    end)

    return self
end

-- ─────────────────────────────────────────────
--  public API
-- ─────────────────────────────────────────────

function Flux:Init(config)
    if config then
        for k, v in config do
            if k == "Theme" then
                for tk, tv in v do
                    self.Theme[tk] = tv
                end
            else
                self.Config[k] = v
            end
        end
    end
    self:_buildWindow()
    return self
end

function Flux:AddTab(name, icon)
    local Tabs = require(script.core.Tabs)
    local tab = Tabs.new(self, name, icon)
    table.insert(self._tabs, tab)

    if name == "Settings" then
        self._settingsBtn.MouseButton1Click:Connect(function()
            tab:Activate()
        end)
    end

    if #self._tabs == 1 then
        tab:Activate()
    end

    return tab
end

function Flux:AddGroupbox(tab, name, column)
    local theme = self.Theme
    column = column or 1

    local colName = "Column_" .. column
    local col = tab.Page:FindFirstChild(colName)

    if not col then
        col = Instance.new("Frame")
        col.Name = colName
        col.Size = UDim2.new(0.5, -6, 1, 0)
        col.Position = UDim2.fromScale((column - 1) * 0.5, 0)
        col.BackgroundTransparency = 1
        col.BorderSizePixel = 0
        col.Parent = tab.Page

        local colLayout = Instance.new("UIListLayout")
        colLayout.Padding = UDim.new(0, 8)
        colLayout.SortOrder = Enum.SortOrder.LayoutOrder
        colLayout.FillDirection = Enum.FillDirection.Vertical
        colLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        colLayout.Parent = col
    end

    local box = Instance.new("Frame")
    box.Name = "Groupbox_" .. name
    box.Size = UDim2.new(1, 0, 0, 0)
    box.AutomaticSize = Enum.AutomaticSize.Y
    box.BackgroundColor3 = theme.Surface
    box.BorderSizePixel = 0
    box.Parent = col

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 5)
    boxCorner.Parent = box

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = theme.Border
    boxStroke.Thickness = 1
    boxStroke.Parent = box

    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, -16, 0, 24)
    header.BackgroundTransparency = 1
    header.Text = name
    header.TextColor3 = theme.TextMuted
    header.TextSize = 10
    header.Font = Enum.Font.GothamMedium
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = box

    local headerPadding = Instance.new("UIPadding")
    headerPadding.PaddingLeft = UDim.new(0, 10)
    headerPadding.Parent = header

    local headerDivider = Instance.new("Frame")
    headerDivider.Name = "HeaderDivider"
    headerDivider.Size = UDim2.new(1, -20, 0, 1)
    headerDivider.Position = UDim2.fromOffset(10, 23)
    headerDivider.BackgroundColor3 = theme.Border
    headerDivider.BorderSizePixel = 0
    headerDivider.Parent = box

    local page = Instance.new("Frame")
    page.Name = "Page"
    page.Size = UDim2.new(1, 0, 0, 0)
    page.Position = UDim2.fromOffset(0, 28)
    page.AutomaticSize = Enum.AutomaticSize.Y
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Parent = box

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 4)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.FillDirection = Enum.FillDirection.Vertical
    pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    pageLayout.Parent = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingLeft = UDim.new(0, 8)
    pagePadding.PaddingRight = UDim.new(0, 8)
    pagePadding.PaddingBottom = UDim.new(0, 8)
    pagePadding.Parent = page

    local groupbox = {
        Frame = box,
        Page = page,
        Name = name,
        _flux = self,
    }

    return groupbox
end

-- element wrappers
-- each one creates the element, registers it by its instance name so the
-- config system can find it later, then returns it to the caller

function Flux:AddToggle(groupbox, id, name, default, callback)
    local Elements = require(script.core.Elements)
    local el = Elements.Toggle.new(groupbox, id, name, default, callback)
    self._elementRegistry["Toggle_" .. id] = el
    return el
end

function Flux:AddSlider(groupbox, id, name, min, max, default, suffix, callback)
    local Elements = require(script.core.Elements)
    local el = Elements.Slider.new(groupbox, id, name, min, max, default, suffix, callback)
    self._elementRegistry["Slider_" .. id] = el
    return el
end

function Flux:AddButton(groupbox, id, name, callback)
    local Elements = require(script.core.Elements)
    local el = Elements.Button.new(groupbox, id, name, callback)
    -- buttons have no persistent state so no need to register them
    return el
end

function Flux:AddDropdown(groupbox, id, name, options, default, multi, callback)
    local Elements = require(script.core.Elements)
    local el = Elements.Dropdown.new(groupbox, id, name, options, default, multi, callback)
    self._elementRegistry["Dropdown_" .. id] = el
    return el
end

function Flux:AddColorPicker(groupbox, id, name, default, callback)
    local Elements = require(script.core.Elements)
    local el = Elements.ColorPicker.new(groupbox, id, name, default, callback)
    self._elementRegistry["ColorPicker_" .. id] = el
    return el
end

function Flux:AddLabel(groupbox, id, name)
    local Elements = require(script.core.Elements)
    return Elements.Label.new(groupbox, id, name)
end

function Flux:AddParagraph(groupbox, id, title, content)
    local Elements = require(script.core.Elements)
    return Elements.Paragraph.new(groupbox, id, title, content)
end

function Flux:AddDivider(groupbox)
    local Elements = require(script.core.Elements)
    return Elements.Divider.new(groupbox)
end

-- ─────────────────────────────────────────────
--  config system
-- ─────────────────────────────────────────────

-- sets up the config folder. call this before SaveConfig/LoadConfig.
-- configFolder is just the subfolder name, e.g. "MyScript"
function Flux:SetupConfig(configFolder)
    local Config = require(script.core.Config)
    Config.Setup(self, configFolder)
end

function Flux:SaveConfig(name)
    local Config = require(script.core.Config)
    local ok, err = Config.Save(self, name)
    if ok then
        self:Notify("Config Saved", name)
    else
        self:Notify("Save Failed", tostring(err))
    end
    return ok, err
end

function Flux:LoadConfig(name)
    local Config = require(script.core.Config)
    local ok, err = Config.Load(self, name)
    if ok then
        self:Notify("Config Loaded", name)
    else
        self:Notify("Load Failed", tostring(err))
    end
    return ok, err
end

function Flux:DeleteConfig(name)
    local Config = require(script.core.Config)
    return Config.Delete(self, name)
end

function Flux:ListConfigs()
    local Config = require(script.core.Config)
    return Config.List(self)
end

function Flux:SetAutoload(name)
    local Config = require(script.core.Config)
    return Config.SetAutoload(self, name)
end

function Flux:ClearAutoload()
    local Config = require(script.core.Config)
    return Config.ClearAutoload(self)
end

-- call this at the end of your setup to auto-load whatever config was last saved
function Flux:LoadAutoload()
    local Config = require(script.core.Config)
    return Config.LoadAutoload(self)
end

-- ─────────────────────────────────────────────
--  notifications
-- ─────────────────────────────────────────────

function Flux:Notify(title, body, duration)
    duration = duration or 3

    local theme = self.Theme
    local gui = self._gui

    local notifHolder = gui:FindFirstChild("NotifHolder")
    if not notifHolder then
        notifHolder = Instance.new("Frame")
        notifHolder.Name = "NotifHolder"
        notifHolder.Size = UDim2.fromOffset(240, 0)
        notifHolder.Position = UDim2.new(1, -252, 1, -12)
        notifHolder.AnchorPoint = Vector2.new(0, 1)
        notifHolder.BackgroundTransparency = 1
        notifHolder.BorderSizePixel = 0
        notifHolder.AutomaticSize = Enum.AutomaticSize.Y
        notifHolder.Parent = gui

        local holderLayout = Instance.new("UIListLayout")
        holderLayout.Padding = UDim.new(0, 6)
        holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
        holderLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        holderLayout.FillDirection = Enum.FillDirection.Vertical
        holderLayout.Parent = notifHolder
    end

    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(240, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = theme.Surface
    card.BorderSizePixel = 0
    card.BackgroundTransparency = 1
    card.Parent = notifHolder

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 5)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = theme.Border
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 2, 1, 0)
    accentBar.BackgroundColor3 = theme.Accent
    accentBar.BorderSizePixel = 0
    accentBar.Parent = card

    local accentBarCorner = Instance.new("UICorner")
    accentBarCorner.CornerRadius = UDim.new(0, 5)
    accentBarCorner.Parent = accentBar

    local cardPadding = Instance.new("UIPadding")
    cardPadding.PaddingLeft = UDim.new(0, 10)
    cardPadding.PaddingRight = UDim.new(0, 8)
    cardPadding.PaddingTop = UDim.new(0, 8)
    cardPadding.PaddingBottom = UDim.new(0, 8)
    cardPadding.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 14)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = theme.Text
    titleLabel.TextSize = 12
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = card

    local bodyLabel = Instance.new("TextLabel")
    bodyLabel.Size = UDim2.new(1, 0, 0, 0)
    bodyLabel.Position = UDim2.fromOffset(0, 16)
    bodyLabel.AutomaticSize = Enum.AutomaticSize.Y
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Text = body or ""
    bodyLabel.TextColor3 = theme.TextMuted
    bodyLabel.TextSize = 11
    bodyLabel.Font = Enum.Font.Gotham
    bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bodyLabel.TextWrapped = true
    bodyLabel.Parent = card

    tween(card, { BackgroundTransparency = 0 }, 0.2)

    task.delay(duration, function()
        tween(card, { BackgroundTransparency = 1 }, 0.2)
        task.wait(0.25)
        card:Destroy()
    end)
end

function Flux:_updateTheme()
    local t = self.Theme
    if not self._window then return end
    self._window.BackgroundColor3 = t.Background
    self._window.Sidebar.BackgroundColor3 = t.Sidebar
end

return Flux