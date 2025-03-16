BaleWrapCounterResetEvent = {}
local BaleWrapCounterResetEvent_mt = Class(BaleWrapCounterResetEvent, Event)

function BaleWrapCounterResetEvent.emptyNew()
    return Event.new(BaleWrapCounterResetEvent_mt)
end

function BaleWrapCounterResetEvent.new(object)
    local self = BaleWrapCounterResetEvent.emptyNew()
    self.object = object
    return self
end

function BaleWrapCounterResetEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end

function BaleWrapCounterResetEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end

function BaleWrapCounterResetEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:doBaleWrapCounterReset(true)
    end
end

function BaleWrapCounterResetEvent.sendEvent(object, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BaleWrapCounterResetEvent.new(object, noEventSend), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(BaleWrapCounterResetEvent.new(object, noEventSend))
        end
    end
end
