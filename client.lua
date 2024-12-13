-- モデルを事前にロードしないとだめ
function loadTrainModels()
    local trainsAndCarriages = {
        'freight', 'metrotrain', 'freightcont1', 'freightcar', 
        'freightcar2', 'freightcont2', 'tankercar', 'freightgrain'
    }

    for _, vehicleName in ipairs(trainsAndCarriages) do
        local modelHashKey = GetHashKey(vehicleName)
        RequestModel(modelHashKey) 
        -- モデルがロード待機
        while not HasModelLoaded(modelHashKey) do
            Citizen.Wait(500)
        end
    end
end
-- 上記のモデルをロード
loadTrainModels()
-- 列車を保持
local spawnedTrain = nil
local trainMovementTask = nil
-- 座標
local startCoords = vector3(1438.98, 6405.92, 34.19) -- 開始地点
local endCoords = vector3(1500.00, 6500.00, 35.00) -- 止める地点
local trainSpeed = 10.0 -- 列車の速度
-- 電車生成
function createAndMoveTrain()
    -- 削除してから生成
    if spawnedTrain then
        DeleteMissionTrain(spawnedTrain)
        spawnedTrain = nil
    end

    local variation = 0 -- 列車のバリエーション
    spawnedTrain = CreateMissionTrain(
        variation,
        startCoords.x, startCoords.y, startCoords.z,
        true,  -- 方向(前)
        false, -- ミッション用
        true   -- ネットワーク同期
    )

    if spawnedTrain then
        -- 列車の速度
        SetTrainSpeed(spawnedTrain, trainSpeed)
        SetTrainCruiseSpeed(spawnedTrain, trainSpeed)

        trainMovementTask = Citizen.CreateThread(function()
            while true do
                local trainCoords = GetEntityCoords(spawnedTrain)
                -- 列車が目標地点に近づくと速度落とす
                if #(trainCoords - endCoords) < 10.0 then
                    SetTrainSpeed(spawnedTrain, 0.0)
                    SetTrainCruiseSpeed(spawnedTrain, 0.0)
                    TriggerEvent('chat:addMessage', {
                        args = { 'The train has stopped.' }
                    })
                    break
                end
                Citizen.Wait(500) 
            end
        end)
    else
        TriggerEvent('chat:addMessage', {
            args = { 'Failed to spawn' }
        })
    end
end

-- movetrain
RegisterCommand("strtrain", function(source, args, rawCommand)
    createAndMoveTrain()
end)

-- deletetrain
RegisterCommand("deletrain", function(source, args, rawCommand)
    if spawnedTrain then
        DeleteMissionTrain(spawnedTrain)
        spawnedTrain = nil

        if trainMovementTask then
            Citizen.Wait(trainMovementTask)
            trainMovementTask = nil
        end

        TriggerEvent('chat:addMessage', {
            args = { 'Train deleted' }
        })
    else
        TriggerEvent('chat:addMessage', {
            args = { 'No train' }
        })
    end
end)
