CutterCounter = {}
CutterCounter.modName = g_currentModName
CutterCounter.modDir = g_currentModDirectory
CutterCounter.schemaKey = ("vehicles.vehicle(?).%s.cutterCounter#area"):format(g_currentModName)
CutterCounter.sessionSchemaKey = ("vehicles.vehicle(?).%s.cutterCounter#session"):format(g_currentModName)

---
function CutterCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Cutter, specializations)
end

---
function CutterCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("CutterCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.cutterCounter.dashoards", {"usageCounter", "sessionCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, CutterCounter.schemaKey, "Harvested area in hectares")
    schemaSavegame:register(XMLValueType.FLOAT, CutterCounter.sessionSchemaKey, "Harvested area this session in hectares")
end

---
function CutterCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CutterCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", CutterCounter)
end

---@param savegame table
function CutterCounter:onLoad(savegame)
    local spec = self.spec_cutter
    spec.usageCounter = 0
    spec.sessionCounter = 0
    spec.counterActionEvents = {}

    if savegame ~= nil and not savegame.resetVehicles then
        spec.usageCounter = savegame.xmlFile:getValue(savegame.key .. "." .. CutterCounter.modName .. ".cutterCounter#area", spec.usageCounter) or 0
        spec.sessionCounter = savegame.xmlFile:getValue(savegame.key .. "." .. CutterCounter.modName .. ".cutterCounter#session", spec.sessionCounter) or 0
    end

    if self.isClient then
        spec.hudExtension = UsageCounterHUDExtension.new(self, "spec_cutter", g_i18n:getText("hud_cutterCounter"), true)
    end
end

---
function CutterCounter:onDelete()
    local spec = self.spec_cutter
    if spec.hudExtension ~= nil then
        g_currentMission.hud:removeInfoExtension(spec.hudExtension)
        spec.hudExtension:delete()
    end
end

---
function CutterCounter:onDraw()
    local spec = self.spec_cutter
    if spec.hudExtension ~= nil then
        g_currentMission.hud:addInfoExtension(spec.hudExtension)
    end
end

---@param streamId number
---@param connection number
function CutterCounter:onReadStream(streamId, connection)
    local spec = self.spec_cutter
    spec.usageCounter = streamReadFloat32(streamId)
    spec.sessionCounter = streamReadFloat32(streamId)
end

---@param streamId number
---@param connection number
function CutterCounter:onWriteStream(streamId, connection)
    local spec = self.spec_cutter
    streamWriteFloat32(streamId, spec.usageCounter)
    streamWriteFloat32(streamId, spec.sessionCounter)
end

---Called on post load to register dashboard value types
function CutterCounter:onRegisterDashboardValueTypes()
    local spec = self.spec_cutter

    local usageCounter = DashboardValueType.new("cutterCounter", "usageCounter")
    usageCounter:setValue(spec, "usageCounter")
    self:registerDashboardValueType(usageCounter)

    local sessionCounter = DashboardValueType.new("cutterCounter", "sessionCounter")
    sessionCounter:setValue(spec, "sessionCounter")
    self:registerDashboardValueType(sessionCounter)
end

---
function CutterCounter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_cutter
        spec.counterActionEvents = spec.counterActionEvents or {}
        self:clearActionEventsTable(spec.counterActionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.counterActionEvents, InputAction.IMPLEMENT_USAGE_COUNTER_RESET, self, CutterCounter.actionEventResetCounter, false, true, false, true, nil)
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("input_IMPLEMENT_USAGE_COUNTER_RESET"))
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
        end
    end
end

---
function CutterCounter:actionEventResetCounter()
    local spec = self.spec_cutter
    spec.sessionCounter = 0
    UsageCounterResetEvent.sendEvent(self, "spec_cutter")
end

---
function CutterCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_cutter
    xmlFile:setValue(key .. "#area", spec.usageCounter or 0)
    xmlFile:setValue(key .. "#session", spec.sessionCounter or 0)
end

---
function CutterCounter:onEndWorkAreaProcessing()
    local spec = self.spec_cutter
    local lastStatsArea = spec.workAreaParameters.lastArea

    if lastStatsArea > 0 then
        local delta = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
        spec.usageCounter = spec.usageCounter + delta
        spec.sessionCounter = spec.sessionCounter + delta
    end
end
