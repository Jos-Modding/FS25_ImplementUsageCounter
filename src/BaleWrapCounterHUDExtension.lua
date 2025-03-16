BaleWrapCounterHUDExtension = {}

---Displays the current bale counters
local BaleWrapCounterHUDExtension_mt = Class(BaleWrapCounterHUDExtension)


---Create a new instance of BaleCounterHUDExtension.
-- @param table vehicle Vehicle which has the specialization required by a sub-class
function BaleWrapCounterHUDExtension.new(vehicle, customMt)
    local self = setmetatable({}, customMt or BaleWrapCounterHUDExtension_mt)
    self.priority = GS_PRIO_NORMAL

    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.background = g_overlayManager:createOverlay("gui.shortcutBox1", 0, 0, 0, 0)
    self.background:setColor(r, g, b, a)

    self.sessionOverlay = g_overlayManager:createOverlay("gui.baleCount_session", 0, 0, 0, 0)
    self.sessionOverlay:setColor(1, 1, 1, 1)

    self.lifetimeOverlay = g_overlayManager:createOverlay("gui.baleCount_lifetime", 0, 0, 0, 0)
    self.lifetimeOverlay:setColor(1, 1, 1, 1)

    self.title = utf8ToUpper(g_i18n:getText("info_baleWrapCounter"))
    self.vehicle = vehicle

    self:storeScaledValues()

    return self
end

---
function BaleWrapCounterHUDExtension:delete()
    self.background:delete()
    self.sessionOverlay:delete()
    self.lifetimeOverlay:delete()
end

---@see gui/hud/ContextActionDisplay:storeScaledValues
---@see gui/hud/InfoDisplayKeyValueBoxMobile:storeScaledValues
function BaleWrapCounterHUDExtension:storeScaledValues()
    local function normalize(x, y)
        local scale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE) or 1.0

        return x * scale * g_aspectScaleX / g_referenceScreenWidth, y * scale * g_aspectScaleY / g_referenceScreenHeight
    end

    local backgroundWidth, backgroundHeight = normalize(330, 25)
    self.background:setDimension(backgroundWidth, backgroundHeight)

    local overlayWidth, overlayHeight = normalize(20, 20)
    self.sessionOverlay:setDimension(overlayWidth, overlayHeight)
    self.lifetimeOverlay:setDimension(overlayWidth, overlayHeight)

    local textOffsetX, textOffsetY = normalize(14, 8)
    self.textOffsetX = textOffsetX
    self.textOffsetY = textOffsetY

    local _, textHeight = normalize(0, 12)
    self.textSize = textHeight

    local sessionIconOffsetX, sessionIconOffsetY = normalize(210, 4)
    self.sessionIconOffsetX = sessionIconOffsetX
    self.sessionIconOffsetY = sessionIconOffsetY

    local lifetimeIconOffsetX, lifetimeIconOffsetY = normalize(270, 4)
    self.lifetimeIconOffsetX = lifetimeIconOffsetX
    self.lifetimeIconOffsetY = lifetimeIconOffsetY

    local sessionTextOffsetX, sessionTextOffsetY = normalize(235, 8)
    self.sessionTextOffsetX = sessionTextOffsetX
    self.sessionTextOffsetY = sessionTextOffsetY
    
    local lifetimeTextOffsetX, lifetimeTextOffsetY = normalize(295, 8)
    self.lifetimeTextOffsetX = lifetimeTextOffsetX
    self.lifetimeTextOffsetY = lifetimeTextOffsetY
end

---@see gui/hud/InputHelpDisplay:draw
---@param newPosY number
---@param posX number
---@param posY number
function BaleWrapCounterHUDExtension:draw(newPosY, posX, posY)
    local spec = self.vehicle["spec_FS25_ImplementUsageCounter.baleWrapCounter"]
    --BaleWrapCounterHUDExtension

    newPosY = posY - self.background.height
    self.background:setPosition(posX, newPosY)
    self.background:render()
    setTextBold(true)
    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)
    
    local x = posX + self.textOffsetX
    local y = newPosY + self.textOffsetY
    renderText(x, y, self.textSize, self.title)
    setTextBold(false)

    local sessionOverlay = self.sessionOverlay
    sessionOverlay:setPosition(posX + self.sessionIconOffsetX, newPosY + self.sessionIconOffsetY)
    sessionOverlay:render()
    renderText(posX + self.sessionTextOffsetX, newPosY + self.sessionTextOffsetY, self.textSize, string.format("%d", spec.sessionCounter))

    local lifetimeOverlay = self.lifetimeOverlay
    lifetimeOverlay:setPosition(posX + self.lifetimeIconOffsetX, newPosY + self.lifetimeIconOffsetY)
    lifetimeOverlay:render()
    renderText(posX + self.lifetimeTextOffsetX, newPosY + self.lifetimeTextOffsetY, self.textSize, string.format("%d", spec.lifetimeCounter))

    return newPosY -- null compare if nothing returned
end

---Get this HUD element's height in screen space.
function BaleWrapCounterHUDExtension:getHeight()
    return self.background.height
end
