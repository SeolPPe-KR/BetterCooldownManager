local _, BCDM = ...
local LEMO = LibStub("LibEditModeOverride-1.0")

function BCDM:SetupEventManager()
    local BCDMEventManager = CreateFrame("Frame", "BCDMEventManagerFrame")
    BCDMEventManager:RegisterEvent("PLAYER_ENTERING_WORLD")
    BCDMEventManager:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    BCDMEventManager:RegisterEvent("TRAIT_CONFIG_UPDATED")
    BCDMEventManager:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            local unit = ...
            if unit ~= "player" then return end
            BCDM:UpdateBCDM()
            LEMO:ApplyChanges()
        else
            BCDM:UpdateBCDM()
            LEMO:ApplyChanges()
        end
    end)
end