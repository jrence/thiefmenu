local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["rightSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["rightCTRL"] = 36, ["rightALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["right"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX = nil

local handcuffed                = false
local IsDragged                 = false
local CopPed                    = 0
local IsAbleToSearch            = false


Citizen.CreateThread(function()
    while ESX == nil do
      TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
      Citizen.Wait(0)
    end
end)

function IsAbleToSteal(targetSID, err)
    ESX.TriggerServerCallback('esx_thief:getValue', function(result)
        local result = result
        if result.value then
            err(false)
        else
            err(_U('no_hands_up'))
        end
    end, targetSID)
end

---- MENU

function GetPlayers()
    local players = {}

    for i = 0, 31 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end

    return players
end

function GetClosestPlayer()
    local players = GetPlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local ply = GetPlayerPed(-1)
    local plyCoords = GetEntityCoords(ply, 0)

    for index,value in ipairs(players) do
        local target = GetPlayerPed(value)
        if(target ~= ply) then
            local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
            local distance = GetDistanceBetweenCoords(targetCoords['x'], targetCoords['y'], targetCoords['z'], plyCoords['x'], plyCoords['y'], plyCoords['z'], true)
            if(closestDistance == -1 or closestDistance > distance) then
                closestPlayer = value
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

function OpenCuffMenu()

  local elements = {
        {label = _U('cuff'), value = 'cuff'},
        {label = _U('uncuff'), value = 'uncuff'}, 
        {label = _U('drag'), value = 'drag'},
		{label = _U('search'), value = 'search'},
		{label = _U('blindfold'), value = 'blindfold'},
       		
      }

  ESX.UI.Menu.CloseAll()

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'cuffing',
    {
      title    = _U('handcuffs'),
      align    = 'top-right',
      elements = elements
      },
          function(data2, menu2)
            local player, distance = ESX.Game.GetClosestPlayer()
            if distance ~= -1 and distance <= 3.0 then
              if data2.current.value == 'cuff' then
                if Config.EnableItems then

                    local target_id = GetPlayerServerId(player)
                
                    IsAbleToSteal(target_id, function(err)

                        if not err then
                            ESX.TriggerServerCallback('esx_thief:getItemQ', function(quantity)
                                if quantity > 0 then
                                    IsAbleToSearch = true
                                    TriggerServerEvent('cuffServer', GetPlayerServerId(player))
                                else
                                    ESX.ShowNotification(_U('no_handcuffs'))
                                end
                            end, 'handcuffs')
                        else
                            ESX.ShowNotification(err)
                        end
                    end)
                else
                    IsAbleToSearch = true
                    TriggerServerEvent('cuffServer', GetPlayerServerId(player))
                end
              end
			  
              if data2.current.value == 'uncuff' then
                if Config.EnableItems then
                    ESX.TriggerServerCallback('esx_thief:getItemQ', function(quantity)
                        if quantity > 0 then
                            IsAbleToSearch = false
                            TriggerServerEvent('unCuffServer', GetPlayerServerId(player))
                        else
                            ESX.ShowNotification(_U('no_handcuffs'))
                        end
                    end, 'handcuffs')
                else
                    IsAbleToSearch = false
                    TriggerServerEvent('cuffServer', GetPlayerServerId(player))
                end
              end
              if data2.current.value == 'drag' then
                if Config.EnableItems then
                    ESX.TriggerServerCallback('esx_thief:getItemQ', function(quantity)
                        if quantity > 0 then
                            IsAbleToSearch = false
                            TriggerServerEvent('dragServer', GetPlayerServerId(player))
                        else
                            ESX.ShowNotification(_U('no_rope'))
                        end
                    end, 'rope')
                else
                    TriggerServerEvent('dragServer', GetPlayerServerId(player))
                end
              end  
			                if data2.current.value == 'bagol1' then
TriggerServerEvent('esx_policejob:trunk', GetPlayerServerId(closestPlayer))
              end  
              if data2.current.value == 'search' then

                local ped = PlayerPedId()

                if IsPedArmed(ped, 7) then
                    if IsAbleToSearch then
                        local target, distance = ESX.Game.GetClosestPlayer()
                        if target ~= -1 and distance ~= -1 and distance <= 2.0 then
                            local target_id = GetPlayerServerId(target)
                            OpenStealMenu(target, target_id)
                            TriggerEvent('animation')
                        elseif distance < 20 and distance > 2.0 then
                            ESX.ShowNotification(_U('too_far'))
                        else
                            ESX.ShowNotification(_U('no_players_nearby'))
                        end
                    else
                        ESX.ShowNotification(_U('not_cuffed'))
                    
                    end
                else
                    ESX.ShowNotification(_U('not_armed'))
                end
              end
            else
              ESX.ShowNotification(_U('no_players_nearby'))
            end
          end,
    function(data2, menu2)
      menu2.close()
    end
  )

end


Citizen.CreateThread(function()
       while true do
   		Citizen.Wait(5)

                if PlayerIsInTrunk then

                local playerPed = PlayerPedId()
                 local boneName = GetEntityBoneIndexByName(vehicleTrunk, 'boot')
            if currentView ~= 4 then
                SetFollowPedCamViewMode(4)
                Citizen.Trace(GetFollowPedCamViewMode())
            end
DisplayRadar(false)
			--DisableControlAction(0, 322, true) -- Animations
			--DisableControlAction(0, 177, true) -- Animations
			--DisableControlAction(0, 200, true) -- Animations
			--DisableControlAction(0, 202, true) -- Animations
			--DisableControlAction(0, Keys['P'], true) -- Job

			--DisableControlAction(0, 75, true)  -- Disable exit vehicle

		--bag = CreateObject(GetHashKey("prop_beach_punchbag"), 0, 0, 0, true, true, true)		

                 AttachEntityToEntity(playerPed, vehicleTrunk, boneName, 0.1, 0, -0.75, 0, 0, 0, 0, true, false, true , 0, false)

                -- AttachEntityToEntity(bag, vehicleTrunk, boneName, 0, 0, 0, 0, 0, 0, 0, true, false, true , 0, false)
SetEntityVisible(playerPed, false)
end
end
end)

Citizen.CreateThread(function()
    while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('cuffClient')
AddEventHandler('cuffClient', function()
	local pP = GetPlayerPed(-1)
	RequestAnimDict('mp_arresting')
	while not HasAnimDictLoaded('mp_arresting') do
		Citizen.Wait(100)
	end
	TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 30.0, 'Kajdanki', 0.2)
	TaskPlayAnim(pP, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
	SetEnableHandcuffs(pP, true)
	SetCurrentPedWeapon(pP, GetHashKey('WEAPON_UNARMED'), true)
	DisablePlayerFiring(pP, true)
    ESX.ShowNotification(_U('cuffed'))
	FreezeEntityPosition(pP, true)
	handcuffed = true
end)

RegisterNetEvent('unCuffClient')
AddEventHandler('unCuffClient', function()
	local pP = GetPlayerPed(-1)
	ClearPedSecondaryTask(pP)
	SetEnableHandcuffs(pP, false)
	TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 30.0, 'Kajdanki', 0.2)
	SetCurrentPedWeapon(pP, GetHashKey('WEAPON_UNARMED'), true)
  ESX.ShowNotification(_U('uncuffed'))
	FreezeEntityPosition(pP, false)
	handcuffed = false
end)

RegisterNetEvent('cuffscript:drag')
AddEventHandler('cuffscript:drag', function(cop)
  --TriggerServerEvent('esx:clientLog', 'starting dragging')
  IsDragged = not IsDragged
  CopPed = tonumber(cop)
end)

RegisterNetEvent('esx_policejob:putouttrunk')
AddEventHandler('esx_policejob:putouttrunk', function()
		local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed, true)
	vehicleTrunk = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
local typeVeh = GetVehicleClass(vehicleTrunk)
if typeVeh == 7 or typeVeh == 8 or typeVeh ==13 then

else
  if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0)  then
  		if IsHandcuffed then
	PlayerIsInTrunk = not PlayerIsInTrunk
	
--if not IsHandcuffed then
--TriggerEVent('esx_policejob:handcuff')
--end
	SetVehicleDoorOpen(vehicleTrunk, 5, false, false)
Wait(300)
		SetVehicleDoorShut(vehicleTrunk, 5, false)
		end
if not PlayerIsInTrunk then
	DetachEntity(playerPed, 0, true)
	SetEntityVisible(playerPed, true)
DisplayRadar(true)
end

end
end
end)

Citizen.CreateThread(function()
  while true do
    Wait(0)
    if handcuffed then
      if IsDragged then
        local ped = GetPlayerPed(GetPlayerFromServerId(CopPed))
        local myped = GetPlayerPed(-1)
        AttachEntityToEntity(myped, ped, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
      else
        DetachEntity(GetPlayerPed(-1), true, false)
      end
    end
  end
end)

-- Handcuff
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(10)
    if handcuffed then
      DisableControlAction(2, 24, true) -- Attack
      DisableControlAction(2, 257, true) -- Attack 2
      DisableControlAction(2, 25, true) -- Aim
      DisableControlAction(2, 263, true) -- Melee Attack 1
      DisableControlAction(0, 21, true) -- SPRINT
      --DisableControlAction(0, 30,  true) -- MoverightRight
     -- DisableControlAction(0, 31,  true) -- MoveUpDown
      DisableControlAction(2, Keys['R'], true) -- Reload
      DisableControlAction(2, Keys['TOP'], true) -- Open phone (not needed?)
      DisableControlAction(2, Keys['SPACE'], true) -- Jump
      DisableControlAction(2, Keys['Q'], true) -- Cover
      DisableControlAction(2, Keys['TAB'], true) -- Select Weapon
      DisableControlAction(2, Keys['F'], true) -- Also 'enter'?
      DisableControlAction(2, Keys['F1'], true) -- Disable phone
      DisableControlAction(2, Keys['F2'], true) -- Inventory
      DisableControlAction(2, Keys['F3'], true) -- Animations

    else
      Citizen.Wait(1000)
    end
  end
end)


---- END MENU


function OpenStealMenu(target, target_id)

    ESX.UI.Menu.CloseAll()

    ESX.TriggerServerCallback('esx_thief:getOtherPlayerData', function(data)

        local elements = {}

        if Config.EnableCash then
            table.insert(elements, {
                label      = '[' .. _U('cash') .. '] $' .. data.money,
                value      = 'money',
                type       = 'item_money',
                amount     = data.money,
            })
        end

        if Config.EnableBlackMoney then
            local blackMoney = 0
            for i=1, #data.accounts, 1 do
              if data.accounts[i].name == 'black_money' then
                blackMoney = data.accounts[i].money
              end
            end

            table.insert(elements, {
              label          = '[' .. _U('black_money') .. '] $' .. blackMoney,
              value          = 'black_money',
              type           = 'item_account',
              amount         = blackMoney,
            })
        end

        if Config.EnableInventory then
            table.insert(elements, {label = '--- ' .. _U('inventory') .. ' ---', value = nil})

            for i=1, #data.inventory, 1 do
              if data.inventory[i].count > 0 then
                table.insert(elements, {
                  label          = data.inventory[i].label .. ' x' .. data.inventory[i].count,
                  value          = data.inventory[i].name,
                  type           = 'item_standard',
                  amount         = data.inventory[i].count,
                })
              end
            end
        end

        if Config.EnableWeapons then
            table.insert(elements, {label = '=== ' .. _U('gun_label') .. ' ===', value = nil})

            for i=1, #data.weapons, 1 do
                table.insert(elements, {
                    label    = ESX.GetWeaponLabel(data.weapons[i].name) .. ' x' .. data.weapons[i].ammo,
                    value    = data.weapons[i].name,
                    type     = 'item_weapon',
                    amount   = data.weapons[i].ammo
                })
            end
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'steal_inventory',
        {
            title  = _U('target_inventory'),
            elements = elements,
            align = 'top-right'
        },
        function(data, menu)

            if data.current.value ~= nil then

                local itemType = data.current.type
                local itemName = data.current.value
                local amount   = data.current.amount
                local elements = {}
                table.insert(elements, {label = _U('steal'), action = "steal", itemType, itemName, amount})
                table.insert(elements, {label = _U('return'), action = "return"})
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'steal_inventory_item',
                    {
                        title = _U('action_choice'),
                        align = "top-right",
                        elements = elements
                    },
                    function(data2, menu2)

                        if data2.current.action == 'steal' then

                            if itemType == 'item_standard' then
                                ESX.UI.Menu.Open(
                                    'dialog', GetCurrentResourceName(), 'steal_inventory_item_standard',
                                    {
                                      title = _U('amount')
                                    },
                                    function(data3, menu3)
                                        local quantity = tonumber(data3.value)
                                        TriggerServerEvent('esx_thief:stealPlayerItem', GetPlayerServerId(target), itemType, itemName, quantity)
                                        OpenStealMenu(target)
                                    
                                        menu3.close()
                                        menu2.close()
                                    end,
                                    function(data3, menu3)
                                      menu3.close()
                                    end
                                  )

                            else
                                TriggerServerEvent('esx_thief:stealPlayerItem', GetPlayerServerId(target), itemType, itemName, amount)
                                OpenStealMenu(target)
                            end

                        elseif data2.current.action == 'return' then

                            ESX.UI.Menu.CloseAll()
                            OpenStealMenu(target)

                        end

                    end,
                    function(data2, menu2)
                        menu2.close()
                    end
                )

            end

        end,
        function(data, menu)
            menu.close()
        end
        )
        
    end, GetPlayerServerId(target))

end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

            local ped = PlayerPedId()

            if IsControlJustPressed(1, Keys["DELETE"]) and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped, true) then -- OPEN CUFF MENU
                OpenCuffMenu()
            end
    end
end)



--[[Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
		if IsControlJustPressed(1, Keys['G']) and IsPedArmed(ped, 7) and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped, true) then
			local target, distance = ESX.Game.GetClosestPlayer()

            if target ~= -1 and distance ~= -1 and distance <= 2.0 then

                local target_id = GetPlayerServerId(target)
                
                IsAbleToSteal(target_id, function(err)
                    if(not err)then
                        OpenStealMenu(target, target_id)
                        TriggerEvent('animation')
					else
						ESX.ShowNotification(err)
					end
                end)
                
            elseif distance < 20 and distance > 2.0 then

                ESX.ShowNotification(_U('too_far'))
                    
            else
                
                ESX.ShowNotification(_U('no_players_nearby'))
                    
			end

		end
	end
end)]]--


RegisterNetEvent('animation')
AddEventHandler('animation', function()
  local pid = PlayerPedId()
  RequestAnimDict("amb@prop_human_bum_bin@idle_b")
  while (not HasAnimDictLoaded("amb@prop_human_bum_bin@idle_b")) do Citizen.Wait(0) end
        TaskPlayAnim(pid,"amb@prop_human_bum_bin@idle_b","idle_d",-1, -1, -1, 120, 1, 0, 0, 0)
end)



