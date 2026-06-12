SprayerCounter = {}
SprayerCounter.modName = g_currentModName
SprayerCounter.schemaKey = ("vehicles.vehicle(?).%s.sprayerCounter#area"):format(g_currentModName)
SprayerCounter.sessionSchemaKey = ("vehicles.vehicle(?).%s.sprayerCounter#session"):format(g_currentModName)

---@param specializations table
function SprayerCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Sprayer, specializations)
end

---
function SprayerCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("SprayerCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.sprayerCounter.dashoards", {"usageCounter", "sessionCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, SprayerCounter.schemaKey, "Sprayed area in hectares")
    schemaSavegame:register(XMLValueType.FLOAT, SprayerCounter.sessionSchemaKey, "Sprayed area this session in hectares")
end

---
function SprayerCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", SprayerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", SprayerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SprayerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SprayerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", SprayerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", SprayerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", SprayerCounter)
end

---@param savegame table
function SprayerCounter:onLoad(savegame)
    local spec = self.spec_sprayer
    spec.usageCounter = 0
    spec.sessionCounter = 0
    spec.counterActionEvents = {}

    if savegame ~= nil and not savegame.resetVehicles then
        spec.usageCounter = savegame.xmlFile:getValue(savegame.key .. "." .. SprayerCounter.modName .. ".sprayerCounter#area", spec.usageCounter) or 0
        spec.sessionCounter = savegame.xmlFile:getValue(savegame.key .. "." .. SprayerCounter.modName .. ".sprayerCounter#session", spec.sessionCounter) or 0
    end
end

---
function SprayerCounter:onDraw()
    local spec = self.spec_sprayer
    local unit = g_i18n:getAreaUnit(true)
    local area = g_i18n:getArea(spec.usageCounter)
    local sessionArea = g_i18n:getArea(spec.sessionCounter)
    local text = g_i18n:getText("statistic_sprayerCounter"):format(area, unit)
        .. g_i18n:getText("statistic_sessionArea"):format(sessionArea, unit)

    g_currentMission:addExtraPrintText(text)
end

---@param streamId number
---@param connection number
function SprayerCounter:onReadStream(streamId, connection)
    local spec = self.spec_sprayer
    spec.usageCounter = streamReadFloat32(streamId)
    spec.sessionCounter = streamReadFloat32(streamId)
end

---@param streamId number
---@param connection number
function SprayerCounter:onWriteStream(streamId, connection)
    local spec = self.spec_sprayer
    streamWriteFloat32(streamId, spec.usageCounter)
    streamWriteFloat32(streamId, spec.sessionCounter)
end

---Called on post load to register dashboard value types
function SprayerCounter:onRegisterDashboardValueTypes()
    local spec = self.spec_sprayer

    local usageCounter = DashboardValueType.new("sprayerCounter", "usageCounter")
    usageCounter:setValue(spec, "usageCounter")
    self:registerDashboardValueType(usageCounter)

    local sessionCounter = DashboardValueType.new("sprayerCounter", "sessionCounter")
    sessionCounter:setValue(spec, "sessionCounter")
    self:registerDashboardValueType(sessionCounter)
end

---
function SprayerCounter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_sprayer
        spec.counterActionEvents = spec.counterActionEvents or {}
        self:clearActionEventsTable(spec.counterActionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.counterActionEvents, InputAction.IMPLEMENT_USAGE_COUNTER_RESET, self, SprayerCounter.actionEventResetCounter, false, true, false, true, nil)
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("input_IMPLEMENT_USAGE_COUNTER_RESET"))
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
        end
    end
end

---
function SprayerCounter:actionEventResetCounter()
    local spec = self.spec_sprayer
    spec.sessionCounter = 0
    UsageCounterResetEvent.sendEvent(self, "spec_sprayer")
end

---
function SprayerCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_sprayer
    xmlFile:setValue(key .. "#area", spec.usageCounter or 0)
    xmlFile:setValue(key .. "#session", spec.sessionCounter or 0)
end

---
function SprayerCounter:onEndWorkAreaProcessing()
    local spec = self.spec_sprayer
    local lastStatsArea = spec.workAreaParameters.lastStatsArea

    if lastStatsArea > 0 then
        local delta = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
        spec.usageCounter = spec.usageCounter + delta
        spec.sessionCounter = spec.sessionCounter + delta
    end
end