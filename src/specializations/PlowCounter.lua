PlowCounter = {}
PlowCounter.modName = g_currentModName
PlowCounter.schemaKey = ("vehicles.vehicle(?).%s.plowCounter#area"):format(g_currentModName)

---@param specializations table
function PlowCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Plow, specializations)
end

---
function PlowCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("PlowCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.plowCounter.dashoards", {"usageCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, PlowCounter.schemaKey, "Plowed area in hectares")
end

---
function PlowCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", PlowCounter)
end

---@param savegame table
function PlowCounter:onLoad(savegame)
    local spec = self.spec_plow
    spec.usageCounter = 0

    if savegame ~= nil and not savegame.resetVehicles then
        spec.usageCounter = savegame.xmlFile:getValue(savegame.key .. "." .. PlowCounter.modName .. ".plowCounter#area", spec.usageCounter) or 0
    end
end

---
function PlowCounter:onDraw()
    local spec = self.spec_plow
    local area = g_i18n:getArea(spec.usageCounter)
    local unit = g_i18n:getAreaUnit(true)
    local text = g_i18n:getText("statistic_plowCounter"):format(area, unit)

    g_currentMission:addExtraPrintText(text)
end

---@param streamId number
---@param connection number
function PlowCounter:onReadStream(streamId, connection)
    local spec = self.spec_plow
    spec.usageCounter = streamReadFloat32(streamId)
end

---@param streamId number
---@param connection number
function PlowCounter:onWriteStream(streamId, connection)
    local spec = self.spec_plow
    streamWriteFloat32(streamId, spec.usageCounter)
end

---Called on post load to register dashboard value types
function PlowCounter:onRegisterDashboardValueTypes()
    local spec = self.spec_plow

    local usageCounter = DashboardValueType.new("plowCounter", "usageCounter")
    usageCounter:setValue(spec, "usageCounter")
    self:registerDashboardValueType(usageCounter)
end

---
function PlowCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_plow
    xmlFile:setValue(key .. "#area", spec.usageCounter or 0)
end

---
function PlowCounter:onEndWorkAreaProcessing()
    local spec = self.spec_plow
    local lastStatsArea = spec.workAreaParameters.lastStatsArea

    if lastStatsArea > 0 then
        local delta = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
        spec.usageCounter = spec.usageCounter + delta
    end
end
