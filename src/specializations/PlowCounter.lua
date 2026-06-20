PlowCounter = {}
PlowCounter.modName = g_currentModName
PlowCounter.schemaKey = ("vehicles.vehicle(?).%s.plowCounter#area"):format(g_currentModName)
PlowCounter.sessionSchemaKey = ("vehicles.vehicle(?).%s.plowCounter#session"):format(g_currentModName)

---
function PlowCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Plow, specializations)
end

---
function PlowCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("PlowCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.plowCounter.dashoards", {"usageCounter", "sessionCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, PlowCounter.schemaKey, "Plowed area in hectares")
    schemaSavegame:register(XMLValueType.FLOAT, PlowCounter.sessionSchemaKey, "Plowed area this session in hectares")
end

---
function PlowCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", PlowCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", PlowCounter)
end

---
function PlowCounter:onLoad(savegame)
    local spec = self.spec_plow
    spec.usageCounter = 0
    spec.sessionCounter = 0
    spec.counterActionEvents = {}

    if savegame ~= nil and not savegame.resetVehicles then
        spec.usageCounter = savegame.xmlFile:getValue(savegame.key .. "." .. PlowCounter.modName .. ".plowCounter#area", spec.usageCounter) or 0
        spec.sessionCounter = savegame.xmlFile:getValue(savegame.key .. "." .. PlowCounter.modName .. ".plowCounter#session", spec.sessionCounter) or 0
    end

    if self.isClient then
        spec.hudExtension = UsageCounterHUDExtension.new(self, "spec_plow", g_i18n:getText("hud_plowCounter"), true)
    end
end

---
function PlowCounter:onDelete()
    local spec = self.spec_plow

    if spec.hudExtension ~= nil then
        g_currentMission.hud:removeInfoExtension(spec.hudExtension)
        spec.hudExtension:delete()
    end
end

---
function PlowCounter:onDraw()
    local spec = self.spec_plow

    if spec.hudExtension ~= nil then
        g_currentMission.hud:addInfoExtension(spec.hudExtension)
    end
end

---@param streamId number
---@param connection number
function PlowCounter:onReadStream(streamId, connection)
    local spec = self.spec_plow
    spec.usageCounter = streamReadFloat32(streamId)
    spec.sessionCounter = streamReadFloat32(streamId)
end

---@param streamId number
---@param connection number
function PlowCounter:onWriteStream(streamId, connection)
    local spec = self.spec_plow
    streamWriteFloat32(streamId, spec.usageCounter)
    streamWriteFloat32(streamId, spec.sessionCounter)
end

---Called on post load to register dashboard value types
function PlowCounter:onRegisterDashboardValueTypes()
    local spec = self.spec_plow

    local usageCounter = DashboardValueType.new("plowCounter", "usageCounter")
    usageCounter:setValue(spec, "usageCounter")
    self:registerDashboardValueType(usageCounter)

    local sessionCounter = DashboardValueType.new("plowCounter", "sessionCounter")
    sessionCounter:setValue(spec, "sessionCounter")
    self:registerDashboardValueType(sessionCounter)
end

---
function PlowCounter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_plow
        spec.counterActionEvents = spec.counterActionEvents or {}
        self:clearActionEventsTable(spec.counterActionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.counterActionEvents, InputAction.IMPLEMENT_USAGE_COUNTER_RESET, self, PlowCounter.actionEventResetCounter, false, true, false, true, nil)
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("input_IMPLEMENT_USAGE_COUNTER_RESET"))
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
        end
    end
end

---
function PlowCounter:actionEventResetCounter()
    local spec = self.spec_plow
    spec.sessionCounter = 0
    UsageCounterResetEvent.sendEvent(self, "spec_plow")
end

---
function PlowCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_plow
    xmlFile:setValue(key .. "#area", spec.usageCounter or 0)
    xmlFile:setValue(key .. "#session", spec.sessionCounter or 0)
end

---
function PlowCounter:onEndWorkAreaProcessing()
    local spec = self.spec_plow
    local lastStatsArea = spec.workAreaParameters.lastStatsArea

    if lastStatsArea > 0 then
        local delta = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
        spec.usageCounter = spec.usageCounter + delta
        spec.sessionCounter = spec.sessionCounter + delta
    end
end
