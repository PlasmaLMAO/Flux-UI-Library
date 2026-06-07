# Flux
A clean, minimal Roblox UI library built entirely from scratch in pure Lua. No model assets, no asset IDs required for the library itself — everything is constructed in code.

Built by [Plasma](https://github.com/PlasmaLMAO).

---

## Features
- Pure Lua — no Roblox model required, works via loadstring
- Dark minimal aesthetic with a customizable accent color
- Icon sidebar with tab switching
- Two-column groupbox layout
- Full element set: Toggle, Slider, Button, Dropdown, Label, Paragraph, Divider, ColorPicker
- Lock / Unlock on all interactive elements
- Config save/load system with autoload support
- Toast notifications
- Built-in Dashboard tab (player info, game info, session stats)
- Built-in Settings tab (accent presets, keybind rebinding, config management)

---

## Installation

Paste this at the top of your script:

```lua
local Flux = loadstring(game:HttpGet("https://raw.githubusercontent.com/PlasmaLMAO/Flux-UI-Library/main/init.luau"))()
```

If you want the built-in Dashboard and Settings tabs:

```lua
local Dashboard = loadstring(game:HttpGet("https://raw.githubusercontent.com/PlasmaLMAO/Flux-UI-Library/main/tabs/Dashboard.luau"))()
local Settings = loadstring(game:HttpGet("https://raw.githubusercontent.com/PlasmaLMAO/Flux-UI-Library/main/tabs/Settings.luau"))()
```

---

## Quick Start

```lua
local Flux = loadstring(game:HttpGet("https://raw.githubusercontent.com/PlasmaLMAO/Flux-UI-Library/main/init.luau"))()
local Dashboard = loadstring(game:HttpGet("https://raw.githubusercontent.com/PlasmaLMAO/Flux-UI-Library/main/tabs/Dashboard.luau"))()
local Settings = loadstring(game:HttpGet("https://raw.githubusercontent.com/PlasmaLMAO/Flux-UI-Library/main/tabs/Settings.luau"))()

-- setup config before Init so the settings tab shows the config UI
Flux:SetupConfig("MyScript")

local ui = Flux:Init({
    Name = "My Script",
    Version = "1.0.0",
    Keybind = Enum.KeyCode.RightShift,
})

-- built-in tabs
Dashboard.Create(ui)

-- your own tabs
local tab = ui:AddTab("Main", "rbxassetid://your_icon_here")
local group = ui:AddGroupbox(tab, "Combat", 1)

ui:AddToggle(group, "esp", "ESP", false, function(v)
    print("esp:", v)
end)

ui:AddSlider(group, "fov", "FOV", 1, 360, 90, "°", function(v)
    print("fov:", v)
end)

-- settings always last
Settings.Create(ui)

-- auto-load last saved config
ui:LoadAutoload()
```

---

## API Reference

### Flux:Init(config)
Boots the library and builds the window. Call this first.

```lua
local ui = Flux:Init({
    Name = "My Script",        -- window title
    Version = "1.0.0",         -- shown in the about section
    Keybind = Enum.KeyCode.RightShift,  -- toggle visibility
    Width = 520,               -- window width in pixels
    Height = 340,              -- window height in pixels
    Theme = {                  -- optional theme overrides
        Accent = Color3.fromRGB(100, 149, 255),
    },
})
```

---

### Flux:AddTab(name, icon)
Creates a new tab in the sidebar. Returns a tab object.

```lua
local tab = ui:AddTab("Main", "rbxassetid://10734950834")
```

| Param | Type | Description |
|---|---|---|
| name | string | Tab name, shown in the topbar when active |
| icon | string | rbxassetid URL for the sidebar icon |

---

### Flux:AddGroupbox(tab, name, column)
Creates a groupbox inside a tab. Returns a groupbox object.

```lua
local group = ui:AddGroupbox(tab, "Options", 1)
```

| Param | Type | Description |
|---|---|---|
| tab | Tab | The tab to put this groupbox in |
| name | string | Groupbox header text |
| column | number | 1 or 2 — which column to place it in |

---

### Flux:AddToggle(groupbox, id, name, default, callback)
A checkbox-style toggle.

```lua
local toggle = ui:AddToggle(group, "my_toggle", "Enable Thing", false, function(value)
    print(value) -- true or false
end)

-- read or set from outside the callback
print(toggle.Value)
toggle:SetValue(true)

-- lock to prevent interaction
toggle:Lock("Requires Pro")
toggle:Unlock()
```

| Param | Type | Description |
|---|---|---|
| groupbox | Groupbox | Where to place this element |
| id | string | Unique ID used for config saving |
| name | string | Label text |
| default | boolean | Starting value |
| callback | function(bool) | Fires when toggled |

---

### Flux:AddSlider(groupbox, id, name, min, max, default, suffix, callback)
A draggable value slider.

```lua
local slider = ui:AddSlider(group, "my_slider", "Walk Speed", 0, 100, 16, nil, function(value)
    print(value)
end)

slider:SetValue(50)
slider:Lock("Locked")
slider:Unlock()
```

| Param | Type | Description |
|---|---|---|
| min | number | Minimum value |
| max | number | Maximum value |
| default | number | Starting value |
| suffix | string? | Unit shown after the value, e.g. `"°"` or `"ms"`. Pass `nil` for none |
| callback | function(number) | Fires while dragging |

---

### Flux:AddButton(groupbox, id, name, callback)
A clickable button.

```lua
local btn = ui:AddButton(group, "my_btn", "Do Something", function()
    print("clicked")
end)

btn:Lock("Not available")
btn:Unlock()
```

---

### Flux:AddDropdown(groupbox, id, name, options, default, multi, callback)
A dropdown with single or multi-select.

```lua
local drop = ui:AddDropdown(group, "my_drop", "Aim Part",
    { "Head", "Torso", "LeftArm" },
    { "Head" },
    false, -- multi-select off
    function(selected)
        print(selected[1]) -- array of selected option strings
    end
)

drop:SetValue({ "Torso" })
drop:SetOptions({ "Head", "Torso" }) -- replace the option list
drop:Lock("Locked")
drop:Unlock()
```

| Param | Type | Description |
|---|---|---|
| options | table | Array of option strings |
| default | table | Array of initially selected options |
| multi | boolean | Allow selecting more than one option |
| callback | function(table) | Fires on selection change, receives array of selected strings |

---

### Flux:AddColorPicker(groupbox, id, name, default, callback)
A color picker with an SV square, hue bar, and hex input.

```lua
local cp = ui:AddColorPicker(group, "my_color", "ESP Color", Color3.fromRGB(255, 50, 50), function(color)
    print(color) -- Color3
end)

cp:SetValue(Color3.fromRGB(0, 255, 0))
cp:Lock("Locked")
cp:Unlock()
```

| Param | Type | Description |
|---|---|---|
| default | Color3 | Starting color |
| callback | function(Color3) | Fires when the color changes |

---

### Flux:AddLabel(groupbox, id, name)
A simple text label.

```lua
local lbl = ui:AddLabel(group, "my_label", "Status: Ready")

lbl:SetText("Status: Active")
```

---

### Flux:AddParagraph(groupbox, id, title, content)
A title with a body of wrapped text below it.

```lua
ui:AddParagraph(group, "my_para", "About", "Some longer description text that wraps.")
```

---

### Flux:AddDivider(groupbox)
A horizontal separator line.

```lua
ui:AddDivider(group)
```

---

### Flux:Notify(title, body, duration)
Shows a toast notification in the bottom-right corner.

```lua
ui:Notify("Hello", "Script loaded successfully", 3)
```

| Param | Type | Description |
|---|---|---|
| title | string | Bold heading |
| body | string? | Subtext below the title |
| duration | number? | Seconds before it disappears. Defaults to 3 |

---

## Config System

Flux can save and load element states (toggles, sliders, dropdowns, color pickers) to JSON files on disk.

### Setup
Call `SetupConfig` before `Init` so the Settings tab can show the config UI:

```lua
Flux:SetupConfig("MyScript") -- creates Flux/MyScript/ folder
local ui = Flux:Init({ Name = "My Script" })
```

### Saving and Loading

```lua
-- save current state
ui:SaveConfig("default")

-- load a saved config
ui:LoadConfig("default")

-- set a config to auto-load on next run
ui:SetAutoload("default")

-- load the autoload config (call at end of your setup)
ui:LoadAutoload()

-- list all saved configs
local configs = ui:ListConfigs() -- returns { "default", "pvp", ... }

-- delete a config
ui:DeleteConfig("default")

-- clear the autoload
ui:ClearAutoload()
```

### Ignoring an element
If you don't want an element saved/loaded, set `IgnoreConfig = true` when you have access to the element object:

```lua
local toggle = ui:AddToggle(group, "internal_flag", "Hidden", false, function(v) end)
toggle.IgnoreConfig = true
```

---

## Theme Customization

Pass a `Theme` table inside `Init` to override any colors:

```lua
local ui = Flux:Init({
    Name = "My Script",
    Theme = {
        Accent = Color3.fromRGB(100, 149, 255),
        Background = Color3.fromRGB(15, 15, 15),
    }
})
```

All theme keys:

| Key | Default | Description |
|---|---|---|
| Background | `18, 18, 18` | Outermost window background |
| Surface | `26, 26, 26` | Groupbox and element backgrounds |
| Sidebar | `14, 14, 14` | Sidebar background |
| Border | `40, 40, 40` | Strokes and dividers |
| Text | `210, 210, 210` | Primary text |
| TextMuted | `90, 90, 90` | Secondary and inactive text |
| Accent | `255, 255, 255` | Active indicators, toggle fill, slider fill |
| Toggle_Off | `50, 50, 50` | Toggle pill background when off |

---

## Built-in Tabs

### Dashboard
Shows player info (avatar, display name, username, user ID, account age), game info (name, place ID, server ID, player count), and session stats (session time, ping, friend count).

```lua
local Dashboard = loadstring(game:HttpGet("https://raw.githubusercontent.com/PlasmaLMAO/Flux-UI-Library/main/tabs/Dashboard.luau"))()
Dashboard.Create(ui)
```

### Settings
Accent color presets, keybind rebinding, config save/load UI, and an about section. Automatically shows the config UI if `SetupConfig` was called beforehand.

```lua
local Settings = loadstring(game:HttpGet("https://raw.githubusercontent.com/PlasmaLMAO/Flux-UI-Library/main/tabs/Settings.luau"))()
Settings.Create(ui) -- call this last, after all your own tabs
```

---

## License
MIT — see [LICENSE](LICENSE).