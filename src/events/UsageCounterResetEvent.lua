UsageCounterResetEvent = {}
local UsageCounterResetEvent_mt = Class(UsageCounterResetEvent, Event)
InitStaticEventClass(UsageCounterResetEvent, "UsageCounterResetEvent")

function UsageCounterResetEvent.emptyNew()
    return Event.new(UsageCounterResetEvent_mt)
end

---@param vehicle table vehicle owning the counter spec
---@param specKey string key of the spec table holding sessionCounter (e.g. "spec_cutter")
function UsageCounterResetEvent.new(vehicle, specKey)
    local self = UsageCounterResetEvent.emptyNew()
    self.vehicle = vehicle
    self.specKey = specKey
    return self
end

function UsageCounterResetEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.specKey = streamReadString(streamId)
    self:run(connection)
end

function UsageCounterResetEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.specKey)
end

function UsageCounterResetEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        local spec = self.vehicle[self.specKey]
        if spec ~= nil then
            spec.sessionCounter = 0
        end
    end
end

---@param vehicle table vehicle owning the counter spec
---@param specKey string key of the spec table holding sessionCounter
---@param noEventSend boolean|nil
function UsageCounterResetEvent.sendEvent(vehicle, specKey, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(UsageCounterResetEvent.new(vehicle, specKey), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(UsageCounterResetEvent.new(vehicle, specKey))
    end
end