MowerCounter = {}
MowerCounter.modName = g_currentModName
MowerCounter.schemaKey = ("vehicles.vehicle(?).%s.mowerCounter#area"):format(g_currentModName)

---@param specializations table
function MowerCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Mower, specializations)
end

---
function MowerCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("MowerCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.mowerCounter.dashoards", {"usageCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, MowerCounter.schemaKey, "Mowed area in hectares")
end

---
function MowerCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", MowerCounter)
end

---@param savegame table
function MowerCounter:onLoad(savegame)
    local spec = self.spec_mower
    spec.usageCounter = 0

    if savegame ~= nil and not savegame.resetVehicles then
        spec.usageCounter = savegame.xmlFile:getValue(savegame.key .. "." .. MowerCounter.modName .. ".mowerCounter#area", spec.usageCounter) or 0
    end
end

---
function MowerCounter:onDraw()
    local spec = self.spec_mower
    local area = g_i18n:getArea(spec.usageCounter)
    local unit = g_i18n:getAreaUnit(true)
    local text = g_i18n:getText("statistic_mowerCounter"):format(area, unit)

    g_currentMission:addExtraPrintText(text)
end

---@param streamId number
---@param connection number
function MowerCounter:onReadStream(streamId, connection)
    local spec = self.spec_mower
    spec.usageCounter = streamReadFloat32(streamId)
end

---@param streamId number
---@param connection number
function MowerCounter:onWriteStream(streamId, connection)
    local spec = self.spec_mower
    streamWriteFloat32(streamId, spec.usageCounter)
end

---Called on post load to register dashboard value types
function MowerCounter:onRegisterDashboardValueTypes()
    local spec = self.spec_mower

    local usageCounter = DashboardValueType.new("mowerCounter", "usageCounter")
    usageCounter:setValue(spec, "usageCounter")
    self:registerDashboardValueType(usageCounter)
end

---
function MowerCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_mower
    xmlFile:setValue(key .. "#area", spec.usageCounter or 0)
end

---
function MowerCounter:onEndWorkAreaProcessing()
    local spec = self.spec_mower
    local lastStatsArea = spec.workAreaParameters.lastStatsArea

    if lastStatsArea > 0 then
        local delta = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
        spec.usageCounter = spec.usageCounter + delta
    end
end
