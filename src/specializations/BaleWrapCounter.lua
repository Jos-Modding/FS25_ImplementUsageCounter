BaleWrapCounter = {}
BaleWrapCounter.SEND_NUM_BITS = 16
BaleWrapCounter.modName = g_currentModName
BaleWrapCounter.modDir = g_currentModDirectory
BaleWrapCounter.specName = ("spec_%s.baleWrapCounter"):format(g_currentModName)
BaleWrapCounter.schemaKey = ("vehicles.vehicle(?).%s.baleWrapCounter"):format(g_currentModName)

---
function BaleWrapCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(BaleWrapper, specializations) or SpecializationUtil.hasSpecialization(InlineWrapper, specializations)
end

---
function BaleWrapCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("BaleWrapCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.baleWrapCounter.dashoards", {"lifetimeCounter", "sessionCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, BaleWrapCounter.schemaKey .. "#lifetimeCounter", "Lifetime counter")
    schemaSavegame:register(XMLValueType.INT, BaleWrapCounter.schemaKey .. "#sessionCounter", "Session counter")
end

---
function BaleWrapCounter.registerOverwrittenFunctions(vehicleType)
    if vehicleType.name == "inlineWrapper" then
        SpecializationUtil.registerOverwrittenFunction(vehicleType, "pushOffInlineBale", BaleWrapCounter.pushOffInlineBale)
    else
        SpecializationUtil.registerOverwrittenFunction(vehicleType, "doStateChange", BaleWrapCounter.doStateChange)
    end
end

---
function BaleWrapCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", BaleWrapCounter)
end

---
function BaleWrapCounter:onLoad(savegame)
    local spec = self[BaleWrapCounter.specName]
    spec.lifetimeCounter = 0
    spec.sessionCounter = 0
    spec.counterActionEvents = {}

    if savegame ~= nil and not savegame.resetVehicles then
        spec.lifetimeCounter = savegame.xmlFile:getValue(savegame.key .. "." .. BaleWrapCounter.modName .. ".baleWrapCounter#lifetimeCounter", spec.lifetimeCounter) or 0
        spec.sessionCounter = savegame.xmlFile:getValue(savegame.key .. "." .. BaleWrapCounter.modName .. ".baleWrapCounter#sessionCounter", spec.sessionCounter) or 0
    end

    if self.isClient then
        spec.hudExtension = UsageCounterHUDExtension.new(self, BaleWrapCounter.specName, g_i18n:getText("hud_baleWrapCounter"), false, "lifetimeCounter")
    end
end

---
function BaleWrapCounter:onLoadFinished(savegame)
    --These mods overwrite doStateChange
    if g_modIsLoaded["FS25_roundBalerExtension"] or g_modIsLoaded["FS25_SwitchableBaleWrappersforBalers"] then
        self.doStateChange = Utils.prependedFunction(BaleWrapper.doStateChange, BaleWrapCounter.inj_doStateChange)
    end
end

---
function BaleWrapCounter:onDelete()
    local spec = self[BaleWrapCounter.specName]
    if spec.hudExtension ~= nil then
        g_currentMission.hud:removeInfoExtension(spec.hudExtension)
        spec.hudExtension:delete()
    end
end

---
function BaleWrapCounter:onDraw()
    local spec = self[BaleWrapCounter.specName]
    if spec.hudExtension ~= nil then
        g_currentMission.hud:addInfoExtension(spec.hudExtension)
    end
end

---Called on post load to register dashboard value types
function BaleWrapCounter:onRegisterDashboardValueTypes()
    local spec = self[BaleWrapCounter.specName]

    local lifetimeCounter = DashboardValueType.new("baleWrapCounter", "lifetimeCounter")
    lifetimeCounter:setValue(spec, "lifetimeCounter")
    self:registerDashboardValueType(lifetimeCounter)

    local sessionCounter = DashboardValueType.new("baleWrapCounter", "sessionCounter")
    sessionCounter:setValue(spec, "sessionCounter")
    self:registerDashboardValueType(sessionCounter)
end

---
function BaleWrapCounter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self[BaleWrapCounter.specName]
        spec.counterActionEvents = spec.counterActionEvents or {}
        self:clearActionEventsTable(spec.counterActionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.counterActionEvents, InputAction.IMPLEMENT_USAGE_COUNTER_RESET, self, BaleWrapCounter.actionEventResetCounter, false, true, false, true, nil)
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("input_IMPLEMENT_USAGE_COUNTER_RESET"))
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
        end
    end
end

---
function BaleWrapCounter:actionEventResetCounter()
    local spec = self[BaleWrapCounter.specName]
    spec.sessionCounter = 0
    UsageCounterResetEvent.sendEvent(self, BaleWrapCounter.specName)
end

function BaleWrapCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self[BaleWrapCounter.specName]
    xmlFile:setValue(key .. "#lifetimeCounter", spec.lifetimeCounter)
    xmlFile:setValue(key .. "#sessionCounter", spec.sessionCounter)
end

---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleWrapCounter:onReadStream(streamId, connection)
    local spec = self[BaleWrapCounter.specName]
    spec.lifetimeCounter = streamReadUIntN(streamId, BaleWrapCounter.SEND_NUM_BITS)
    spec.sessionCounter = streamReadUIntN(streamId, BaleWrapCounter.SEND_NUM_BITS)
end

---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleWrapCounter:onWriteStream(streamId, connection)
    local spec = self[BaleWrapCounter.specName]
    streamWriteUIntN(streamId, spec.lifetimeCounter, BaleWrapCounter.SEND_NUM_BITS)
    streamWriteUIntN(streamId, spec.sessionCounter, BaleWrapCounter.SEND_NUM_BITS)
end

---Changed wrapper state
-- @param integer id id of new state
-- @param integer nearestBaleServerId server id of nearest bale
function BaleWrapCounter:doStateChange(superFunc, id, nearestBaleServerId)
    local spec = self.spec_baleWrapper

    if id == BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED then
        local bale = NetworkUtil.getObject(spec.currentWrapper.currentBale)
        local baleType = spec.currentWrapper.allowedBaleTypes[spec.currentBaleTypeIndex]
        local skippedWrapping = not bale:getSupportsWrapping() or baleType.skipWrapping

        if not skippedWrapping then
            local specCounter = self[BaleWrapCounter.specName]
            specCounter.lifetimeCounter = specCounter.lifetimeCounter + 1
            specCounter.sessionCounter = specCounter.sessionCounter + 1
        end
    end

    superFunc(self, id, nearestBaleServerId)
end

---Changed wrapper state
-- @param integer id id of new state
-- @param integer nearestBaleServerId server id of nearest bale
function BaleWrapCounter:inj_doStateChange(id, nearestBaleServerId)
    local spec = self.spec_baleWrapper

    if id == BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED then
        local bale = NetworkUtil.getObject(spec.currentWrapper.currentBale)
        local baleType = spec.currentWrapper.allowedBaleTypes[spec.currentBaleTypeIndex]
        local skippedWrapping = not bale:getSupportsWrapping() or baleType.skipWrapping

        if not skippedWrapping then
            local specCounter = self[BaleWrapCounter.specName]
            specCounter.lifetimeCounter = specCounter.lifetimeCounter + 1
            specCounter.sessionCounter = specCounter.sessionCounter + 1
        end
    end
end

---
function BaleWrapCounter:pushOffInlineBale()
    local spec = self.spec_inlineWrapper
    local specCounter = self[BaleWrapCounter.specName]

    if not self:getIsAnimationPlaying(spec.animations.pushOff) then
        self:playAnimation(spec.animations.pushOff, 1)
        spec.pushOffStarted = true

        local currentInlineBale = self:getCurrentInlineBale()
        local balesToAdd = math.max(1, currentInlineBale:getNumberOfBales())
        specCounter.lifetimeCounter = specCounter.lifetimeCounter + balesToAdd
        specCounter.sessionCounter = specCounter.sessionCounter + balesToAdd
    end
end
