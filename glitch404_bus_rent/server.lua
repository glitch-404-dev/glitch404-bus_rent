RegisterNetEvent('ox_bus:buyTicket', function()
    local src = source

    if exports.ox_inventory:GetItemCount(src, Config.TicketItem) > 0 then
        TriggerClientEvent('ox_bus:ticketApproved', src)
        return
    end

    exports.ox_inventory:AddItem(src, Config.TicketItem, 1)

    TriggerClientEvent('ox_bus:ticketApproved', src)
end)

RegisterNetEvent('ox_bus:calculateFare', function(dest)
    local src = source
    local ped = GetPlayerPed(src)
    local startCoords = GetEntityCoords(ped)

    local distance = #(startCoords - vector3(dest.x, dest.y, dest.z))
    local price = math.floor(distance * Config.PricePerMeter)

    local money = exports.ox_inventory:GetItemCount(src, 'money')

    if money < price then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Bus Fare',
            description = 'Enough money nai!',
            type = 'error'
        })
        return
    end

    exports.ox_inventory:RemoveItem(src, 'money', price)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Bus Fare',
        description = ('Fare paid: $%s'):format(price),
        type = 'success'
    })
end)