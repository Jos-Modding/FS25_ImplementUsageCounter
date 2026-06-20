UsageCounterHUDExtension = {}
local UsageCounterHUDExtension_mt = Class(UsageCounterHUDExtension)

local modDir = g_currentModDirectory or ""
local SESSION_ICON = modDir .. "gui/icons/session.dds"
local LIFETIME_ICON = modDir .. "gui/icons/lifetime.dds"

---
function UsageCounterHUDExtension.new(vehicle, specKey, title, isArea, lifetimeField, customMt)
    local self = setmetatable({}, customMt or UsageCounterHUDExtension_mt)
    self.priority = GS_PRIO_NORMAL

    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.background = g_overlayManager:createOverlay("gui.shortcutBox1", 0, 0, 0, 0)
    self.background:setColor(r, g, b, a)
    self.sessionOverlay = Overlay.new(SESSION_ICON, 0, 0, 0, 0)
    self.sessionOverlay:setColor(1, 1, 1, 1)
    self.lifetimeOverlay = Overlay.new(LIFETIME_ICON, 0, 0, 0, 0)
    self.lifetimeOverlay:setColor(1, 1, 1, 1)
    self.vehicle = vehicle
    self.specKey = specKey
    self.isArea = isArea
    self.lifetimeField = lifetimeField or "usageCounter"

    if isArea then
        title = ("%s (%s)"):format(title, g_i18n:getAreaUnit(false))
    end

    self.title = utf8ToUpper(title)
    self:storeScaledValues()
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)

    return self
end

---
function UsageCounterHUDExtension:delete()
    self.background:delete()
    self.sessionOverlay:delete()
    self.lifetimeOverlay:delete()
    g_messageCenter:unsubscribeAll(self)
end

---
function UsageCounterHUDExtension:storeScaledValues()
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local width, height = getNormalizedScreenValues(330 * uiScale, 25 * uiScale)
    self.background:setDimension(width, height)
    local iconWidth, iconHeight = getNormalizedScreenValues(20 * uiScale, 20 * uiScale)
    self.sessionOverlay:setDimension(iconWidth, iconHeight)
    self.lifetimeOverlay:setDimension(iconWidth, iconHeight)
    self.textOffsetX, self.textOffsetY = getNormalizedScreenValues(14 * uiScale, 8 * uiScale)
    _, self.textSize = getNormalizedScreenValues(0, 12 * uiScale)
    self.sessionIconOffsetX, self.sessionIconOffsetY = getNormalizedScreenValues(210 * uiScale, 3 * uiScale)
    self.lifetimeIconOffsetX, self.lifetimeIconOffsetY = getNormalizedScreenValues(270 * uiScale, 4 * uiScale)
    self.sessionTextOffsetX, self.sessionTextOffsetY = getNormalizedScreenValues(235 * uiScale, 8 * uiScale)
    self.lifetimeTextOffsetX, self.lifetimeTextOffsetY = getNormalizedScreenValues(295 * uiScale, 8 * uiScale)
end

---
function UsageCounterHUDExtension:formatValue(value)
    if self.isArea then
        return ("%.2f"):format(g_i18n:getArea(value or 0))
    end

    return ("%d"):format(value or 0)
end

---
function UsageCounterHUDExtension:draw(_, posX, posY)
    local spec = self.vehicle[self.specKey]

    if spec == nil then
        return posY
    end

    posY = posY - self.background.height
    self.background:setPosition(posX, posY)
    self.background:render()

    setTextBold(true)
    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(posX + self.textOffsetX, posY + self.textOffsetY, self.textSize, self.title)
    setTextBold(false)

    local sessionOverlay = self.sessionOverlay
    sessionOverlay:setPosition(posX + self.sessionIconOffsetX, posY + self.sessionIconOffsetY)
    sessionOverlay:render()
    renderText(posX + self.sessionTextOffsetX, posY + self.sessionTextOffsetY, self.textSize, self:formatValue(spec.sessionCounter))

    local lifetimeOverlay = self.lifetimeOverlay
    lifetimeOverlay:setPosition(posX + self.lifetimeIconOffsetX, posY + self.lifetimeIconOffsetY)
    lifetimeOverlay:render()
    renderText(posX + self.lifetimeTextOffsetX, posY + self.lifetimeTextOffsetY, self.textSize, self:formatValue(spec[self.lifetimeField]))

    return posY
end

---
function UsageCounterHUDExtension:getHeight()
    return self.background.height
end
