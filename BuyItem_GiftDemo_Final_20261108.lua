--[[
	LocalScript DEMO: bảng "Buy item" + "Purchase completed" (giao diện mô phỏng cục bộ)
	Đặt vào: StarterPlayer > StarterPlayerScripts (LocalScript)

	Luồng: bấm nút tàng hình cạnh icon chat -> bảng Buy item trượt lên (0.3s)
	-> bấm Buy: nút chuyển lại xanh đậm (0.2s) -> bảng Buy trượt xuống
	-> bảng Purchase completed và thông báo gift xuất hiện cùng lúc -> bấm OK / X để đóng.

	Bảng Purchase completed đã được gộp vào file này, nên hãy XOÁ LocalScript
	"PurchaseCompleted" cũ đi (không thì nó tự hiện ngay khi vào game).
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

for _, oldName in ipairs({"BuyItem", "PurchaseCompleted", "TriggerBuyUI", "DemoRobuxControl", "GiftNotificationDemo", "FakeGiftGui", "TDBGui", "InvisibleGiftButton", "LakeGiftGui", "MinimalGifter", "DelfiOverlay"}) do
	local oldGui = playerGui:FindFirstChild(oldName)
	if oldGui then oldGui:Destroy() end
end

-- ===== CẤU HÌNH (sửa ở đây) =====
local TITLE = "Buy item"
local ITEM_IMAGE = "" -- ảnh dự phòng nếu món quà không có trong danh sách
local robuxBalance = 0 -- số dư DEMO, được nhập trong bảng điều khiển
local triggerGui -- khai báo trước để các hàm đóng/mở có thể bật/tắt nút kích hoạt
local ROBUX_ICON = "rbxassetid://79289060473744" -- logo Robux
local PLUS_ICON = "rbxassetid://124086938389734" -- icon Roblox Plus
local ROBUX_ICON_SIZE = 16 -- cỡ logo Robux (px, hình vuông) - thấy nhỏ/to quá thì sửa số này
local PLUS_ICON_SIZE = 18 -- cỡ icon Roblox Plus (px, hình vuông)
local PLUS_TEXT = "Get 10% off with Roblox Plus"
local SHOW_PLUS_BANNER = true -- dải "Roblox Plus" ở dưới
local SHOW_SCRIM = true -- nền tối phía sau bảng

local DONE_TITLE = "Purchase completed"
local DONE_MESSAGE = "You have successfully bought %s." -- %s = tên món đồ

-- ===== KÍCH THƯỚC + THỜI GIAN HIỆU ỨNG (sửa ở đây) =====
local BUY_WIDTH_PERCENT = 0.565 -- bảng Buy item. Đã nâng từ 0.518 lên 0.565 vì so 2 ảnh thì bảng của script nhỏ hơn bảng thật ~9%. Muốn to/nhỏ hơn thì tăng/giảm số này
local DONE_WIDTH_PERCENT = 0.48 -- bảng Purchase completed chiếm 48% chiều rộng màn hình (đo từ ảnh mẫu)
local SLIDE_TIME = 0.3 -- bảng Buy item trượt từ dưới lên (giây)
local FILL_TIME = 3.5 -- màu xanh sáng chạy hết nút Buy từ trái sang phải (giây)
local PRESS_TIME = 0.2 -- bấm Buy xong, nút chuyển lại xanh đậm trong (giây)
local DONE_SLIDE_TIME = 0.3 -- bảng Purchase completed trượt từ dưới lên (giây)
local CLOSE_TIME = 0.3 -- bảng trượt xuống khi đóng / khi chuyển sang bảng sau (giây)

-- ===== MÀU (đo từ ảnh) =====
local BG = Color3.fromRGB(25, 26, 31)
local TEXT = Color3.fromRGB(213, 215, 221)
local WHITE = Color3.fromRGB(247, 247, 248)
local BLUE = Color3.fromRGB(51, 95, 255) -- xanh sáng
local BLUE_DARK = Color3.fromRGB(39, 61, 144) -- xanh đậm
local BLUE_HOVER = Color3.fromRGB(71, 111, 255)
local BLUE_PRESS = Color3.fromRGB(41, 82, 224)
local BORDER = Color3.fromRGB(46, 46, 54)
local PLACEHOLDER = Color3.fromRGB(47, 48, 55)

-- kích thước gốc của 2 bảng (px) - không cần sửa
local DIALOG_WIDTH = 457
local BUY_HEIGHT = 284
local DONE_HEIGHT = 234

-- vị trí bảng: đang hiện (giữa màn hình) / đang ẩn (nằm dưới màn hình)
local DIALOG_SHOWN = UDim2.fromScale(0.5, 0.5)
local DIALOG_HIDDEN = UDim2.fromScale(0.5, 1.5)
local SCRIM_TRANSPARENCY = 0.5

-- ===== HÀM PHỤ =====
local function create(className, props, children)
	local inst = Instance.new(className)
	local parent = props.Parent
	for key, value in pairs(props) do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	inst.Parent = parent
	return inst
end

local function corner(radius)
	return create("UICorner", { CornerRadius = radius })
end

-- cho phép dán "rbxassetid://123" hoặc chỉ số 123
local function toAsset(id)
	id = tostring(id or "")
	if id:match("^%d+$") then
		return "rbxassetid://" .. id
	end
	return id
end

-- 5000 -> "5,000"
local function formatNumber(n)
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

-- Đoạn thẳng bo tròn 2 đầu từ p1 -> p2 (pixel), nằm trong khung "parent" cỡ "area" (dùng cho nút X, dấu tick)
local function line(parent, area, p1, p2, thickness, color)
	local d = p2 - p1
	local mid = (p1 + p2) / 2
	return create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(mid.X / area.X, mid.Y / area.Y),
		Size = UDim2.fromOffset(d.Magnitude + thickness, thickness),
		Rotation = math.deg(math.atan2(d.Y, d.X)),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = parent,
	}, { corner(UDim.new(0.5, 0)) })
end


-- ===== DANH SÁCH MÓN QUÀ: tên, giá DEMO và ảnh =====
local ITEM_CATALOG = {}
local function addItem(name, price, imageId, aliases, category)
	local info = {
		name = name,
		price = price,
		image = "rbxassetid://" .. tostring(imageId),
		category = category or "fruit",
	}
	ITEM_CATALOG[string.lower(name)] = info
	for _, alias in ipairs(aliases or {}) do
		ITEM_CATALOG[string.lower(alias)] = info
	end
end

addItem("Rocket", 50, 74865743684566)
addItem("Spin", 75, 140449159404405)
addItem("Blade", 100, 107921822284039)
addItem("Spring", 180, 96804308007607)
addItem("Bomb", 220, 87590149231144)
addItem("Smoke", 250, 120443034817988)
addItem("Spike", 380, 114735723219626)
addItem("Flame", 550, 71400835505255)
addItem("Ice", 750, 96319754826215)
addItem("Sand", 850, 76045700053059)
addItem("Dark", 950, 120593697335577)
addItem("Eagle", 975, 95493988230476)
addItem("Diamond", 1000, 89010608722381)
addItem("Light", 1100, 107150632425169)
addItem("Rubber", 1200, 91461104324777)
addItem("Ghost", 1275, 86941425535302)
addItem("Magma", 1300, 133464129750678)
addItem("Quake", 1500, 133286718310883)
addItem("Human Buddha", 1650, 98957012155395, {"Buddha"})
addItem("Love", 1700, 86042292381432)
addItem("Creation", 1750, 98242337227948)
addItem("Spider", 1800, 96367323271251)
addItem("Sound", 1900, 123198645753175)
addItem("Phoenix", 2000, 91897159145509)
addItem("Portal", 2000, 109286545716188)
addItem("Lightning", 2100, 111221767502028)
addItem("Pain", 2200, 71767250785560)
addItem("Blizzard", 2250, 117002904661805)
addItem("Gravity", 2300, 107407838281324)
addItem("Mammoth", 2350, 76593881964225)
addItem("T-Rex", 2350, 94551768673500, {"Trex", "T Rex"})
addItem("Dough", 2400, 139266569511863)
addItem("Shadow", 2425, 136222392814211)
addItem("Permanent Gas Fruit", 2500, 137265822205765, {"Permanent Gas", "Gas Fruit", "Gas"})
addItem("Spirit", 2550, 84879941545833)
addItem("Tiger", 3000, 117492513709559)
addItem("Yeti", 3000, 123423441215836)
addItem("Magnet", 3500, 113940415408194)
addItem("Control", 4000, 97683450888445)
addItem("Kitsune", 4000, 130345719387867)
addItem("Dragon", 5000, 107942478646068)
addItem("Soulfire Bundle", 3499, 126162094947436, nil, "bundle")
addItem("[GIFT] Fast Boats", 350, 135614168103141, {"Fast Boats"}, "gift")
addItem("[GIFT] 2x Boss Drops", 350, 124577901152062, {"2x Boss Drops"}, "gift")
addItem("[GIFT] 2x Mastery", 450, 94248506319015, {"2x Mastery"}, "gift")
addItem("[GIFT] 2x Money", 450, 88287062101545, {"2x Money"}, "gift")
addItem("[GIFT] Dark Blade", 1200, 80725153471665, {"Dark Blade"}, "gift")
addItem("[GIFT] Fruit Notifier", 2700, 80787405177143, {"Fruit Notifier"}, "gift")

local function trim(text)
	return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeGiftKey(rawName)
	local key = string.lower(trim(rawName))
	key = key:gsub("^%[gift%]%s*", "")
	key = key:gsub("^permanent%s+", "")
	key = key:gsub("%s+", " ")
	return key
end

local function resolveGift(rawName)
	local raw = trim(rawName)
	local data = ITEM_CATALOG[string.lower(raw)] or ITEM_CATALOG[normalizeGiftKey(raw)]
	if not data then
		return raw ~= "" and raw or "Unknown item", 0, ITEM_IMAGE
	end
	local displayName = data.name
	if string.lower(raw):match("^permanent%s+") and data.category == "fruit" then
		if data.name == "Permanent Gas Fruit" then
			displayName = "Permanent Gas Fruit"
		else
			displayName = "Permanent " .. data.name
		end
	end
	return displayName, data.price, data.image
end

-- Đọc dòng game đang chọn quà, ví dụ: Gifting [TênNgườiChơi] <Permanent Dragon>
local function extractGiftInfo()
	for _, obj in ipairs(playerGui:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			local text = tostring(obj.Text or "")
			if text:find("Gifting", 1, true) then
				local targetName, giftName = text:match("Gifting%s*%[([^%]]+)%]%s*<([^>]+)>")
				if targetName and giftName then
					return trim(giftName), trim(targetName)
				end
			end
		end
	end
	return nil, "a friend"
end

local function escapeRichText(text)
	text = tostring(text or "")
	text = text:gsub("&", "&amp;")
	text = text:gsub("<", "&lt;")
	text = text:gsub(">", "&gt;")
	return text
end

-- ===== THÔNG BÁO GIFT: hiển thị cùng lúc với Purchase completed =====
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "GiftNotificationDemo"
notifGui.ResetOnSpawn = false
notifGui.IgnoreGuiInset = true
notifGui.DisplayOrder = 2000
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notifGui.Parent = playerGui

local notifMain = Instance.new("Frame")
notifMain.Parent = notifGui
notifMain.BackgroundTransparency = 1
notifMain.Size = UDim2.new(1, 0, 0, 80)
notifMain.Position = UDim2.new(0, 0, 0.05, 0)
notifMain.Visible = false

local notifTop = Instance.new("TextLabel")
notifTop.Parent = notifMain
notifTop.BackgroundTransparency = 1
notifTop.Size = UDim2.new(1, 0, 0, 40)
notifTop.Position = UDim2.new(0, 0, 0, 0)
notifTop.RichText = true
notifTop.TextSize = 31
notifTop.Font = Enum.Font.SourceSans
notifTop.TextStrokeTransparency = 0.5
notifTop.TextStrokeColor3 = Color3.fromRGB(45, 45, 45)
notifTop.TextXAlignment = Enum.TextXAlignment.Center

local notifBottom = Instance.new("TextLabel")
notifBottom.Parent = notifMain
notifBottom.BackgroundTransparency = 1
notifBottom.Size = UDim2.new(1, 0, 0, 20)
notifBottom.Position = UDim2.new(0, 0, 0, 22)
notifBottom.Text = "Gift sent successfully!"
notifBottom.TextSize = 31
notifBottom.Font = Enum.Font.SourceSans
notifBottom.TextColor3 = Color3.fromRGB(106, 250, 85)
notifBottom.TextStrokeTransparency = 0.5
notifBottom.TextStrokeColor3 = Color3.fromRGB(45, 45, 45)
notifBottom.TextXAlignment = Enum.TextXAlignment.Center

local notificationToken = 0
local function stopGiftNotification()
	notificationToken += 1
	notifMain.Visible = false
	notifTop.TextTransparency = 1
	notifBottom.TextTransparency = 1
end

local function playGiftNotification(itemText, targetPlayer)
	notificationToken += 1
	local myToken = notificationToken
	local function stillCurrent()
		return myToken == notificationToken
	end

	local safeItem = escapeRichText(itemText)
	local safeTarget = escapeRichText(targetPlayer)
	notifTop.Text =
		'<font color="rgb(255,255,255)">Sending gift </font>' ..
		'<font color="rgb(254,239,52)">&lt;' .. safeItem .. '&gt;</font>' ..
		'<font color="rgb(255,255,255)"> to ' .. safeTarget .. '</font>'

	notifMain.Visible = true
	notifTop.Position = UDim2.new(0, 0, -0.15, 0)
	notifBottom.Position = UDim2.new(0, 0, -0.15, 0)
	notifTop.TextTransparency = 1
	notifBottom.TextTransparency = 1

	TweenService:Create(notifTop, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0), TextTransparency = 0,
	}):Play()
	task.wait(1.5)
	if not stillCurrent() then return end

	TweenService:Create(notifBottom, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 22), TextTransparency = 0,
	}):Play()
	task.wait(1.5)
	if not stillCurrent() then return end

	TweenService:Create(notifTop, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 250, 0, 0), TextTransparency = 1,
	}):Play()
	task.wait(1.5)
	if not stillCurrent() then return end

	TweenService:Create(notifBottom, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(-1, -250, 0, 22), TextTransparency = 1,
	}):Play()
	task.wait(0.3)
	if stillCurrent() then
		notifMain.Visible = false
	end
end

-- ===== BẢNG NHẬP SỐ DƯ DEMO =====
local balanceGui = Instance.new("ScreenGui")
balanceGui.Name = "DemoRobuxControl"
balanceGui.ResetOnSpawn = false
balanceGui.IgnoreGuiInset = true
balanceGui.DisplayOrder = 900
balanceGui.Parent = playerGui

local panelColor = Color3.fromRGB(16, 22, 34)
local panelEdge = Color3.fromRGB(58, 140, 255)
local panelWhite = Color3.fromRGB(236, 240, 248)
local panelBlue = Color3.fromRGB(40, 122, 232)

local balancePanel = Instance.new("Frame")
balancePanel.Name = "RobuxPanel"
balancePanel.Size = UDim2.fromOffset(220, 110)
balancePanel.Position = UDim2.new(1, -240, 0, 60)
balancePanel.BackgroundColor3 = panelColor
balancePanel.BackgroundTransparency = 0.1
balancePanel.BorderSizePixel = 0
balancePanel.Active = true
balancePanel.Draggable = true
balancePanel.Parent = balanceGui
corner(UDim.new(0, 10)).Parent = balancePanel
local panelStroke = Instance.new("UIStroke")
panelStroke.Color = panelEdge
panelStroke.Thickness = 2
panelStroke.Parent = balancePanel

local panelTitle = Instance.new("TextLabel")
panelTitle.Size = UDim2.new(1, 0, 0, 30)
panelTitle.BackgroundTransparency = 1
panelTitle.Text = "ROBUX AMOUNT (DEMO)"
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextColor3 = panelEdge
panelTitle.TextSize = 12
panelTitle.Parent = balancePanel

local balanceInput = Instance.new("TextBox")
balanceInput.Size = UDim2.new(1, -20, 0, 30)
balanceInput.Position = UDim2.fromOffset(10, 32)
balanceInput.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
balanceInput.TextColor3 = panelWhite
balanceInput.Font = Enum.Font.Gotham
balanceInput.TextSize = 14
balanceInput.PlaceholderText = "Nhập số Robux..."
balanceInput.Text = "0"
balanceInput.ClearTextOnFocus = false
balanceInput.Parent = balancePanel
corner(UDim.new(0, 6)).Parent = balanceInput
local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(40, 50, 70)
inputStroke.Parent = balanceInput

local applyBalance = Instance.new("TextButton")
applyBalance.Size = UDim2.new(1, -20, 0, 30)
applyBalance.Position = UDim2.fromOffset(10, 70)
applyBalance.BackgroundColor3 = panelBlue
applyBalance.Text = "APPLY"
applyBalance.Font = Enum.Font.GothamBold
applyBalance.TextSize = 14
applyBalance.TextColor3 = panelWhite
applyBalance.Parent = balancePanel
corner(UDim.new(0, 6)).Parent = applyBalance

local panelHide = Instance.new("TextButton")
panelHide.Size = UDim2.fromOffset(24, 24)
panelHide.Position = UDim2.new(1, -28, 0, 2)
panelHide.BackgroundTransparency = 1
panelHide.Text = "_"
panelHide.Font = Enum.Font.GothamBold
panelHide.TextSize = 20
panelHide.TextColor3 = panelWhite
panelHide.Parent = balancePanel

local miniBalanceButton = Instance.new("TextButton")
miniBalanceButton.Name = "MiniRobuxPanel"
miniBalanceButton.Size = UDim2.fromOffset(42, 16)
miniBalanceButton.Position = balancePanel.Position
miniBalanceButton.BackgroundTransparency = 1
miniBalanceButton.Text = "_"
miniBalanceButton.Font = Enum.Font.GothamBold
miniBalanceButton.TextSize = 24
miniBalanceButton.TextColor3 = panelWhite
miniBalanceButton.Visible = false
miniBalanceButton.Parent = balanceGui

local function toggleBalancePanel()
	if balancePanel.Visible then
		miniBalanceButton.Position = balancePanel.Position
		balancePanel.Visible = false
		miniBalanceButton.Visible = true
	else
		miniBalanceButton.Visible = false
		balancePanel.Visible = true
	end
end
panelHide.Activated:Connect(toggleBalancePanel)
miniBalanceButton.Activated:Connect(toggleBalancePanel)

applyBalance.Activated:Connect(function()
	local digits = tostring(balanceInput.Text):gsub("%D", "")
	local amount = tonumber(digits)
	if not amount then
		applyBalance.Text = "INVALID"
		task.delay(1, function()
			if applyBalance.Parent then applyBalance.Text = "APPLY" end
		end)
		return
	end
	robuxBalance = math.floor(amount)
	balanceInput.Text = formatNumber(robuxBalance)
	applyBalance.Text = "APPLIED!"
	task.delay(1, function()
		if applyBalance.Parent then applyBalance.Text = "APPLY" end
	end)
end)

-- Logo Robux (ảnh thật)
local function robuxIcon(parent, layoutOrder)
	return create("ImageLabel", {
		Name = "RobuxIcon",
		LayoutOrder = layoutOrder,
		Size = UDim2.fromOffset(ROBUX_ICON_SIZE, ROBUX_ICON_SIZE),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = toAsset(ROBUX_ICON),
		ImageColor3 = WHITE,
		ScaleType = Enum.ScaleType.Fit,
		Parent = parent,
	})
end

-- Icon Roblox Plus (ảnh thật)
local function plusIcon(parent)
	return create("ImageLabel", {
		Name = "PlusIcon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(PLUS_ICON_SIZE, PLUS_ICON_SIZE),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = toAsset(PLUS_ICON),
		ImageColor3 = WHITE,
		ScaleType = Enum.ScaleType.Fit,
		Parent = parent,
	})
end

-- Cỡ bảng = chiếm đúng "percent" chiều rộng màn hình (như ảnh mẫu) trên mọi màn hình,
-- không có giới hạn to nhất. Chỉ chặn để bảng không cao quá màn hình và không nhỏ hơn 0.5.
local function dialogScale(percent, designHeight)
	local vp = workspace.CurrentCamera.ViewportSize
	local byWidth = vp.X * percent / DIALOG_WIDTH
	local byHeight = (vp.Y - 24) / designHeight
	return math.max(math.min(byWidth, byHeight), 0.5)
end

-- Trượt bảng xuống rồi xoá ScreenGui.
-- fadeScrim = true: nền tối mờ đi (đóng hẳn); false: giữ nền tối để bảng sau hiện lên liền mạch.
-- onDone (không bắt buộc): chạy sau khi bảng đã trượt xuống xong.
local function slideOut(gui, scrim, dialog, fadeScrim, onDone)
	if fadeScrim then
		TweenService:Create(scrim, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	end
	local tween = TweenService:Create(
		dialog,
		TweenInfo.new(CLOSE_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
		{ Position = DIALOG_HIDDEN }
	)
	tween.Completed:Connect(function(state)
		gui:Destroy()
		if onDone and state == Enum.PlaybackState.Completed then
			onDone()
		end
	end)
	tween:Play()
end

-- ===== BẢNG "PURCHASE COMPLETED" (giao diện lấy từ file PurchaseCompleted) =====
local function showPurchaseCompleted(itemName)
	local old = playerGui:FindFirstChild("PurchaseCompleted")
	if old then
		old:Destroy()
	end

	local gui = create("ScreenGui", {
		Name = "PurchaseCompleted",
		DisplayOrder = 1000,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	-- nền tối (chặn bấm xuyên xuống game). Giữ đúng độ tối của bảng Buy item nên chuyển bảng không bị nháy
	local scrim = create("Frame", {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = SHOW_SCRIM and SCRIM_TRANSPARENCY or 1,
		BorderSizePixel = 0,
		Active = true,
		Parent = gui,
	})

	-- khung bảng (bắt đầu nằm dưới màn hình, sau đó trượt lên)
	local uiScale = create("UIScale", { Scale = dialogScale(DONE_WIDTH_PERCENT, DONE_HEIGHT) })
	local dialog = create("Frame", {
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = DIALOG_HIDDEN,
		Size = UDim2.fromOffset(DIALOG_WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = BG,
		BorderSizePixel = 0,
		Parent = scrim,
	}, {
		corner(UDim.new(0, 16)),
		uiScale,
		create("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 20),
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
		}),
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- 1) Hàng tiêu đề + nút X
	local header = create("Frame", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Parent = dialog,
	})

	create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansBold,
		Text = DONE_TITLE,
		TextColor3 = TEXT,
		TextSize = 21,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local closeButton = create("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -13, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = header,
	})
	local closeArea = Vector2.new(32, 32)
	line(closeButton, closeArea, Vector2.new(10, 10), Vector2.new(22, 22), 2, WHITE)
	line(closeButton, closeArea, Vector2.new(22, 10), Vector2.new(10, 22), 2, WHITE)

	-- 2) Icon tròn có dấu tick
	local iconHolder = create("Frame", {
		Name = "IconHolder",
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 67),
		BackgroundTransparency = 1,
		Parent = dialog,
	})

	local ring = create("Frame", {
		Name = "Ring",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 24),
		Size = UDim2.fromOffset(43, 43),
		BackgroundColor3 = TEXT,
		BorderSizePixel = 0,
		Parent = iconHolder,
	}, { corner(UDim.new(0.5, 0)) })

	create("Frame", { -- lỗ ở giữa => viền dày 3px
		Name = "Hole",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(37, 37),
		BackgroundColor3 = BG,
		BorderSizePixel = 0,
		Parent = ring,
	}, { corner(UDim.new(0.5, 0)) })

	local ringArea = Vector2.new(43, 43)
	local tickStart = Vector2.new(13.5, 23)
	local tickBottom = Vector2.new(18, 27)
	local tickEnd = Vector2.new(29, 17)
	line(ring, ringArea, tickStart, tickBottom, 3, TEXT)
	line(ring, ringArea, tickBottom, tickEnd, 3, TEXT)

	-- 3) Dòng thông báo (tự xuống dòng nếu tên món dài)
	local messageHolder = create("Frame", {
		Name = "MessageHolder",
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = dialog,
	}, {
		create("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 23),
		}),
	})

	create("TextLabel", {
		Name = "Message",
		Size = UDim2.new(1, 0, 0, 24),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansMedium,
		Text = string.format(DONE_MESSAGE, itemName),
		TextColor3 = TEXT,
		TextSize = 14,
		TextWrapped = true,
		Parent = messageHolder,
	})

	-- 4) Nút OK
	local okButton = create("TextButton", {
		Name = "OK",
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = BLUE,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.BuilderSansBold,
		Text = "OK",
		TextColor3 = WHITE,
		TextSize = 14,
		Parent = dialog,
	}, { corner(UDim.new(0, 8)) })

	-- ===== SỰ KIỆN =====
	local closing = false
	local function closeDialog()
		if closing then
			return
		end
		closing = true
		stopGiftNotification()
		slideOut(gui, scrim, dialog, true, function()
			if triggerGui then triggerGui.Enabled = true end
		end)
	end
	okButton.Activated:Connect(closeDialog)
	closeButton.Activated:Connect(closeDialog)

	okButton.MouseEnter:Connect(function()
		okButton.BackgroundColor3 = BLUE_HOVER
	end)
	okButton.MouseLeave:Connect(function()
		okButton.BackgroundColor3 = BLUE
	end)
	okButton.MouseButton1Down:Connect(function()
		okButton.BackgroundColor3 = BLUE_PRESS
	end)
	okButton.MouseButton1Up:Connect(function()
		okButton.BackgroundColor3 = BLUE_HOVER
	end)

	-- co bảng theo màn hình (điện thoại)
	local camera = workspace.CurrentCamera
	local conn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		uiScale.Scale = dialogScale(DONE_WIDTH_PERCENT, DONE_HEIGHT)
	end)
	gui.Destroying:Connect(function()
		conn:Disconnect()
	end)

	gui.Parent = playerGui

	-- ===== HIỆU ỨNG MỞ: bảng trượt từ dưới lên =====
	TweenService:Create(
		dialog,
		TweenInfo.new(DONE_SLIDE_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Position = DIALOG_SHOWN }
	):Play()

	return gui
end

-- ===== BẢNG "BUY ITEM" =====
-- opts (không bắt buộc): Name, Price, Balance, Image, OnBuy(tênMón, giá)
local function showBuyItem(opts)
	opts = opts or {}
	local rawGiftName, targetPlayer = extractGiftInfo()
	local resolvedName, resolvedPrice, resolvedImage = resolveGift(rawGiftName)
	local itemName = opts.Name or resolvedName
	local itemPrice = tonumber(opts.Price) or resolvedPrice
	local balance = tonumber(opts.Balance) or robuxBalance
	local notificationItemName = rawGiftName or itemName
	local itemImage = toAsset(opts.Image or resolvedImage or ITEM_IMAGE)

	local old = playerGui:FindFirstChild("BuyItem")
	if old then
		old:Destroy()
	end
	if triggerGui then triggerGui.Enabled = false end

	local gui = create("ScreenGui", {
		Name = "BuyItem",
		DisplayOrder = 1000,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	-- nền tối (chặn bấm xuyên xuống game) - bắt đầu trong suốt, mờ dần khi mở
	local scrim = create("Frame", {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = true,
		Parent = gui,
	})

	-- khung bảng (bắt đầu nằm dưới màn hình, sau đó trượt lên)
	local uiScale = create("UIScale", { Scale = dialogScale(BUY_WIDTH_PERCENT, BUY_HEIGHT) })
	local dialog = create("Frame", {
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = DIALOG_HIDDEN,
		Size = UDim2.fromOffset(DIALOG_WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = BG,
		BorderSizePixel = 0,
		Parent = scrim,
	}, {
		corner(UDim.new(0, 16)),
		uiScale,
		create("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 20),
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
		}),
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local function spacer(order, height)
		create("Frame", {
			Name = "Spacer",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, height),
			BackgroundTransparency = 1,
			Parent = dialog,
		})
	end

	-- 1) Hàng tiêu đề: "Buy item" | logo Robux + số dư | nút X
	local header = create("Frame", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Parent = dialog,
	})

	create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -150, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansBold,
		Text = TITLE,
		TextColor3 = TEXT,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local balanceBox = create("Frame", {
		Name = "Balance",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(0, 376, 0, 15),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = header,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
	})
	robuxIcon(balanceBox, 1)
	local balanceAmountLabel = create("TextLabel", {
		Name = "Amount",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansMedium,
		Text = formatNumber(balance),
		TextColor3 = WHITE,
		TextSize = 16,
		Parent = balanceBox,
	})

	local closeButton = create("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -13, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = header,
	})
	local closeArea = Vector2.new(32, 32)
	line(closeButton, closeArea, Vector2.new(10, 10), Vector2.new(22, 22), 2, WHITE)
	line(closeButton, closeArea, Vector2.new(22, 10), Vector2.new(10, 22), 2, WHITE)

	spacer(2, 12)

	-- 2) Hàng món đồ: ảnh 72x72 | tên + giá
	local row = create("Frame", {
		Name = "ItemRow",
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundTransparency = 1,
		Parent = dialog,
	})

	create("ImageLabel", {
		Name = "Thumbnail",
		Size = UDim2.fromOffset(72, 72),
		BackgroundColor3 = PLACEHOLDER,
		BackgroundTransparency = (itemImage == "") and 0 or 1,
		BorderSizePixel = 0,
		Image = itemImage,
		ScaleType = Enum.ScaleType.Fit,
		Parent = row,
	})

	create("TextLabel", {
		Name = "ItemName",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 80, 0, 22),
		Size = UDim2.new(1, -80, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansBold,
		Text = itemName,
		TextColor3 = WHITE,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local priceRow = create("Frame", {
		Name = "PriceRow",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 81, 0, 49),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = row,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
	})
	robuxIcon(priceRow, 1)
	create("TextLabel", {
		Name = "Price",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSansBold,
		Text = formatNumber(itemPrice),
		TextColor3 = WHITE,
		TextSize = 16,
		Parent = priceRow,
	})

	spacer(4, 40)

	-- 3) Nút Buy
	-- Nền nút là 1 Frame có UIGradient (bo góc vẫn đúng khi tô màu), nút bấm trong suốt nằm đè lên trên
	local buyHolder = create("Frame", {
		Name = "BuyHolder",
		LayoutOrder = 5,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = dialog,
	})

	local buyBackground = create("Frame", {
		Name = "BuyBackground",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1), -- để trắng cho màu UIGradient hiện đúng
		BorderSizePixel = 0,
		Parent = buyHolder,
	}, { corner(UDim.new(0, 8)) })
	local buyGradient = create("UIGradient", { Parent = buyBackground })

	local buyButton = create("TextButton", {
		Name = "Buy",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.BuilderSansMedium,
		Text = "Buy",
		TextColor3 = WHITE,
		TextSize = 15,
		ZIndex = 2,
		Parent = buyHolder,
	})

	-- Hiệu ứng nút Buy:
	--  * progress 0 -> 1: phần bên trái (xanh sáng) lan dần sang phải, phần còn lại xanh đậm
	--  * darken 0 -> 1 (sau khi bấm Buy): xanh sáng chuyển lại thành xanh đậm
	local brightColor = BLUE -- màu "xanh sáng" hiện tại (đổi theo hover / nhấn)
	local progress = 0
	local darken = 0

	local function paintBuy()
		local bright = brightColor:Lerp(BLUE_DARK, darken)
		if progress <= 0.002 then
			buyGradient.Color = ColorSequence.new(BLUE_DARK)
		elseif progress >= 0.998 then
			buyGradient.Color = ColorSequence.new(bright)
		else
			buyGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, bright),
				ColorSequenceKeypoint.new(progress, bright),
				ColorSequenceKeypoint.new(progress + 0.001, BLUE_DARK),
				ColorSequenceKeypoint.new(1, BLUE_DARK),
			})
		end
	end
	paintBuy()

	local fillValue = Instance.new("NumberValue")
	fillValue.Changed:Connect(function(value)
		progress = value
		paintBuy()
	end)
	local fillTween = TweenService:Create(fillValue, TweenInfo.new(FILL_TIME, Enum.EasingStyle.Linear), {
		Value = 1,
	})

	local darkenValue = Instance.new("NumberValue")
	darkenValue.Changed:Connect(function(value)
		darken = value
		paintBuy()
	end)

	-- 4) Dải "Get 10% off with Roblox Plus" + nhãn New
	if SHOW_PLUS_BANNER then
		spacer(6, 10)

		local holder = create("Frame", {
			Name = "PlusBannerHolder",
			LayoutOrder = 7,
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundTransparency = 1,
			Parent = dialog,
		})

		-- viền 1px = khung ngoài màu viền + khung trong màu nền
		local outer = create("Frame", {
			Name = "PlusBanner",
			Position = UDim2.fromOffset(-1, 0),
			Size = UDim2.new(1, 2, 1, 0),
			BackgroundColor3 = BORDER,
			BorderSizePixel = 0,
			Parent = holder,
		}, { corner(UDim.new(0, 12)) })

		create("Frame", {
			Name = "Fill",
			Position = UDim2.fromOffset(1, 1),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = BG,
			BorderSizePixel = 0,
			Parent = outer,
		}, { corner(UDim.new(0, 11)) })

		plusIcon(outer)

		create("TextLabel", {
			Name = "PlusText",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 41, 0.5, 0),
			Size = UDim2.new(1, -110, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.BuilderSans,
			Text = PLUS_TEXT,
			TextColor3 = WHITE,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = outer,
		})

		create("Frame", {
			Name = "NewPill",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -13, 0.5, 0),
			Size = UDim2.fromOffset(40, 24),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			Parent = outer,
		}, {
			corner(UDim.new(0.5, 0)),
			create("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Enum.Font.BuilderSansMedium,
				Text = "New",
				TextColor3 = BG,
				TextSize = 12,
			}),
		})
	end

	-- ===== SỰ KIỆN =====
	local closing = false -- bảng đang trượt xuống / đã đóng
	local purchasing = false -- đã bấm Buy

	-- Đóng bảng Buy (trượt xuống rồi xoá)
	local function closeBuy(fadeScrim, onDone)
		if closing then
			return
		end
		closing = true
		fillTween:Cancel()
		slideOut(gui, scrim, dialog, fadeScrim, onDone)
	end

	-- Bấm X: đóng hẳn (sau khi đã bấm Buy thì bỏ qua)
	closeButton.Activated:Connect(function()
		if not purchasing then
			closeBuy(true, function()
				if triggerGui then triggerGui.Enabled = true end
			end)
		end
	end)

	-- Bấm Buy:
	--  1) nút chuyển lại xanh đậm trong PRESS_TIME giây
	--  2) bảng Buy trượt xuống (giữ nền tối)
	--  3) bảng Purchase completed trượt lên
	buyButton.Activated:Connect(function()
		if closing or purchasing then
			return
		end

		if balance < itemPrice then
			buyButton.Text = "Not enough DEMO Robux"
			task.delay(1.4, function()
				if buyButton.Parent and not purchasing then
					buyButton.Text = "Buy"
				end
			end)
			return
		end

		purchasing = true
		fillTween:Cancel()

		-- Trừ số dư DEMO và cập nhật số hiển thị. Không có giao dịch Roblox thật.
		robuxBalance = math.max(0, balance - itemPrice)
		balanceAmountLabel.Text = formatNumber(robuxBalance)
		balanceInput.Text = formatNumber(robuxBalance)

		if opts.OnBuy then
			task.spawn(opts.OnBuy, itemName, itemPrice)
		end

		local darkenTween = TweenService:Create(
			darkenValue,
			TweenInfo.new(PRESS_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Value = 1 }
		)
		darkenTween.Completed:Connect(function(state)
			if state ~= Enum.PlaybackState.Completed then
				return
			end
			closeBuy(false, function()
				-- Purchase completed và thông báo gift bắt đầu cùng một lúc.
				showPurchaseCompleted(itemName)
				task.spawn(playGiftNotification, notificationItemName, targetPlayer)
			end)
		end)
		darkenTween:Play()
	end)

	-- hover / nhấn (bỏ qua sau khi đã bấm Buy để không phá hiệu ứng xanh đậm)
	buyButton.MouseEnter:Connect(function()
		if purchasing then
			return
		end
		brightColor = BLUE_HOVER
		paintBuy()
	end)
	buyButton.MouseLeave:Connect(function()
		if purchasing then
			return
		end
		brightColor = BLUE
		paintBuy()
	end)
	buyButton.MouseButton1Down:Connect(function()
		if purchasing then
			return
		end
		brightColor = BLUE_PRESS
		paintBuy()
	end)
	buyButton.MouseButton1Up:Connect(function()
		if purchasing then
			return
		end
		brightColor = BLUE_HOVER
		paintBuy()
	end)

	-- co bảng theo màn hình (điện thoại)
	local camera = workspace.CurrentCamera
	local conn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		uiScale.Scale = dialogScale(BUY_WIDTH_PERCENT, BUY_HEIGHT)
	end)
	gui.Destroying:Connect(function()
		conn:Disconnect()
		fillTween:Cancel()
		fillValue:Destroy()
		darkenValue:Destroy()
	end)

	gui.Parent = playerGui

	-- ===== HIỆU ỨNG MỞ =====
	-- bảng trượt từ dưới lên + nền tối mờ dần vào
	local slideIn = TweenService:Create(
		dialog,
		TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Position = DIALOG_SHOWN }
	)
	slideIn:Play()
	if SHOW_SCRIM then
		TweenService:Create(scrim, TweenInfo.new(SLIDE_TIME), {
			BackgroundTransparency = SCRIM_TRANSPARENCY,
		}):Play()
	end
	-- trượt xong mới bắt đầu chạy màu xanh sáng trên nút Buy
	slideIn.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and not purchasing and not closing then
			fillTween:Play()
		end
	end)

	return gui
end

-- KHÔNG GỌI TỰ ĐỘNG, CHỜ BẤM NÚT MỚI HIỆN
-- showBuyItem()

-- ==========================================
-- TẠO NÚT TÀNG HÌNH ĐỂ MỞ BẢNG (CẠNH ICON CHAT)
-- ==========================================
triggerGui = Instance.new("ScreenGui")
triggerGui.Name = "TriggerBuyUI"
triggerGui.ResetOnSpawn = false
triggerGui.IgnoreGuiInset = true
triggerGui.DisplayOrder = 2147483647 -- mức cao nhất trong PlayerGui
triggerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
triggerGui.Parent = playerGui

local invisibleButton = Instance.new("TextButton")
invisibleButton.Name = "ChatTriggerBtn"
invisibleButton.AnchorPoint = Vector2.new(0.5, 0.5)
invisibleButton.Text = ""
invisibleButton.BackgroundTransparency = 1
invisibleButton.AutoButtonColor = false
invisibleButton.Active = true
invisibleButton.Selectable = false
invisibleButton.Position = UDim2.new(0.12, 0, 0.25, 0) -- vị trí vòng đỏ trong ảnh đã gửi
invisibleButton.Size = UDim2.fromOffset(65, 65)
invisibleButton.ZIndex = 2147483647
invisibleButton.Parent = triggerGui

invisibleButton.Activated:Connect(function()
	if not playerGui:FindFirstChild("BuyItem") and not playerGui:FindFirstChild("PurchaseCompleted") then
		showBuyItem()
	end
end)

-- Ghi chú: DisplayOrder cao nhất trong PlayerGui không thể vượt qua CoreGui hệ thống của Roblox.

