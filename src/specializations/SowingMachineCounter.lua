SowingMachineCounter = {}
SowingMachineCounter.modName = g_currentModName
SowingMachineCounter.schemaKey = ("vehicles.vehicle(?).%s.sowingMachineCounter#area"):format(g_currentModName)

---@param specializations table
function SowingMachineCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations)
end

---
function SowingMachineCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("SowingMachineCounter")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.sowingMachineCounter.dashoards", {"usageCounter"})
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, SowingMachineCounter.schemaKey, "Plowed area in hectares")
end

---
function SowingMachineCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", SowingMachineCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", SowingMachineCounter)
end

---@param savegame table
function SowingMachineCounter:onLoad(savegame)
    local spec = self.spec_sowingMachine
    spec.usageCounter = 0

    if savegame ~= nil and not savegame.resetVehicles then
        spec.usageCounter = savegame.xmlFile:getValue(savegame.key .. "." .. SowingMachineCounter.modName .. ".sowingMachineCounter#area", spec.usageCounter) or 0
    end
end

---
function SowingMachineCounter:onDraw()
    local spec = self.spec_sowingMachine
    local area = g_i18n:getArea(spec.usageCounter)
    local unit = g_i18n:getAreaUnit(true)
    local text = g_i18n:getText("statistic_sowingMachineCounter"):format(area, unit)

    g_currentMission:addExtraPrintText(text)
end

---@param streamId number
---@param connection number
function SowingMachineCounter:onReadStream(streamId, connection)
    local spec = self.spec_sowingMachine
    spec.usageCounter = streamReadFloat32(streamId)
end

---@param streamId number
---@param connection number
function SowingMachineCounter:onWriteStream(streamId, connection)
    local spec = self.spec_sowingMachine
    streamWriteFloat32(streamId, spec.usageCounter)
end

---Called on post load to register dashboard value types
function SowingMachineCounter:onRegisterDashboardValueTypes()
    local spec = self.spec_sowingMachine

    local usageCounter = DashboardValueType.new("sowingMachineCounter", "usageCounter")
    usageCounter:setValue(spec, "usageCounter")
    self:registerDashboardValueType(usageCounter)
end

---
function SowingMachineCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_sowingMachine
    xmlFile:setValue(key .. "#area", spec.usageCounter or 0)
end

---
function SowingMachineCounter:onEndWorkAreaProcessing()
    local spec = self.spec_sowingMachine
    local lastStatsArea = spec.workAreaParameters.lastStatsArea

    if lastStatsArea > 0 then
        local delta = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
        spec.usageCounter = spec.usageCounter + delta
    end
end
