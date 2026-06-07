local Tabs = {}

local TweenService = game:GetService("TweenService")

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

function Tabs.new(flux, name, icon)
    local theme = flux.Theme
    local tabList = flux._tabList
    local pageContainer = flux._pageContainer

    -- sidebar button
    local btn = Instance.new("Frame")
    btn.Name = "TAB_" .. name
    btn.Size = UDim2.fromOffset(28, 28)
    btn.BackgroundColor3 = theme.Sidebar
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Parent = tabList

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    -- left accent bar, visible when the tab is active
    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 2, 0, 14)
    accent.Position = UDim2.new(0, -3, 0.5, -7)
    accent.BackgroundColor3 = theme.Accent
    accent.BorderSizePixel = 0
    accent.BackgroundTransparency = 1
    accent.Parent = btn

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 1)
    accentCorner.Parent = accent

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.fromOffset(16, 16)
    img.Position = UDim2.fromScale(0.5, 0.5)
    img.AnchorPoint = Vector2.new(0.5, 0.5)
    img.BackgroundTransparency = 1
    img.Image = icon or ""
    img.ImageColor3 = theme.TextMuted
    img.Parent = btn

    local interact = Instance.new("TextButton")
    interact.Size = UDim2.fromScale(1, 1)
    interact.BackgroundTransparency = 1
    interact.Text = ""
    interact.ZIndex = 5
    interact.Parent = btn

    -- page that holds column frames and groupboxes
    local page = Instance.new("Frame")
    page.Name = "PAGE_" .. name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.BorderSizePixel = 0
    page.Parent = pageContainer

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.FillDirection = Enum.FillDirection.Horizontal
    pageLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, 10)
    pagePadding.PaddingLeft = UDim.new(0, 10)
    pagePadding.PaddingRight = UDim.new(0, 10)
    pagePadding.PaddingBottom = UDim.new(0, 10)
    pagePadding.Parent = page

    local Tab = {
        Name = name,
        Button = btn,
        Page = page,
        Active = false,
        _flux = flux,
        _accent = accent,
        _img = img,
    }

    function Tab:Activate()
        for _, other in flux._tabs do
            if other ~= self then
                other:Deactivate()
            end
        end

        self.Active = true
        self.Page.Visible = true

        tween(self.Button, { BackgroundTransparency = 0.82 })
        tween(self._img, { ImageColor3 = flux.Theme.Text })
        tween(self._accent, { BackgroundTransparency = 0 })

        local title = flux._window.Content.Topbar:FindFirstChild("TabTitle")
        if title then title.Text = self.Name end
    end

    function Tab:Deactivate()
        self.Active = false
        self.Page.Visible = false

        tween(self.Button, { BackgroundTransparency = 1 })
        tween(self._img, { ImageColor3 = flux.Theme.TextMuted })
        tween(self._accent, { BackgroundTransparency = 1 })
    end

    interact.MouseEnter:Connect(function()
        if not Tab.Active then
            tween(btn, { BackgroundTransparency = 0.91 })
            tween(img, { ImageColor3 = Color3.fromRGB(170, 170, 170) })
        end
    end)

    interact.MouseLeave:Connect(function()
        if not Tab.Active then
            tween(btn, { BackgroundTransparency = 1 })
            tween(img, { ImageColor3 = flux.Theme.TextMuted })
        end
    end)

    interact.MouseButton1Click:Connect(function()
        Tab:Activate()
    end)

    return Tab
end

return Tabs