MowerCounter = {}
MowerCounter.modName = g_currentModName
MowerCounter.schemaKey = ("vehicles.vehicle(?).%s.mowerCounter#area"):format(g_currentModName)
MowerCounter.sessionSchemaKey = ("vehicles.vehicle(?).%s.mowerCounter#session"):format(g_currentModName)

---
function MowerCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Mower, specializations)
end

---
function MowerCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("MowerCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.mowerCounter.dashoards", {"usageCounter", "sessionCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, MowerCounter.schemaKey, "Mowed area in hectares")
    schemaSavegame:register(XMLValueType.FLOAT, MowerCounter.sessionSchemaKey, "Mowed area this session in hectares")
end

---
function MowerCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", MowerCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", MowerCounter)
end

---
function MowerCounter:onLoad(savegame)
    local spec = self.spec_mower
    spec.usageCounter = 0
    spec.sessionCounter = 0
    spec.counterActionEvents = {}

    if savegame ~= nil and not savegame.resetVehicles then
        spec.usageCounter = savegame.xmlFile:getValue(savegame.key .. "." .. MowerCounter.modName .. ".mowerCounter#area", spec.usageCounter) or 0
        spec.sessionCounter = savegame.xmlFile:getValue(savegame.key .. "." .. MowerCounter.modName .. ".mowerCounter#session", spec.sessionCounter) or 0
    end

    if self.isClient then
        spec.hudExtension = UsageCounterHUDExtension.new(self, "spec_mower", g_i18n:getText("hud_mowerCounter"), true)
    end
end

---
function MowerCounter:onDelete()
    local spec = self.spec_mower

    if spec.hudExtension ~= nil then
        g_currentMission.hud:removeInfoExtension(spec.hudExtension)
        spec.hudExtension:delete()
    end
end

---
function MowerCounter:onDraw()
    local spec = self.spec_mower

    if spec.hudExtension ~= nil then
        g_currentMission.hud:addInfoExtension(spec.hudExtension)
    end
end

---@param streamId number
---@param connection number
function MowerCounter:onReadStream(streamId, connection)
    local spec = self.spec_mower
    spec.usageCounter = streamReadFloat32(streamId)
    spec.sessionCounter = streamReadFloat32(streamId)
end

---@param streamId number
---@param connection number
function MowerCounter:onWriteStream(streamId, connection)
    local spec = self.spec_mower
    streamWriteFloat32(streamId, spec.usageCounter)
    streamWriteFloat32(streamId, spec.sessionCounter)
end

---Called on post load to register dashboard value types
function MowerCounter:onRegisterDashboardValueTypes()
    local spec = self.spec_mower

    local usageCounter = DashboardValueType.new("mowerCounter", "usageCounter")
    usageCounter:setValue(spec, "usageCounter")
    self:registerDashboardValueType(usageCounter)

    local sessionCounter = DashboardValueType.new("mowerCounter", "sessionCounter")
    sessionCounter:setValue(spec, "sessionCounter")
    self:registerDashboardValueType(sessionCounter)
end

---
function MowerCounter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_mower
        spec.counterActionEvents = spec.counterActionEvents or {}
        self:clearActionEventsTable(spec.counterActionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.counterActionEvents, InputAction.IMPLEMENT_USAGE_COUNTER_RESET, self, MowerCounter.actionEventResetCounter, false, true, false, true, nil)
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("input_IMPLEMENT_USAGE_COUNTER_RESET"))
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
        end
    end
end

---
function MowerCounter:actionEventResetCounter()
    local spec = self.spec_mower
    spec.sessionCounter = 0
    UsageCounterResetEvent.sendEvent(self, "spec_mower")
end

---
function MowerCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_mower
    xmlFile:setValue(key .. "#area", spec.usageCounter or 0)
    xmlFile:setValue(key .. "#session", spec.sessionCounter or 0)
end

---
function MowerCounter:onEndWorkAreaProcessing()
    local spec = self.spec_mower
    local lastStatsArea = spec.workAreaParameters.lastStatsArea

    if lastStatsArea > 0 then
        local delta = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
        spec.usageCounter = spec.usageCounter + delta
        spec.sessionCounter = spec.sessionCounter + delta
    end
end
