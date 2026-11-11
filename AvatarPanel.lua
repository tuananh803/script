-- LocalScript: đặt trong StarterPlayer > StarterPlayerScripts
-- Bảng điều khiển nhập tên người chơi -> mặc avatar của họ (chỉ mình bạn thấy)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TOGGLE_KEY = Enum.KeyCode.K

-- ========== TẠO GIAO DIỆN ==========
local gui = Instance.new("ScreenGui")
gui.Name = "AvatarPanel"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
end

-- Nút tròn bật/tắt bảng
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "Toggle"
toggleBtn.Size = UDim2.fromOffset(44, 44)
toggleBtn.Position = UDim2.new(0, 12, 0.5, -22)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
toggleBtn.Text = "👕"
toggleBtn.TextSize = 22
toggleBtn.AutoButtonColor = true
toggleBtn.Parent = gui
corner(toggleBtn, 22)

-- Bảng chính
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(260, 200)
panel.Position = UDim2.new(0, 70, 0.5, -100)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 10)

-- Thanh tiêu đề (dùng để kéo)
local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 54)
titleBar.BorderSizePixel = 0
titleBar.Text = "  Avatar Changer"
titleBar.TextColor3 = Color3.new(1, 1, 1)
titleBar.TextSize = 16
titleBar.Font = Enum.Font.GothamBold
titleBar.TextXAlignment = Enum.TextXAlignment.Left
titleBar.Parent = panel
corner(titleBar, 10)

-- Nút đóng (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(26, 26)
closeBtn.Position = UDim2.new(1, -30, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
corner(closeBtn, 6)

-- Ô nhập tên
local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -24, 0, 36)
textBox.Position = UDim2.new(0, 12, 0, 46)
textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
textBox.PlaceholderText = "Nhập tên người chơi..."
textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
textBox.Text = ""
textBox.TextColor3 = Color3.new(1, 1, 1)
textBox.TextSize = 15
textBox.Font = Enum.Font.Gotham
textBox.ClearTextOnFocus = false
textBox.Parent = panel
corner(textBox, 6)

-- Nút Apply
local applyBtn = Instance.new("TextButton")
applyBtn.Size = UDim2.new(0.5, -17, 0, 36)
applyBtn.Position = UDim2.new(0, 12, 0, 92)
applyBtn.BackgroundColor3 = Color3.fromRGB(70, 160, 90)
applyBtn.Text = "Apply"
applyBtn.TextColor3 = Color3.new(1, 1, 1)
applyBtn.TextSize = 15
applyBtn.Font = Enum.Font.GothamBold
applyBtn.Parent = panel
corner(applyBtn, 6)

-- Nút Reset
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.5, -17, 0, 36)
resetBtn.Position = UDim2.new(0.5, 5, 0, 92)
resetBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
resetBtn.Text = "Reset"
resetBtn.TextColor3 = Color3.new(1, 1, 1)
resetBtn.TextSize = 15
resetBtn.Font = Enum.Font.GothamBold
resetBtn.Parent = panel
corner(resetBtn, 6)

-- Dòng trạng thái
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 50)
status.Position = UDim2.new(0, 12, 0, 140)
status.BackgroundTransparency = 1
status.Text = "Nhấn K để ẩn/mở bảng"
status.TextColor3 = Color3.fromRGB(180, 180, 190)
status.TextSize = 13
status.Font = Enum.Font.Gotham
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = panel

local function setStatus(text, color)
	status.Text = text
	status.TextColor3 = color or Color3.fromRGB(180, 180, 190)
end

-- ========== ẨN / MỞ BẢNG ==========
local function setPanelVisible(visible)
	panel.Visible = visible
end

local function togglePanel()
	setPanelVisible(not panel.Visible)
end

toggleBtn.MouseButton1Click:Connect(togglePanel)
closeBtn.MouseButton1Click:Connect(function()
	setPanelVisible(false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end -- đang gõ chữ thì không bắt phím
	if input.KeyCode == TOGGLE_KEY then
		togglePanel()
	end
end)

-- ========== KÉO BẢNG ==========
do
	local dragging = false
	local dragStart, startPos

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = panel.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			panel.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- ========== LOGIC ĐỔI AVATAR (chạy ở client) ==========
-- Humanoid:ApplyDescription() chỉ gọi được từ server, nên ở client mình tự lấy
-- "bộ đồ" của người chơi rồi gắn lên nhân vật. Chỉ mình bạn thấy.

local currentUserId = nil -- avatar đang mượn (nil = avatar gốc)
local busy = false

local function isClothing(inst)
	return inst:IsA("Shirt") or inst:IsA("Pants") or inst:IsA("ShirtGraphic")
		or inst:IsA("CharacterMesh") or inst:IsA("BodyColors")
end

local function applyAppearance(userId)
	local appearance = Players:GetCharacterAppearanceAsync(userId)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local head = character:WaitForChild("Head")

	-- Xoá đồ cũ
	humanoid:RemoveAccessories()
	for _, child in ipairs(character:GetChildren()) do
		if isClothing(child) then
			child:Destroy()
		end
	end

	-- Gắn đồ mới
	for _, item in ipairs(appearance:GetChildren()) do
		if item:IsA("Accessory") then
			humanoid:AddAccessory(item:Clone())
		elseif isClothing(item) then
			item:Clone().Parent = character
		end
	end

	-- Đổi mặt
	local newHead = appearance:FindFirstChild("Head")
	local newFace = newHead and newHead:FindFirstChildOfClass("Decal")
	if newFace then
		local oldFace = head:FindFirstChildOfClass("Decal")
		if oldFace then
			oldFace.Texture = newFace.Texture
		else
			newFace:Clone().Parent = head
		end
	end

	appearance:Destroy()
end

local function applyByName(name)
	if busy then return end
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		setStatus("Chưa nhập tên!", Color3.fromRGB(255, 190, 90))
		return
	end

	busy = true
	setStatus("Đang tìm " .. name .. "...")

	local okId, userId = pcall(function()
		return Players:GetUserIdFromNameAsync(name)
	end)
	if not okId then
		setStatus("Không tìm thấy người chơi: " .. name, Color3.fromRGB(255, 110, 110))
		busy = false
		return
	end

	local okApply, err = pcall(applyAppearance, userId)
	if okApply then
		currentUserId = userId
		setStatus("Đã mặc đồ của " .. name, Color3.fromRGB(110, 220, 130))
	else
		setStatus("Lỗi: " .. tostring(err), Color3.fromRGB(255, 110, 110))
	end
	busy = false
end

local function resetAvatar()
	if busy then return end
	busy = true
	setStatus("Đang khôi phục avatar gốc...")

	local ok, err = pcall(applyAppearance, player.UserId)
	if ok then
		currentUserId = nil
		setStatus("Đã về avatar gốc", Color3.fromRGB(110, 220, 130))
	else
		setStatus("Lỗi: " .. tostring(err), Color3.fromRGB(255, 110, 110))
	end
	busy = false
end

applyBtn.MouseButton1Click:Connect(function()
	applyByName(textBox.Text)
end)

textBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		applyByName(textBox.Text)
	end
end)

resetBtn.MouseButton1Click:Connect(resetAvatar)

-- Respawn xong thì mặc lại đồ đang mượn
player.CharacterAdded:Connect(function(character)
	if not currentUserId then return end
	character:WaitForChild("Humanoid")
	task.wait(0.5) -- đợi nhân vật load xong
	pcall(applyAppearance, currentUserId)
end)
