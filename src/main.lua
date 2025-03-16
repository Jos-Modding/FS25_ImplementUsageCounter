source(Utils.getFilename("src/BaleWrapCounterHUDExtension.lua", g_currentModDirectory))
source(Utils.getFilename("src/BaleWrapCounterResetEvent.lua", g_currentModDirectory))

g_specializationManager:addSpecialization("baleWrapCounter", "BaleWrapCounter", Utils.getFilename("src/BaleWrapCounter.lua", g_currentModDirectory), "")

for vehicleName, vehicleType in pairs(g_vehicleTypeManager.types) do
    if SpecializationUtil.hasSpecialization(BaleWrapper, vehicleType.specializations) then
        g_vehicleTypeManager:addSpecialization(vehicleName, g_currentModName .. ".baleWrapCounter")
    end

    if SpecializationUtil.hasSpecialization(InlineWrapper, vehicleType.specializations) then
        g_vehicleTypeManager:addSpecialization(vehicleName, g_currentModName .. ".baleWrapCounter")
    end
end

--print("# BaleCounter")
--print_r(BaleCounter)
--print("# BaleCounterHUDExtension")
--print_r(BaleCounterHUDExtension)
--print("# BaleCounterResetEvent")
--print_r(BaleCounterResetEvent)
--print_r(BaleWrapper)
