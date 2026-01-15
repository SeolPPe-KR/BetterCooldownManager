local _, BCDM = ...
local activeGlowingIcons = {}
local LCG = LibStub("LibCustomGlow-1.0")

local GLOW_KEY = "_BCDMGlow"
local shouldBypassHook = false

local function NudgeViewer(viewerName, xOffset, yOffset)
    local viewerFrame = _G[viewerName]
    if not viewerFrame then return end
    local point, relativeTo, relativePoint, currentX, currentY = viewerFrame:GetPoint(1)
    viewerFrame:ClearAllPoints()
    viewerFrame:SetPoint(point, relativeTo, relativePoint, currentX + xOffset, currentY + yOffset)
end

local function FetchCooldownTextRegion(cooldown)
    if not cooldown then return end
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            return region
        end
    end
end

local function ApplyCooldownText(cooldownViewer)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CooldownTextDB = CooldownManagerDB.CooldownManager.General.CooldownText
    local Viewer = _G[cooldownViewer]
    if not Viewer then return end
    for _, icon in ipairs({ Viewer:GetChildren() }) do
        if icon and icon.Cooldown then
            local textRegion = FetchCooldownTextRegion(icon.Cooldown)
            if textRegion then
                if CooldownTextDB.ScaleByIconSize then
                    local iconWidth = icon:GetWidth()
                    local scaleFactor = iconWidth / 36
                    textRegion:SetFont(BCDM.Media.Font, CooldownTextDB.FontSize * scaleFactor, GeneralDB.Fonts.FontFlag)
                else
                    textRegion:SetFont(BCDM.Media.Font, CooldownTextDB.FontSize, GeneralDB.Fonts.FontFlag)
                end
                textRegion:SetTextColor(CooldownTextDB.Colour[1], CooldownTextDB.Colour[2], CooldownTextDB.Colour[3], 1)
                textRegion:ClearAllPoints()
                textRegion:SetPoint(CooldownTextDB.Layout[1], icon, CooldownTextDB.Layout[2], CooldownTextDB.Layout[3], CooldownTextDB.Layout[4])
                if GeneralDB.Fonts.Shadow.Enabled then
                    textRegion:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
                    textRegion:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
                else
                    textRegion:SetShadowColor(0, 0, 0, 0)
                    textRegion:SetShadowOffset(0, 0)
                end
            end
        end
    end
end

local function IsCooldownViewerIcon(button)
    if not button then return false end
    local currentParent = button
    for _ = 1, 6 do
        currentParent = currentParent:GetParent()
        if not currentParent then return false end
        local parentName = currentParent:GetName()
        if parentName then
            for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
                if parentName == viewerName then
                    return true
                end
            end
        end
    end
    return false
end

local function StartGlow(iconFrame)
    if iconFrame._bcdmGlowActive then return end

    local glowSettings = BCDM.db.profile.CooldownManager.General.Glow
    if not glowSettings or not glowSettings.Enabled then return end

    LCG.PixelGlow_Stop(iconFrame, GLOW_KEY)
    LCG.AutoCastGlow_Stop(iconFrame, GLOW_KEY)

    if glowSettings.GlowType == "PIXEL" then
        LCG.PixelGlow_Start(
            iconFrame,
            glowSettings.Colour,
            glowSettings.Lines,
            glowSettings.Frequency,
            nil,
            glowSettings.Thickness,
            glowSettings.XOffset,
            glowSettings.YOffset,
            true,
            GLOW_KEY
        )
    elseif glowSettings.GlowType == "AUTO_CAST" then
        LCG.AutoCastGlow_Start(
            iconFrame,
            glowSettings.Colour,
            glowSettings.Particles,
            glowSettings.Frequency,
            glowSettings.Scale,
            glowSettings.XOffset,
            glowSettings.YOffset,
            GLOW_KEY
        )
    end

    iconFrame._bcdmGlowActive = true
    activeGlowingIcons[iconFrame] = true
end

local function StopGlow(iconFrame)
    if not iconFrame._bcdmGlowActive then return end
    LCG.PixelGlow_Stop(iconFrame, GLOW_KEY)
    LCG.AutoCastGlow_Stop(iconFrame, GLOW_KEY)
    iconFrame._bcdmGlowActive = nil
    activeGlowingIcons[iconFrame] = nil
end


local function Position()
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        local viewerSettings = cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]]
        local viewerFrame = _G[viewerName]
        if viewerFrame and (viewerName == "UtilityCooldownViewer" or viewerName == "BuffIconCooldownViewer") then
            viewerFrame:ClearAllPoints()
            viewerFrame:SetPoint(viewerSettings.Layout[1], _G[viewerSettings.Layout[2]], viewerSettings.Layout[3], viewerSettings.Layout[4], viewerSettings.Layout[5])
            viewerFrame:SetFrameStrata("LOW")
        elseif viewerFrame then
            viewerFrame:ClearAllPoints()
            viewerFrame:SetPoint(viewerSettings.Layout[1], _G[viewerSettings.Layout[2]], viewerSettings.Layout[3], viewerSettings.Layout[4], viewerSettings.Layout[5])
            viewerFrame:SetFrameStrata("LOW")
        end
        NudgeViewer(viewerName, -0.1, 0)
    end
end

local function StyleIcons()
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        for _, childFrame in ipairs({_G[viewerName]:GetChildren()}) do
            if childFrame then
                if childFrame.Icon then
                    BCDM:StripTextures(childFrame.Icon)
                    local iconZoomAmount = cooldownManagerSettings.General.IconZoom * 0.5
                    childFrame.Icon:SetTexCoord(iconZoomAmount, 1 - iconZoomAmount, iconZoomAmount, 1 - iconZoomAmount)
                end
                if childFrame.Cooldown then
                    childFrame.Cooldown:ClearAllPoints()
                    childFrame.Cooldown:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 1, -1)
                    childFrame.Cooldown:SetPoint("BOTTOMRIGHT", childFrame, "BOTTOMRIGHT", -1, 1)
                    childFrame.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
                    childFrame.Cooldown:SetDrawEdge(false)
                    childFrame.Cooldown:SetDrawSwipe(true)
                    childFrame.Cooldown:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
                end
                if childFrame.CooldownFlash then childFrame.CooldownFlash:SetAlpha(0) end
                if childFrame.DebuffBorder then childFrame.DebuffBorder:SetAlpha(0) end
                childFrame:SetSize(cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].IconSize, cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].IconSize)
                BCDM:AddBorder(childFrame)
            end
        end
    end
end

local function HideBlizzardGlow(iconFrame)
    if iconFrame.SpellActivationAlert then
        iconFrame.SpellActivationAlert:Hide()
        if iconFrame.SpellActivationAlert.ProcLoopFlipbook then
            iconFrame.SpellActivationAlert.ProcLoopFlipbook:Hide()
        end
        if iconFrame.SpellActivationAlert.ProcStartFlipbook then
            iconFrame.SpellActivationAlert.ProcStartFlipbook:Hide()
        end
    end

    if iconFrame.overlay then iconFrame.overlay:Hide() end
    if iconFrame.Overlay then iconFrame.Overlay:Hide() end
    if iconFrame.Glow then iconFrame.Glow:Hide() end
end

local function SetupGlowHooks()
    if ActionButtonSpellAlertManager then
        if ActionButtonSpellAlertManager.ShowAlert then
            hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(_, button)
                if shouldBypassHook or not IsCooldownViewerIcon(button) then return end
                HideBlizzardGlow(button)
                StartGlow(button)
            end)
        end

        if ActionButtonSpellAlertManager.HideAlert then
            hooksecurefunc(ActionButtonSpellAlertManager, "HideAlert", function(_, button)
                if not IsCooldownViewerIcon(button) then return end
                StopGlow(button)
            end)
        end
    end
end



local function SetHooks()
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() if InCombatLockdown() then return end Position() end)
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() if InCombatLockdown() then return end Position() end)
    hooksecurefunc(CooldownViewerSettings, "RefreshLayout", function() if InCombatLockdown() then return end BCDM:UpdateCooldownViewer("Buffs") BCDM:UpdateBCDM() end)
    SetupGlowHooks()
end

local function StyleChargeCount()
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    local generalSettings = BCDM.db.profile.General
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        for _, childFrame in ipairs({ _G[viewerName]:GetChildren() }) do
            if childFrame and childFrame.ChargeCount and childFrame.ChargeCount.Current then
                local currentChargeText = childFrame.ChargeCount.Current
                currentChargeText:SetFont(BCDM.Media.Font, cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.FontSize, generalSettings.Fonts.FontFlag)
                currentChargeText:ClearAllPoints()
                currentChargeText:SetPoint(cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[1], childFrame, cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[2], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[3], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[4])
                currentChargeText:SetTextColor(cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[1], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[2], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[3], 1)
                if generalSettings.Fonts.Shadow.Enabled then
                    currentChargeText:SetShadowColor(generalSettings.Fonts.Shadow.Colour[1], generalSettings.Fonts.Shadow.Colour[2], generalSettings.Fonts.Shadow.Colour[3], generalSettings.Fonts.Shadow.Colour[4])
                    currentChargeText:SetShadowOffset(generalSettings.Fonts.Shadow.OffsetX, generalSettings.Fonts.Shadow.OffsetY)
                else
                    currentChargeText:SetShadowColor(0, 0, 0, 0)
                    currentChargeText:SetShadowOffset(0, 0)
                end
            end
        end
        for _, childFrame in ipairs({ _G[viewerName]:GetChildren() }) do
            if childFrame and childFrame.Applications then
                local applicationsText = childFrame.Applications.Applications
                applicationsText:SetFont(BCDM.Media.Font, cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.FontSize, generalSettings.Fonts.FontFlag)
                applicationsText:ClearAllPoints()
                applicationsText:SetPoint(cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[1], childFrame, cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[2], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[3], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[4])
                applicationsText:SetTextColor(cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[1], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[2], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[3], 1)
                if generalSettings.Fonts.Shadow.Enabled then
                    applicationsText:SetShadowColor(generalSettings.Fonts.Shadow.Colour[1], generalSettings.Fonts.Shadow.Colour[2], generalSettings.Fonts.Shadow.Colour[3], generalSettings.Fonts.Shadow.Colour[4])
                    applicationsText:SetShadowOffset(generalSettings.Fonts.Shadow.OffsetX, generalSettings.Fonts.Shadow.OffsetY)
                else
                    applicationsText:SetShadowColor(0, 0, 0, 0)
                    applicationsText:SetShadowOffset(0, 0)
                end
            end
        end
    end
end

local function StyleBars()
    local generalSettings = BCDM.db.profile.CooldownManager.General
    local buffBarSettings = BCDM.db.profile.CooldownManager.BuffBar
    local buffBarChildren = {_G["BuffBarCooldownViewer"]:GetChildren()}


    for _, childFrame in ipairs(buffBarChildren) do
        local buffBar = childFrame.Bar
        local buffIcon = childFrame.Icon

        childFrame:SetSize(buffBarSettings.Width, buffBarSettings.Height)

        if buffBar then
            buffBar:SetSize(buffBarSettings.Width, buffBarSettings.Height)
            buffBar.BarBG:SetPoint("TOPLEFT", buffBar, "TOPLEFT", 0, 0)
            buffBar.BarBG:SetPoint("BOTTOMRIGHT", buffBar, "BOTTOMRIGHT", 0, 0)
            buffBar.BarBG:SetTexture(BCDM.Media.Background)
            buffBar.BarBG:SetVertexColor(buffBarSettings.BackgroundColour[1], buffBarSettings.BackgroundColour[2], buffBarSettings.BackgroundColour[3], buffBarSettings.BackgroundColour[4])

            if buffIcon then
                BCDM:StripTextures(buffIcon.Icon)
                buffIcon.Icon:SetSize(buffBarSettings.Height, buffBarSettings.Height)
                buffIcon.Icon:ClearAllPoints()
                buffIcon.Icon:SetPoint("RIGHT", buffBar, "LEFT", 1, 0)
                buffIcon.Icon:SetTexCoord(generalSettings.IconZoom * 0.5, 1 - generalSettings.IconZoom * 0.5, generalSettings.IconZoom * 0.5, 1 - generalSettings.IconZoom * 0.5)
            end

            BCDM:AddBorder(buffBar)
            BCDM:AddBorder(buffIcon)
        end
    end
end

local function CenterBuffs()
    local visibleBuffIcons = {}

    for _, childFrame in ipairs({BuffIconCooldownViewer:GetChildren()}) do
        if childFrame and childFrame.Icon and childFrame:IsShown() then
            table.insert(visibleBuffIcons, childFrame)
        end
    end
    local visibleCount = #visibleBuffIcons

    if visibleCount == 0 then return 0 end

    local iconWidth = visibleBuffIcons[1]:GetWidth()
    local iconSpacing = BuffIconCooldownViewer.childXPadding or 0

    local totalWidth = (visibleCount * iconWidth) + ((visibleCount - 1) * iconSpacing)
    local startX = -totalWidth / 2 + iconWidth / 2

    for index, iconFrame in ipairs(visibleBuffIcons) do
        iconFrame:ClearAllPoints()
        local xPosition = startX + (index - 1) * (iconWidth + iconSpacing)
        iconFrame:SetPoint("CENTER", BuffIconCooldownViewer, "CENTER", xPosition, 0)
    end

    return visibleCount
end

local centerBuffsEventFrame = CreateFrame("Frame")

local function SetupCenterBuffs()
    local buffsSettings = BCDM.db.profile.CooldownManager.Buffs

    if buffsSettings.CenterBuffs then
        centerBuffsEventFrame:SetScript("OnUpdate", CenterBuffs)
    else
        centerBuffsEventFrame:SetScript("OnUpdate", nil)
        centerBuffsEventFrame:Hide()
    end
end

local function SetGlowType()
    local glowSettings = BCDM.db.profile.CooldownManager.General.Glow

    for iconFrame in pairs(activeGlowingIcons) do
        LCG.PixelGlow_Stop(iconFrame, GLOW_KEY)
        LCG.AutoCastGlow_Stop(iconFrame, GLOW_KEY)
        iconFrame._bcdmGlowActive = nil

        if glowSettings and glowSettings.Enabled then
            StartGlow(iconFrame)
        end
    end
end


function BCDM:SkinCooldownManager()
    C_CVar.SetCVar("cooldownViewerEnabled", 1)
    StyleIcons()
    StyleChargeCount()
    Position()
    C_Timer.After(1, function() StyleBars() end)
    SetHooks()
    SetupCenterBuffs()
    SetGlowType()
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        C_Timer.After(0.1, function() ApplyCooldownText(viewerName) end)
    end
end

function BCDM:UpdateCooldownViewer(viewerType)
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    local cooldownViewerFrame = _G[BCDM.DBViewerToCooldownManagerViewer[viewerType]]
    if viewerType == "Custom" then BCDM:UpdateCustomCooldownViewer() return end
    if viewerType == "Item" then BCDM:UpdateCustomItemBar() return end
    if viewerType == "Buffs" then SetupCenterBuffs() end
    for _, childFrame in ipairs({cooldownViewerFrame:GetChildren()}) do
        if childFrame then
            if childFrame.Icon then
                BCDM:StripTextures(childFrame.Icon)
                childFrame.Icon:SetTexCoord(cooldownManagerSettings.General.IconZoom, 1 - cooldownManagerSettings.General.IconZoom, cooldownManagerSettings.General.IconZoom, 1 - cooldownManagerSettings.General.IconZoom)
            end
            if childFrame.Cooldown then
                childFrame.Cooldown:ClearAllPoints()
                childFrame.Cooldown:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 1, -1)
                childFrame.Cooldown:SetPoint("BOTTOMRIGHT", childFrame, "BOTTOMRIGHT", -1, 1)
                childFrame.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
                childFrame.Cooldown:SetDrawEdge(false)
                childFrame.Cooldown:SetDrawSwipe(true)
                childFrame.Cooldown:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
            end
            if childFrame.CooldownFlash then childFrame.CooldownFlash:SetAlpha(0) end
            childFrame:SetSize(cooldownManagerSettings[viewerType].IconSize, cooldownManagerSettings[viewerType].IconSize)
        end
        if cooldownViewerFrame then cooldownViewerFrame:Hide() C_Timer.After(0.001, function() cooldownViewerFrame:Show() end) end
    end

    StyleIcons()

    Position()

    StyleChargeCount()

    SetGlowType()

    ApplyCooldownText(BCDM.DBViewerToCooldownManagerViewer[viewerType])

    BCDM:UpdatePowerBarWidth()
    BCDM:UpdateSecondaryPowerBarWidth()
    BCDM:UpdateCastBarWidth()
end

function BCDM:UpdateCooldownViewers()
    BCDM:UpdateCooldownViewer("Essential")
    BCDM:UpdateCooldownViewer("Utility")
    BCDM:UpdateCooldownViewer("Buffs")
    BCDM:UpdateCustomCooldownViewer()
    BCDM:UpdateCustomItemBar()
    BCDM:UpdateCastBar()
end