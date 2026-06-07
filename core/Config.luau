local Config = {}

local HttpService = game:GetService("HttpService")

local ROOT_FOLDER = "Flux"

local function ensureFolder()
    if not isfolder(ROOT_FOLDER) then
        makefolder(ROOT_FOLDER)
    end
end

local function filePath(configFolder, name)
    return ROOT_FOLDER .. "/" .. configFolder .. "/" .. name .. ".json"
end

local function folderPath(configFolder)
    return ROOT_FOLDER .. "/" .. configFolder
end

local function collectElements(flux)
    local data = {}

    for _, tab in flux._tabs do
        local page = tab.Page

        for _, col in page:GetChildren() do
            if not col.Name:match("^Column_") then continue end

            for _, box in col:GetChildren() do
                if not box.Name:match("^Groupbox_") then continue end

                local contentPage = box:FindFirstChild("Page")
                if not contentPage then continue end

                for _, inst in contentPage:GetChildren() do
                    local el = flux._elementRegistry and flux._elementRegistry[inst.Name]
                    if not el then continue end
                    if el.IgnoreConfig then continue end
                    if not el._type or not el.Value then continue end

                    local key = tab.Name .. "." .. box.Name .. "." .. inst.Name

                    if el._type == "Toggle" then
                        data[key] = { type = "Toggle", value = el.Value }

                    elseif el._type == "Slider" then
                        data[key] = { type = "Slider", value = el.Value }

                    elseif el._type == "Dropdown" then
                        local arr = {}
                        for k in el.Value do table.insert(arr, k) end
                        data[key] = { type = "Dropdown", value = arr }

                    elseif el._type == "ColorPicker" then
                        local c = el.Value
                        data[key] = {
                            type = "ColorPicker",
                            value = {
                                r = math.floor(c.R * 255 + 0.5),
                                g = math.floor(c.G * 255 + 0.5),
                                b = math.floor(c.B * 255 + 0.5),
                            }
                        }
                    end
                end
            end
        end
    end

    return data
end

local function applyElements(flux, data)
    for key, entry in data do
        local el = flux._elementRegistry and flux._elementRegistry[key]
        if not el then continue end
        if el._type ~= entry.type then continue end

        if entry.type == "Toggle" then
            el:SetValue(entry.value)

        elseif entry.type == "Slider" then
            el:SetValue(entry.value)

        elseif entry.type == "Dropdown" then
            el:SetValue(entry.value)

        elseif entry.type == "ColorPicker" then
            local v = entry.value
            el:SetValue(Color3.fromRGB(v.r, v.g, v.b))
        end
    end
end

-- ─────────────────────────────────────────────
--  public API
-- ─────────────────────────────────────────────

function Config.Setup(flux, configFolder)
    flux._configFolder = configFolder

    ensureFolder()

    local fp = folderPath(configFolder)
    if not isfolder(fp) then
        makefolder(fp)
    end
end

function Config.Save(flux, name)
    if not flux._configFolder then
        warn("Flux Config: no config folder set, call SetupConfig() first")
        return false, "no config folder"
    end

    ensureFolder()

    local ok, data = pcall(collectElements, flux)
    if not ok then
        warn("Flux Config: failed to collect elements - " .. tostring(data))
        return false, data
    end

    local ok2, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok2 then
        warn("Flux Config: failed to encode - " .. tostring(encoded))
        return false, encoded
    end

    local path = filePath(flux._configFolder, name)
    local ok3, err = pcall(writefile, path, encoded)
    if not ok3 then
        warn("Flux Config: failed to write file - " .. tostring(err))
        return false, err
    end

    return true
end

function Config.Load(flux, name)
    if not flux._configFolder then
        warn("Flux Config: no config folder set, call SetupConfig() first")
        return false, "no config folder"
    end

    local path = filePath(flux._configFolder, name)

    if not isfile(path) then
        return false, "file not found: " .. path
    end

    local ok, raw = pcall(readfile, path)
    if not ok then
        warn("Flux Config: failed to read file - " .. tostring(raw))
        return false, raw
    end

    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 then
        warn("Flux Config: failed to decode - " .. tostring(data))
        return false, data
    end

    local ok3, err = pcall(applyElements, flux, data)
    if not ok3 then
        warn("Flux Config: failed to apply elements - " .. tostring(err))
        return false, err
    end

    return true
end

function Config.SetAutoload(flux, name)
    if not flux._configFolder then return false, "no config folder" end

    ensureFolder()

    local path = folderPath(flux._configFolder) .. "/autoload.txt"
    local ok, err = pcall(writefile, path, name)
    if not ok then return false, err end

    return true
end

function Config.ClearAutoload(flux)
    if not flux._configFolder then return false, "no config folder" end

    local path = folderPath(flux._configFolder) .. "/autoload.txt"
    if isfile(path) then
        pcall(delfile, path)
    end

    return true
end

function Config.GetAutoload(flux)
    if not flux._configFolder then return nil end

    local path = folderPath(flux._configFolder) .. "/autoload.txt"
    if not isfile(path) then return nil end

    local ok, name = pcall(readfile, path)
    if not ok then return nil end

    return name ~= "" and name or nil
end

function Config.LoadAutoload(flux)
    local name = Config.GetAutoload(flux)
    if not name then return false, "no autoload set" end

    return Config.Load(flux, name)
end

function Config.List(flux)
    if not flux._configFolder then return {} end

    local fp = folderPath(flux._configFolder)
    if not isfolder(fp) then return {} end

    local files = listfiles(fp)
    local names = {}

    for _, f in files do
        if f:sub(-5) == ".json" then
            local name = f:match("([^/\\]+)%.json$")
            if name then
                table.insert(names, name)
            end
        end
    end

    return names
end

function Config.Delete(flux, name)
    if not flux._configFolder then return false, "no config folder" end

    local path = filePath(flux._configFolder, name)
    if not isfile(path) then return false, "file not found" end

    local ok, err = pcall(delfile, path)
    if not ok then return false, err end

    return true
end

return Config
