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
    ['UI Settings'] = Window:AddTab('UI Settings'),
}



-- // Main Tabs

local AimbotLeftTab = Tabs.Main:AddLeftGroupbox('Aimbot configuration')
local AimbotLeftVisualsBox = Tabs.Main:AddRightTabbox()
local AimbotVisualsBox = AimbotLeftVisualsBox:AddTab('Fov')

-- // Variables
local Workspace, Players, RunService, Camera, UserInputService = game:GetService("Workspace"), game:GetService("Players"), game:GetService("RunService"), Game:GetService("Workspace").CurrentCamera, game:GetService("UserInputService")
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

local Checks = {
    Visible = false,
    Wall = false,

}

local GlobalFovCircle = Drawing.new("Circle")
GlobalFovCircle.Radius = 100
GlobalFovCircle.Visible = false
GlobalFovCircle.Thickness = 1
GlobalFovCircle.Transparency = 1
GlobalFovCircle.Color = Color3.fromRGB(0, 0, 255)

-- // fucntions
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
            if Character ~= LocalPlayer.Character and Character:FindFirstChild(HitScanPart) then
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

-- // Main script below


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
AimbotLeftTab:AddToggle('AimbotClosestPartToggle', {Text = 'Closest Part', Default = false, Tooltip = 'Will aim at the nearest part to the mouse instead of 1 part', Callback = function(Value)
    ClosestPart = Value
end})
AimbotLeftTab:AddToggle('AimbotClosestPointToggle', {Text = 'Closest Point', Default = false, Tooltip = 'Will aim at the nearest point on the part to the cursor', Callback = function(Value)
    ClosestPoint = Value
end})


AimbotVisualsBox:AddToggle('FovVisibleToggle', {Text = 'Visible', Default = false, Tooltip = 'Aimbot toggle', Callback = function(Value)
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


RunService.RenderStepped:Connect(function()


    -- // Fov circle
    if GlobalFovCircle.Visible then
        GlobalFovCircle.Position = UserInputService:GetMouseLocation() -- WorldToViewport(Mouse.Hit.Position) (both the same)
    end

    if AimbotToggleStatus and AimbotKeyToggleStatus then
        NearestCharacter = GetClosestCharacterToCursor(GetEnemies())
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

    if NearestCharacterPosition2D and not MouseHook then
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
ThemeManager:SetFolder('Kennedy')
SaveManager:SetFolder('Kennedy/Universal')
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
