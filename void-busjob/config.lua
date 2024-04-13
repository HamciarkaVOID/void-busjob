Config = {}

Config.PricePerPoint = 50
Config.CreatingDestinations = false --Enable it when creating destinations. It's going to help a lot.
Config.DurationForEachStop = 10000 -- miliseconds
Config.Deposit = 500

Config.Job = {
    ['LS Central Bus Station'] = {
        coords = vec3(435.9806, -645.6779, 27.7394),
        blip = {
            color = 2,
            sprite = 513,
            scale = 0.7,
        },
        ped = {
            model = 'a_m_m_skater_01',
            heading = 89.3560
        },
        bus = {
            coords = vec3(462.0979, -646.0181, 28.3099),
            heading = 173.1868,
            modelHash = 'bus',
        },
        destination = {
            vec3(304.4504, -765.5596, 29.3099),
            vec3(-110.0889, -1686.0311, 29.3067),
            vec3(114.3204, -781.4406, 31.4071),
            vec3(-176.1069, -818.5172, 31.1218),
            vec3(-644.5959, -137.7529, 37.6802),
            vec3(-693.7390, -6.0147, 38.1177)
        }
    },
    --- add more if needed
}

-- creds to: wasabi
RegisterNetEvent('void-busjob:notify')
AddEventHandler('void-busjob:notify', function(title, message, msgType)	
    if not msgType then
        exports['void-notify']:Notify({
            title = title,
            description = message,
            type = 'info',
            duration = 5 
        })    
    else
        exports['void-notify']:Notify({
            title = title,
            description = message,
            type = msgType,
            duration = 5 
        })  
    end
end)