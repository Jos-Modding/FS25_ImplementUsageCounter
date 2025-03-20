BaleWrapCounter = {}
BaleWrapCounter.SEND_NUM_BITS = 16
BaleWrapCounter.modName = g_currentModName
BaleWrapCounter.specName = ("spec_%s.baleWrapCounter"):format(g_currentModName)
BaleWrapCounter.schemaKey = ("vehicles.vehicle(?).%s.baleWrapCounter"):format(g_currentModName)

function BaleWrapCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(BaleWrapper, specializations) or SpecializationUtil.hasSpecialization(InlineWrapper, specializations)
end

function BaleWrapCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("BaleWrapCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.baleWrapCounter.dashoards", {"sessionCounter", "lifetimeCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, BaleWrapCounter.schemaKey .. "#sessionCounter", "Session counter")
    schemaSavegame:register(XMLValueType.INT, BaleWrapCounter.schemaKey .. "#lifetimeCounter", "Lifetime counter")
end

function BaleWrapCounter.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "doBaleWrapCounterReset", BaleWrapCounter.doBaleWrapCounterReset)
end

function BaleWrapCounter.registerOverwrittenFunctions(vehicleType)
    if vehicleType.name == "inlineWrapper" then
        SpecializationUtil.registerOverwrittenFunction(vehicleType, "pushOffInlineBale", BaleWrapCounter.pushOffInlineBale)
    else
        SpecializationUtil.registerOverwrittenFunction(vehicleType, "doStateChange", BaleWrapCounter.doStateChange)
    end
end

function BaleWrapCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", BaleWrapCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", BaleWrapCounter)
end

---
function BaleWrapCounter:onLoad(savegame)
    local spec = self[BaleWrapCounter.specName]

    spec.sessionCounter = 0
    spec.lifetimeCounter = 0

    if savegame ~= nil and not savegame.resetVehicles then
        spec.sessionCounter = savegame.xmlFile:getValue(savegame.key .. "." .. BaleWrapCounter.modName .. ".baleWrapCounter#sessionCounter", spec.sessionCounter) or 0
        spec.lifetimeCounter = savegame.xmlFile:getValue(savegame.key .. "." .. BaleWrapCounter.modName .. ".baleWrapCounter#lifetimeCounter", spec.lifetimeCounter) or 0
    end

    spec.hudExtension = BaleWrapCounterHUDExtension.new(self)
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

    local sessionCounter = DashboardValueType.new("baleWrapCounter", "sessionCounter")
    sessionCounter:setValue(spec, "sessionCounter")
    self:registerDashboardValueType(sessionCounter)

    local lifetimeCounter = DashboardValueType.new("baleWrapCounter", "lifetimeCounter")
    lifetimeCounter:setValue(spec, "lifetimeCounter")
    self:registerDashboardValueType(lifetimeCounter)
end

function BaleWrapCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self[BaleWrapCounter.specName]
    xmlFile:setValue(key .. "#sessionCounter", spec.sessionCounter)
    xmlFile:setValue(key .. "#lifetimeCounter", spec.lifetimeCounter)
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleWrapCounter:onReadStream(streamId, connection)
    local spec = self[BaleWrapCounter.specName]
    spec.sessionCounter = streamReadUIntN(streamId, BaleWrapCounter.SEND_NUM_BITS)
    spec.lifetimeCounter = streamReadUIntN(streamId, BaleWrapCounter.SEND_NUM_BITS)
end

---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleWrapCounter:onWriteStream(streamId, connection)
    local spec = self[BaleWrapCounter.specName]
    streamWriteUIntN(streamId, spec.sessionCounter, BaleWrapCounter.SEND_NUM_BITS)
    streamWriteUIntN(streamId, spec.lifetimeCounter, BaleWrapCounter.SEND_NUM_BITS)
end

function BaleWrapCounter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self[BaleWrapCounter.specName]
        self:clearActionEventsTable(spec.actionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.BALE_WRAP_COUNTER_RESET, self, BaleWrapCounter.actionEventResetCounter, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            g_inputBinding:setActionEventText(actionEventId, "Reset Bale Wrap Counter")
        end
    end
end

---Called on load to register external action events
function BaleWrapCounter:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
    if name == "baleWrapCounterReset" then
        self:registerExternalActionEvent(trigger, name, BaleWrapCounter.externalActionEventRegister, BaleWrapCounter.externalActionEventUpdate)
    end
end

---
function BaleWrapCounter.actionEventResetCounter(self, actionName, inputValue, callbackState, isAnalog)
    self:doBaleWrapCounterReset()
end

---
function BaleWrapCounter.externalActionEventRegister(data, vehicle)
    local function actionEvent(_, actionName, inputValue, callbackState, isAnalog)
        vehicle:doBaleWrapCounterReset()
    end

    local _
    _, data.actionEventId = g_inputBinding:registerActionEvent(InputAction.BALE_WRAP_COUNTER_RESET, data, actionEvent, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end

---
function BaleWrapCounter.externalActionEventUpdate(data, vehicle)
end

-- @param boolean noEventSend no event send
function BaleWrapCounter:doBaleWrapCounterReset(noEventSend)
    local spec = self[BaleWrapCounter.specName]

    spec.sessionCounter = 0

    BaleWrapCounterResetEvent.sendEvent(self, noEventSend)
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
            specCounter.sessionCounter = specCounter.sessionCounter + 1
            specCounter.lifetimeCounter = specCounter.lifetimeCounter + 1
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
            specCounter.sessionCounter = specCounter.sessionCounter + 1
            specCounter.lifetimeCounter = specCounter.lifetimeCounter + 1
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

        specCounter.sessionCounter = specCounter.sessionCounter + balesToAdd
        specCounter.lifetimeCounter = specCounter.lifetimeCounter + balesToAdd
    end
end
