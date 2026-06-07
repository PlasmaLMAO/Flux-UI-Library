-- all UI elements: Toggle, Slider, Button, Dropdown, Label, Paragraph, Divider, ColorPicker
-- every element returns an object with .Value and :SetValue() where it makes sense
-- elements that can be locked also have :Lock(reason) and :Unlock()

local Elements = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

-- adds a lock overlay on top of any element container
-- returns show/hide functions so the element can expose :Lock() and :Unlock()
local function makeLockOverlay(container, theme)
    local overlay = Instance.new("Frame")
    overlay.Name = "LockOverlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = theme.Surface
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 50
    overlay.Visible = false
    overlay.Parent = container

    local overlayCorner = Instance.new("UICorner")
    overlayCorner.CornerRadius = UDim.new(0, 4)
    overlayCorner.Parent = overlay

    local overlayLabel = Instance.new("TextLabel")
    overlayLabel.Name = "Reason"
    overlayLabel.Size = UDim2.fromScale(1, 1)
    overlayLabel.BackgroundTransparency = 1
    overlayLabel.TextColor3 = theme.TextMuted
    overlayLabel.TextSize = 10
    overlayLabel.Font = Enum.Font.Gotham
    overlayLabel.Text = ""
    overlayLabel.TextWrapped = true
    overlayLabel.Parent = overlay

    local function lock(reason)
        overlayLabel.Text = reason or ""
        overlay.Visible = true
    end

    local function unlock()
        overlay.Visible = false
        overlayLabel.Text = ""
    end

    return lock, unlock
end

-- ─────────────────────────────────────────────
--  Toggle
-- ─────────────────────────────────────────────

Elements.Toggle = {}

function Elements.Toggle.new(groupbox, id, name, default, callback)
    local theme = groupbox._flux.Theme
    default = default or false

    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. id
    container.Size = UDim2.new(1, 0, 0, 28)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = groupbox.Page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = container

    local pill = Instance.new("Frame")
    pill.Name = "Pill"
    pill.Size = UDim2.fromOffset(36, 18)
    pill.Position = UDim2.new(1, -36, 0.5, -9)
    pill.BackgroundColor3 = default and theme.Accent or theme.Toggle_Off
    pill.BorderSizePixel = 0
    pill.Parent = container

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = pill

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.fromOffset(12, 12)
    knob.Position = default and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = pill

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local interact = Instance.new("TextButton")
    interact.Size = UDim2.fromScale(1, 1)
    interact.BackgroundTransparency = 1
    interact.Text = ""
    interact.Parent = container

    local state = default
    local lockFn, unlockFn = makeLockOverlay(container, theme)

    local element = {
        Container = container,
        _id = id,
        Value = state,
        _type = "Toggle",
    }

    local function setState(val, fireCallback)
        state = val
        element.Value = val
        tween(pill, { BackgroundColor3 = val and theme.Accent or theme.Toggle_Off })
        tween(knob, { Position = val and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3) })
        if fireCallback ~= false and callback then
            callback(val)
        end
    end

    function element:SetValue(val)
        setState(val, true)
    end

    function element:Lock(reason)
        lockFn(reason)
    end

    function element:Unlock()
        unlockFn()
    end

    interact.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    return element
end

-- ─────────────────────────────────────────────
--  Slider
-- ─────────────────────────────────────────────

Elements.Slider = {}

function Elements.Slider.new(groupbox, id, name, min, max, default, suffix, callback)
    local theme = groupbox._flux.Theme
    default = math.clamp(default or min, min, max)
    suffix = suffix or ""

    local container = Instance.new("Frame")
    container.Name = "Slider_" .. id
    container.Size = UDim2.new(1, 0, 0, 44)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = groupbox.Page

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 14)
    label.BackgroundTransparency = 1
    label.Text = name .. "  " .. default .. suffix
    label.TextColor3 = theme.Text
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Position = UDim2.fromOffset(0, 26)
    track.BackgroundColor3 = theme.Toggle_Off
    track.BorderSizePixel = 0
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.fromOffset(10, 10)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    knob.BackgroundColor3 = theme.Accent
    knob.BorderSizePixel = 0
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local trackInteract = Instance.new("TextButton")
    trackInteract.Size = UDim2.new(1, 0, 0, 22)
    trackInteract.Position = UDim2.fromOffset(0, -9)
    trackInteract.BackgroundTransparency = 1
    trackInteract.Text = ""
    trackInteract.Parent = track

    local state = default
    local dragging = false
    local lockFn, unlockFn = makeLockOverlay(container, theme)

    local element = {
        Container = container,
        _id = id,
        Value = state,
        _type = "Slider",
    }

    local function setValue(val)
        val = math.clamp(val, min, max)
        val = math.floor(val * 100 + 0.5) / 100
        state = val
        element.Value = val

        local pct = (val - min) / (max - min)
        tween(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.08)
        tween(knob, { Position = UDim2.new(pct, 0, 0.5, 0) }, 0.08)

        local display = (val == math.floor(val)) and tostring(math.floor(val)) or tostring(val)
        label.Text = name .. "  " .. display .. suffix

        if callback then callback(val) end
    end

    local function updateFromMouse()
        local mouse = game.Players.LocalPlayer:GetMouse()
        local pct = math.clamp((mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        setValue(min + (max - min) * pct)
    end

    function element:SetValue(val)
        setValue(val)
    end

    function element:Lock(reason)
        lockFn(reason)
    end

    function element:Unlock()
        unlockFn()
    end

    trackInteract.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromMouse()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return element
end

-- ─────────────────────────────────────────────
--  Button
-- ─────────────────────────────────────────────

Elements.Button = {}

function Elements.Button.new(groupbox, id, name, callback)
    local theme = groupbox._flux.Theme

    local btn = Instance.new("TextButton")
    btn.Name = "Button_" .. id
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = theme.Surface
    btn.BorderSizePixel = 0
    btn.TextColor3 = theme.Text
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.Text = name
    btn.AutoButtonColor = false
    btn.Parent = groupbox.Page

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = theme.Border
    btnStroke.Thickness = 1
    btnStroke.Parent = btn

    local lockFn, unlockFn = makeLockOverlay(btn, theme)

    btn.MouseEnter:Connect(function()
        tween(btn, { BackgroundColor3 = Color3.fromRGB(36, 36, 36) })
    end)

    btn.MouseLeave:Connect(function()
        tween(btn, { BackgroundColor3 = theme.Surface })
    end)

    btn.MouseButton1Down:Connect(function()
        tween(btn, { BackgroundColor3 = Color3.fromRGB(44, 44, 44) })
    end)

    btn.MouseButton1Click:Connect(function()
        tween(btn, { BackgroundColor3 = Color3.fromRGB(36, 36, 36) })
        if callback then pcall(callback) end
    end)

    local element = {
        Button = btn,
        _id = id,
        _type = "Button",
    }

    function element:Lock(reason)
        lockFn(reason)
    end

    function element:Unlock()
        unlockFn()
    end

    return element
end

-- ─────────────────────────────────────────────
--  Dropdown
-- ─────────────────────────────────────────────

Elements.Dropdown = {}

function Elements.Dropdown.new(groupbox, id, name, options, default, multi, callback)
    local theme = groupbox._flux.Theme
    multi = multi or false
    default = default or {}
    if type(default) == "string" then default = { default } end

    -- popup goes on the top-level gui so it doesn't get clipped by the groupbox
    local gui = groupbox._flux._gui

    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. id
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = groupbox.Page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 13)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = theme.TextMuted
    label.TextSize = 10
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local dropBtn = Instance.new("TextButton")
    dropBtn.Name = "DropBtn"
    dropBtn.Size = UDim2.new(1, 0, 0, 26)
    dropBtn.Position = UDim2.fromOffset(0, 16)
    dropBtn.BackgroundColor3 = theme.Surface
    dropBtn.BorderSizePixel = 0
    dropBtn.TextColor3 = theme.Text
    dropBtn.TextSize = 11
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.TextXAlignment = Enum.TextXAlignment.Left
    dropBtn.AutoButtonColor = false
    dropBtn.ClipsDescendants = true
    dropBtn.Parent = container

    local dropBtnCorner = Instance.new("UICorner")
    dropBtnCorner.CornerRadius = UDim.new(0, 4)
    dropBtnCorner.Parent = dropBtn

    local dropBtnStroke = Instance.new("UIStroke")
    dropBtnStroke.Color = theme.Border
    dropBtnStroke.Thickness = 1
    dropBtnStroke.Parent = dropBtn

    local dropBtnPadding = Instance.new("UIPadding")
    dropBtnPadding.PaddingLeft = UDim.new(0, 8)
    dropBtnPadding.Parent = dropBtn

    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.fromOffset(16, 26)
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▾"
    arrow.TextColor3 = theme.TextMuted
    arrow.TextSize = 12
    arrow.Font = Enum.Font.Gotham
    arrow.Parent = dropBtn

    local popup = Instance.new("Frame")
    popup.Name = "Popup_" .. id
    popup.Size = UDim2.fromOffset(0, 0)
    popup.BackgroundColor3 = theme.Surface
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.ZIndex = 99
    popup.ClipsDescendants = true
    popup.Parent = gui

    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, 4)
    popupCorner.Parent = popup

    local popupStroke = Instance.new("UIStroke")
    popupStroke.Color = theme.Border
    popupStroke.Thickness = 1
    popupStroke.Parent = popup

    local optList = Instance.new("Frame")
    optList.Name = "OptionList"
    optList.Size = UDim2.new(1, 0, 0, 0)
    optList.AutomaticSize = Enum.AutomaticSize.Y
    optList.BackgroundTransparency = 1
    optList.BorderSizePixel = 0
    optList.Parent = popup

    local optListLayout = Instance.new("UIListLayout")
    optListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optListLayout.FillDirection = Enum.FillDirection.Vertical
    optListLayout.Parent = optList

    local optListPadding = Instance.new("UIPadding")
    optListPadding.PaddingTop = UDim.new(0, 4)
    optListPadding.PaddingBottom = UDim.new(0, 4)
    optListPadding.Parent = optList

    local selected = {}
    for _, v in default do selected[v] = true end
    local isOpen = false

    local function getDisplayText()
        local parts = {}
        for k in selected do table.insert(parts, k) end
        if #parts == 0 then return "Select..." end
        return table.concat(parts, ", ")
    end

    local function refreshDisplay()
        dropBtn.Text = getDisplayText()
    end

    local function positionPopup()
        local abs = dropBtn.AbsolutePosition
        local size = dropBtn.AbsoluteSize
        local viewY = game.Workspace.CurrentCamera.ViewportSize.Y
        -- flip upward if not enough room below
        if abs.Y + size.Y + 180 > viewY then
            popup.AnchorPoint = Vector2.new(0, 1)
            popup.Position = UDim2.fromOffset(abs.X, abs.Y - 2)
        else
            popup.AnchorPoint = Vector2.new(0, 0)
            popup.Position = UDim2.fromOffset(abs.X, abs.Y + size.Y + 2)
        end
        popup.Size = UDim2.fromOffset(size.X, 0)
    end

    local function openPopup()
        isOpen = true
        positionPopup()
        popup.Visible = true
        local targetH = math.min(optList.AbsoluteSize.Y + 8, 180)
        tween(popup, { Size = UDim2.fromOffset(dropBtn.AbsoluteSize.X, targetH) }, 0.12)
        arrow.Text = "▴"
    end

    local function closePopup()
        isOpen = false
        tween(popup, { Size = UDim2.fromOffset(dropBtn.AbsoluteSize.X, 0) }, 0.1)
        arrow.Text = "▾"
        task.delay(0.12, function()
            popup.Visible = false
        end)
    end

    local function buildOptions()
        for _, child in optList:GetChildren() do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for _, opt in options do
            local row = Instance.new("TextButton")
            row.Name = "Opt_" .. opt
            row.Size = UDim2.new(1, 0, 0, 26)
            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0
            row.TextColor3 = selected[opt] and theme.Text or theme.TextMuted
            row.TextSize = 11
            row.Font = Enum.Font.Gotham
            row.Text = opt
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.AutoButtonColor = false
            row.ZIndex = 100
            row.Parent = optList

            local rowPadding = Instance.new("UIPadding")
            rowPadding.PaddingLeft = UDim.new(0, 10)
            rowPadding.Parent = row

            row.MouseEnter:Connect(function()
                row.BackgroundTransparency = 0.88
                row.BackgroundColor3 = theme.Accent
            end)

            row.MouseLeave:Connect(function()
                row.BackgroundTransparency = 1
            end)

            row.MouseButton1Click:Connect(function()
                if multi then
                    if selected[opt] then
                        selected[opt] = nil
                    else
                        selected[opt] = true
                    end
                else
                    selected = {}
                    selected[opt] = true
                    closePopup()
                end

                for _, r in optList:GetChildren() do
                    if r:IsA("TextButton") then
                        local optName = r.Name:sub(5)
                        r.TextColor3 = selected[optName] and theme.Text or theme.TextMuted
                    end
                end

                refreshDisplay()

                if callback then
                    local arr = {}
                    for k in selected do table.insert(arr, k) end
                    callback(arr)
                end
            end)
        end
    end

    buildOptions()
    refreshDisplay()

    dropBtn.MouseButton1Click:Connect(function()
        if isOpen then closePopup() else openPopup() end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isOpen then
            local mp = UserInputService:GetMouseLocation()
            local p = popup.AbsolutePosition
            local s = popup.AbsoluteSize
            local inPopup = mp.X >= p.X and mp.X <= p.X + s.X and mp.Y >= p.Y and mp.Y <= p.Y + s.Y
            local db = dropBtn.AbsolutePosition
            local ds = dropBtn.AbsoluteSize
            local inBtn = mp.X >= db.X and mp.X <= db.X + ds.X and mp.Y >= db.Y and mp.Y <= db.Y + ds.Y
            if not inPopup and not inBtn then
                closePopup()
            end
        end
    end)

    local lockFn, unlockFn = makeLockOverlay(container, theme)

    local element = {
        Container = container,
        _id = id,
        Value = selected,
        _type = "Dropdown",
    }

    function element:SetOptions(newOptions)
        options = newOptions
        buildOptions()
        refreshDisplay()
    end

    function element:SetValue(val)
        selected = {}
        if type(val) == "table" then
            for _, v in val do selected[v] = true end
        else
            selected[val] = true
        end
        self.Value = selected
        refreshDisplay()
    end

    function element:Lock(reason)
        lockFn(reason)
    end

    function element:Unlock()
        unlockFn()
    end

    return element
end

-- ─────────────────────────────────────────────
--  Label
-- ─────────────────────────────────────────────

Elements.Label = {}

function Elements.Label.new(groupbox, id, name)
    local theme = groupbox._flux.Theme

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label_" .. id
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = theme.Text
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.Parent = groupbox.Page

    local element = {
        Label = lbl,
        _id = id,
        _type = "Label",
    }

    function element:SetText(text)
        lbl.Text = text
    end

    return element
end

-- ─────────────────────────────────────────────
--  Paragraph
-- ─────────────────────────────────────────────

Elements.Paragraph = {}

function Elements.Paragraph.new(groupbox, id, title, content)
    local theme = groupbox._flux.Theme

    local container = Instance.new("Frame")
    container.Name = "Paragraph_" .. id
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = groupbox.Page

    local containerLayout = Instance.new("UIListLayout")
    containerLayout.Padding = UDim.new(0, 3)
    containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    containerLayout.FillDirection = Enum.FillDirection.Vertical
    containerLayout.Parent = container

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 14)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = theme.Text
    titleLabel.TextSize = 12
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container

    local bodyLabel = Instance.new("TextLabel")
    bodyLabel.Name = "Body"
    bodyLabel.Size = UDim2.new(1, 0, 0, 0)
    bodyLabel.AutomaticSize = Enum.AutomaticSize.Y
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Text = content
    bodyLabel.TextColor3 = theme.TextMuted
    bodyLabel.TextSize = 11
    bodyLabel.Font = Enum.Font.Gotham
    bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bodyLabel.TextWrapped = true
    bodyLabel.Parent = container

    local element = {
        Container = container,
        _id = id,
        _type = "Paragraph",
    }

    function element:SetContent(newContent)
        bodyLabel.Text = newContent
    end

    function element:SetTitle(newTitle)
        titleLabel.Text = newTitle
    end

    return element
end

-- ─────────────────────────────────────────────
--  Divider
-- ─────────────────────────────────────────────

Elements.Divider = {}

function Elements.Divider.new(groupbox)
    local theme = groupbox._flux.Theme

    local line = Instance.new("Frame")
    line.Name = "Divider"
    line.Size = UDim2.new(1, 0, 0, 1)
    line.BackgroundColor3 = theme.Border
    line.BorderSizePixel = 0
    line.Parent = groupbox.Page

    return { Line = line }
end

-- ─────────────────────────────────────────────
--  ColorPicker
-- ─────────────────────────────────────────────
--
-- shows a small colored square next to a label.
-- clicking it opens a floating picker with:
--   - a saturation/value square
--   - a hue bar on the side
--   - hex input at the bottom
--
-- returns element.Value as a Color3

Elements.ColorPicker = {}

function Elements.ColorPicker.new(groupbox, id, name, default, callback)
    local theme = groupbox._flux.Theme
    default = default or Color3.fromRGB(255, 255, 255)

    local gui = groupbox._flux._gui

    -- the inline row that lives inside the groupbox
    local container = Instance.new("Frame")
    container.Name = "ColorPicker_" .. id
    container.Size = UDim2.new(1, 0, 0, 24)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = groupbox.Page

    local rowLabel = Instance.new("TextLabel")
    rowLabel.Size = UDim2.new(1, -32, 1, 0)
    rowLabel.BackgroundTransparency = 1
    rowLabel.Text = name
    rowLabel.TextColor3 = theme.Text
    rowLabel.TextSize = 12
    rowLabel.Font = Enum.Font.Gotham
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.TextTruncate = Enum.TextTruncate.AtEnd
    rowLabel.Parent = container

    -- the colored preview square
    local preview = Instance.new("TextButton")
    preview.Name = "Preview"
    preview.Size = UDim2.fromOffset(22, 22)
    preview.Position = UDim2.new(1, -22, 0.5, -11)
    preview.BackgroundColor3 = default
    preview.BorderSizePixel = 0
    preview.Text = ""
    preview.AutoButtonColor = false
    preview.Parent = container

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 4)
    previewCorner.Parent = preview

    local previewStroke = Instance.new("UIStroke")
    previewStroke.Color = theme.Border
    previewStroke.Thickness = 1
    previewStroke.Parent = preview

    -- ── floating picker panel ─────────────────
    local PICKER_W = 200
    local PICKER_H = 220

    local panel = Instance.new("Frame")
    panel.Name = "ColorPanel_" .. id
    panel.Size = UDim2.fromOffset(PICKER_W, PICKER_H)
    panel.BackgroundColor3 = theme.Surface
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 100
    panel.Parent = gui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 6)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = theme.Border
    panelStroke.Thickness = 1
    panelStroke.Parent = panel

    -- sv square (saturation on X, value on Y inverted)
    local svSquare = Instance.new("ImageLabel")
    svSquare.Name = "SVSquare"
    svSquare.Size = UDim2.fromOffset(160, 140)
    svSquare.Position = UDim2.fromOffset(10, 10)
    svSquare.BorderSizePixel = 0
    svSquare.ZIndex = 101
    -- this asset is a white-to-transparent horizontal gradient,
    -- overlaid on top of a hue-colored background
    svSquare.Image = "rbxassetid://4155801252"
    svSquare.Parent = panel

    local svSquareCorner = Instance.new("UICorner")
    svSquareCorner.CornerRadius = UDim.new(0, 3)
    svSquareCorner.Parent = svSquare

    -- dark-to-transparent vertical gradient over the sv square
    local svDark = Instance.new("ImageLabel")
    svDark.Size = UDim2.fromScale(1, 1)
    svDark.BackgroundTransparency = 1
    svDark.Image = "rbxassetid://4155801252"
    svDark.ImageColor3 = Color3.new(0, 0, 0)
    svDark.Rotation = 90
    svDark.ZIndex = 102
    svDark.Parent = svSquare

    -- cursor dot on the sv square
    local svCursor = Instance.new("Frame")
    svCursor.Name = "Cursor"
    svCursor.Size = UDim2.fromOffset(8, 8)
    svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    svCursor.BorderSizePixel = 0
    svCursor.ZIndex = 103
    svCursor.Parent = svSquare

    local svCursorCorner = Instance.new("UICorner")
    svCursorCorner.CornerRadius = UDim.new(1, 0)
    svCursorCorner.Parent = svCursor

    local svCursorStroke = Instance.new("UIStroke")
    svCursorStroke.Color = Color3.new(0, 0, 0)
    svCursorStroke.Thickness = 1
    svCursorStroke.Parent = svCursor

    -- hue bar on the right side
    local hueBar = Instance.new("ImageLabel")
    hueBar.Name = "HueBar"
    hueBar.Size = UDim2.fromOffset(14, 140)
    hueBar.Position = UDim2.fromOffset(178, 10)
    hueBar.BorderSizePixel = 0
    hueBar.Image = "rbxassetid://698052001" -- vertical rainbow gradient
    hueBar.ZIndex = 101
    hueBar.Parent = panel

    local hueBarCorner = Instance.new("UICorner")
    hueBarCorner.CornerRadius = UDim.new(0, 3)
    hueBarCorner.Parent = hueBar

    -- hue cursor line
    local hueCursor = Instance.new("Frame")
    hueCursor.Name = "HueCursor"
    hueCursor.Size = UDim2.new(1, 4, 0, 2)
    hueCursor.Position = UDim2.new(0, -2, 0, 0)
    hueCursor.AnchorPoint = Vector2.new(0, 0.5)
    hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    hueCursor.BorderSizePixel = 0
    hueCursor.ZIndex = 102
    hueCursor.Parent = hueBar

    local hueCursorCorner = Instance.new("UICorner")
    hueCursorCorner.CornerRadius = UDim.new(0, 1)
    hueCursorCorner.Parent = hueCursor

    -- hex input at the bottom
    local hexInput = Instance.new("TextBox")
    hexInput.Name = "HexInput"
    hexInput.Size = UDim2.new(1, -20, 0, 24)
    hexInput.Position = UDim2.fromOffset(10, 160)
    hexInput.BackgroundColor3 = theme.Background
    hexInput.BorderSizePixel = 0
    hexInput.TextColor3 = theme.Text
    hexInput.PlaceholderColor3 = theme.TextMuted
    hexInput.TextSize = 11
    hexInput.Font = Enum.Font.Code
    hexInput.Text = ""
    hexInput.PlaceholderText = "#FFFFFF"
    hexInput.ClearTextOnFocus = false
    hexInput.ZIndex = 101
    hexInput.Parent = panel

    local hexInputCorner = Instance.new("UICorner")
    hexInputCorner.CornerRadius = UDim.new(0, 4)
    hexInputCorner.Parent = hexInput

    local hexInputStroke = Instance.new("UIStroke")
    hexInputStroke.Color = theme.Border
    hexInputStroke.Thickness = 1
    hexInputStroke.Parent = hexInput

    local hexInputPadding = Instance.new("UIPadding")
    hexInputPadding.PaddingLeft = UDim.new(0, 6)
    hexInputPadding.Parent = hexInput

    -- current result preview strip at very bottom
    local resultStrip = Instance.new("Frame")
    resultStrip.Name = "ResultStrip"
    resultStrip.Size = UDim2.new(1, -20, 0, 16)
    resultStrip.Position = UDim2.fromOffset(10, 192)
    resultStrip.BackgroundColor3 = default
    resultStrip.BorderSizePixel = 0
    resultStrip.ZIndex = 101
    resultStrip.Parent = panel

    local resultStripCorner = Instance.new("UICorner")
    resultStripCorner.CornerRadius = UDim.new(0, 3)
    resultStripCorner.Parent = resultStrip

    -- ── state ─────────────────────────────────
    local h, s, v = Color3.toHSV(default)
    local currentColor = default
    local isOpen = false
    local draggingSV = false
    local draggingHue = false

    local function colorToHex(c)
        return string.format("#%02X%02X%02X",
            math.floor(c.R * 255 + 0.5),
            math.floor(c.G * 255 + 0.5),
            math.floor(c.B * 255 + 0.5)
        )
    end

    local function hexToColor(hex)
        hex = hex:gsub("#", "")
        if #hex ~= 6 then return nil end
        local r = tonumber(hex:sub(1, 2), 16)
        local g = tonumber(hex:sub(3, 4), 16)
        local b = tonumber(hex:sub(5, 6), 16)
        if not (r and g and b) then return nil end
        return Color3.fromRGB(r, g, b)
    end

    local function updateVisuals()
        -- update sv square background to current hue
        svSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

        -- move sv cursor
        svCursor.Position = UDim2.fromScale(s, 1 - v)

        -- move hue cursor
        hueCursor.Position = UDim2.new(0, -2, h, 0)

        -- update previews
        preview.BackgroundColor3 = currentColor
        resultStrip.BackgroundColor3 = currentColor

        -- update hex box only when not focused (don't interrupt typing)
        if not hexInput:IsFocused() then
            hexInput.Text = colorToHex(currentColor)
        end
    end

    local function applyColor(newH, newS, newV)
        h = math.clamp(newH, 0, 1)
        s = math.clamp(newS, 0, 1)
        v = math.clamp(newV, 0, 1)
        currentColor = Color3.fromHSV(h, s, v)
        updateVisuals()
        if callback then callback(currentColor) end
    end

    local function positionPanel()
        local abs = preview.AbsolutePosition
        local viewX = game.Workspace.CurrentCamera.ViewportSize.X
        local viewY = game.Workspace.CurrentCamera.ViewportSize.Y
        local px = abs.X + 26
        local py = abs.Y

        -- keep panel on screen
        if px + PICKER_W > viewX - 10 then
            px = abs.X - PICKER_W - 4
        end
        if py + PICKER_H > viewY - 10 then
            py = viewY - PICKER_H - 10
        end

        panel.Position = UDim2.fromOffset(px, py)
    end

    local function openPanel()
        isOpen = true
        positionPanel()
        panel.Visible = true
        updateVisuals()
        tween(panel, { BackgroundTransparency = 0 }, 0.1)
    end

    local function closePanel()
        isOpen = false
        panel.Visible = false
    end

    preview.MouseButton1Click:Connect(function()
        if isOpen then closePanel() else openPanel() end
    end)

    -- close when clicking outside
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not isOpen then return end

        local mp = UserInputService:GetMouseLocation()
        local pp = panel.AbsolutePosition
        local ps = panel.AbsoluteSize
        local inPanel = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
        local pv = preview.AbsolutePosition
        local pvs = preview.AbsoluteSize
        local inPreview = mp.X >= pv.X and mp.X <= pv.X + pvs.X and mp.Y >= pv.Y and mp.Y <= pv.Y + pvs.Y

        if not inPanel and not inPreview then
            closePanel()
        end
    end)

    -- sv square drag
    svSquare.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSV = true
        end
    end)

    -- hue bar drag
    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingHue = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSV = false
            draggingHue = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if not isOpen then return end

        local mp = UserInputService:GetMouseLocation()

        if draggingSV then
            local sqPos = svSquare.AbsolutePosition
            local sqSize = svSquare.AbsoluteSize
            local newS = math.clamp((mp.X - sqPos.X) / sqSize.X, 0, 1)
            local newV = 1 - math.clamp((mp.Y - sqPos.Y) / sqSize.Y, 0, 1)
            applyColor(h, newS, newV)
        end

        if draggingHue then
            local barPos = hueBar.AbsolutePosition
            local barSize = hueBar.AbsoluteSize
            local newH = math.clamp((mp.Y - barPos.Y) / barSize.Y, 0, 1)
            applyColor(newH, s, v)
        end
    end)

    -- hex input
    hexInput.FocusLost:Connect(function()
        local c = hexToColor(hexInput.Text)
        if c then
            local nh, ns, nv = Color3.toHSV(c)
            applyColor(nh, ns, nv)
        else
            -- invalid hex, reset the box to current color
            hexInput.Text = colorToHex(currentColor)
        end
    end)

    -- set initial visuals
    updateVisuals()

    local lockFn, unlockFn = makeLockOverlay(container, theme)

    local element = {
        Container = container,
        _id = id,
        Value = currentColor,
        _type = "ColorPicker",
    }

    function element:SetValue(color)
        local nh, ns, nv = Color3.toHSV(color)
        applyColor(nh, ns, nv)
        self.Value = currentColor
    end

    function element:Lock(reason)
        lockFn(reason)
    end

    function element:Unlock()
        unlockFn()
    end

    return element
end

return Elements