local _, BCDM = ...
local LEMO = LibStub("LibEditModeOverride-1.0")

local buffBarPostLoadTimer

local function QueueBuffBarPostLoadRefresh()
    if buffBarPostLoadTimer then
        buffBarPostLoadTimer:Cancel()
        buffBarPostLoadTimer = nil
    end
    buffBarPostLoadTimer = C_Timer.After(0.6, function()
        buffBarPostLoadTimer = nil
        if InCombatLockdown() then return end
        BCDM:UpdateCooldownViewer("BuffBar")
    end)
end

function BCDM:SetupEventManager()
    local BCDMEventManager = CreateFrame("Frame", "BCDMEventManagerFrame")
    BCDMEventManager:RegisterEvent("PLAYER_ENTERING_WORLD")
    BCDMEventManager:RegisterEvent("LOADING_SCREEN_DISABLED")
    BCDMEventManager:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    BCDMEventManager:RegisterEvent("TRAIT_CONFIG_UPDATED")
    BCDMEventManager:SetScript("OnEvent", function(_, event, ...)
        if InCombatLockdown() then return end
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            local unit = ...
            if unit ~= "player" then return end
            LEMO:ApplyChanges()
            BCDM:UpdateBCDM()
        else
            BCDM:UpdateBCDM()
            if event == "PLAYER_ENTERING_WORLD" or event == "LOADING_SCREEN_DISABLED" then
                QueueBuffBarPostLoadRefresh()
            end
        end
    end)
end
