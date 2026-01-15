local _, BCDM = ...
BCDM.EditModeLayoutsLayouts = {}

-- Thank you Meeres & Alf for this.
-- Alf provided most of the code, I just adapted where appropriate.

function BCDM:GetLayouts()
    local layoutInfo = C_EditMode.GetLayouts()
    for i, info in pairs(layoutInfo.layouts) do
        table.insert(BCDM.EditModeLayoutsLayouts, info.layoutName)
    end
    return BCDM.EditModeLayoutsLayouts
end

local function GetIndexForName(name)
    local layoutInfo = C_EditMode.GetLayouts()
    for i, info in pairs(layoutInfo.layouts) do
        if info.layoutName == name then
            local offset = 2
            local index = i + offset
            if index == layoutInfo.activeLayout then return end
            return index
        end
    end
end

function BCDM:SetupEditModeManager()
    local EditModeManagerEventFrame = CreateFrame("Frame")
    EditModeManagerEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    EditModeManagerEventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    EditModeManagerEventFrame:SetScript("OnEvent", function() BCDM:UpdateLayout() end)
end

function BCDM:UpdateLayout()
    local DIFFICULTY_IDS = {
        [14] = BCDM.db.profile.EditModeManager.RaidLayouts.Normal,
        [15] = BCDM.db.profile.EditModeManager.RaidLayouts.Heroic,
        [16] = BCDM.db.profile.EditModeManager.RaidLayouts.Mythic,
        [17] = BCDM.db.profile.EditModeManager.RaidLayouts.LFR,
    }

    local SPEC_IDS = {
        [1] = BCDM.db.profile.EditModeManager.SpecializationLayouts[1],
        [2] = BCDM.db.profile.EditModeManager.SpecializationLayouts[2],
        [3] = BCDM.db.profile.EditModeManager.SpecializationLayouts[3],
        [4] = BCDM.db.profile.EditModeManager.SpecializationLayouts[4],
    }
    if BCDM.db.profile.EditModeManager.SwapOnInstanceDifficulty then
        local DifficultyID = select(3, GetInstanceInfo())
        local layoutName = DIFFICULTY_IDS[DifficultyID]
        if not layoutName then return end
        if layoutName then
            local index = GetIndexForName(layoutName)
            if index then
                BCDM:PrettyPrint("Layout Set - |cFF8080FF" .. layoutName .. "|r")
                C_EditMode.SetActiveLayout(index)
                return layoutName, index
            end
        end
    end

    if BCDM.db.profile.EditModeManager.SwapOnSpecializationChange then
        local specID = GetSpecialization()
        local layoutName = SPEC_IDS[specID]
        if not layoutName then return end
        if layoutName then
            local index = GetIndexForName(layoutName)
            if index then
                BCDM:PrettyPrint("Layout Set - |cFF8080FF" .. layoutName .. "|r")
                C_EditMode.SetActiveLayout(index)
                return layoutName, index
            end
        end
    end
end