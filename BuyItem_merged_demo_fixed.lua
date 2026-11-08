--[[
	LocalScript: bảng "Buy item" + bảng "Purchase completed" giống Roblox
	Đặt vào: StarterPlayer > StarterPlayerScripts (LocalScript)

	Luồng: bấm nút tàng hình cạnh icon chat -> bảng Buy item trượt lên (0.3s)
	-> bấm Buy: nút chuyển lại xanh đậm (0.2s) -> bảng Buy trượt xuống
	-> bảng Purchase completed trượt lên (0.3s) -> bấm OK / X để đóng.

	Bảng Purchase completed đã được gộp vào file này, nên hãy XOÁ LocalScript
	"PurchaseCompleted" cũ đi (không thì nó tự hiện ngay khi vào game).
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== CẤU HÌNH (sửa ở đây) =====
local TITLE = "Buy item"
local ITEM_NAME = "Dragon"
local ITEM_PRICE = 5000 -- giá (Robux)
local ROBUX_BALANCE = 0 -- số dư DEMO ban đầu trong bảng Buy Item tự tạo (không phải Robux thật)

-- Số dư mô phỏng, chỉ dùng trong giao diện Buy Item do script tự tạo.
local demoBalance = ROBUX_BALANCE
local currentBalanceLabel = nil
local ITEM_IMAGE = "" -- ảnh món, vd "rbxassetid://123456789" (để trống = ô xám)
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


-- ===== THÔNG BÁO GIFT (lấy từ file phụ deepseek_lua) =====
-- Thông báo này là UI cục bộ, không xác nhận giao dịch Roblox thật.
local giftNotifBusy = false

local function extractGiftInfo(fallbackItemName)
	local targetPlayer = "a friend"
	local itemName = tostring(fallbackItemName or ITEM_NAME)
	if not itemName:lower():find("permanent", 1, true) then
		itemName = "Permanent " .. itemName
	end

	for _, obj in ipairs(playerGui:GetDescendants()) do
		if obj:IsA("TextLabel") and obj.Text:find("Gifting", 1, true) then
			local pName, iName = string.match(obj.Text, "Gifting%s*%[([^%]]+)%]%s*<([^>]+)>")
			if pName and iName then
				return iName, pName
			end
		end
	end

	return itemName, targetPlayer
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


-- ===== GIFT NOTIFICATION GUI =====
local giftNotifGui = create("ScreenGui", {
	Name = "GiftNotification",
	ResetOnSpawn = false,
	DisplayOrder = 2000,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

local giftNotifMain = create("Frame", {
	Name = "Main",
	Parent = giftNotifGui,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 80),
	Position = UDim2.new(0, 0, 0.05, 0),
	Visible = false,
})

local giftNotifTop = create("TextLabel", {
	Name = "Top",
	Parent = giftNotifMain,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.new(0, 0, -0.15, 0),
	RichText = true,
	TextSize = 31,
	Font = Enum.Font.SourceSans,
	TextStrokeTransparency = 0.5,
	TextStrokeColor3 = Color3.fromRGB(45, 45, 45),
	TextXAlignment = Enum.TextXAlignment.Center,
})

local giftNotifBottom = create("TextLabel", {
	Name = "Bottom",
	Parent = giftNotifMain,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.new(0, 0, -0.15, 0),
	Text = "Gift sent successfully!",
	TextSize = 31,
	Font = Enum.Font.SourceSans,
	TextColor3 = Color3.fromRGB(106, 250, 85),
	TextStrokeTransparency = 0.5,
	TextStrokeColor3 = Color3.fromRGB(45, 45, 45),
	TextXAlignment = Enum.TextXAlignment.Center,
})

local function playGiftNotification(itemName, targetPlayer)
	if giftNotifBusy then
		return
	end
	giftNotifBusy = true

	itemName = tostring(itemName or ("Permanent " .. ITEM_NAME))
	targetPlayer = tostring(targetPlayer or "a friend")
	giftNotifTop.Text = string.format(
		'<font color="rgb(255,255,255)">Sending gift </font><font color="rgb(254,239,52)">&lt;%s&gt;</font><font color="rgb(255,255,255)"> to %s</font>',
		itemName,
		targetPlayer
	)

	giftNotifMain.Visible = true
	giftNotifTop.Position = UDim2.new(0, 0, -0.15, 0)
	giftNotifBottom.Position = UDim2.new(0, 0, -0.15, 0)
	giftNotifTop.TextTransparency = 1
	giftNotifBottom.TextTransparency = 1

	TweenService:Create(giftNotifTop, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
		TextTransparency = 0,
	}):Play()
	task.wait(1.5)

	TweenService:Create(giftNotifBottom, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 22),
		TextTransparency = 0,
	}):Play()
	task.wait(1.5)

	TweenService:Create(giftNotifTop, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 250, 0, 0),
		TextTransparency = 1,
	}):Play()
	task.wait(1.5)

	TweenService:Create(giftNotifBottom, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(-1, -250, 0, 22),
		TextTransparency = 1,
	}):Play()
	task.wait(0.3)

	giftNotifMain.Visible = false
	giftNotifBusy = false
end

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
		slideOut(gui, scrim, dialog, true)
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
	local itemName = opts.Name or ITEM_NAME
	local itemPrice = opts.Price or ITEM_PRICE
	local balance = demoBalance
	local itemImage = toAsset(opts.Image or ITEM_IMAGE)

	local old = playerGui:FindFirstChild("BuyItem")
	if old then
		old:Destroy()
	end

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
	currentBalanceLabel = balanceAmountLabel

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
			closeBuy(true)
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

		-- Chỉ trừ số dư DEMO trong giao diện do script tạo, không trừ Robux thật.
		if demoBalance < itemPrice then
			buyButton.Text = "Not enough Robux"
			task.delay(1.2, function()
				if buyButton and buyButton.Parent and not purchasing then
					buyButton.Text = "Buy"
				end
			end)
			return
		end

		purchasing = true
		demoBalance = demoBalance - itemPrice
		balanceAmountLabel.Text = formatNumber(demoBalance)
		fillTween:Cancel()

		-- Hiện thông báo cùng lúc khi nhấn Buy.
		local giftItemName, giftTarget = extractGiftInfo(itemName)
		task.spawn(playGiftNotification, giftItemName, giftTarget)

		-- Giữ callback tùy chọn của file chính.
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
				showPurchaseCompleted(itemName)
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
		if currentBalanceLabel == balanceAmountLabel then
			currentBalanceLabel = nil
		end
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
-- BẢNG NHẬP SỐ DƯ ROBUX DEMO (LẤY TỪ FILE PHỤ)
-- ==========================================
local controlGui = Instance.new("ScreenGui")
controlGui.Name = "MinimalGifter"
controlGui.ResetOnSpawn = false
controlGui.DisplayOrder = 900 -- nằm dưới hộp Buy Item
controlGui.IgnoreGuiInset = true
controlGui.Parent = playerGui

local panelColors = {
	panel = Color3.fromRGB(16, 22, 34),
	edge = Color3.fromRGB(58, 140, 255),
	white = Color3.fromRGB(236, 240, 248),
	button = Color3.fromRGB(40, 122, 232),
}

local controlMain = Instance.new("Frame")
controlMain.Name = "RobuxPanel"
controlMain.Size = UDim2.fromOffset(220, 110)
controlMain.Position = UDim2.new(1, -240, 0, 60)
controlMain.BackgroundColor3 = panelColors.panel
controlMain.BackgroundTransparency = 0.1
controlMain.BorderSizePixel = 0
controlMain.Active = true
controlMain.Draggable = true
controlMain.Parent = controlGui
corner(UDim.new(0, 10)).Parent = controlMain
local panelStroke = Instance.new("UIStroke")
panelStroke.Color = panelColors.edge
panelStroke.Thickness = 2
panelStroke.Parent = controlMain

local controlTitle = Instance.new("TextLabel")
controlTitle.Size = UDim2.new(1, 0, 0, 30)
controlTitle.BackgroundTransparency = 1
controlTitle.Text = "DEMO ROBUX AMOUNT"
controlTitle.Font = Enum.Font.GothamBold
controlTitle.TextColor3 = panelColors.edge
controlTitle.TextSize = 12
controlTitle.Parent = controlMain

local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.new(1, -20, 0, 30)
amountBox.Position = UDim2.fromOffset(10, 32)
amountBox.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
amountBox.TextColor3 = panelColors.white
amountBox.Font = Enum.Font.Gotham
amountBox.TextSize = 14
amountBox.PlaceholderText = "Nhập số Robux..."
amountBox.Text = formatNumber(demoBalance)
amountBox.ClearTextOnFocus = false
amountBox.Parent = controlMain
corner(UDim.new(0, 6)).Parent = amountBox
local amountStroke = Instance.new("UIStroke")
amountStroke.Color = Color3.fromRGB(40, 50, 70)
amountStroke.Thickness = 1
amountStroke.Parent = amountBox

local applyButton = Instance.new("TextButton")
applyButton.Size = UDim2.new(1, -20, 0, 30)
applyButton.Position = UDim2.fromOffset(10, 70)
applyButton.BackgroundColor3 = panelColors.button
applyButton.Text = "APPLY"
applyButton.Font = Enum.Font.GothamBold
applyButton.TextSize = 14
applyButton.TextColor3 = panelColors.white
applyButton.Parent = controlMain
corner(UDim.new(0, 6)).Parent = applyButton

local miniButton = Instance.new("TextButton")
miniButton.Name = "MiniButton"
miniButton.Size = UDim2.fromOffset(40, 40)
miniButton.Position = controlMain.Position
miniButton.BackgroundColor3 = panelColors.panel
miniButton.Text = "-"
miniButton.Font = Enum.Font.GothamBold
miniButton.TextSize = 24
miniButton.TextColor3 = panelColors.white
miniButton.AutoButtonColor = false
miniButton.Parent = controlGui
corner(UDim.new(0, 8)).Parent = miniButton
local miniStroke = Instance.new("UIStroke")
miniStroke.Color = panelColors.edge
miniStroke.Thickness = 2
miniStroke.Parent = miniButton
miniButton.Visible = false

local isMinimized = false
local hideButton = Instance.new("TextButton")
hideButton.Size = UDim2.fromOffset(24, 24)
hideButton.Position = UDim2.new(1, -28, 0, 3)
hideButton.BackgroundTransparency = 1
hideButton.Text = "-"
hideButton.Font = Enum.Font.GothamBold
hideButton.TextSize = 18
hideButton.TextColor3 = panelColors.white
hideButton.Parent = controlMain

local function toggleMinimize()
	isMinimized = not isMinimized
	if isMinimized then
		miniButton.Position = controlMain.Position
		controlMain.Visible = false
		miniButton.Visible = true
	else
		miniButton.Visible = false
		controlMain.Visible = true
	end
end

hideButton.Activated:Connect(toggleMinimize)
miniButton.Activated:Connect(toggleMinimize)

applyButton.Activated:Connect(function()
	local digits = amountBox.Text:gsub("[^%d]", "")
	local amount = tonumber(digits)
	if not amount or amount < 0 or amount ~= amount or amount == math.huge then
		applyButton.Text = "INVALID AMOUNT"
		task.delay(1.2, function()
			if applyButton and applyButton.Parent then applyButton.Text = "APPLY" end
		end)
		return
	end

	demoBalance = math.floor(amount)
	amountBox.Text = formatNumber(demoBalance)
	if currentBalanceLabel and currentBalanceLabel.Parent then
		currentBalanceLabel.Text = formatNumber(demoBalance)
	end
	applyButton.Text = "APPLIED!"
	task.delay(1, function()
		if applyButton and applyButton.Parent then applyButton.Text = "APPLY" end
	end)
end)

-- ==========================================
-- TẠO NÚT TÀNG HÌNH ĐỂ MỞ BẢNG (CẠNH ICON CHAT)
-- ==========================================
local triggerGui = Instance.new("ScreenGui")
triggerGui.Name = "TriggerBuyUI"
triggerGui.ResetOnSpawn = false
triggerGui.IgnoreGuiInset = true
triggerGui.DisplayOrder = 2147483647 -- Cao nhất trong các ScreenGui thuộc PlayerGui
triggerGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
triggerGui.Parent = playerGui

local invisibleButton = Instance.new("TextButton")
invisibleButton.Name = "ChatTriggerBtn"
invisibleButton.Text = ""
invisibleButton.BackgroundTransparency = 1 -- Tàng hình hoàn toàn
invisibleButton.TextTransparency = 1
invisibleButton.AutoButtonColor = false
invisibleButton.Active = true
invisibleButton.Selectable = true
invisibleButton.Modal = true
invisibleButton.ZIndex = 2147483647

-- Vị trí nút: cạnh khu vực icon chat, gần mép trên bên trái.
-- Tăng vùng chạm để dễ bấm trên điện thoại.
invisibleButton.AnchorPoint = Vector2.new(0, 0)
invisibleButton.Position = UDim2.fromOffset(180, 15)
invisibleButton.Size = UDim2.fromOffset(65, 65)
invisibleButton.Parent = triggerGui

-- Dùng cả Activated và InputBegan để nhận thao tác chạm/nhấp.
local triggerDebounce = false
local function activateBuyPanel()
	if triggerDebounce then return end
	triggerDebounce = true
	showBuyItem()
	task.delay(0.35, function()
		triggerDebounce = false
	end)
end

invisibleButton.Activated:Connect(activateBuyPanel)
