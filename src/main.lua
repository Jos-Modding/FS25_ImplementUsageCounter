local modName = g_currentModName or "unknown"

local function initSpecializations(manager)
    if manager.typeName == "vehicle" then
        for typeName, typeEntry in pairs(g_vehicleTypeManager:getTypes()) do
            if SpecializationUtil.hasSpecialization(BaleWrapper, typeEntry.specializations) or SpecializationUtil.hasSpecialization(InlineWrapper, typeEntry.specializations) then
                g_vehicleTypeManager:addSpecialization(typeName, modName .. ".baleWrapCounter")
            end

            if SpecializationUtil.hasSpecialization(Cultivator, typeEntry.specializations) then
                g_vehicleTypeManager:addSpecialization(typeName, modName .. ".cultivatorCounter")
            end

            if SpecializationUtil.hasSpecialization(Cutter, typeEntry.specializations) then
                g_vehicleTypeManager:addSpecialization(typeName, modName .. ".cutterCounter")
            end

            if SpecializationUtil.hasSpecialization(Mower, typeEntry.specializations) then
                g_vehicleTypeManager:addSpecialization(typeName, modName .. ".mowerCounter")
            end

            if SpecializationUtil.hasSpecialization(Plow, typeEntry.specializations) then
                g_vehicleTypeManager:addSpecialization(typeName, modName .. ".plowCounter")
            end

            if SpecializationUtil.hasSpecialization(SowingMachine, typeEntry.specializations) then
                g_vehicleTypeManager:addSpecialization(typeName, modName .. ".sowingMachineCounter")
            end

            if SpecializationUtil.hasSpecialization(Sprayer, typeEntry.specializations) then
                g_vehicleTypeManager:addSpecialization(typeName, modName .. ".sprayerCounter")
            end
        end
    end
end

TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, initSpecializations)
