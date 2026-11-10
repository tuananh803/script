--[[
	LocalScript: báº£ng "Buy item" + báº£ng "Purchase completed" giá»‘ng Roblox
	Äáº·t vĂ o: StarterPlayer > StarterPlayerScripts (LocalScript)

	Luá»“ng: báº¥m nĂºt tĂ ng hĂ¬nh cáº¡nh icon chat -> báº£ng Buy item trÆ°á»£t lĂªn (0.3s)
	-> báº¥m Buy: nĂºt chuyá»ƒn láº¡i xanh Ä‘áº­m (0.2s) -> báº£ng Buy trÆ°á»£t xuá»‘ng
	-> báº£ng Purchase completed trÆ°á»£t lĂªn (0.3s) -> báº¥m OK / X Ä‘á»ƒ Ä‘Ă³ng.
	TĂªn / giĂ¡ / áº£nh trong báº£ng Buy item tá»± Ä‘á»•i theo trĂ¡i trong thĂ´ng bĂ¡o gift (danh sĂ¡ch ITEM_LIST bĂªn dÆ°á»›i).
	Chá»¯ gift ("Sending gift ...") hiá»‡n cĂ¹ng lĂºc vá»›i báº£ng Purchase completed.
	Cáº£ 2 báº£ng Ä‘á»u lĂ m má» Ä‘en pháº§n mĂ n hĂ¬nh xung quanh; báº¥m OK / X thĂ¬ mĂ n hĂ¬nh trá»Ÿ láº¡i bĂ¬nh thÆ°á»ng.

	Báº£ng Purchase completed Ä‘Ă£ Ä‘Æ°á»£c gá»™p vĂ o file nĂ y, nĂªn hĂ£y XOĂ LocalScript
	"PurchaseCompleted" cÅ© Ä‘i (khĂ´ng thĂ¬ nĂ³ tá»± hiá»‡n ngay khi vĂ o game).
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== Cáº¤U HĂŒNH (sá»­a á»Ÿ Ä‘Ă¢y) =====
local TITLE = "Buy item"
-- TĂªn / giĂ¡ / áº£nh cá»§a báº£ng Buy item Tá»° Äá»”I theo trĂ¡i trong thĂ´ng bĂ¡o gift (tra trong ITEM_LIST bĂªn dÆ°á»›i).
-- ITEM_NAME / ITEM_PRICE / ITEM_IMAGE chá»‰ dĂ¹ng khi game khĂ´ng cĂ³ dĂ²ng "Gifting [...] <...>" hoáº·c trĂ¡i Ä‘Ă³ khĂ´ng cĂ³ trong ITEM_LIST.
local ITEM_NAME = "Dragon"
local ITEM_PRICE = 5000 -- giĂ¡ (Robux)
local ROBUX_BALANCE = 0 -- sá»‘ dÆ° DEMO ban Ä‘áº§u trong báº£ng Buy Item tá»± táº¡o (khĂ´ng pháº£i Robux tháº­t)

-- Sá»‘ dÆ° mĂ´ phá»ng, chá»‰ dĂ¹ng trong giao diá»‡n Buy Item do script tá»± táº¡o.
local demoBalance = ROBUX_BALANCE
local currentBalanceLabel = nil
local ITEM_IMAGE = "" -- áº£nh mĂ³n, vd "rbxassetid://123456789" (Ä‘á»ƒ trá»‘ng = Ă´ xĂ¡m)
local ROBUX_ICON = "rbxassetid://79289060473744" -- logo Robux
local PLUS_ICON = "rbxassetid://124086938389734" -- icon Roblox Plus
local ROBUX_ICON_SIZE = 20 -- tÄƒng logo Robux, giá»¯ nguyĂªn kĂ­ch thÆ°á»›c tá»•ng thá»ƒ cá»§a báº£ng
local PLUS_ICON_SIZE = 29 -- tÄƒng icon Roblox Plus, giá»¯ nguyĂªn kĂ­ch thÆ°á»›c tá»•ng thá»ƒ cá»§a báº£ng
local PLUS_TEXT = "Get 10% off with Roblox Plus"
local SHOW_PLUS_BANNER = true -- dáº£i "Roblox Plus" á»Ÿ dÆ°á»›i
local SHOW_SCRIM = true -- ná»n tá»‘i phĂ­a sau báº£ng
local GIFT_TEXT_DIMMED = true -- false: chá»¯ gift náº±m trĂªn cĂ¹ng, sĂ¡ng rĂµ (khĂ´ng bá»‹ má»); true: chá»¯ gift cÅ©ng bá»‹ má» Ä‘en cĂ¹ng mĂ n hĂ¬nh nhÆ° game tháº­t

local DONE_TITLE = "Purchase completed"
local DONE_MESSAGE = "You have successfully bought %s." -- %s = tĂªn mĂ³n Ä‘á»“

-- ===== KĂCH THÆ¯á»C + THá»œI GIAN HIá»†U á»¨NG (sá»­a á»Ÿ Ä‘Ă¢y) =====
local BUY_WIDTH_PERCENT = 0.565 -- báº£ng Buy item. ÄĂ£ nĂ¢ng tá»« 0.518 lĂªn 0.565 vĂ¬ so 2 áº£nh thĂ¬ báº£ng cá»§a script nhá» hÆ¡n báº£ng tháº­t ~9%. Muá»‘n to/nhá» hÆ¡n thĂ¬ tÄƒng/giáº£m sá»‘ nĂ y
local DONE_WIDTH_PERCENT = 0.48 -- báº£ng Purchase completed chiáº¿m 48% chiá»u rá»™ng mĂ n hĂ¬nh (Ä‘o tá»« áº£nh máº«u)
local SLIDE_TIME = 0.3 -- báº£ng Buy item trÆ°á»£t tá»« dÆ°á»›i lĂªn (giĂ¢y)
local FILL_TIME = 3.5 -- mĂ u xanh sĂ¡ng cháº¡y háº¿t nĂºt Buy tá»« trĂ¡i sang pháº£i (giĂ¢y)
local PRESS_TIME = 0.2 -- báº¥m Buy xong, nĂºt chuyá»ƒn láº¡i xanh Ä‘áº­m trong (giĂ¢y)
local DONE_SLIDE_TIME = 0.3 -- báº£ng Purchase completed trÆ°á»£t tá»« dÆ°á»›i lĂªn (giĂ¢y)
local LOCK_UNTIL_FILL_DONE = true -- true: màu xanh còn đang chạy trên nút Buy thì chưa ấn được gì, chạy xong mới ấn được
local LOCK_CLOSE_BUTTON_TOO = true -- true: nút X cũng bị khoá cùng lúc; false: chỉ khoá nút Buy, vẫn bấm X để đóng được
local CLOSE_TIME = 0.3 -- báº£ng trÆ°á»£t xuá»‘ng khi Ä‘Ă³ng / khi chuyá»ƒn sang báº£ng sau (giĂ¢y)

-- ===== MĂ€U (Ä‘o tá»« áº£nh) =====
local BG = Color3.fromRGB(25, 26, 31)
local TEXT = Color3.fromRGB(213, 215, 221)
local WHITE = Color3.fromRGB(247, 247, 248)
local BLUE = Color3.fromRGB(51, 95, 255) -- xanh sĂ¡ng
local BLUE_DARK = Color3.fromRGB(39, 61, 144) -- xanh Ä‘áº­m
local BLUE_HOVER = Color3.fromRGB(71, 111, 255)
local BLUE_PRESS = Color3.fromRGB(41, 82, 224)
local BORDER = Color3.fromRGB(46, 46, 54)
local PLACEHOLDER = Color3.fromRGB(47, 48, 55)

-- kĂ­ch thÆ°á»›c gá»‘c cá»§a 2 báº£ng (px) - khĂ´ng cáº§n sá»­a
local DIALOG_WIDTH = 457
local BUY_HEIGHT = 284
local DONE_HEIGHT = 234

-- vá»‹ trĂ­ báº£ng: Ä‘ang hiá»‡n (giá»¯a mĂ n hĂ¬nh) / Ä‘ang áº©n (náº±m dÆ°á»›i mĂ n hĂ¬nh)
local DIALOG_SHOWN = UDim2.fromScale(0.5, 0.5)
local DIALOG_HIDDEN = UDim2.fromScale(0.5, 1.5)
local SCRIM_TRANSPARENCY = 0.5

-- thá»© tá»± hiá»ƒn thá»‹ (DisplayOrder), tá»« dÆ°á»›i lĂªn: UI game < lá»›p má» + báº£ng < chá»¯ gift < nĂºt kĂ­ch hoáº¡t
-- (náº¿u GIFT_TEXT_DIMMED = true thĂ¬ chá»¯ gift náº±m dÆ°á»›i lá»›p má», nhÆ°ng váº«n náº±m trĂªn UI game).
-- Äáº·t tháº­t cao Ä‘á»ƒ lá»›p má» phá»§ Ä‘Æ°á»£c cáº£ UI cá»§a game cĂ³ DisplayOrder lá»›n.
local DIALOG_ORDER = 2147483600
local GIFT_TEXT_ORDER = GIFT_TEXT_DIMMED and 2147483000 or 2147483601

-- ===== HĂ€M PHá»¤ =====
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

-- cho phĂ©p dĂ¡n "rbxassetid://123" hoáº·c chá»‰ sá»‘ 123
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


-- ===== DANH SĂCH MĂ“N: { tĂªn, giĂ¡ Robux, id áº£nh } =====
-- Báº£ng Buy item tá»± láº¥y tĂªn / giĂ¡ / áº£nh theo trĂ¡i trong thĂ´ng bĂ¡o gift ("Gifting [ngÆ°á»i] <trĂ¡i>").
-- Muá»‘n thĂªm / sá»­a mĂ³n thĂ¬ thĂªm / sá»­a 1 dĂ²ng á»Ÿ Ä‘Ă¢y.
-- id áº£nh pháº£i Ä‘á»ƒ trong ngoáº·c kĂ©p (dáº¡ng chá»¯): id dĂ i hÆ¡n 14 chá»¯ sá»‘ mĂ  Ä‘á»ƒ dáº¡ng sá»‘ thĂ¬ Roblox Ä‘á»•i thĂ nh 1.2e+14 lĂ m há»ng id.
local ITEM_LIST = {
	{ "Rocket", 50, "140645454238585" },
	{ "Spin", 75, "130148926909180" },
	{ "Blade", 100, "117073881503970" }, -- THIẾU, giữ ID cũ
	{ "Spring", 180, "103334075902325" },
	{ "Bomb", 220, "105862186430042" },
	{ "Smoke", 250, "76304619221915" },
	{ "Spike", 380, "78238989719779" },
	{ "Flame", 550, "118974892159455" },
	{ "Ice", 750, "101549382056412" },
	{ "Sand", 850, "121749996633198" },
	{ "Dark", 950, "133126556783554" },
	{ "Eagle", 975, "71261272109607" },
	{ "Diamond", 1000, "135138953822149" },
	{ "Light", 1100, "116984804195277" },
	{ "Rubber", 1200, "94363719573306" },
	{ "Ghost", 1275, "91595683399715" },
	{ "Magma", 1300, "126239005047404" },
	{ "Quake", 1500, "102521393649450" },
	{ "Human Buddha", 1650, "136378903931718" },
	{ "Love", 1700, "135767923773383" },
	{ "Creation", 1750, "122076290025352" },
	{ "Spider", 1800, "129748293007119" },
	{ "Sound", 1900, "73189140349435" },
	{ "Phoenix", 2000, "107028260783556" },
	{ "Portal", 2000, "107330367034634" },
	{ "Lightning", 2100, "134301231259378" },
	{ "Pain", 2200, "105308734871350" },
	{ "Blizzard", 2250, "117114602382137" },
	{ "Gravity", 2300, "99975147509058" },
	{ "Mammoth", 2350, "127376628624277" },
	{ "T-Rex", 2350, "99611015796118" },
	{ "Dough", 2400, "132422513136009" },
	{ "Shadow", 2425, "73616763788993" },
	{ "Permanent Gas Fruit", 2500, "105365900498377" },
	{ "Spirit", 2550, "140429719465168" },
	{ "Tiger", 3000, "134195674187629" },
	{ "Yeti", 3000, "73702334160756" },
	{ "Magnet", 3500, "108825324838376" },
	{ "Control", 4000, "128848258869248" },
	{ "Kitsune", 4000, "131001819573510" },
	{ "Dragon", 5000, "129710990180752" },
	{ "Soulfire Bundle", 3499, "113571014704367" },
	{ "[GIFT] Fast Boats", 350, "126132058466729" }, -- giữ ID cũ
	{ "[GIFT] 2x Boss Drops", 350, "96577294795747" }, -- giữ ID cũ
	{ "[GIFT] 2x Mastery", 450, "98285210533123" }, -- giữ ID cũ
	{ "[GIFT] 2x Money", 450, "76085871035201" }, -- giữ ID cũ
	{ "[GIFT] Dark Blade", 1200, "88405113202582" }, -- giữ ID cũ
	{ "[GIFT] Fruit Notifier", 2700, "123492658695663" }, -- giữ ID cũ
}

-- TĂªn gá»i khĂ¡c cá»§a vĂ i mĂ³n (viáº¿t thÆ°á»ng, liá»n nhau, khĂ´ng dáº¥u cĂ¡ch / gáº¡ch) -> tĂªn Ä‘Ăºng trong ITEM_LIST
local ITEM_ALIASES = {
	buddha = "Human Buddha",
	soulfire = "Soulfire Bundle",
}

-- "Permanent T-Rex" -> "permanenttrex": chá»¯ thÆ°á»ng, bá» dáº¥u cĂ¡ch / ngoáº·c / gáº¡ch Ä‘á»ƒ so tĂªn cho dá»…
local function simplifyName(text)
	text = tostring(text or ""):lower()
	text = text:gsub("[^%w]", "")
	return text
end

-- bá» chá»¯ "permanent" / "gift" á»Ÿ Ä‘áº§u vĂ  chá»¯ "fruit" á»Ÿ cuá»‘i: "permanentdragon" -> "dragon"
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

-- TĂ¬m mĂ³n theo tĂªn trong thĂ´ng bĂ¡o gift (khĂ´ng phĂ¢n biá»‡t hoa / thÆ°á»ng, cĂ³ hay khĂ´ng cĂ³ chá»¯ Permanent / Fruit Ä‘á»u Ä‘Æ°á»£c)
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

-- Táº£i trÆ°á»›c áº£nh cĂ¡c mĂ³n (cháº¡y ná»n) Ä‘á»ƒ báº£ng Buy hiá»‡n ra lĂ  cĂ³ áº£nh ngay, khĂ´ng bá»‹ trá»‘ng má»™t lĂºc
task.spawn(function()
	local assets = {}
	for _, entry in ipairs(ITEM_LIST) do
		table.insert(assets, toAsset(entry[3]))
	end
	pcall(function()
		ContentProvider:PreloadAsync(assets)
	end)
end)


-- ===== THĂ”NG BĂO GIFT (láº¥y tá»« file phá»¥ deepseek_lua) =====
-- ThĂ´ng bĂ¡o nĂ y lĂ  UI cá»¥c bá»™, khĂ´ng xĂ¡c nháº­n giao dá»‹ch Roblox tháº­t.
local giftRun = 0 -- má»—i láº§n cháº¡y chá»¯ gift tÄƒng 1; láº§n má»›i sáº½ thay láº§n cÅ© náº¿u láº§n cÅ© chÆ°a cháº¡y xong
local giftTweens = {}

-- Tên trái lấy từ thông báo của game đôi khi dính dấu } ở cuối (vd "Permanent Dragon}") -> bỏ đi, chỉ còn "Permanent Dragon"
local function cleanGiftItemName(name)
	name = tostring(name or "")
	name = name:gsub("[%s}]+$", "")
	return name
end

-- Giao diá»‡n (cá»§a game) cĂ³ Ä‘ang hiá»‡n tháº­t khĂ´ng, hay Ä‘ang bá»‹ áº©n bá»Ÿi khung cha / ScreenGui?
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

-- TĂ¬m dĂ²ng "Gifting [TĂªn ngÆ°á»i] <TĂªn trĂ¡i>" trong giao diá»‡n game.
-- Tráº£ vá»: tĂªn trĂ¡i, tĂªn ngÆ°á»i. KhĂ´ng tháº¥y thĂ¬ tráº£ vá» mĂ³n máº·c Ä‘á»‹nh (ITEM_NAME) + "a friend".
local function extractGiftInfo(fallbackItemName)
	local fallbackItem = tostring(fallbackItemName or ITEM_NAME)
	if not fallbackItem:lower():find("permanent", 1, true) then
		fallbackItem = "Permanent " .. fallbackItem
	end

	local hiddenItem, hiddenPlayer -- dĂ²ng Gifting Ä‘ang bá»‹ áº©n (chá»‰ dĂ¹ng táº¡m náº¿u khĂ´ng cĂ³ dĂ²ng nĂ o Ä‘ang hiá»‡n)
	for _, obj in ipairs(playerGui:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			-- ContentText = chá»¯ Ä‘ang hiá»ƒn thá»‹ (Ä‘Ă£ bá» tháº» rich text), Text = chá»¯ gá»‘c
			for _, text in ipairs({ obj.ContentText, obj.Text }) do
				if text:find("Gifting", 1, true) then
					local pName, iName = string.match(text, "Gifting%s*%[([^%]]+)%]%s*<([^>]+)>")
					if pName and iName then
						if isShown(obj) then
							return cleanGiftItemName(iName), pName
						end
						hiddenItem = hiddenItem or cleanGiftItemName(iName)
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

-- Äoáº¡n tháº³ng bo trĂ²n 2 Ä‘áº§u tá»« p1 -> p2 (pixel), náº±m trong khung "parent" cá»¡ "area" (dĂ¹ng cho nĂºt X, dáº¥u tick)
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
-- Bám theo script "SendingGift": 2 dòng chữ, cỡ chữ + vị trí đo theo TỈ LỆ màn hình (giống nhau trên mọi thiết bị),
-- mỗi dòng có thêm 1 label xám đen đặt lệch thẳng xuống vài px làm bóng đổ (Roblox không có drop-shadow sẵn).
-- Hiệu ứng trượt / mờ dần giữ nguyên như cũ. Muốn chỉnh cỡ / vị trí / màu thì sửa bảng GIFT_STYLE bên dưới.
local GIFT_STYLE = {
	SAMPLE_ITEM = "Permanent Control", -- chữ MẪU (đúng như ảnh gốc) để đo cỡ chữ chuẩn; cỡ này dùng cho mọi món / mọi người nhận
	SAMPLE_TARGET = "nicoleestes984",
	DONE_TEXT = "Gift sent successfully!", -- dòng thứ 2
	FONT = Enum.Font.SourceSansSemibold, -- cả 2 dòng cùng 1 font (muốn đậm hơn: SourceSansBold)
	WHITE = Color3.fromRGB(255, 255, 255), -- chữ thường
	YELLOW_HEX = "#F8E558", -- phần <tên trái> (248, 229, 88)
	GREEN = Color3.fromRGB(110, 236, 112), -- dòng "Gift sent successfully!" (#6EEC70)
	POS_X = 0.5, -- tâm chữ: giữa màn hình theo chiều ngang
	POS_Y = 0.192, -- tâm dòng 1: 19.2% chiều cao màn hình (lệch vài px thì chỉnh số này)
	WIDTH_RATIO = 1.3723, -- bề rộng dòng 1 (chữ mẫu) / chiều cao màn hình (1301 / 948)
	SIZE_SCALE = 1.06, -- phóng chữ to thêm 6% so với cỡ chuẩn ở trên (1 = đúng cỡ ảnh gốc; muốn to nữa thì tăng, vd 1.1)
	OUTLINE_THICKNESS = 1, -- độ dày viền (px), cố định mọi màn hình như game thật. Muốn mỏng hơn nữa thì 0.5; 0 = tắt viền
	OUTLINE_COLOR = Color3.fromRGB(45, 45, 45), -- viền XÁM ĐEN (không phải đen tuyền), theo ảnh game thật
	OUTLINE_TRANSPARENCY = 0.5, -- viền hơi trong (0 = đặc, 1 = trong suốt)
	MAX_WIDTH_RATIO = 0.96, -- chữ không được rộng quá 96% chiều rộng màn hình
	GAP_RATIO = 0.139, -- khoảng cách giữa 2 dòng / bề rộng dòng 2 (33px / 237px trên ảnh mẫu)
	SHADOW_Y = 0.0016, -- bóng lệch thẳng xuống ~1.5px / 948 (đã giảm mỏng hơn trước), không lệch ngang, không mờ. Muốn mỏng nữa thì giảm số này (tối thiểu 1px)
	SHADOW_COLOR = Color3.fromRGB(45, 45, 45), -- bóng màu XÁM ĐEN (cùng tông với viền)
	SHADOW_TRANSPARENCY = 0.3, -- bóng hơi trong (0 = đặc, 1 = trong suốt)
	SLIDE_IN = 12, -- lúc hiện ra, chữ trượt xuống từ cao hơn vị trí cuối bấy nhiêu px
}

local playGiftNotification
do
	local TextService = game:GetService("TextService")
	local S = GIFT_STYLE

	local samplePlain = ("Sending gift <%s> to %s..."):format(S.SAMPLE_ITEM, S.SAMPLE_TARGET)
	local currentPlain = samplePlain -- chữ dòng 1 đang hiển thị (dạng thường, để đo bề rộng)
	local giftLayout = { shadowDy = 1, gap = 0 }

	local giftGui = create("ScreenGui", {
		Name = "GiftNotification",
		ResetOnSpawn = false,
		DisplayOrder = GIFT_TEXT_ORDER,
		IgnoreGuiInset = true, -- tính tọa độ từ mép trên cùng của màn hình, giống trong ảnh
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})

	local giftMain = create("Frame", {
		Name = "Main",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = giftGui,
	})

	local function makeLabel(name, text, rich, color, z)
		return create("TextLabel", {
			Name = name,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
			Position = UDim2.fromScale(S.POS_X, S.POS_Y),
			Font = S.FONT,
			RichText = rich,
			Text = text,
			TextColor3 = color,
			TextTransparency = 1,
			ZIndex = z,
			Parent = giftMain,
		})
	end

	-- mỗi dòng = label bóng đen (nằm dưới) + label chính (nằm trên)
	local function makeLine(name, text, rich, color)
		local main = makeLabel(name, text, rich, color, 2)
		-- viền đen mỏng bao quanh chữ chính (UIStroke), để chữ không bị chìm vào màu bảng
		local stroke = create("UIStroke", {
			Color = S.OUTLINE_COLOR,
			Thickness = 1,
			Transparency = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			LineJoinMode = Enum.LineJoinMode.Round,
			Parent = main,
		})
		return {
			shadow = makeLabel(name .. "Shadow", text, false, S.SHADOW_COLOR, 1),
			main = main,
			stroke = stroke,
		}
	end

	local giftTop = makeLine("Top", samplePlain, true, S.WHITE)
	local giftBottom = makeLine("Bottom", S.DONE_TEXT, false, S.GREEN)

	local function measure(text, size)
		return TextService:GetTextSize(text, size, S.FONT, Vector2.new(1e5, 1e5)).X
	end

	-- chữ có thể chứa < > & (vd tên món) -> đổi sang dạng an toàn cho RichText
	local function escapeRich(text)
		text = text:gsub("&", "&amp;")
		text = text:gsub("<", "&lt;")
		text = text:gsub(">", "&gt;")
		return text
	end

	-- Tính lại cỡ chữ / khoảng cách / độ lệch bóng theo kích thước màn hình hiện tại.
	local function applyLayout()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local vp = camera.ViewportSize
		if vp.X <= 0 or vp.Y <= 0 then
			return
		end

		-- cỡ chữ chuẩn: chọn TextSize (số nguyên) để CHỮ MẪU rộng đúng tỉ lệ như ảnh gốc
		local targetW = math.min(S.WIDTH_RATIO * vp.Y, vp.X * S.MAX_WIDTH_RATIO)
		local size, best = 1, math.huge
		for s = 1, 100 do
			local d = math.abs(measure(samplePlain, s) - targetW)
			if d < best then
				size, best = s, d
			end
		end

		-- phóng to thêm 1 chút (SIZE_SCALE); TextSize tối đa của Roblox là 100
		size = math.min(100, math.round(size * S.SIZE_SCALE))

		-- tên món / tên người nhận dài hơn chữ mẫu mà tràn màn hình thì thu nhỏ vừa đủ
		local maxW = vp.X * S.MAX_WIDTH_RATIO
		while size > 1 and measure(currentPlain, size) > maxW do
			size = size - 1
		end

		-- độ dày viền (0 nếu tắt viền)
		local outline = math.max(0, S.OUTLINE_THICKNESS)

		-- bóng lệch xuống theo tỉ lệ màn hình, tối thiểu 1px
		giftLayout.shadowDy = math.max(1, math.round(vp.Y * S.SHADOW_Y))
		-- khoảng cách 2 dòng tính theo bề rộng chữ nên luôn khớp tỉ lệ với cỡ chữ
		giftLayout.gap = math.round(measure(S.DONE_TEXT, size) * S.GAP_RATIO)

		for _, ln in ipairs({ giftTop, giftBottom }) do
			ln.main.TextSize = size
			ln.shadow.TextSize = size
			ln.stroke.Enabled = outline > 0
			ln.stroke.Thickness = math.max(outline, 0.1)
		end
	end

	-- đặt ngay 1 dòng (không tween): chữ + bóng, đang trong suốt
	local function placeLine(ln, dy)
		ln.main.Position = UDim2.new(S.POS_X, 0, S.POS_Y, dy)
		ln.shadow.Position = UDim2.new(S.POS_X, 0, S.POS_Y, dy + giftLayout.shadowDy)
		ln.main.TextTransparency = 1
		ln.shadow.TextTransparency = 1
		ln.stroke.Transparency = 1
	end

	-- trượt + mờ dần / rõ dần cả chữ lẫn bóng cùng lúc
	local function slideLine(ln, time, direction, xScale, dy, transparency)
		for _, label in ipairs({ ln.main, ln.shadow }) do
			local isShadow = label == ln.shadow
			local extra = isShadow and giftLayout.shadowDy or 0
			local goal = transparency
			if isShadow and transparency < 1 then
				goal = S.SHADOW_TRANSPARENCY
			end
			local tween = TweenService:Create(label, TweenInfo.new(time, Enum.EasingStyle.Quad, direction), {
				Position = UDim2.new(xScale, 0, S.POS_Y, dy + extra),
				TextTransparency = goal,
			})
			table.insert(giftTweens, tween)
			tween:Play()
		end

		-- viền đen mờ / rõ cùng nhịp với chữ (không thì viền còn nguyên khi chữ đã mờ hết)
		local strokeGoal = (transparency < 1) and S.OUTLINE_TRANSPARENCY or 1
		local strokeTween = TweenService:Create(ln.stroke, TweenInfo.new(time, Enum.EasingStyle.Quad, direction), {
			Transparency = strokeGoal,
		})
		table.insert(giftTweens, strokeTween)
		strokeTween:Play()
	end

	local function hookCamera()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
		end
	end
	hookCamera()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		hookCamera()
		applyLayout()
	end)
	applyLayout()

	playGiftNotification = function(itemName, targetPlayer)
		-- đang chạy dở thì bỏ lượt cũ, chạy lại từ đầu (để lần mua sau vẫn có chữ)
		giftRun = giftRun + 1
		local myRun = giftRun
		for _, tween in ipairs(giftTweens) do
			tween:Cancel()
		end
		table.clear(giftTweens)

		itemName = cleanGiftItemName(itemName or ("Permanent " .. ITEM_NAME))
		targetPlayer = tostring(targetPlayer or "a friend")

		-- dòng 1: "Sending gift <tên trái> to người nhận..." (phần <...> màu vàng); bóng dùng chữ thường cùng nội dung
		currentPlain = ("Sending gift <%s> to %s..."):format(itemName, targetPlayer)
		giftTop.shadow.Text = currentPlain
		giftTop.main.Text = ('Sending gift <font color="%s">&lt;%s&gt;</font> to %s...'):format(
			S.YELLOW_HEX,
			escapeRich(itemName),
			escapeRich(targetPlayer)
		)
		applyLayout()

		giftMain.Visible = true
		placeLine(giftTop, -S.SLIDE_IN)
		placeLine(giftBottom, -S.SLIDE_IN)

		slideLine(giftTop, 0.35, Enum.EasingDirection.Out, S.POS_X, 0, 0)
		task.wait(1.5)
		if myRun ~= giftRun then
			return
		end

		slideLine(giftBottom, 0.35, Enum.EasingDirection.Out, S.POS_X, giftLayout.gap, 0)
		task.wait(1.5)
		if myRun ~= giftRun then
			return
		end

		-- dòng 1 trượt ra bên phải, rồi dòng 2 trượt ra bên trái (như cũ)
		slideLine(giftTop, 0.2, Enum.EasingDirection.In, 1 + S.POS_X, 0, 1)
		task.wait(1.5)
		if myRun ~= giftRun then
			return
		end

		slideLine(giftBottom, 0.2, Enum.EasingDirection.In, -S.POS_X, giftLayout.gap, 1)
		task.wait(0.3)
		if myRun ~= giftRun then
			return
		end

		giftMain.Visible = false
	end
end

-- Logo Robux (áº£nh tháº­t)
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

-- Icon Roblox Plus (áº£nh tháº­t)
local function plusIcon(parent)
	return create("ImageLabel", {
		Name = "PlusIcon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(PLUS_ICON_SIZE, PLUS_ICON_SIZE),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = toAsset(PLUS_ICON),
		ImageColor3 = WHITE,
		ScaleType = Enum.ScaleType.Fit,
		Parent = parent,
	})
end

-- Cá»¡ báº£ng = chiáº¿m Ä‘Ăºng "percent" chiá»u rá»™ng mĂ n hĂ¬nh (nhÆ° áº£nh máº«u) trĂªn má»i mĂ n hĂ¬nh,
-- khĂ´ng cĂ³ giá»›i háº¡n to nháº¥t. Chá»‰ cháº·n Ä‘á»ƒ báº£ng khĂ´ng cao quĂ¡ mĂ n hĂ¬nh vĂ  khĂ´ng nhá» hÆ¡n 0.5.
local function dialogScale(percent, designHeight)
	local vp = workspace.CurrentCamera.ViewportSize
	local byWidth = vp.X * percent / DIALOG_WIDTH
	local byHeight = (vp.Y - 24) / designHeight
	return math.max(math.min(byWidth, byHeight), 0.5)
end

-- TrÆ°á»£t báº£ng xuá»‘ng rá»“i xoĂ¡ ScreenGui.
-- fadeScrim = true: ná»n tá»‘i má» Ä‘i (Ä‘Ă³ng háº³n); false: giá»¯ ná»n tá»‘i Ä‘á»ƒ báº£ng sau hiá»‡n lĂªn liá»n máº¡ch.
-- onDone (khĂ´ng báº¯t buá»™c): cháº¡y sau khi báº£ng Ä‘Ă£ trÆ°á»£t xuá»‘ng xong.
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

-- 2 báº£ng cá»§a script Ä‘ang má»Ÿ (hoáº·c nil) - Ä‘á»ƒ nĂºt kĂ­ch hoáº¡t khĂ´ng má»Ÿ chá»“ng thĂªm báº£ng
local currentBuyGui = nil
local currentDoneGui = nil

-- ===== Báº¢NG "PURCHASE COMPLETED" (giao diá»‡n láº¥y tá»« file PurchaseCompleted) =====
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

	-- ná»n tá»‘i (cháº·n báº¥m xuyĂªn xuá»‘ng game). Giá»¯ Ä‘Ăºng Ä‘á»™ tá»‘i cá»§a báº£ng Buy item nĂªn chuyá»ƒn báº£ng khĂ´ng bá»‹ nhĂ¡y
	local scrim = create("Frame", {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = SHOW_SCRIM and SCRIM_TRANSPARENCY or 1,
		BorderSizePixel = 0,
		Active = true,
		Parent = gui,
	})

	-- khung báº£ng (báº¯t Ä‘áº§u náº±m dÆ°á»›i mĂ n hĂ¬nh, sau Ä‘Ă³ trÆ°á»£t lĂªn)
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

	-- 1) HĂ ng tiĂªu Ä‘á» + nĂºt X
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

	-- 2) Icon trĂ²n cĂ³ dáº¥u tick
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

	create("Frame", { -- lá»— á»Ÿ giá»¯a => viá»n dĂ y 3px
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

	-- 3) DĂ²ng thĂ´ng bĂ¡o (tá»± xuá»‘ng dĂ²ng náº¿u tĂªn mĂ³n dĂ i)
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

	-- 4) NĂºt OK
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

	-- ===== Sá»° KIá»†N =====
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

	-- co báº£ng theo mĂ n hĂ¬nh (Ä‘iá»‡n thoáº¡i)
	local camera = workspace.CurrentCamera
	local conn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		uiScale.Scale = dialogScale(DONE_WIDTH_PERCENT, DONE_HEIGHT)
	end)
	gui.Destroying:Connect(function()
		conn:Disconnect()
	end)

	currentDoneGui = gui
	gui.Parent = playerGui

	-- ===== HIá»†U á»¨NG Má»: báº£ng trÆ°á»£t tá»« dÆ°á»›i lĂªn =====
	TweenService:Create(
		dialog,
		TweenInfo.new(DONE_SLIDE_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Position = DIALOG_SHOWN }
	):Play()

	-- chá»¯ gift ("Sending gift ..." / "Gift sent successfully!") hiá»‡n CĂ™NG LĂC vá»›i báº£ng
	task.spawn(playGiftNotification, giftItemName, giftTarget)

	return gui
end

-- ===== Báº¢NG "BUY ITEM" =====
-- opts (khĂ´ng báº¯t buá»™c): Name, Price, Balance, Image, GiftItem, GiftTarget, OnBuy(tĂªnMĂ³n, giĂ¡)
-- GiftItem / GiftTarget = trĂ¡i + ngÆ°á»i nháº­n hiá»‡n trong chá»¯ gift (khĂ´ng truyá»n thĂ¬ tá»± Ä‘á»c tá»« thĂ´ng bĂ¡o gift cá»§a game)
local function showBuyItem(opts)
	opts = opts or {}
	local itemName = opts.Name or ITEM_NAME
	local itemPrice = opts.Price or ITEM_PRICE
	local balance = demoBalance
	local itemImage = toAsset(opts.Image or ITEM_IMAGE)

	-- TrĂ¡i + ngÆ°á»i nháº­n cho chá»¯ gift: láº¥y 1 láº§n lĂºc má»Ÿ báº£ng, dĂ¹ng láº¡i khi báº¥m Buy
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

	-- ná»n tá»‘i (cháº·n báº¥m xuyĂªn xuá»‘ng game) - báº¯t Ä‘áº§u trong suá»‘t, má» dáº§n khi má»Ÿ
	local scrim = create("Frame", {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = true,
		Parent = gui,
	})

	-- khung báº£ng (báº¯t Ä‘áº§u náº±m dÆ°á»›i mĂ n hĂ¬nh, sau Ä‘Ă³ trÆ°á»£t lĂªn)
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

	-- 1) HĂ ng tiĂªu Ä‘á»: "Buy item" | logo Robux + sá»‘ dÆ° | nĂºt X
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
		TextSize = 25,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local balanceBox = create("Frame", {
		Name = "Balance",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(0, 376, 0, 16),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = header,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
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
	}, {
		create("UIPadding", { PaddingBottom = UDim.new(0, 1) }), -- day so len 1 chut cho cung tam voi icon
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

	-- 2) HĂ ng mĂ³n Ä‘á»“: áº£nh 72x72 | tĂªn + giĂ¡
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
		TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local priceRow = create("Frame", {
		Name = "PriceRow",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 80, 0, 49),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = row,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
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

	-- 3) NĂºt Buy
	-- Ná»n nĂºt lĂ  1 Frame cĂ³ UIGradient (bo gĂ³c váº«n Ä‘Ăºng khi tĂ´ mĂ u), nĂºt báº¥m trong suá»‘t náº±m Ä‘Ă¨ lĂªn trĂªn
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
		BackgroundColor3 = Color3.new(1, 1, 1), -- Ä‘á»ƒ tráº¯ng cho mĂ u UIGradient hiá»‡n Ä‘Ăºng
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
		TextSize = 18,
		ZIndex = 2,
		Parent = buyHolder,
	})

	-- Hiá»‡u á»©ng nĂºt Buy:
	--  * progress 0 -> 1: pháº§n bĂªn trĂ¡i (xanh sĂ¡ng) lan dáº§n sang pháº£i, pháº§n cĂ²n láº¡i xanh Ä‘áº­m
	--  * darken 0 -> 1 (sau khi báº¥m Buy): xanh sĂ¡ng chuyá»ƒn láº¡i thĂ nh xanh Ä‘áº­m
	local brightColor = BLUE -- mĂ u "xanh sĂ¡ng" hiá»‡n táº¡i (Ä‘á»•i theo hover / nháº¥n)
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

	-- 4) Dáº£i "Get 10% off with Roblox Plus" + nhĂ£n New
	if SHOW_PLUS_BANNER then
		spacer(6, 10)

		local holder = create("Frame", {
			Name = "PlusBannerHolder",
			LayoutOrder = 7,
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundTransparency = 1,
			Parent = dialog,
		})

		-- viá»n 1px = khung ngoĂ i mĂ u viá»n + khung trong mĂ u ná»n
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
			TextSize = 16,
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
				TextSize = 16,
			}),
		})
	end

	-- ===== Sá»° KIá»†N =====
	local closing = false -- báº£ng Ä‘ang trÆ°á»£t xuá»‘ng / Ä‘Ă£ Ä‘Ă³ng
	local buyReady = not LOCK_UNTIL_FILL_DONE -- false = hiệu ứng nút Buy đang chạy, chưa cho ấn
	local hovering = false -- chuột có đang đặt trên nút Buy không (kể cả lúc đang khoá)
	fillTween.Completed:Connect(function(state)
		if state ~= Enum.PlaybackState.Completed then
			return
		end
		buyReady = true
		if hovering then
			brightColor = BLUE_HOVER
			paintBuy()
		end
	end)
	local purchasing = false -- Ä‘Ă£ báº¥m Buy

	-- ÄĂ³ng báº£ng Buy (trÆ°á»£t xuá»‘ng rá»“i xoĂ¡)
	local function closeBuy(fadeScrim, onDone)
		if closing then
			return
		end
		closing = true
		fillTween:Cancel()
		slideOut(gui, scrim, dialog, fadeScrim, onDone)
	end

	-- Báº¥m X: Ä‘Ă³ng háº³n (sau khi Ä‘Ă£ báº¥m Buy thĂ¬ bá» qua)
	closeButton.Activated:Connect(function()
		if not purchasing and (buyReady or not LOCK_CLOSE_BUTTON_TOO) then
			closeBuy(true)
		end
	end)

	-- Báº¥m Buy:
	--  1) nĂºt chuyá»ƒn láº¡i xanh Ä‘áº­m trong PRESS_TIME giĂ¢y
	--  2) báº£ng Buy trÆ°á»£t xuá»‘ng (giá»¯ ná»n tá»‘i)
	--  3) báº£ng Purchase completed trÆ°á»£t lĂªn
	buyButton.Activated:Connect(function()
		if closing or purchasing or not buyReady then
			return
		end

		-- Chá»‰ trá»« sá»‘ dÆ° DEMO trong giao diá»‡n do script táº¡o, khĂ´ng trá»« Robux tháº­t.
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

		-- Chá»¯ gift hiá»‡n cĂ¹ng lĂºc vá»›i báº£ng Purchase completed (xem showPurchaseCompleted), khĂ´ng hiá»‡n á»Ÿ bÆ°á»›c nĂ y.

		-- Giá»¯ callback tĂ¹y chá»n cá»§a file chĂ­nh.
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

	-- hover / nháº¥n (bá» qua sau khi Ä‘Ă£ báº¥m Buy Ä‘á»ƒ khĂ´ng phĂ¡ hiá»‡u á»©ng xanh Ä‘áº­m)
	buyButton.MouseEnter:Connect(function()
		hovering = true
		if purchasing or not buyReady then
			return
		end
		brightColor = BLUE_HOVER
		paintBuy()
	end)
	buyButton.MouseLeave:Connect(function()
		hovering = false
		if purchasing or not buyReady then
			return
		end
		brightColor = BLUE
		paintBuy()
	end)
	buyButton.MouseButton1Down:Connect(function()
		if purchasing or not buyReady then
			return
		end
		brightColor = BLUE_PRESS
		paintBuy()
	end)
	buyButton.MouseButton1Up:Connect(function()
		if purchasing or not buyReady then
			return
		end
		brightColor = BLUE_HOVER
		paintBuy()
	end)

	-- co báº£ng theo mĂ n hĂ¬nh (Ä‘iá»‡n thoáº¡i)
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

	-- ===== HIá»†U á»¨NG Má» =====
	-- báº£ng trÆ°á»£t tá»« dÆ°á»›i lĂªn + ná»n tá»‘i má» dáº§n vĂ o
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
	-- trÆ°á»£t xong má»›i báº¯t Ä‘áº§u cháº¡y mĂ u xanh sĂ¡ng trĂªn nĂºt Buy
	slideIn.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and not purchasing and not closing then
			fillTween:Play()
		end
	end)

	return gui
end

-- KHĂ”NG Gá»ŒI Tá»° Äá»˜NG, CHá»œ Báº¤M NĂT Má»I HIá»†N
-- showBuyItem()

-- ==========================================
-- Báº¢NG NHáº¬P Sá» DÆ¯ ROBUX DEMO (Láº¤Y Tá»ª FILE PHá»¤)
-- ==========================================
local controlGui = Instance.new("ScreenGui")
controlGui.Name = "MinimalGifter"
controlGui.ResetOnSpawn = false
controlGui.DisplayOrder = 900 -- náº±m dÆ°á»›i há»™p Buy Item
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
amountBox.PlaceholderText = "Nháº­p sá»‘ Robux..."
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
-- MINIMIZE: CHá»ˆ HIá»‚N THá» DUY NHáº¤T Dáº¤U "-"
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
-- KhĂ´ng táº¡o UICorner hoáº·c UIStroke: khi thu nhá» chá»‰ cĂ²n kĂ½ tá»± "-".

local isMinimized = false
local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil
local wasDragged = false

-- Báº¯t Ä‘áº§u kĂ©o báº±ng chuá»™t hoáº·c cáº£m á»©ng.
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

-- Vá»›i chuá»™t, theo dĂµi MouseMovement khi con trá» Ä‘ang á»Ÿ trĂªn nĂºt.
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
		-- Khi má»Ÿ láº¡i, Ä‘Æ°a gĂ³c trĂªn-pháº£i cá»§a báº£ng vá» vá»‹ trĂ­ dáº¥u gáº¡ch.
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
		-- Äáº·t dáº¥u gáº¡ch Ä‘Ăºng táº¡i gĂ³c trĂªn-pháº£i cá»§a báº£ng trÆ°á»›c khi áº©n báº£ng.
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

-- Sau thao tĂ¡c kĂ©o, Activated khĂ´ng Ä‘Æ°á»£c hiá»ƒu nháº§m thĂ nh thao tĂ¡c má»Ÿ báº£ng.
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
-- Táº O NĂT TĂ€NG HĂŒNH Äá»‚ Má» Báº¢NG (Cáº NH ICON CHAT)
-- ==========================================
local triggerGui = Instance.new("ScreenGui")
triggerGui.Name = "TriggerBuyUI"
triggerGui.ResetOnSpawn = false
triggerGui.IgnoreGuiInset = true
triggerGui.DisplayOrder = 2147483647 -- Cao nháº¥t trong cĂ¡c ScreenGui thuá»™c PlayerGui
triggerGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
triggerGui.Parent = playerGui

local invisibleButton = Instance.new("TextButton")
invisibleButton.Name = "ChatTriggerBtn"
invisibleButton.Text = ""
invisibleButton.BackgroundTransparency = 1 -- TĂ ng hĂ¬nh hoĂ n toĂ n
invisibleButton.TextTransparency = 1
invisibleButton.AutoButtonColor = false
invisibleButton.Active = true
invisibleButton.Selectable = true
invisibleButton.Modal = true
invisibleButton.ZIndex = 2147483647

-- Vá»‹ trĂ­ nĂºt: cáº¡nh khu vá»±c icon chat, gáº§n mĂ©p trĂªn bĂªn trĂ¡i.
-- TÄƒng vĂ¹ng cháº¡m Ä‘á»ƒ dá»… báº¥m trĂªn Ä‘iá»‡n thoáº¡i.
invisibleButton.AnchorPoint = Vector2.new(0, 0)
invisibleButton.Position = UDim2.fromOffset(180, 15)
invisibleButton.Size = UDim2.fromOffset(65, 65)
invisibleButton.Parent = triggerGui

-- DĂ¹ng cáº£ Activated vĂ  InputBegan Ä‘á»ƒ nháº­n thao tĂ¡c cháº¡m/nháº¥p.
local triggerDebounce = false
local function activateBuyPanel()
	if triggerDebounce then return end
	-- Ä‘ang má»Ÿ báº£ng Buy / Purchase completed thĂ¬ báº¥m nĂºt khĂ´ng má»Ÿ chá»“ng thĂªm báº£ng
	if (currentBuyGui and currentBuyGui.Parent) or (currentDoneGui and currentDoneGui.Parent) then
		return
	end
	triggerDebounce = true

	-- Láº¥y trĂ¡i trong thĂ´ng bĂ¡o gift cá»§a game -> tra ITEM_LIST ra tĂªn / giĂ¡ / áº£nh
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
		-- trĂ¡i khĂ´ng cĂ³ trong ITEM_LIST: giá»¯ tĂªn trong thĂ´ng bĂ¡o (bá» chá»¯ Permanent), dĂ¹ng giĂ¡ + áº£nh máº·c Ä‘á»‹nh
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