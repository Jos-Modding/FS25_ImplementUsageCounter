SowingMachineCounter = {}
SowingMachineCounter.modName = g_currentModName
SowingMachineCounter.schemaKey = ("vehicles.vehicle(?).%s.sowingMachineCounter#area"):format(g_currentModName)
SowingMachineCounter.sessionSchemaKey = ("vehicles.vehicle(?).%s.sowingMachineCounter#session"):format(g_currentModName)

---
function SowingMachineCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations)
end

---
function SowingMachineCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("SowingMachineCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.sowingMachineCounter.dashoards", {"usageCounter", "sessionCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, SowingMachineCounter.schemaKey, "Sown area in hectares")
    schemaSavegame:register(XMLValueType.FLOAT, SowingMachineCounter.sessionSchemaKey, "Sown area this session in hectares")
end

---
function SowingMachineCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", SowingMachineCounter)
end

---
function SowingMachineCounter:onLoad(savegame)
    local spec = self.spec_sowingMachine
    spec.usageCounter = 0
    spec.sessionCounter = 0
    spec.counterActionEvents = {}

    if savegame ~= nil and not savegame.resetVehicles then
        spec.usageCounter = savegame.xmlFile:getValue(savegame.key .. "." .. SowingMachineCounter.modName .. ".sowingMachineCounter#area", spec.usageCounter) or 0
        spec.sessionCounter = savegame.xmlFile:getValue(savegame.key .. "." .. SowingMachineCounter.modName .. ".sowingMachineCounter#session", spec.sessionCounter) or 0
    end

    if self.isClient then
        spec.hudExtension = UsageCounterHUDExtension.new(self, "spec_sowingMachine", g_i18n:getText("hud_sowingMachineCounter"), true)
    end
end

---
function SowingMachineCounter:onDelete()
    local spec = self.spec_sowingMachine

    if spec.hudExtension ~= nil then
        g_currentMission.hud:removeInfoExtension(spec.hudExtension)
        spec.hudExtension:delete()
    end
end

---
function SowingMachineCounter:onDraw()
    local spec = self.spec_sowingMachine

    if spec.hudExtension ~= nil then
        g_currentMission.hud:addInfoExtension(spec.hudExtension)
    end
end

---
function SowingMachineCounter:onReadStream(streamId, connection)
    local spec = self.spec_sowingMachine
    spec.usageCounter = streamReadFloat32(streamId)
    spec.sessionCounter = streamReadFloat32(streamId)
end

---
function SowingMachineCounter:onWriteStream(streamId, connection)
    local spec = self.spec_sowingMachine
    streamWriteFloat32(streamId, spec.usageCounter)
    streamWriteFloat32(streamId, spec.sessionCounter)
end

---Called on post load to register dashboard value types
function SowingMachineCounter:onRegisterDashboardValueTypes()
    local spec = self.spec_sowingMachine

    local usageCounter = DashboardValueType.new("sowingMachineCounter", "usageCounter")
    usageCounter:setValue(spec, "usageCounter")
    self:registerDashboardValueType(usageCounter)

    local sessionCounter = DashboardValueType.new("sowingMachineCounter", "sessionCounter")
    sessionCounter:setValue(spec, "sessionCounter")
    self:registerDashboardValueType(sessionCounter)
end

---
function SowingMachineCounter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_sowingMachine
        spec.counterActionEvents = spec.counterActionEvents or {}
        self:clearActionEventsTable(spec.counterActionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.counterActionEvents, InputAction.IMPLEMENT_USAGE_COUNTER_RESET, self, SowingMachineCounter.actionEventResetCounter, false, true, false, true, nil)
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("input_IMPLEMENT_USAGE_COUNTER_RESET"))
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
        end
    end
end

---
function SowingMachineCounter:actionEventResetCounter()
    local spec = self.spec_sowingMachine
    spec.sessionCounter = 0
    UsageCounterResetEvent.sendEvent(self, "spec_sowingMachine")
end

---
function SowingMachineCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_sowingMachine
    xmlFile:setValue(key .. "#area", spec.usageCounter or 0)
    xmlFile:setValue(key .. "#session", spec.sessionCounter or 0)
end

---
function SowingMachineCounter:onEndWorkAreaProcessing()
    local spec = self.spec_sowingMachine
    local lastStatsArea = spec.workAreaParameters.lastStatsArea

    if lastStatsArea > 0 then
        local delta = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
        spec.usageCounter = spec.usageCounter + delta
        spec.sessionCounter = spec.sessionCounter + delta
    end
end
