CutterCounter = {}
CutterCounter.modName = g_currentModName
CutterCounter.modDir = g_currentModDirectory
CutterCounter.schemaKey = ("vehicles.vehicle(?).%s.cutterCounter#area"):format(g_currentModName)

---@param specializations table
function CutterCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Cutter, specializations)
end

---
function CutterCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("CutterCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.cutterCounter.dashoards", {"usageCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, CutterCounter.schemaKey, "Cultivated area in hectares")
end

---
function CutterCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", CutterCounter)
end

---@param savegame table
function CutterCounter:onLoad(savegame)
    local spec = self.spec_cutter
    spec.usageCounter = 0

    if savegame ~= nil and not savegame.resetVehicles then
        spec.usageCounter = savegame.xmlFile:getValue(savegame.key .. "." .. CutterCounter.modName .. ".cutterCounter#area", spec.usageCounter) or 0
    end
end

---
function CutterCounter:onDraw()
    local spec = self.spec_cutter
    local area = g_i18n:getArea(spec.usageCounter)
    local unit = g_i18n:getAreaUnit(true)
    local text = g_i18n:getText("statistic_cutterCounter"):format(area, unit)

    g_currentMission:addExtraPrintText(text)
end

---@param streamId number
---@param connection number
function CutterCounter:onReadStream(streamId, connection)
    local spec = self.spec_cutter
    spec.usageCounter = streamReadFloat32(streamId)
end

---@param streamId number
---@param connection number
function CutterCounter:onWriteStream(streamId, connection)
    local spec = self.spec_cutter
    streamWriteFloat32(streamId, spec.usageCounter)
end

---Called on post load to register dashboard value types
function CutterCounter:onRegisterDashboardValueTypes()
    local spec = self.spec_cutter

    local usageCounter = DashboardValueType.new("cutterCounter", "usageCounter")
    usageCounter:setValue(spec, "usageCounter")
    self:registerDashboardValueType(usageCounter)
end

---
function CutterCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_cutter
    xmlFile:setValue(key .. "#area", spec.usageCounter or 0)
end

---
function CutterCounter:onEndWorkAreaProcessing()
    local spec = self.spec_cutter
    local lastStatsArea = spec.workAreaParameters.lastArea

    if lastStatsArea > 0 then
        local delta = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
        spec.usageCounter = spec.usageCounter + delta
    end
end
