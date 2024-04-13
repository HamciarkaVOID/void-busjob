ESX.RegisterServerCallback('void-busjob:updatedPoints', function(source, cb, collectedPoints)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.Async.execute('UPDATE users SET busPoints = @busPoints WHERE identifier = @identifier', {
        ['@busPoints'] = collectedPoints,
        ['@identifier'] = xPlayer.identifier
    }, function(rowsChanged)
        if rowsChanged > 0 then
            cb(true)
        else
            cb(false)
        end
    end)
end)

ESX.RegisterServerCallback('void-busjob:getTotalPoints', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.Async.fetchScalar('SELECT busPoints FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(totalPoints)
        if totalPoints then
            cb(totalPoints)
        else
            cb(0)
        end
    end)
end)


ESX.RegisterServerCallback('void-busjob:payAndResetPoints', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.Async.fetchScalar('SELECT busPoints FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(currentPoints)
        if currentPoints and currentPoints > 0 then
            local totalPrice = currentPoints * Config.PricePerPoint

            xPlayer.addAccountMoney('bank', totalPrice)

            MySQL.Async.execute('UPDATE users SET busPoints = 0 WHERE identifier = @identifier', {
                ['@identifier'] = xPlayer.identifier
            })
            cb(currentPoints, totalPrice)
        else
            cb(0, 0)
        end
    end)
end)

ESX.RegisterServerCallback('void-busjob:deposit', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer.getAccount('bank').money >= Config.Deposit then
        xPlayer.removeAccountMoney('bank', Config.Deposit)
        cb(true)
    else
        cb(false)
    end
end)


ESX.RegisterServerCallback('void-busjob:addDepositToBank', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    xPlayer.addAccountMoney('bank', Config.Deposit)

    cb(true)
end)

