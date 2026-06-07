local Settings = {}

local UserInputService = game:GetService("UserInputService")

local function keycodeToString(kc)
    local str = tostring(kc)
    return str:match("Enum%.KeyCode%.(.+)") or str
end

function Settings.Create(flux)
    local theme = flux.Theme

    local tab = flux:AddTab("Settings", "rbxassetid://7733960981")

    -- appearence
    local appearGroup = flux:AddGroupbox(tab, "Appearance", 1)

    flux:AddLabel(appearGroup, "accent_label", "Accent Color")

    local presets = {
        {name = "White", color = Color3.fromRGB(255, 255, 255)},
        {name = "Blue", color = Color3.fromRGB(100, 149, 255)},
        {name = "Purple", color = Color3.fromRGB(160, 100, 255)},
        {name = "Red", color = Color3.fromRGB(255, 90, 90)},
        {name = "Green", color = Color3.fromRGB(90, 220, 130)},
        {name = "Orange", color = Color3.fromRGB(255, 160, 60)},
    }

    local swatchRow = Instance.new("Frame")
    swatchRow.Name = "SwatchRow"
    swatchRow.Size = UDim2.new(1, 0, 0, 28)
    swatchRow.BackgroundTransparency = 1
    swatchRow.BorderSizePixel = 0
    swatchRow.Parent = appearGroup.Page

    local swatchLayout = Instance.new("UIListLayout")
    swatchLayout.FillDirection = Enum.FillDirection.Horizontal
    swatchLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    swatchLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    swatchLayout.Padding = UDim.new(0, 6)
    swatchLayout.SortOrder = Enum.SortOrder.LayoutOrder
    swatchLayout.Parent = swatchRow

    local function updateSwatchBorders(activeName)
        for _, child in swatchRow:GetChildren() do
            if child:IsA("Frame") then
                local stroke = child:FindFirstChildWhichIsA("UIStroke")
                if stroke then
                    stroke.Transparency = child.Name == activeName and 0 or 1
                end
            end
        end
    end

    for i, preset in presets do
        local swatch = Instance.new("Frame")
        swatch.Name = preset.name
        swatch.Size = UDim2.fromOffset(20, 20)
        swatch.BackgroundColor3 = preset.color
        swatch.BorderSizePixel = 0
        swatch.LayoutOrder = i
        swatch.Parent = swatchRow

        local swatchCorner = Instance.new("UICorner")
        swatchCorner.CornerRadius = UDim.new(1, 0)
        swatchCorner.Parent = swatch

        local swatchStroke = Instance.new("UIStroke")
        swatchStroke.Color = Color3.fromRGB(255, 255, 255)
        swatchStroke.Thickness = 1.5
        swatchStroke.Transparency = 1
        swatchStroke.Parent = swatch

        local swatchInteract = Instance.new("TextButton")
        swatchInteract.Size = UDim2.fromScale(1, 1)
        swatchInteract.BackgroundTransparency = 1
        swatchInteract.Text = ""
        swatchInteract.Parent = swatch

        swatchInteract.MouseButton1Click:Connect(function()
            flux.Theme.Accent = preset.color
            updateSwatchBorders(preset.name)
            flux:Notify("Accent Updated", preset.name)
        end)
    end

    updateSwatchBorders("White")

    flux:AddDivider(appearGroup)

    flux:AddSlider(appearGroup, "ui_width", "UI Width", 300, 600, flux.Config.Width, "px", function(v)
        if flux._window then
            flux._window.Size = UDim2.fromOffset(v, flux.Config.Height)
        end
    end)

    -- controls
    local controlsGroup = flux:AddGroupbox(tab, "Controls", 2)

    local bindLabel = flux:AddLabel(controlsGroup, "keybind_label", "Keybind: " .. keycodeToString(flux.Config.Keybind))

    local rebindActive = false
    flux:AddButton(controlsGroup, "rebind_btn", "Change Keybind", function()
        if rebindActive then return end
        rebindActive = true
        bindLabel:SetText("Keybind: [ press a key ]")
        flux:Notify("Listening", "Press any key to rebind")

        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            conn:Disconnect()
            rebindActive = false
            flux.Config.Keybind = input.KeyCode
            local keyStr = keycodeToString(input.KeyCode)
            bindLabel:SetText("Keybind: " .. keyStr)
            flux:Notify("Keybind Set", keyStr)
        end)
    end)

    flux:AddDivider(controlsGroup)

    flux:AddButton(controlsGroup, "close_btn", "Close UI", function()
        flux._gui.Enabled = false
    end)

    flux:AddButton(controlsGroup, "destroy_btn", "Destroy UI", function()
        flux:Notify("Goodbye", "Flux destroyed")
        task.delay(0.5, function()
            flux._gui:Destroy()
        end)
    end)

    -- manage config
    -- only shows if SetupConfig() was called before this tab was created
    local configGroup = flux:AddGroupbox(tab, "Configs", 1)

    if not flux._configFolder then
        flux:AddParagraph(configGroup, "config_notice", "Config Unavailable",
            "Call flux:SetupConfig(\"FolderName\") before creating the Settings tab to enable saving.")
    else
        -- declare configDropdown up here so the save button callback can reference it
        local configDropdown

        local configNameInput = Instance.new("TextBox")
        configNameInput.Name = "ConfigNameInput"
        configNameInput.Size = UDim2.new(1, 0, 0, 26)
        configNameInput.BackgroundColor3 = theme.Background
        configNameInput.BorderSizePixel = 0
        configNameInput.TextColor3 = theme.Text
        configNameInput.PlaceholderColor3 = theme.TextMuted
        configNameInput.PlaceholderText = "Config name..."
        configNameInput.Text = ""
        configNameInput.TextSize = 11
        configNameInput.Font = Enum.Font.Gotham
        configNameInput.ClearTextOnFocus = false
        configNameInput.Parent = configGroup.Page

        local configInputCorner = Instance.new("UICorner")
        configInputCorner.CornerRadius = UDim.new(0, 4)
        configInputCorner.Parent = configNameInput

        local configInputStroke = Instance.new("UIStroke")
        configInputStroke.Color = theme.Border
        configInputStroke.Thickness = 1
        configInputStroke.Parent = configNameInput

        local configInputPadding = Instance.new("UIPadding")
        configInputPadding.PaddingLeft = UDim.new(0, 8)
        configInputPadding.Parent = configNameInput

        flux:AddButton(configGroup, "config_save", "Save Config", function()
            local name = configNameInput.Text
            if name == "" then
                flux:Notify("Config", "Enter a name first")
                return
            end
            flux:SaveConfig(name)
            configDropdown:SetOptions(flux:ListConfigs())
        end)

        flux:AddDivider(configGroup)

        configDropdown = flux:AddDropdown(configGroup, "config_select", "Saved Configs", flux:ListConfigs(), {}, false, function(_selected)
            -- selection tracked via configDropdown.Value, buttons below read it
        end)

        flux:AddButton(configGroup, "config_load", "Load Selected", function()
            local selected = next(configDropdown.Value)
            if not selected then
                flux:Notify("Config", "Select a config first")
                return
            end
            flux:LoadConfig(selected)
        end)

        flux:AddButton(configGroup, "config_autoload", "Set as Autoload", function()
            local selected = next(configDropdown.Value)
            if not selected then
                flux:Notify("Config", "Select a config first")
                return
            end
            flux:SetAutoload(selected)
            flux:Notify("Autoload Set", selected .. " will load on startup")
        end)

        flux:AddButton(configGroup, "config_delete", "Delete Selected", function()
            local selected = next(configDropdown.Value)
            if not selected then
                flux:Notify("Config", "Select a config first")
                return
            end
            local ok, err = flux:DeleteConfig(selected)
            if ok then
                flux:Notify("Config Deleted", selected)
                configDropdown:SetOptions(flux:ListConfigs())
            else
                flux:Notify("Delete Failed", tostring(err))
            end
        end)

        local Config = require(script.Parent.Parent.core.Config)
        local autoloadName = Config.GetAutoload(flux) or "None"
        local autoloadLabel = flux:AddLabel(configGroup, "autoload_label", "Autoload: " .. autoloadName)

        flux:AddButton(configGroup, "config_clear_autoload", "Clear Autoload", function()
            flux:ClearAutoload()
            autoloadLabel:SetText("Autoload: None")
            flux:Notify("Autoload Cleared", "")
        end)
    end

    -- about
    local aboutGroup = flux:AddGroupbox(tab, "About", 2)

    flux:AddParagraph(aboutGroup, "about_text", "Flux UI Library",
        "Made by Plasma (8zsk)\nPure Lua, no model assets\ngithub.com/PlasmaLMAO")

    flux:AddDivider(aboutGroup)

    flux:AddLabel(aboutGroup, "version_label", "Version: " .. flux.Config.Version)

    return tab
end

return Settings
