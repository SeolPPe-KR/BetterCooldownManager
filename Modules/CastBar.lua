local _, BCDM = ...

local function FetchCastBarColour(unit)
    local CooldownManagerDB = BCDM.db.profile
    local CastBarDB = CooldownManagerDB.CastBar
    if CastBarDB.ColourByClass then
        local _, class = UnitClass(unit)
        local classColour = RAID_CLASS_COLORS[class]
        if classColour then return classColour.r, classColour.g, classColour.b, 1 end
    end
    return CastBarDB.FGColour[1], CastBarDB.FGColour[2], CastBarDB.FGColour[3], CastBarDB.FGColour[4]
end

local function CreateCastBar()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CastBarDB = CooldownManagerDB.CastBar
    if BCDM.CastBar then return end
    local CastBarContainer = CreateFrame("Frame", "BCDM_CastBarContainer", UIParent, "BackdropTemplate")
    CastBarContainer:SetPoint(CastBarDB.Anchors[1], CastBarDB.Anchors[2], CastBarDB.Anchors[3], CastBarDB.Anchors[4], CastBarDB.Anchors[5])
    CastBarContainer:SetSize(224, CastBarDB.Height)
    CastBarContainer:SetBackdrop({ bgFile = BCDM.Media.CastBarBGTexture, edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, })
    CastBarContainer:SetBackdropColor(20/255, 20/255, 20/255, 1)
    CastBarContainer:SetBackdropBorderColor(0, 0, 0, 1)

    local CastBarIcon = CastBarContainer:CreateTexture("BCDM_CastBarIcon", "ARTWORK")
    CastBarIcon:SetSize(CastBarDB.Height - 2, CastBarDB.Height - 2)
    CastBarIcon:SetPoint("LEFT", CastBarContainer, "LEFT", 1, 0)
    CastBarIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local CastBar = CreateFrame("StatusBar", "BCDM_CastBar", CastBarContainer)
    CastBar:SetPoint("LEFT", CastBarIcon, "RIGHT", 0, 0)
    CastBar:SetPoint("TOPRIGHT", CastBarContainer, "TOPRIGHT", 1, -1)
    CastBar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -1, 1)
    CastBar:SetMinMaxValues(0, 100)
    CastBar:SetStatusBarTexture(BCDM.Media.CastBarFGTexture)
    CastBar:SetStatusBarColor(FetchCastBarColour("player"))

    CastBar.SpellName = CastBar:CreateFontString(nil, "OVERLAY")
    CastBar.SpellName:SetFont(BCDM.Media.Font, CastBarDB.SpellName.FontSize, BCDM.db.profile.General.FontFlag)
    CastBar.SpellName:SetPoint(CastBarDB.SpellName.Anchors[1], CastBar, CastBarDB.SpellName.Anchors[2], CastBarDB.SpellName.Anchors[3], CastBarDB.SpellName.Anchors[4])
    CastBar.SpellName:SetText("")
    CastBar.SpellName:SetTextColor(CastBarDB.SpellName.Colour[1], CastBarDB.SpellName.Colour[2], CastBarDB.SpellName.Colour[3], CastBarDB.SpellName.Colour[4])
    CastBar.SpellName:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
    CastBar.SpellName:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)

    CastBar.Duration = CastBar:CreateFontString(nil, "OVERLAY")
    CastBar.Duration:SetFont(BCDM.Media.Font, CastBarDB.Duration.FontSize, BCDM.db.profile.General.FontFlag)
    CastBar.Duration:SetPoint(CastBarDB.Duration.Anchors[1], CastBar, CastBarDB.Duration.Anchors[2], CastBarDB.Duration.Anchors[3], CastBarDB.Duration.Anchors[4])
    CastBar.Duration:SetText("")
    CastBar.Duration:SetTextColor(CastBarDB.Duration.Colour[1], CastBarDB.Duration.Colour[2], CastBarDB.Duration.Colour[3], CastBarDB.Duration.Colour[4])
    CastBar.Duration:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
    CastBar.Duration:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)

    CastBar.Icon = CastBarIcon

    CastBar:SetScript("OnShow", function(self)
        local spellName, _, icon = UnitCastingInfo("player")
        if not spellName then spellName, _, icon = UnitChannelInfo("player") end
        if icon then
            self.Icon:SetTexture(icon)
            self.Icon:Show()
        else
            self.Icon:Hide()
        end
    end)

    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")

    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")


    local CAST_START = {
        UNIT_SPELLCAST_START = true,
        UNIT_SPELLCAST_INTERRUPTIBLE = true,
        UNIT_SPELLCAST_NOT_INTERRUPTIBLE = true,
        UNIT_SPELLCAST_SENT = true,
    }

    local CAST_STOP = {
        UNIT_SPELLCAST_STOP = true,
        UNIT_SPELLCAST_CHANNEL_STOP = true,
        PLAYER_TARGET_CHANGED = true,
        UNIT_SPELLCAST_FAILED = true,
        UNIT_SPELLCAST_INTERRUPTED = true,
    }

    local CHANNEL_START = {
        UNIT_SPELLCAST_CHANNEL_START = true,
    }

    CastBar:SetScript("OnEvent", function(self, event, unit)
        if unit ~= "player" then return end
        if CAST_START[event] then
            local castDuration = UnitCastingDuration("player")
            if not castDuration then return end
            CastBar:SetTimerDuration(castDuration, 0)
            CastBar.Icon:SetTexture(select(3, UnitCastingInfo("player")) or nil)
            CastBar.SpellName:SetText(UnitCastingInfo("player") or "")
            CastBar:SetScript("OnUpdate", function()
                local remainingDuration = castDuration:GetRemainingDuration()
                if remainingDuration < BCDM.db.profile.CastBar.Duration.ExpirationThreshold then
                    CastBar.Duration:SetText(string.format("%.1f", remainingDuration))
                else
                    CastBar.Duration:SetText(string.format("%.0f", remainingDuration))
                end
            end)
            CastBarContainer:Show()
            CastBar:Show()
        elseif CHANNEL_START[event] then
            local channelDuration = UnitChannelDuration("player")
            if not channelDuration then return end
            CastBar:SetTimerDuration(channelDuration, 0)
            CastBar:SetMinMaxValues(0, channelDuration:GetTotalDuration())
            CastBar.SpellName:SetText(UnitChannelInfo("player") or "")
            CastBar.Icon:SetTexture(select(3, UnitChannelInfo("player")) or nil)
            CastBar:SetScript("OnUpdate", function()
                local remainingDuration = channelDuration:GetRemainingDuration()
                CastBar:SetValue(remainingDuration)
                if remainingDuration < BCDM.db.profile.CastBar.Duration.ExpirationThreshold then
                    CastBar.Duration:SetText(string.format("%.1f", remainingDuration))
                else
                    CastBar.Duration:SetText(string.format("%.0f", remainingDuration))
                end
            end)
            CastBarContainer:Show()
            CastBar:Show()
        elseif CAST_STOP[event] then
            CastBarContainer:Hide()
            CastBar:Hide()
            CastBar:SetScript("OnUpdate", nil)
        end
    end)

    BCDM.CastBar = CastBar
    BCDM.CastBarContainer = CastBarContainer
    CastBar:Hide()
    CastBarContainer:Hide()
end

function BCDM:SetupCastBar()
    CreateCastBar()
    C_Timer.After(1, function() PlayerCastingBarFrame:UnregisterAllEvents() end)
end

function BCDM:SetCastBarHeight()
    local CastBarDB = BCDM.db.profile.CastBar
    if BCDM.CastBar then
        BCDM.CastBarContainer:SetHeight(CastBarDB.Height)
        BCDM.CastBar.Icon:SetSize(CastBarDB.Height - 2, CastBarDB.Height - 2)
    end
end

function BCDM:SetCastBarWidth()
    local CastBarDB = BCDM.db.profile.CastBar
    if BCDM.CastBar then
        local powerBarAnchor = _G[CastBarDB.Anchors[2]] == _G["BCDM_PowerBar"] or _G[CastBarDB.Anchors[2]] == _G["BCDM_SecondaryPowerBar"]
        local castBarWidth = (powerBarAnchor and _G[CastBarDB.Anchors[2]]:GetWidth()) or _G[CastBarDB.Anchors[2]]:GetWidth() + 2
        BCDM.CastBar:SetWidth(castBarWidth)
        BCDM.CastBarContainer:SetWidth(castBarWidth)
    end
end

function BCDM:UpdateCastBar()
    local GeneralDB = BCDM.db.profile.General
    local CastBarDB = BCDM.db.profile.CastBar
    if BCDM.CastBar then
        BCDM:ResolveMedia()
        BCDM.CastBarContainer:ClearAllPoints()
        BCDM.CastBarContainer:SetPoint(CastBarDB.Anchors[1], CastBarDB.Anchors[2], CastBarDB.Anchors[3], CastBarDB.Anchors[4], CastBarDB.Anchors[5])
        BCDM.CastBarContainer:SetBackdrop({bgFile = BCDM.Media.CastBarBGTexture, edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        BCDM.CastBarContainer:SetBackdropColor(unpack(CastBarDB.BGColour))
        BCDM.CastBarContainer:SetBackdropBorderColor(0, 0, 0, 1)
        BCDM.CastBar:SetStatusBarTexture(BCDM.Media.CastBarFGTexture)
        BCDM.CastBar:SetStatusBarColor(FetchCastBarColour("player"))
        BCDM.CastBar.SpellName:ClearAllPoints()
        BCDM.CastBar.SpellName:SetPoint(CastBarDB.SpellName.Anchors[1], BCDM.CastBar, CastBarDB.SpellName.Anchors[2], CastBarDB.SpellName.Anchors[3], CastBarDB.SpellName.Anchors[4])
        BCDM.CastBar.SpellName:SetFont(BCDM.Media.Font, CastBarDB.SpellName.FontSize, BCDM.db.profile.General.FontFlag)
        BCDM.CastBar.SpellName:SetTextColor(CastBarDB.SpellName.Colour[1], CastBarDB.SpellName.Colour[2], CastBarDB.SpellName.Colour[3], CastBarDB.SpellName.Colour[4])
        BCDM.CastBar.SpellName:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
        BCDM.CastBar.SpellName:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)
        BCDM.CastBar.Duration:ClearAllPoints()
        BCDM.CastBar.Duration:SetPoint(CastBarDB.Duration.Anchors[1], BCDM.CastBar, CastBarDB.Duration.Anchors[2], CastBarDB.Duration.Anchors[3], CastBarDB.Duration.Anchors[4])
        BCDM.CastBar.Duration:SetFont(BCDM.Media.Font, CastBarDB.Duration.FontSize, BCDM.db.profile.General.FontFlag)
        BCDM.CastBar.Duration:SetTextColor(CastBarDB.Duration.Colour[1], CastBarDB.Duration.Colour[2], CastBarDB.Duration.Colour[3], CastBarDB.Duration.Colour[4])
        BCDM.CastBar.Duration:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
        BCDM.CastBar.Duration:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)
        BCDM:SetCastBarHeight()
        BCDM:SetCastBarWidth()
    end
end