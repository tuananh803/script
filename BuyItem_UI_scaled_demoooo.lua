--[[
	LocalScript: bảng "Buy item" + bảng "Purchase completed" giống Roblox
	Đặt vào: StarterPlayer > StarterPlayerScripts (LocalScript)

	Luồng: bấm nút tàng hình cạnh icon chat -> bảng Buy item trượt lên (0.3s)
	-> bấm Buy: nút chuyển lại xanh đậm (0.2s) -> bảng Buy trượt xuống
	-> bảng Purchase completed trượt lên (0.3s) -> bấm OK / X để đóng.
	Tên / giá / ảnh trong bảng Buy item tự đổi theo trái trong thông báo gift (danh sách ITEM_LIST bên dưới).
	Chữ gift ("Sending gift ...") hiện cùng lúc với bảng Purchase completed.
	Cả 2 bảng đều làm mờ đen phần màn hình xung quanh; bấm OK / X thì màn hình trở lại bình thường.

	Bảng Purchase completed đã được gộp vào file này, nên hãy XOÁ LocalScript
	"PurchaseCompleted" cũ đi (không thì nó tự hiện ngay khi vào game).
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== CẤU HÌNH (sửa ở đây) =====
local TITLE = "Buy item"
-- Tên / giá / ảnh của bảng Buy item TỰ ĐỔI theo trái trong thông báo gift (tra trong ITEM_LIST bên dưới).
-- ITEM_NAME / ITEM_PRICE / ITEM_IMAGE chỉ dùng khi game không có dòng "Gifting [...] <...>" hoặc trái đó không có trong ITEM_LIST.
local ITEM_NAME = "Dragon"
local ITEM_PRICE = 5000 -- giá (Robux)
local ROBUX_BALANCE = 0 -- số dư DEMO ban đầu trong bảng Buy Item tự tạo (không phải Robux thật)

-- Số dư mô phỏng, chỉ dùng trong giao diện Buy Item do script tự tạo.
local demoBalance = ROBUX_BALANCE
local currentBalanceLabel = nil
local ITEM_IMAGE = "" -- ảnh món, vd "rbxassetid://123456789" (để trống = ô xám)
local ROBUX_ICON = "rbxassetid://79289060473744" -- logo Robux
local PLUS_ICON = "rbxassetid://124086938389734" -- icon Roblox Plus
local ROBUX_ICON_SIZE = 20 -- tăng logo Robux, giữ nguyên kích thước tổng thể của bảng
local PLUS_ICON_SIZE = 21 -- tăng icon Roblox Plus, giữ nguyên kích thước tổng thể của bảng
local PLUS_TEXT = "Get 10% off with Roblox Plus"
local SHOW_PLUS_BANNER = true -- dải "Roblox Plus" ở dưới
local SHOW_SCRIM = true -- nền tối phía sau bảng
local GIFT_TEXT_DIMMED = false -- false: chữ gift nằm trên cùng, sáng rõ (không bị mờ); true: chữ gift cũng bị mờ đen cùng màn hình như game thật

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

-- thứ tự hiển thị (DisplayOrder), từ dưới lên: UI game < lớp mờ + bảng < chữ gift < nút kích hoạt
-- (nếu GIFT_TEXT_DIMMED = true thì chữ gift nằm dưới lớp mờ, nhưng vẫn nằm trên UI game).
-- Đặt thật cao để lớp mờ phủ được cả UI của game có DisplayOrder lớn.
local DIALOG_ORDER = 2147483600
local GIFT_TEXT_ORDER = GIFT_TEXT_DIMMED and 2147483000 or 2147483601

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


-- ===== DANH SÁCH MÓN: { tên, giá Robux, id ảnh } =====
-- Bảng Buy item tự lấy tên / giá / ảnh theo trái trong thông báo gift ("Gifting [người] <trái>").
-- Muốn thêm / sửa món thì thêm / sửa 1 dòng ở đây.
-- id ảnh phải để trong ngoặc kép (dạng chữ): id dài hơn 14 chữ số mà để dạng số thì Roblox đổi thành 1.2e+14 làm hỏng id.
local ITEM_LIST = {
	{ "Rocket", 50, "74865743684566" },
	{ "Spin", 75, "140449159404405" },
	{ "Blade", 100, "107921822284039" },
	{ "Spring", 180, "96804308007607" },
	{ "Bomb", 220, "87590149231144" },
	{ "Smoke", 250, "120443034817988" },
	{ "Spike", 380, "114735723219626" },
	{ "Flame", 550, "71400835505255" },
	{ "Ice", 750, "96319754826215" },
	{ "Sand", 850, "76045700053059" },
	{ "Dark", 950, "120593697335577" },
	{ "Eagle", 975, "95493988230476" },
	{ "Diamond", 1000, "89010608722381" },
	{ "Light", 1100, "107150632425169" },
	{ "Rubber", 1200, "91461104324777" },
	{ "Ghost", 1275, "86941425535302" },
	{ "Magma", 1300, "133464129750678" },
	{ "Quake", 1500, "133286718310883" },
	{ "Human Buddha", 1650, "98957012155395" },
	{ "Love", 1700, "86042292381432" },
	{ "Creation", 1750, "98242337227948" },
	{ "Spider", 1800, "96367323271251" },
	{ "Sound", 1900, "123198645753175" },
	{ "Phoenix", 2000, "91897159145509" },
	{ "Portal", 2000, "109286545716188" },
	{ "Lightning", 2100, "111221767502028" },
	{ "Pain", 2200, "71767250785560" },
	{ "Blizzard", 2250, "117002904661805" },
	{ "Gravity", 2300, "107407838281324" },
	{ "Mammoth", 2350, "76593881964225" },
	{ "T-Rex", 2350, "94551768673500" },
	{ "Dough", 2400, "139266569511863" },
	{ "Shadow", 2425, "136222392814211" },
	{ "Permanent Gas Fruit", 2500, "137265822205765" },
	{ "Spirit", 2550, "84879941545833" },
	{ "Tiger", 3000, "117492513709559" },
	{ "Yeti", 3000, "123423441215836" },
	{ "Magnet", 3500, "113940415408194" },
	{ "Control", 4000, "97683450888445" },
	{ "Kitsune", 4000, "130345719387867" },
	{ "Dragon", 5000, "107942478646068" },
	{ "Soulfire Bundle", 3499, "126162094947436" },
	{ "[GIFT] Fast Boats", 350, "135614168103141" },
	{ "[GIFT] 2x Boss Drops", 350, "124577901152062" },
	{ "[GIFT] 2x Mastery", 450, "94248506319015" },
	{ "[GIFT] 2x Money", 450, "88287062101545" },
	{ "[GIFT] Dark Blade", 1200, "80725153471665" },
	{ "[GIFT] Fruit Notifier", 2700, "80787405177143" },
}

-- Tên gọi khác của vài món (viết thường, liền nhau, không dấu cách / gạch) -> tên đúng trong ITEM_LIST
local ITEM_ALIASES = {
	buddha = "Human Buddha",
	soulfire = "Soulfire Bundle",
}

-- "Permanent T-Rex" -> "permanenttrex": chữ thường, bỏ dấu cách / ngoặc / gạch để so tên cho dễ
local function simplifyName(text)
	text = tostring(text or ""):lower()
	text = text:gsub("[^%w]", "")
	return text
end

-- bỏ chữ "permanent" / "gift" ở đầu và chữ "fruit" ở cuối: "permanentdragon" -> "dragon"
local function stripAffixes(key)
	key = key:gsub("^permanent", "")
	key = key:gsub("^gift", "")
	key = key:gsub("fruit$", "")
	return key
end

local ITEM_INDEX = {}
for _, entry in ipairs(ITEM_LIST) do
	local info = { name = entry[1], price = entry[2], image = entry[3] }
	local key = simplifyName(info.name)
	ITEM_INDEX[key] = info
	local short = stripAffixes(key)
	if short ~= "" and ITEM_INDEX[short] == nil then
		ITEM_INDEX[short] = info
	end
end

-- Tìm món theo tên trong thông báo gift (không phân biệt hoa / thường, có hay không có chữ Permanent / Fruit đều được)
local function findItem(rawName)
	local key = simplifyName(rawName)
	if key == "" then
		return nil
	end
	local item = ITEM_INDEX[key]
	if item then
		return item
	end
	local short = stripAffixes(key)
	item = ITEM_INDEX[short]
	if item then
		return item
	end
	local aliasName = ITEM_ALIASES[short]
	if aliasName then
		return ITEM_INDEX[simplifyName(aliasName)]
	end
	return nil
end

-- Tải trước ảnh các món (chạy nền) để bảng Buy hiện ra là có ảnh ngay, không bị trống một lúc
task.spawn(function()
	local assets = {}
	for _, entry in ipairs(ITEM_LIST) do
		table.insert(assets, toAsset(entry[3]))
	end
	pcall(function()
		ContentProvider:PreloadAsync(assets)
	end)
end)


-- ===== THÔNG BÁO GIFT (lấy từ file phụ deepseek_lua) =====
-- Thông báo này là UI cục bộ, không xác nhận giao dịch Roblox thật.
local giftRun = 0 -- mỗi lần chạy chữ gift tăng 1; lần mới sẽ thay lần cũ nếu lần cũ chưa chạy xong
local giftTweens = {}

-- Giao diện (của game) có đang hiện thật không, hay đang bị ẩn bởi khung cha / ScreenGui?
local function isShown(obj)
	local current = obj
	while current and current ~= playerGui do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		if current:IsA("ScreenGui") and not current.Enabled then
			return false
		end
		current = current.Parent
	end
	return true
end

-- Tìm dòng "Gifting [Tên người] <Tên trái>" trong giao diện game.
-- Trả về: tên trái, tên người. Không thấy thì trả về món mặc định (ITEM_NAME) + "a friend".
local function extractGiftInfo(fallbackItemName)
	local fallbackItem = tostring(fallbackItemName or ITEM_NAME)
	if not fallbackItem:lower():find("permanent", 1, true) then
		fallbackItem = "Permanent " .. fallbackItem
	end

	local hiddenItem, hiddenPlayer -- dòng Gifting đang bị ẩn (chỉ dùng tạm nếu không có dòng nào đang hiện)
	for _, obj in ipairs(playerGui:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			-- ContentText = chữ đang hiển thị (đã bỏ thẻ rich text), Text = chữ gốc
			for _, text in ipairs({ obj.ContentText, obj.Text }) do
				if text:find("Gifting", 1, true) then
					local pName, iName = string.match(text, "Gifting%s*%[([^%]]+)%]%s*<([^>]+)>")
					if pName and iName then
						if isShown(obj) then
							return iName, pName
						end
						hiddenItem = hiddenItem or iName
						hiddenPlayer = hiddenPlayer or pName
						break
					end
				end
			end
		end
	end

	if hiddenItem then
		return hiddenItem, hiddenPlayer
	end
	return fallbackItem, "a friend"
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
-- Font, vị trí, cỡ chữ và khoảng cách lấy theo file SendingGift người dùng cung cấp.
local GIFT_FONT = Enum.Font.SourceSansSemibold
local GIFT_POS_X = 0.5
local GIFT_POS_Y = 0.192
local GIFT_WIDTH_RATIO = 1.3723
local GIFT_GAP_RATIO = 0.139
local GIFT_SHADOW_Y = 0.0032
local GIFT_YELLOW = Color3.fromRGB(248, 229, 88)
local GIFT_GREEN = Color3.fromRGB(110, 236, 112)

local giftNotifGui = create("ScreenGui", {
	Name = "GiftNotification",
	ResetOnSpawn = false,
	DisplayOrder = GIFT_TEXT_ORDER,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

-- Dùng toàn màn hình làm hệ tọa độ để vị trí 19.2% tính từ mép trên như file mẫu.
local giftNotifMain = create("Frame", {
	Name = "Main",
	Parent = giftNotifGui,
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Position = UDim2.fromScale(0, 0),
	Visible = false,
})

local function makeGiftLabel(name, text, richText, color, zIndex)
	return create("TextLabel", {
		Name = name,
		Parent = giftNotifMain,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Font = GIFT_FONT,
		RichText = richText,
		Text = text,
		TextColor3 = color,
		TextSize = 31,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextStrokeTransparency = 1,
		ZIndex = zIndex,
	})
end

-- Mỗi dòng có một label đen lệch xuống làm bóng, giống file SendingGift.
local giftNotifTopShadow = makeGiftLabel("TopShadow", "", false, Color3.new(0, 0, 0), 1)
local giftNotifBottomShadow = makeGiftLabel("BottomShadow", "Gift sent successfully!", false, Color3.new(0, 0, 0), 1)
local giftNotifTop = makeGiftLabel("Top", "", true, Color3.fromRGB(255, 255, 255), 2)
local giftNotifBottom = makeGiftLabel("Bottom", "Gift sent successfully!", false, GIFT_GREEN, 2)

local function giftTextWidth(text, textSize)
	return TextService:GetTextSize(
		text,
		textSize,
		GIFT_FONT,
		Vector2.new(100000, 100000)
	).X
end

local function setGiftLinePosition(mainLabel, shadowLabel, dy, shadowDy)
	mainLabel.Position = UDim2.new(GIFT_POS_X, 0, GIFT_POS_Y, dy)
	shadowLabel.Position = UDim2.new(GIFT_POS_X, 0, GIFT_POS_Y, dy + shadowDy)
end

local function layoutGiftNotification(itemName, targetPlayer)
	local plainLine1 = ("Sending gift <%s> to %s..."):format(itemName, targetPlayer)
	local richLine1 = ('Sending gift <font color="#F8E558">&lt;%s&gt;</font> to %s...'):format(itemName, targetPlayer)

	giftNotifTopShadow.Text = plainLine1
	giftNotifTop.Text = richLine1
	giftNotifBottom.Text = "Gift sent successfully!"
	giftNotifBottomShadow.Text = "Gift sent successfully!"

	local viewport = workspace.CurrentCamera.ViewportSize
	local targetWidth = math.min(GIFT_WIDTH_RATIO * viewport.Y, viewport.X * 0.96)
	local textSize, bestDifference = 1, math.huge

	-- Chọn cỡ chữ sao cho độ rộng dòng 1 khớp tỷ lệ trong file mẫu.
	for candidate = 1, 100 do
		local difference = math.abs(giftTextWidth(plainLine1, candidate) - targetWidth)
		if difference < bestDifference then
			textSize = candidate
			bestDifference = difference
		end
	end

	local shadowDy = math.max(1, math.round(viewport.Y * GIFT_SHADOW_Y))
	local gap = math.round(giftTextWidth(giftNotifBottom.Text, textSize) * GIFT_GAP_RATIO)

	for _, label in ipairs({ giftNotifTop, giftNotifTopShadow, giftNotifBottom, giftNotifBottomShadow }) do
		label.TextSize = textSize
	end

	setGiftLinePosition(giftNotifTop, giftNotifTopShadow, 0, shadowDy)
	setGiftLinePosition(giftNotifBottom, giftNotifBottomShadow, gap, shadowDy)

	return gap, shadowDy
end

local function playGiftTween(guiObject, time, direction, goal)
	local tween = TweenService:Create(guiObject, TweenInfo.new(time, Enum.EasingStyle.Quad, direction), goal)
	table.insert(giftTweens, tween)
	tween:Play()
	return tween
end

local function tweenGiftLine(mainLabel, shadowLabel, time, direction, goal)
	playGiftTween(mainLabel, time, direction, goal)
	playGiftTween(shadowLabel, time, direction, goal)
end

local function playGiftNotification(itemName, targetPlayer)
	-- Nếu thông báo cũ còn chạy thì hủy trước khi hiển thị lượt mới.
	giftRun = giftRun + 1
	local myRun = giftRun
	for _, tween in ipairs(giftTweens) do
		tween:Cancel()
	end
	table.clear(giftTweens)

	itemName = tostring(itemName or ("Permanent " .. ITEM_NAME))
	targetPlayer = tostring(targetPlayer or "a friend")
	local gap, shadowDy = layoutGiftNotification(itemName, targetPlayer)

	local topFinal = UDim2.new(GIFT_POS_X, 0, GIFT_POS_Y, 0)
	local topShadowFinal = UDim2.new(GIFT_POS_X, 0, GIFT_POS_Y, shadowDy)
	local bottomFinal = UDim2.new(GIFT_POS_X, 0, GIFT_POS_Y, gap)
	local bottomShadowFinal = UDim2.new(GIFT_POS_X, 0, GIFT_POS_Y, gap + shadowDy)
	local enterOffset = -30

	giftNotifMain.Visible = true
	giftNotifTop.Position = topFinal + UDim2.fromOffset(0, enterOffset)
	giftNotifTopShadow.Position = topShadowFinal + UDim2.fromOffset(0, enterOffset)
	giftNotifBottom.Position = bottomFinal + UDim2.fromOffset(0, enterOffset)
	giftNotifBottomShadow.Position = bottomShadowFinal + UDim2.fromOffset(0, enterOffset)

	for _, label in ipairs({ giftNotifTop, giftNotifTopShadow, giftNotifBottom, giftNotifBottomShadow }) do
		label.TextTransparency = 1
	end

	tweenGiftLine(giftNotifTop, giftNotifTopShadow, 0.35, Enum.EasingDirection.Out, {
		Position = topFinal,
		TextTransparency = 0,
	})
	task.wait(1.5)
	if myRun ~= giftRun then return end

	tweenGiftLine(giftNotifBottom, giftNotifBottomShadow, 0.35, Enum.EasingDirection.Out, {
		Position = bottomFinal,
		TextTransparency = 0,
	})
	task.wait(1.5)
	if myRun ~= giftRun then return end

	tweenGiftLine(giftNotifTop, giftNotifTopShadow, 0.2, Enum.EasingDirection.In, {
		Position = UDim2.new(1, 250, GIFT_POS_Y, 0),
		TextTransparency = 1,
	})
	task.wait(1.5)
	if myRun ~= giftRun then return end

	tweenGiftLine(giftNotifBottom, giftNotifBottomShadow, 0.2, Enum.EasingDirection.In, {
		Position = UDim2.new(-1, -250, GIFT_POS_Y, gap),
		TextTransparency = 1,
	})
	task.wait(0.3)
	if myRun ~= giftRun then return end

	giftNotifMain.Visible = false
end

-- Cập nhật tỷ lệ chữ / vị trí khi kích thước cửa sổ thay đổi.
local giftViewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if giftNotifMain.Visible then
		local visibleText = giftNotifTopShadow.Text
		local itemName = visibleText:match("Sending gift <(.-)> to ") or ITEM_NAME
		local targetPlayer = visibleText:match("> to (.-)%.%.%.$") or "a friend"
		layoutGiftNotification(itemName, targetPlayer)
	end
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

-- 2 bảng của script đang mở (hoặc nil) - để nút kích hoạt không mở chồng thêm bảng
local currentBuyGui = nil
local currentDoneGui = nil

-- Khóa toàn bộ thao tác trong lúc chuỗi hiệu ứng Buy đang chạy.
-- Hàm sẽ được nối với lớp chặn input tạo ở phần cuối script.
local setInputLocked = function(_locked) end

-- ===== BẢNG "PURCHASE COMPLETED" (giao diện lấy từ file PurchaseCompleted) =====
local function showPurchaseCompleted(itemName, giftItemName, giftTarget)
	local old = playerGui:FindFirstChild("PurchaseCompleted")
	if old then
		old:Destroy()
	end

	local gui = create("ScreenGui", {
		Name = "PurchaseCompleted",
		DisplayOrder = DIALOG_ORDER,
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
		TextSize = 23,
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
		TextSize = 16,
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
		TextSize = 16,
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

	currentDoneGui = gui
	gui.Parent = playerGui

	-- ===== HIỆU ỨNG MỞ: bảng trượt từ dưới lên =====
	local doneSlideIn = TweenService:Create(
		dialog,
		TweenInfo.new(DONE_SLIDE_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Position = DIALOG_SHOWN }
	)
	doneSlideIn.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then
			-- Chỉ mở khóa sau khi bảng Purchase đã trượt lên hoàn toàn.
			setInputLocked(false)
		end
	end)
	doneSlideIn:Play()

	-- chữ gift ("Sending gift ..." / "Gift sent successfully!") hiện CÙNG LÚC với bảng
	task.spawn(playGiftNotification, giftItemName, giftTarget)

	return gui
end

-- ===== BẢNG "BUY ITEM" =====
-- opts (không bắt buộc): Name, Price, Balance, Image, GiftItem, GiftTarget, OnBuy(tênMón, giá)
-- GiftItem / GiftTarget = trái + người nhận hiện trong chữ gift (không truyền thì tự đọc từ thông báo gift của game)
local function showBuyItem(opts)
	opts = opts or {}
	local itemName = opts.Name or ITEM_NAME
	local itemPrice = opts.Price or ITEM_PRICE
	local balance = demoBalance
	local itemImage = toAsset(opts.Image or ITEM_IMAGE)

	-- Trái + người nhận cho chữ gift: lấy 1 lần lúc mở bảng, dùng lại khi bấm Buy
	local giftItemName, giftTarget = opts.GiftItem, opts.GiftTarget
	if not giftItemName then
		giftItemName, giftTarget = extractGiftInfo(itemName)
	end

	local old = playerGui:FindFirstChild("BuyItem")
	if old then
		old:Destroy()
	end

	local gui = create("ScreenGui", {
		Name = "BuyItem",
		DisplayOrder = DIALOG_ORDER,
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
		TextSize = 22,
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
			Padding = UDim.new(0, 8),
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
		TextSize = 18,
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
		TextSize = 18,
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
			Padding = UDim.new(0, 8),
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
		TextSize = 18,
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
		TextSize = 16,
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
			TextSize = 15,
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
				TextSize = 13,
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
		-- Chặn mọi thao tác cho đến khi hiệu ứng chuyển sang Purchase hoàn tất.
		setInputLocked(true)
		demoBalance = demoBalance - itemPrice
		balanceAmountLabel.Text = formatNumber(demoBalance)
		fillTween:Cancel()

		-- Chữ gift hiện cùng lúc với bảng Purchase completed (xem showPurchaseCompleted), không hiện ở bước này.

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
				showPurchaseCompleted(itemName, giftItemName, giftTarget)
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

	currentBuyGui = gui
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

-- ==========================================
-- MINIMIZE: CHỈ HIỂN THỊ DUY NHẤT DẤU "-"
-- ==========================================
local UserInputService = game:GetService("UserInputService")

local miniButton = Instance.new("TextButton")
miniButton.Name = "MiniButton"
miniButton.Size = UDim2.fromOffset(24, 24)
miniButton.Position = UDim2.new(
	controlMain.Position.X.Scale,
	controlMain.Position.X.Offset + 192,
	controlMain.Position.Y.Scale,
	controlMain.Position.Y.Offset + 3
)
miniButton.BackgroundTransparency = 1
miniButton.BorderSizePixel = 0
miniButton.Text = "-"
miniButton.Font = Enum.Font.Gotham
miniButton.TextSize = 23
miniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
miniButton.TextStrokeTransparency = 1
miniButton.TextXAlignment = Enum.TextXAlignment.Center
miniButton.TextYAlignment = Enum.TextYAlignment.Center
miniButton.AutoButtonColor = false
miniButton.Active = true
miniButton.Selectable = false
miniButton.Visible = false
miniButton.Parent = controlGui
-- Không tạo UICorner hoặc UIStroke: khi thu nhỏ chỉ còn ký tự "-".

local isMinimized = false
local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil
local wasDragged = false

-- Bắt đầu kéo bằng chuột hoặc cảm ứng.
miniButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		wasDragged = false
		dragStart = input.Position
		startPosition = miniButton.Position
		if input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				dragInput = nil
			end
		end)
	end
end)

-- Với chuột, theo dõi MouseMovement khi con trỏ đang ở trên nút.
miniButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end
	if input ~= dragInput then
		return
	end

	local delta = input.Position - dragStart
	if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
		wasDragged = true
	end

	miniButton.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end)

local hideButton = Instance.new("TextButton")
hideButton.Name = "HideButton"
hideButton.Size = UDim2.fromOffset(24, 24)
hideButton.Position = UDim2.new(1, -28, 0, 3)
hideButton.BackgroundTransparency = 1
hideButton.BorderSizePixel = 0
hideButton.Text = "-"
hideButton.Font = Enum.Font.Gotham
hideButton.TextSize = 20
hideButton.TextColor3 = panelColors.white
hideButton.TextStrokeTransparency = 1
hideButton.AutoButtonColor = false
hideButton.Parent = controlMain

local function toggleMinimize()
	if isMinimized then
		-- Khi mở lại, đưa góc trên-phải của bảng về vị trí dấu gạch.
		controlMain.Position = UDim2.new(
			miniButton.Position.X.Scale,
			miniButton.Position.X.Offset - 192,
			miniButton.Position.Y.Scale,
			miniButton.Position.Y.Offset - 3
		)
		miniButton.Visible = false
		controlMain.Visible = true
		isMinimized = false
	else
		-- Đặt dấu gạch đúng tại góc trên-phải của bảng trước khi ẩn bảng.
		miniButton.Position = UDim2.new(
			controlMain.Position.X.Scale,
			controlMain.Position.X.Offset + 192,
			controlMain.Position.Y.Scale,
			controlMain.Position.Y.Offset + 3
		)
		controlMain.Visible = false
		miniButton.Visible = true
		isMinimized = true
	end
end

-- Sau thao tác kéo, Activated không được hiểu nhầm thành thao tác mở bảng.
miniButton.Activated:Connect(function()
	if not wasDragged then
		toggleMinimize()
	end
end)

hideButton.Activated:Connect(toggleMinimize)

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

-- Lớp trong suốt phủ toàn màn hình, chỉ bật trong lúc hiệu ứng Buy chạy.
-- Được tạo sau nút kích hoạt và dùng ZIndex cao nhất để chặn mọi lần nhấn.
local inputBlocker = Instance.new("TextButton")
inputBlocker.Name = "BuyAnimationInputBlocker"
inputBlocker.Size = UDim2.fromScale(1, 1)
inputBlocker.Position = UDim2.fromScale(0, 0)
inputBlocker.BackgroundTransparency = 1
inputBlocker.TextTransparency = 1
inputBlocker.Text = ""
inputBlocker.AutoButtonColor = false
inputBlocker.Active = true
inputBlocker.Selectable = false
inputBlocker.Modal = true
inputBlocker.ZIndex = 2147483647
inputBlocker.Visible = false
inputBlocker.Parent = triggerGui

setInputLocked = function(locked)
	inputBlocker.Visible = locked
	invisibleButton.Active = not locked
	invisibleButton.Selectable = not locked
end

-- Dùng cả Activated và InputBegan để nhận thao tác chạm/nhấp.
local triggerDebounce = false
local function activateBuyPanel()
	if triggerDebounce then return end
	-- đang mở bảng Buy / Purchase completed thì bấm nút không mở chồng thêm bảng
	if (currentBuyGui and currentBuyGui.Parent) or (currentDoneGui and currentDoneGui.Parent) then
		return
	end
	triggerDebounce = true

	-- Lấy trái trong thông báo gift của game -> tra ITEM_LIST ra tên / giá / ảnh
	local giftItemName, giftTarget = extractGiftInfo(ITEM_NAME)
	local item = findItem(giftItemName)
	if item then
		showBuyItem({
			Name = item.name,
			Price = item.price,
			Image = item.image,
			GiftItem = giftItemName,
			GiftTarget = giftTarget,
		})
	else
		-- trái không có trong ITEM_LIST: giữ tên trong thông báo (bỏ chữ Permanent), dùng giá + ảnh mặc định
		showBuyItem({
			Name = (giftItemName:gsub("^[Pp]ermanent%s+", "")),
			Price = ITEM_PRICE,
			Image = ITEM_IMAGE,
			GiftItem = giftItemName,
			GiftTarget = giftTarget,
		})
	end

	task.delay(0.35, function()
		triggerDebounce = false
	end)
end

invisibleButton.Activated:Connect(activateBuyPanel)
