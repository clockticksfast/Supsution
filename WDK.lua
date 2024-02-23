local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua'))()
local ThemeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua'))()


local Window = Library:CreateWindow({
    Title = 'Windows Driver Kit Beta',
    Center = true,
    AutoShow = true,
    TabPadding = 4,
    MenuFadeTime = 0.2
})
local Tabs = {
    Main = Window:AddTab('Main'),
    Automatic = Window:AddTab('Automatic'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}





-- // Main Tabs

-- // Left Tabs
local AimbotLeftTab = Tabs.Main:AddLeftGroupbox('Aimbot configuration')
local AutomaticLeftTab = Tabs.Automatic:AddLeftGroupbox('Autofarm configuration')
local AutomaticChecksLeftTab = Tabs.Automatic:AddLeftGroupbox('Autofarm checks')
local AutomaticBlacklistRightTab = Tabs.Automatic:AddRightGroupbox('Autofarm blacklist')
local AutomaticPriorityListRightTab = Tabs.Automatic:AddRightGroupbox('Autofarm priority')
local AutomaticAutoEquipRightTab = Tabs.Automatic:AddRightGroupbox('Auto equip gun')
local MiscLeftTab = Tabs.Misc:AddLeftGroupbox('Misc')
local MiscRightTab = Tabs.Misc:AddRightGroupbox('Misc')

local AimbotRightVisualsBox = Tabs.Main:AddRightTabbox()
local AimbotVisualsBox = AimbotRightVisualsBox:AddTab('Fov')

-- // Variables
local Workspace, Players, RunService, Camera, UserInputService, ReplicatedStorage, VirtualUser = game:GetService("Workspace"), game:GetService("Players"), game:GetService("RunService"), Game:GetService("Workspace").CurrentCamera, game:GetService("UserInputService"), game:GetService("ReplicatedStorage"), game:GetService("VirtualUser")
local Zombies = Workspace.Zombies
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local AimbotKeyToggleStatus = false
local AimbotToggleStatus = false
local AimbotStickyAim = false
local MouseHook = false
local TargetPart = "Head"
local HitScanParts = {"HumanoidRootPart"}

local ClosestPart = false
local ClosestPoint = false
local NearestCharacter = nil

local AutofarmStatus = false
local AnticheatBypassStatus = false
local AutofarmStartPlace = nil -- position where the autofarm is toggled
local AutofarmPlacement = "Above"
local AutofarmLookat = false
local Autofarmautoexitspawn = false
local Blacklistedzombietable = {}
local Priorityzombietable = {}
local AntiAfkStatus = false
local AutoEquipStatus = false
local AutoEquipName = nil
local Checks = {
    Visible = false,
    Wall = false,
}
local AutofarmChecks = {
    Forcefield = false,
}
local floatpad = Instance.new("Part")
spawn(function()
    while task.wait(1) do
        if LocalPlayer.Character then
            if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                floatpad.Parent = LocalPlayer.Character.HumanoidRootPart
            end
        end
    end

end)
floatpad.Anchored = true
floatpad.Transparency = 1
floatpad.Size = Vector3.new(2,0.2,1.5)


local GlobalFovCircle = Drawing.new("Circle")
GlobalFovCircle.Radius = 100
GlobalFovCircle.Visible = false
GlobalFovCircle.Thickness = 1
GlobalFovCircle.Transparency = 1
GlobalFovCircle.Color = Color3.fromRGB(0, 0, 255)

-- // fucntions
function CalcDistance(position1, position2)
    return (position1 - position2).magnitude
 end
function WorldToViewport(position)
    local Position = Camera:WorldToViewportPoint(position)
    return Vector2.new(Position.X, Position.Y)
end
function WorldToScreen(position)
    local Position = Camera:WorldToScreenPoint(position)
    return Vector2.new(Position.X, Position.Y)
end

function IsVisible(position)
    local position, visible, point = Camera:WorldToScreenPoint(position)
    return visible
end

function IsBehindWall(Part, Origin, Ignore, Distance)
    local Ignore = Ignore or {}
    local Distance = Distance or 2000
    --
    local Cast = Ray.new(Origin, (Part.Position - Origin).Unit * Distance)
    local Hit = Workspace:FindPartOnRayWithIgnoreList(Cast, Ignore)
    if Hit and Hit:IsDescendantOf(Part.Parent) then
        return false, Hit
    else
        return true, Hit
    end
end
function GetEnemies()
    local EnemyTable = {}

    for i,Model in pairs(Zombies:GetChildren()) do
        if Model and Model:FindFirstChildOfClass("Humanoid") and Model:FindFirstChildOfClass("Humanoid").Health > 0 then
            EnemyTable[#EnemyTable + 1] = Model
        end
    end

    return EnemyTable

end

function GetClosestCharacterToPosition(CharacterTable, Position)
    local ClosestPlayer
    local ClosestDistance = math.huge

    -- // Priority
    for i, Character in pairs(CharacterTable) do
        if table.find(Priorityzombietable, Character.Name) then
            if AutofarmChecks.Forcefield and Character:FindFirstChildOfClass("ForceField") then
                -- //
            else
                ClosestPlayer = Character
                ClosestDistance = 0
            end
        end
    end
    -- // Normal
    for i, Character in pairs(CharacterTable) do
        local CharacterPosition = Character:FindFirstChildWhichIsA("BasePart").Position
        local Distance = CalcDistance(CharacterPosition, Position)

        if Distance < ClosestDistance then
            if AutofarmChecks.Forcefield and Character:FindFirstChildOfClass("ForceField") then
                -- //
            elseif table.find(Blacklistedzombietable, Character.Name) then
                -- //
            else

                ClosestPlayer = Character
                ClosestDistance = Distance
            end
        end
    end
    return ClosestPlayer
end

function GetClosestCharacterToCursor(CharacterTable)


    local ClosestPlayer
    local ClosestDistance = math.huge

    local FoundCharacter = false

    for i, Character in pairs(CharacterTable) do
        if AimbotStickyAim and NearestCharacter then
            if Character == NearestCharacter then
                ClosestPlayer = Character
                ClosestDistance = 0
                return ClosestPlayer
            end
        end
    end
    for i, Character in pairs(CharacterTable) do





        for i, HitScanPart in pairs(HitScanParts) do
            if Character:FindFirstChild(HitScanPart) then
                local Hitpart = Character:FindFirstChild(HitScanPart)
                local Hitpart2D = WorldToViewport(Hitpart.Position)
                local Distance = (Vector3.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y, 0) - Vector3.new(Hitpart2D.X, Hitpart2D.Y, 0)).Magnitude
                if Distance <= GlobalFovCircle.Radius and Distance < ClosestDistance then
                    FoundCharacter = true
                    if not Character:FindFirstChildWhichIsA("BasePart") then
                        -- //
                    elseif Checks.Visible and not IsVisible(Hitpart.Position) then
                        -- //
                    elseif Checks.Wall and IsBehindWall(Hitpart, Camera.CFrame.Position, {Players.LocalPlayer.Character}) then
                        -- //
                    else
                        ClosestPlayer = Character -- Return the character instead of the player so for npc's its easier
                        ClosestDistance = Distance
                        if FoundCharacter then
                            break
                        end
                    end
                end
            end
        end
    end
    return ClosestPlayer
end

function GetClosestPart(Model)
    local ClosestPart
    local ClosestDistance = math.huge

    for _, Part in pairs(Model:GetChildren()) do
        if Part:IsA("BasePart") then
            local p = Camera:WorldToViewportPoint(Part.Position)
            local Distance = (Vector3.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y, 0) - Vector3.new(p.X, p.Y, 0)).Magnitude
            if Distance < ClosestDistance then
                ClosestPart = Part
                ClosestDistance = Distance
            end
        end
    end

    return ClosestPart
end

function GetClosestPoint(Part)
    local Hit, Half = Mouse.Hit.Position, Part.Size * 0.5
    local Transform = Part.CFrame:PointToObjectSpace(Hit)
    local NearestPosition = Part.CFrame * Vector3.new(
        math.clamp(Transform.X, - Half.X, Half.X),
        math.clamp(Transform.Y, - Half.Y, Half.Y), 
        0
        --math.clamp(Transform.Z, - Half.Z, Half.Z)) replace w 0 prevents behind aiming
    )
    --
    return NearestPosition
end



function GetPart(Model)
    if ClosestPoint then
        if ClosestPart then
            return GetClosestPart(Model), GetClosestPoint(GetClosestPart(Model))
        else
            return Model:FindFirstChild(TargetPart), GetClosestPoint(Model:FindFirstChild(TargetPart))
        end
    else
        if ClosestPart then
            return GetClosestPart(Model)
        else
            return Model:FindFirstChild(TargetPart)
        end

    end


end
function CalculatePosition(Part, Point)
    if Point then
        return Point
    else
        return Part.Position
    end

end

function FreezeCharacter()
    if LocalPlayer.Character then
        local head = LocalPlayer.Character:FindFirstChild("Head")
        if head then
            local oldSize = head.Size
            head.Size = Vector3.new(0, 0, 0)
            RunService.RenderStepped:Wait()
            head.Size = oldSize
        end
    end
end

function UpdateBlacklistedZombies()
    Blacklistedzombietable = {}

    for _, blacklist in pairs({
        Options.AutofarmBlacklistZombieCommons.Value,
        Options.AutofarmBlacklistZombieUncommons.Value,
        Options.AutofarmBlacklistZombieSpecials.Value
    }) do
        for key, _ in pairs(blacklist) do
            table.insert(Blacklistedzombietable, key)
        end
    end
end
function UpdatePriorityZombies()
    Priorityzombietable = {}

    for _, priority in pairs({
        Options.AutofarmPrioritylistZombieCommons.Value,
        Options.AutofarmPrioritylistZombieUncommons.Value,
        Options.AutofarmPrioritylistZombieSpecials.Value
    }) do
        for key, _ in pairs(priority) do
            table.insert(Priorityzombietable, key)
        end
    end
end


function EquipTool(toolname)
    for i,v in pairs(LocalPlayer.Character:GetChildren()) do
        if v:IsA("Tool") then
            v.Parent = LocalPlayer.Backpack
        end
    end

    if LocalPlayer.Backpack:FindFirstChild(toolname) then
        LocalPlayer.Backpack[toolname].Parent = LocalPlayer.Character
    end
end


-- // Main script below



-- dropdown:SetValues(valuetable)


-- // autofarm zombie blacklist

local CommonZombieList = {
    'Zombie',
    'Crawler', 
    'Boomer',
    'LongerArm', 
    'HeavyArmourZombie', 
    'ArmouredZombie', 
    'HelmetZombie',
}
local UncommonZombieList = {
    'ToxicZombie', 
    'Flamer', 
    'ElectricZombie',
    'HeadlessZombie',
}
local SpecialZombieList = {
    'Wraith', 
    'Berserker', 
    'Destroyer', 
    'Lurker', 
    'Sponger', 
    'Hunter', 
    'Boss',
    'SwampGiant',
}
AutomaticBlacklistRightTab:AddDropdown('AutofarmBlacklistZombieCommons', {Values = CommonZombieList,Default = 0,Multi = true,Text = 'Commons',Tooltip = 'Blacklist zombie', Callback = function(Value)

end})
AutomaticBlacklistRightTab:AddDropdown('AutofarmBlacklistZombieUncommons', {Values = UncommonZombieList,Default = 0,Multi = true ,Text = 'Uncommons',Tooltip = 'Blacklist zombie', Callback = function(Value)

end})

AutomaticBlacklistRightTab:AddDropdown('AutofarmBlacklistZombieSpecials', {Values =  SpecialZombieList ,Default = 0,Multi = true, Text = 'Specials',Tooltip = 'Blacklist zombie', Callback = function(Value)

end})

-- // autofarm zombie priority
AutomaticPriorityListRightTab:AddDropdown('AutofarmPrioritylistZombieCommons', {Values = CommonZombieList,Default = 0,Multi = true,Text = 'Commons',Tooltip = 'Prioritize zombie', Callback = function(Value)

end})
AutomaticPriorityListRightTab:AddDropdown('AutofarmPrioritylistZombieUncommons', {Values = UncommonZombieList,Default = 0,Multi = true ,Text = 'Uncommons',Tooltip = 'Prioritize zombie', Callback = function(Value)

end})

AutomaticPriorityListRightTab:AddDropdown('AutofarmPrioritylistZombieSpecials', {Values = SpecialZombieList,Default = 0,Multi = true, Text = 'Specials',Tooltip = 'Prioritize zombie', Callback = function(Value)

end})

-- // Update the blacklisted zombie table
Options.AutofarmBlacklistZombieCommons:OnChanged(UpdateBlacklistedZombies)
Options.AutofarmBlacklistZombieUncommons:OnChanged(UpdateBlacklistedZombies)
Options.AutofarmBlacklistZombieSpecials:OnChanged(UpdateBlacklistedZombies)
-- // Update the priority zombie table
Options.AutofarmPrioritylistZombieCommons:OnChanged(UpdatePriorityZombies)
Options.AutofarmPrioritylistZombieUncommons:OnChanged(UpdatePriorityZombies)
Options.AutofarmPrioritylistZombieSpecials:OnChanged(UpdatePriorityZombies)



AutomaticAutoEquipRightTab:AddToggle('AutoEquipToggle', {Text = 'Auto equip', Default = false, Tooltip = 'Auto equip toggle', Callback = function(Value)
    AutoEquipStatus = Value
end})
AutomaticAutoEquipRightTab:AddInput('AutoEquipTextbox', { Default = '', Numeric = false,Finished = false, Text = 'Auto equip name', Tooltip = 'Tool to equip (tool icon name)', Placeholder = 'Ex : C96', Callback = function(Value)
    AutoEquipName = Value
end})



AimbotLeftTab:AddToggle('AimbotToggle', {Text = 'Aimbot', Default = false, Tooltip = 'Aimbot toggle', Callback = function(Value)
    AimbotToggleStatus = Value
end}):AddKeyPicker('AimbotKeyToggle', { Default = 'C', SyncToggleState = false, Mode = 'Toggle', Text = 'Aimbot keybind (Aimbot toggle must be activated)' ,})
AimbotLeftTab:AddToggle('AimbotHookToggle', {Text = 'Mouse hook', Default = false, Tooltip = 'Hook the mouse position instead of moving the mouse', Callback = function(Value)
    MouseHook = Value
end})
AimbotLeftTab:AddToggle('AimbotStickyToggle', {Text = 'Sticky', Default = false, Tooltip = 'Stays on the target until unlocked', Callback = function(Value)
    AimbotStickyAim = Value
end})
AimbotLeftTab:AddDivider()
AimbotLeftTab:AddDropdown('AimbotTargetPartDropdown', {Values = { 'Head', 'HumanoidRootPart'},Default = 1,Multi = false,Text = 'Hitpart',Tooltip = 'Wich part to target', Callback = function(Value)
    TargetPart = Value
end})

AimbotLeftTab:AddDropdown('AimbotHitScanDropdown', {Values = { 'Head', 'HumanoidRootPart'},Default = 2,Multi = true,Text = 'Hitscan',Tooltip = 'If the part(s) is detected inside the circle, choose that character', Callback = function(Value)

end})


Options.AimbotHitScanDropdown:OnChanged(function()
    HitScanParts = {}
    for key, value in next, Options.AimbotHitScanDropdown.Value do
        table.insert(HitScanParts, key)
    end
end)
AimbotLeftTab:AddToggle('AimbotClosestPartToggle', {Text = 'Closest Part', Default = false, Tooltip = 'Will aim at the nearest part to the mouse instead of 1 part', Callback = function(Value)
    ClosestPart = Value
end})
AimbotLeftTab:AddToggle('AimbotClosestPointToggle', {Text = 'Closest Point', Default = false, Tooltip = 'Will aim at the nearest point on the part to the cursor', Callback = function(Value)
    ClosestPoint = Value
end})


AutomaticLeftTab:AddToggle('AutofarmToggle', {Text = 'Autofarm', Default = false, Tooltip = 'Toggle autofarm', Callback = function(Value)
    if Value then
        AnticheatBypassStatus = true
        AutofarmStartPlace = LocalPlayer.Character.HumanoidRootPart.CFrame
    else
        if AutofarmStartPlace then
            AnticheatBypassStatus = false
            LocalPlayer.Character.HumanoidRootPart.CFrame = AutofarmStartPlace
        end
    end
    AutofarmStatus = Value
end})
AutomaticLeftTab:AddDropdown('AutofarmPlacementDropdown', {Values = { 'Above', 'Behind', "Infront"},Default = 1,Multi = false,Text = 'Teleport placement',Tooltip = 'Where will it teleport', Callback = function(Value)
    AutofarmPlacement = Value
end})
AutomaticLeftTab:AddDivider()
AutomaticLeftTab:AddToggle('AutofarmLookatToggle', {Text = 'Lookat target', Default = false, Tooltip = 'Will orient the camera so it faces the zombie', Callback = function(Value)
    AutofarmLookat = Value
end})

AutomaticChecksLeftTab:AddToggle('AutofarmForcefieldtoggle', {Text = 'Forcefield', Default = false, Tooltip = 'If forcefield then ignore', Callback = function(Value)
    AutofarmChecks.Forcefield = Value
end})


AimbotVisualsBox:AddToggle('FovVisibleToggle', {Text = 'Visible', Default = false, Tooltip = 'Aimbot fov toggle', Callback = function(Value)
    GlobalFovCircle.Visible = Value
end})

AimbotVisualsBox:AddSlider('FovSizeSlider', { Text = 'Size', Default = 100, Min = 0, Max = 700, Rounding = 0, Compact = false, Callback = function(Value)
    GlobalFovCircle.Radius = Value
end})

AimbotVisualsBox:AddSlider('FovTransparencySlider', { Text = 'Transparency', Default = 1, Min = 0, Max = 1, Rounding = 1, Compact = false, Callback = function(Value)
    GlobalFovCircle.Transparency = Value
end})

AimbotVisualsBox:AddSlider('FovThicknessSlider', { Text = 'Thickness', Default = 1, Min = 1, Max = 25, Rounding = 0, Compact = false, Callback = function(Value)
    GlobalFovCircle.Thickness = Value
end})
AimbotVisualsBox:AddLabel('Color'):AddColorPicker('FovCircleColor', { Default = Color3.fromRGB(0, 85, 255), Title = 'Fov circle color', Transparency = nil, Callback = function(Value)
    GlobalFovCircle.Color = Value
end})


MiscLeftTab:AddButton({Text = 'Copy servercode',
    Func = function()
        if ReplicatedStorage.Values:FindFirstChild("ServerCode") then
            setclipboard(ReplicatedStorage.Values.ServerCode.Value)
        end
    end,
    DoubleClick = false,
    Tooltip = 'Copy the servercode'
})
MiscRightTab:AddToggle('AntiAfkToggle', {Text = 'Anti-AFK', Default = false, Tooltip = 'Anti-AFK Toggle', Callback = function(Value)
    AimbotToggleStatus = Value
end})
MiscRightTab:AddToggle('AutoExitSpawnToggle', {Text = 'Auto exit spawn', Default = false, Tooltip = 'Automatically exit spawn', Callback = function(Value)
    Autofarmautoexitspawn = Value
end})


task.spawn(function()
    while true do
        task.wait()
        local state = Options.AimbotKeyToggle:GetState()
        if state then
            AimbotKeyToggleStatus = true
        else
            AimbotKeyToggleStatus = false
        end

        if Library.Unloaded then break end
    end
end)

game:GetService("Players").LocalPlayer.Idled:connect(function()
    if AntiAfkStatus then
        VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    end
end)


LocalPlayer.CharacterAdded:Connect(function(Character)
    Character:WaitForChild("HumanoidRootPart")
    floatpad = Instance.new("Part", LocalPlayer.Character.HumanoidRootPart)
    floatpad.Anchored = true
    floatpad.Transparency = 1
    floatpad.Size = Vector3.new(2,0.2,1.5)

    if Autofarmautoexitspawn then
        local oldvalue = AnticheatBypassStatus -- // store the old ac bypass value
        AnticheatBypassStatus = false
        LocalPlayer.Character.HumanoidRootPart.CFrame = Workspace.Map.Shop.InvisibleWalls:GetChildren()[23].CFrame
        task.wait(1) -- // delay so that the freeze isn't instant
        spawn(function()
            task.wait(1)
            EquipTool(AutoEquipName)
        
        end)
        AnticheatBypassStatus = oldvalue
    end
end)
RunService.Heartbeat:Connect(function()
    if AnticheatBypassStatus then
        FreezeCharacter()
    end
end)

RunService.RenderStepped:Connect(function()



    -- // Fov circle
    if GlobalFovCircle.Visible then
        GlobalFovCircle.Position = UserInputService:GetMouseLocation() -- WorldToViewport(Mouse.Hit.Position) (both the same)
    end
    if AutofarmStatus then
        NearestCharacter = GetClosestCharacterToPosition(GetEnemies(), Workspace.Map.Scripted.Doors.FakeLight.Position)
        if NearestCharacter and LocalPlayer.Character and AnticheatBypassStatus then
            floatpad.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,-3,0)
            if AutofarmPlacement == "Above" then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(NearestCharacter.HumanoidRootPart.Position + Vector3.new(0, 8, 0))
            elseif AutofarmPlacement == "Infront" then
                LocalPlayer.Character.HumanoidRootPart.CFrame = NearestCharacter.HumanoidRootPart.CFrame + NearestCharacter.HumanoidRootPart.CFrame.LookVector * 5
            elseif AutofarmPlacement == "Behind" then
                LocalPlayer.Character.HumanoidRootPart.CFrame = NearestCharacter.HumanoidRootPart.CFrame - NearestCharacter.HumanoidRootPart.CFrame.LookVector * 5
            end
            if AutofarmLookat then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, NearestCharacter.Head.Position)
            end
        else
            floatpad.CFrame = CFrame.new(Vector3.new(0, 50000, 0))
        end
    end

    if AimbotToggleStatus and AimbotKeyToggleStatus then
        if not AutofarmStatus then
            NearestCharacter = GetClosestCharacterToCursor(GetEnemies())
        end
        if NearestCharacter then
            if NearestCharacter then
                NearestCharacterPosition3D = CalculatePosition(GetPart(NearestCharacter))
                NearestCharacterPosition2D = WorldToScreen(NearestCharacterPosition3D)
            else
                NearestCharacter, NearestCharacterPosition2D, NearestCharacterPosition3D = nil, nil, nil
            end
        end
    else
        NearestCharacter, NearestCharacterPosition2D, NearestCharacterPosition3D = nil, nil, nil
    end

    if NearestCharacter and NearestCharacterPosition2D and not MouseHook then
        mousemoverel(NearestCharacterPosition2D.X - Mouse.X,NearestCharacterPosition2D.Y - Mouse.Y)
    end

end)



-- // Library functions below

Library:OnUnload(function()
    Library.Unloaded = true
end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('WDK')
SaveManager:SetFolder('WDK/TFS2')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()
-- // index hooking
local __index
__index = hookmetamethod(game, "__index", function(t, k)
    if MouseHook and AimbotToggleStatus and AimbotKeyToggleStatus and NearestCharacter and NearestCharacterPosition2D then
        if t:IsA("Mouse") then
            if k == "X" then
                return NearestCharacterPosition2D.X

            elseif k == "Y" then
                return NearestCharacterPosition2D.Y
            end
        end
    end
    return __index(t, k)
end)

