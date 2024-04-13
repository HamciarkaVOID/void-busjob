local npcZones = {}
local spawnedVehicles = {}
local textUI = nil
local Utils = {}
local jobBlips = {}
local visitedDestinations = {}
local allDestinationsVisited = false
local collectedPoints = 0
local currentZone = nil
local currentJobZone = nil
local isInJobZone = false
local lastEnteredZone = nil
local JobStarted = false  
lib.locale()


Utils.ShowTextUI = function(text)
    if not lib.isTextUIOpen() then
        textUI = lib.showTextUI(text, {
            position = 'right-center',
            icon = 'bus',
        })
    end
end

Utils.RemoveDestinationMarker = function()
    if currentJobZone and jobBlips[currentJobZone] then
        RemoveBlip(jobBlips[currentJobZone])
        jobBlips[currentJobZone] = nil
    end    
end

Utils.GetClosestZone = function ()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestZone = nil
    local shortestDistance = nil

    for name, data in pairs(Config.Job) do
        local zoneCoords = data.coords
        local distance = #(playerCoords - zoneCoords) 

        if not shortestDistance or distance < shortestDistance then
            shortestDistance = distance
            closestZone = name
        end
    end

    return closestZone, shortestDistance
end

Utils.GenerateVehicleNumber = function ()
    math.randomseed(GetGameTimer())
    local num1 = math.random(1000, 9999)
    local num2 = math.random(10, 99)
    return string.format("%04d%02d", num1, num2)
end

Utils.CreateJobVehicle = function ()
    local closestZone, shortestDistance = Utils.GetClosestZone()
    if closestZone then

        local jobData = Config.Job[closestZone]

        if jobData and jobData.bus then
            local busCoords = jobData.bus.coords
            local busHeading = jobData.bus.heading
            local busModelHash = GetHashKey(jobData.bus.modelHash)
            local vehicleNumber = Utils.GenerateVehicleNumber()

            RequestModel(busModelHash)
            
            while not HasModelLoaded(busModelHash) do
                Citizen.Wait(100)
            end

            local bus = CreateVehicle(busModelHash, busCoords.x, busCoords.y, busCoords.z, busHeading, true, false)

            TriggerEvent('void-busjob:notify', locale('notify_title'), locale('paid_for_deposit', Config.Deposit), 'success')
            
            if not DoesEntityExist(bus) then
                print("Bus entity does not exist.") 
                return
            end
            
            SetEntityAsMissionEntity(bus, true, true)
            SetVehicleOnGroundProperly(bus)
            
            
            SetPedIntoVehicle(PlayerPedId(), bus, -1)
            
            SetVehicleNumberPlateText(bus, vehicleNumber)
            
            spawnedVehicles[bus] = {
                zone = closestZone,
                plate = vehicleNumber,
                modelHash = busModelHash
            }
            
        else
            print("Job data or bus data not found for " .. closestZone)
        end
    else
        print("No job zones found.")
    end
end

Utils.CreateNPC = function(coords, model, heading)
    local pedModel = GetHashKey(model)  
    RequestModel(pedModel)             
    while not HasModelLoaded(pedModel) do
        Citizen.Wait(0)
    end
    
    local ped = CreatePed(4, pedModel, coords.x, coords.y, coords.z, 0.0, true, false)
    
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityHeading(ped, heading)
    
    AddEventHandler("onResourceStop", function(resource)
        if resource == GetCurrentResourceName() then
            DeleteEntity(ped)
        end
    end)
    
    SetModelAsNoLongerNeeded(pedModel)   
    
    return ped
end

Utils.CreateBlip = function (coords, sprite, color, name, scale)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z) 
    SetBlipSprite(blip, sprite)          
    SetBlipDisplay(blip, 4)               
    SetBlipScale(blip, scale or 1.0)     
    SetBlipColour(blip, color)            
    SetBlipAsShortRange(blip, true)        
    BeginTextCommandSetBlipName("STRING")   
    AddTextComponentString(name)            
    EndTextCommandSetBlipName(blip)      
    return blip  
end


function onEnter(name)
    local jobData = Config.Job[name] 
    if jobData then
        npcZones[name] = Utils.CreateNPC(jobData.coords, jobData.ped.model, jobData.ped.heading)
        Utils.ShowTextUI(locale('start_job'))
        isInJobZone = true
        lastEnteredZone = name  
    end
end

function onExit(name)
    local ped = npcZones[name]
    if ped then
        DeleteEntity(ped)
        npcZones[name] = nil
        lib.hideTextUI()
    end
    isInJobZone = false
end


Citizen.CreateThread(function()
    for name, data in pairs(Config.Job) do
        local zoneCoords = data.coords
        lib.zones.sphere({
            coords = vec3(zoneCoords.x, zoneCoords.y, zoneCoords.z),
            radius = 4,
            debug = false,
            onEnter = function() onEnter(name) end,
            onExit = function() onExit(name) end
        })
    end
end)

Citizen.CreateThread(function()
    for name, data in pairs(Config.Job) do
        if data.blip then
            Utils.CreateBlip(data.coords, data.blip.sprite, data.blip.color, name, data.blip.scale)
        else
            print("Warning: No blip data found for " .. name)
        end
    end
end)

Utils.StartJob = function ()
    local jobName = lastEnteredZone 
    local jobData = Config.Job[jobName]

    if jobData and jobData.destination then
        Utils.RemoveDestinationMarker()

        if #visitedDestinations == #jobData.destination then
            visitedDestinations = {}
            allDestinationsVisited = false
        end

        local availableDestinations = {}
        for _, dest in ipairs(jobData.destination) do
            local isVisited = false
            for _, visited in ipairs(visitedDestinations) do
                if dest.x == visited.x and dest.y == visited.y and dest.z == visited.z then
                    isVisited = true
                    break
                end
            end
            if not isVisited then
                table.insert(availableDestinations, dest)
            end
        end

        if #availableDestinations == 0 then
            allDestinationsVisited = true
        end

        if allDestinationsVisited then
            visitedDestinations = {}
            allDestinationsVisited = false
            return
        end

        local randomIndex = math.random(1, #availableDestinations)
        local destinationCoords = availableDestinations[randomIndex]

        table.insert(visitedDestinations, destinationCoords)

        local blip = AddBlipForCoord(destinationCoords.x, destinationCoords.y, destinationCoords.z)
        SetBlipSprite(blip, 162)  
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)  
        SetBlipColour(blip, 3)  
        SetBlipAsShortRange(blip, true) 

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(locale("destination_blip"))  
        EndTextCommandSetBlipName(blip)

        SetBlipRoute(blip, true)

        jobBlips[jobName] = blip 
        currentJobZone = jobName 

        if currentZone then
            currentZone:remove()  
        end
        currentZone = lib.zones.sphere({
            coords = vec3(destinationCoords.x, destinationCoords.y, destinationCoords.z),
            radius = 5,
            debug = Config.CreatingDestinations,
            onEnter = function(self) 
            
                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                local vehicleModelHash = GetEntityModel(vehicle)
                local jobBusModelHash = GetHashKey(jobData.bus.modelHash)
            
                if vehicleModelHash ~= jobBusModelHash then
                    TriggerEvent('void-busjob:notify', locale('notify_title'), locale('not_correct_vehicle'), 'error')
                    return
                end
            
                if DoesEntityExist(vehicle) then
                    FreezeEntityPosition(vehicle, true)
                end
            
                local success = lib.progressCircle({
                    duration = Config.DurationForEachStop, 
                    position = 'bottom',
                    label = locale('collecting_passengers'),
                    useWhileDead = false,
                    canCancel = false,
                    disable = {
                        car = true,
                        move = true,
                    },
                })
            
                if success then
                    ESX.TriggerServerCallback('void-busjob:getTotalPoints', function(totalPoints)
                        if totalPoints then
                            collectedPoints = totalPoints + 1  
                            
                            ESX.TriggerServerCallback('void-busjob:updatedPoints', function(updatedPoints)
                                if updatedPoints then
                                    collectedPoints = updatedPoints

                                    TriggerEvent('void-busjob:notify', locale('notify_title'), locale('earned_point'), 'success')

                                end
                            end, collectedPoints)
                        end
                    end)
                
                    FreezeEntityPosition(vehicle, false)
                    self:remove() 
                    Utils.StartJob()
                end
            end,
        })

    else
        print("Job data or destination data not found for " .. jobName)
    end
end


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)

        if isInJobZone then
            if IsControlJustPressed(0, 38) then
                local contextOptions = {
                    {
                        title = locale('start_job_title'),
                        description = locale('start_job_desc'),
                        onSelect = function()
                            if JobStarted then
                                TriggerEvent('void-busjob:notify', locale('notify_title'), locale('already_job'), 'info')
                                return
                            end
                    
                            ESX.TriggerServerCallback('void-busjob:deposit', function(hasSufficientFunds)
                                if hasSufficientFunds then
                                    JobStarted = true
                                    Utils.CreateJobVehicle()                                    
                                    Utils.StartJob()
                                else
                                    TriggerEvent('void-busjob:notify', locale('notify_title'), locale('not_enough_funds', Config.Deposit), 'error')
                                end
                            end)
                        end,
                        icon = 'bus'
                    },
                    {
                        title = locale('guidebook_title'),
                        description = locale('guidebook_desc'),
                        onSelect = function()
                            local alert = lib.alertDialog({
                                header = locale('guidebook_title'),
                                content = locale('guidebook_content'),
                                centered = true,
                                cancel = true
                            })
                        end,
                        icon = 'book'
                    },
                }

                ESX.TriggerServerCallback('void-busjob:getTotalPoints', function(totalPoints)
                    table.insert(contextOptions, {
                        title = locale('job_fund_title'),
                        description = locale('job_fund_desc'),
                        icon = 'coins',
                        onSelect = function ()
                            ESX.TriggerServerCallback('void-busjob:payAndResetPoints', function(currentPoints, totalPrice)
                                if currentPoints and totalPrice and currentPoints > 0 then
                                    TriggerEvent('void-busjob:notify', locale('notify_title'), locale('paid_and_reset'), 'success')
                                else
                                    TriggerEvent('void-busjob:notify', locale('notify_title'), locale('paid_failed'), 'error')
                                end
                            end)
                        end,
                        metadata = {
                            {label = locale('points'), value = totalPoints},
                            {label = locale('current_payout'), value = Config.PricePerPoint .. locale('currency_symbol')},
                          },
                    })
                
                    lib.registerContext({
                        id = 'main_menu',
                        title = locale('context_menu'),
                        onExit = function()
                            Utils.ShowTextUI(locale('start_job'))
                        end,
                        options = contextOptions
                    })
                
                    lib.showContext('main_menu')
                    lib.hideTextUI()
                end)
                      

                if JobStarted then
                    table.insert(contextOptions, {
                        title = locale('quit_job_title'),
                        description = locale('quit_job_desc'),
                        onSelect = function()
                            ESX.TriggerServerCallback('void-busjob:addDepositToBank', function(success)
                                if success then
                                    Utils.QuitJob()
                                    TriggerEvent('void-busjob:notify', locale('notify_title'), locale('deposit_back'), 'success')
                                end
                            end)
                        end,
                        icon = 'right-from-bracket'
                    })
                end

                lib.registerContext({
                    id = 'main_menu',
                    title = locale('context_menu'),
                    onExit = function()
                        Utils.ShowTextUI(locale('start_job'))
                    end,
                    options = contextOptions
                })

                lib.showContext('main_menu')
                lib.hideTextUI()
            end
        end
    end
end)

Utils.QuitJob = function ()
    JobStarted = false

    for vehicle, data in pairs(spawnedVehicles) do
        if data.zone == currentJobZone then
            DeleteEntity(vehicle)
            spawnedVehicles[vehicle] = nil
            break
        end
    end

    if jobBlips[currentJobZone] then
        RemoveBlip(jobBlips[currentJobZone])
        jobBlips[currentJobZone] = nil
    end

    visitedDestinations = {}

    TriggerEvent('void-busjob:notify', locale('notify_title'), locale('quit_job'), 'success')
end



AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for _, blip in ipairs(jobBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
    end
end)