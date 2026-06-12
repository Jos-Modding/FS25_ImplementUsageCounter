CultivatorCounter = {}
CultivatorCounter.modName = g_currentModName
CultivatorCounter.modDir = g_currentModDirectory
CultivatorCounter.schemaKey = ("vehicles.vehicle(?).%s.cultivatorCounter#area"):format(g_currentModName)
CultivatorCounter.sessionSchemaKey = ("vehicles.vehicle(?).%s.cultivatorCounter#session"):format(g_currentModName)

---@param specializations table
function CultivatorCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Cultivator, specializations)
end

---
function CultivatorCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("CultivatorCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.cultivatorCounter.dashoards", {"usageCounter", "sessionCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, CultivatorCounter.schemaKey, "Cultivated area in hectares")
    schemaSavegame:register(XMLValueType.FLOAT, CultivatorCounter.sessionSchemaKey, "Cultivated area this session in hectares")
end

---
function CultivatorCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", CultivatorCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", CultivatorCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", CultivatorCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", CultivatorCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", CultivatorCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CultivatorCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", CultivatorCounter)
end

---@param savegame table
function CultivatorCounter:onLoad(savegame)
    local spec = self.spec_cultivator
    spec.usageCounter = 0
    spec.sessionCounter = 0
    spec.counterActionEvents = {}

    if savegame ~= nil and not savegame.resetVehicles then
        spec.usageCounter = savegame.xmlFile:getValue(savegame.key .. "." .. CultivatorCounter.modName .. ".cultivatorCounter#area", spec.usageCounter) or 0
        spec.sessionCounter = savegame.xmlFile:getValue(savegame.key .. "." .. CultivatorCounter.modName .. ".cultivatorCounter#session", spec.sessionCounter) or 0
    end
end

---
function CultivatorCounter:onDraw()
    local spec = self.spec_cultivator
    local unit = g_i18n:getAreaUnit(true)
    local area = g_i18n:getArea(spec.usageCounter)
    local sessionArea = g_i18n:getArea(spec.sessionCounter)
    local text = g_i18n:getText("statistic_cultivatorCounter"):format(area, unit)
        .. g_i18n:getText("statistic_sessionArea"):format(sessionArea, unit)

    g_currentMission:addExtraPrintText(text)
end

---@param streamId number
---@param connection number
function CultivatorCounter:onReadStream(streamId, connection)
    local spec = self.spec_cultivator
    spec.usageCounter = streamReadFloat32(streamId)
    spec.sessionCounter = streamReadFloat32(streamId)
end

---@param streamId number
---@param connection number
function CultivatorCounter:onWriteStream(streamId, connection)
    local spec = self.spec_cultivator
    streamWriteFloat32(streamId, spec.usageCounter)
    streamWriteFloat32(streamId, spec.sessionCounter)
end

---Called on post load to register dashboard value types
function CultivatorCounter:onRegisterDashboardValueTypes()
    local spec = self.spec_cultivator

    local usageCounter = DashboardValueType.new("cultivatorCounter", "usageCounter")
    usageCounter:setValue(spec, "usageCounter")
    self:registerDashboardValueType(usageCounter)

    local sessionCounter = DashboardValueType.new("cultivatorCounter", "sessionCounter")
    sessionCounter:setValue(spec, "sessionCounter")
    self:registerDashboardValueType(sessionCounter)
end

---
function CultivatorCounter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_cultivator
        spec.counterActionEvents = spec.counterActionEvents or {}
        self:clearActionEventsTable(spec.counterActionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.counterActionEvents, InputAction.IMPLEMENT_USAGE_COUNTER_RESET, self, CultivatorCounter.actionEventResetCounter, false, true, false, true, nil)
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("input_IMPLEMENT_USAGE_COUNTER_RESET"))
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
        end
    end
end

---
function CultivatorCounter:actionEventResetCounter()
    local spec = self.spec_cultivator
    spec.sessionCounter = 0
    UsageCounterResetEvent.sendEvent(self, "spec_cultivator")
end

---
function CultivatorCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_cultivator
    xmlFile:setValue(key .. "#area", spec.usageCounter or 0)
    xmlFile:setValue(key .. "#session", spec.sessionCounter or 0)
end

---
function CultivatorCounter:onEndWorkAreaProcessing()
    local spec = self.spec_cultivator
    local lastStatsArea = spec.workAreaParameters.lastStatsArea

    if lastStatsArea > 0 then
        local delta = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
        spec.usageCounter = spec.usageCounter + delta
        spec.sessionCounter = spec.sessionCounter + delta
    end
end