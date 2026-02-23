local spawnedBus = nil
local spawnedDriver = nil
local hasTicket = false

-- ==============================
-- /bus COMMAND
-- ==============================
RegisterCommand('bus', function()
    if spawnedBus then
        lib.notify({
            title = 'Bus',
            description = 'Bus already called!',
            type = 'error'
        })
        return
    end

    callBus()
end)

-- ==============================
-- CALL BUS FUNCTION
-- ==============================
function callBus()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)

    -- 🔥 FIND NEAREST ROAD (VERY IMPORTANT)
    local found, x, y, z, heading =
        GetClosestVehicleNodeWithHeading(
            pedCoords.x,
            pedCoords.y,
            pedCoords.z,
            1,
            3.0,
            0
        )

    if not found then
        lib.notify({
            title = 'Bus',
            description = 'No road found nearby!',
            type = 'error'
        })
        return
    end

    -- Load models
    lib.requestModel(Config.BusModel)
    lib.requestModel(Config.DriverModel)

    -- Spawn bus
    spawnedBus = CreateVehicle(
        joaat(Config.BusModel),
        x,
        y,
        z,
        heading,
        true,
        true
    )

    -- Physics & stability fixes
    SetVehicleOnGroundProperly(spawnedBus)
    SetEntityRotation(spawnedBus, 0.0, 0.0, heading, 2, true)
    SetEntityAsMissionEntity(spawnedBus, true, true)
    SetVehicleEngineOn(spawnedBus, true, true)

    -- Spawn NPC driver
    spawnedDriver = CreatePedInsideVehicle(
        spawnedBus,
        26,
        joaat(Config.DriverModel),
        -1,
        true,
        true
    )

    -- Driver AI settings
    SetBlockingOfNonTemporaryEvents(spawnedDriver, true)
    SetPedKeepTask(spawnedDriver, true)
    SetDriverAbility(spawnedDriver, 1.0)
    SetDriverAggressiveness(spawnedDriver, 0.0)

    -- Drive bus to player
    TaskVehicleDriveToCoord(
        spawnedDriver,
        spawnedBus,
        pedCoords.x,
        pedCoords.y,
        pedCoords.z,
        Config.BusSpeed,
        0,
        GetEntityModel(spawnedBus),
        786603,
        5.0
    )

    -- ox_target on bus
    exports.ox_target:addLocalEntity(spawnedBus, {
        {
            label = '🎟️ Buy Bus Ticket',
            icon = 'ticket',
            distance = 3.0,
            onSelect = function()
                TriggerServerEvent('ox_bus:buyTicket')
            end
        }
    })

    lib.notify({
        title = 'Bus Called',
        description = 'Bus is on the way 🚍',
        type = 'inform'
    })
end

-- ==============================
-- TICKET APPROVED
-- ==============================
RegisterNetEvent('ox_bus:ticketApproved', function()
    if not spawnedBus or not spawnedDriver then return end

    hasTicket = true

    -- Put player into bus
    TaskWarpPedIntoVehicle(PlayerPedId(), spawnedBus, 1)

    lib.notify({
        title = 'Bus',
        description = 'Set your destination on the map 📍',
        type = 'inform'
    })

    selectRoute()
end)

-- ==============================
-- ROUTE SELECTION (MAP WAYPOINT)
-- ==============================
function selectRoute()
    SetWaypointOff()

    while not IsWaypointActive() do
        Wait(500)
    end

    local waypoint = GetFirstBlipInfoId(8)
    local dest = GetBlipInfoIdCoord(waypoint)

    -- Calculate fare server-side
    TriggerServerEvent('ox_bus:calculateFare', dest)

    -- Drive to destination
    TaskVehicleDriveToCoord(
        spawnedDriver,
        spawnedBus,
        dest.x,
        dest.y,
        dest.z,
        Config.BusSpeed,
        0,
        GetEntityModel(spawnedBus),
        786603,
        5.0
    )
end