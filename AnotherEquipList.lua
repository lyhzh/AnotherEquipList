-- 创建主框架，作为角色界面的子框架
local EquipmentListFrame = CreateFrame("Frame", "EquipmentListFrame", CharacterFrame)
EquipmentListFrame:SetWidth(230)
EquipmentListFrame:SetHeight(400)
EquipmentListFrame:SetPoint("TopLeft", CharacterFrame, "TopRight", -20, -10)

-- ===== 添加背景 =====
-- 创建背景纹理
local background = EquipmentListFrame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints(EquipmentListFrame)                         -- 背景填充整个框架
background:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background") -- 使用标准工具提示背景
background:SetVertexColor(0.05, 0.05, 0.05, 0.8)                    -- 深灰色，半透明

-- 创建标题
local title = EquipmentListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("Top", EquipmentListFrame, "Top", 0, -10)
title:SetText("已装备物品")

-- 创建装备列表的容器
local itemsList = {}

for i = 1, 19 do
    itemsList[i] = EquipmentListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    itemsList[i]:SetPoint("TOPLEFT", EquipmentListFrame, "TOPLEFT", 10, -30 - (i - 1) * 15)
    itemsList[i]:SetWidth(300)
    itemsList[i]:SetJustifyH("LEFT")
    itemsList[i]:Hide()
end

-- 质量颜色表（常量，避免每次调用都创建表）
local QUALITY_MAP = {
    [0] = { name = "粗糙", colorCode = "|cff9d9d9d", rgb = { r = 0.62, g = 0.62, b = 0.62 } },
    [1] = { name = "普通", colorCode = "|cffffffff", rgb = { r = 1, g = 1, b = 1 } },
    [2] = { name = "精良", colorCode = "|cff1eff00", rgb = { r = 0.12, g = 1, b = 0 } },
    [3] = { name = "稀有", colorCode = "|cff0070dd", rgb = { r = 0, g = 0.44, b = 0.87 } },
    [4] = { name = "史诗", colorCode = "|cffa335ee", rgb = { r = 0.64, g = 0.21, b = 0.93 } },
    [5] = { name = "传说", colorCode = "|cffff8000", rgb = { r = 1, g = 0.5, b = 0 } },
    [6] = { name = "神器", colorCode = "|cffe6cc80", rgb = { r = 0.9, g = 0.8, b = 0.5 } },
}

-- 获取物品颜色的函数
local function GetItemQualityColor(quality)
    quality = quality or 0 -- 如果质量值为nil，默认为普通
    local entry = QUALITY_MAP[quality] or QUALITY_MAP[0]
    return entry.rgb
end

---
-- 获取指定装备栏位的物品ID
-- @param itemLink (string): 由 GetInventoryItemLink() 等函数返回的完整链接。
-- @return number or nil: 如果有装备则返回物品ID，否则返回nil
---
local function GetItemIdFromLink(itemLink)
    -- 检查链接是否存在
    if itemLink then
        -- 使用 string.find 解析 ID
        -- "item:(%d+)" 会匹配 "item:" 后面的一个或多个数字，并捕获它们
        local _, _, itemIDString = string.find(itemLink, "item:(%d+)")

        if itemIDString then
            -- 将捕获到的字符串ID转换为数字并返回
            return tonumber(itemIDString)
        end
    end

    -- 如果栏位为空或解析失败，返回 nil
    return nil
end

local function DoSomethingWithItemInfo(index, itemID)
    local itemName, _, itemQuality, _, _, _, _, _, _, _, equipItemLevel = GetItemInfo(itemID)
    if itemName then
        -- 获取装备等级并格式化名称
        local displayName = itemName
        local itemLevel = equipItemLevel
        if not itemLevel and itemID and Item_Level and Item_Level[itemID] then
            itemLevel = Item_Level[itemID]
        end
        if itemLevel then
            displayName = "[" .. itemLevel .. "] " .. itemName
        end

        -- 设置物品名称（包含等级）
        itemsList[index]:SetText(displayName)

        -- 如果无法获取质量，使用默认颜色
        if not itemQuality then
            itemQuality = 0
        end

        -- 获取并应用物品质量颜色
        local color = GetItemQualityColor(itemQuality)
        itemsList[index]:SetTextColor(color.r, color.g, color.b)

        -- 显示物品
        itemsList[index]:Show()
    end
end

-- 显示装备列表的函数
local function UpdateEquipmentList()
    -- 隐藏所有已显示的物品
    for i = 1, 19 do
        itemsList[i]:Hide()
    end

    -- 排除不计入统计的槽位（4=衬衣，19=战袍）
    local excludeSlots = { [4] = true, [19] = true }

    local totalItemLevel = 0 -- 装备等级总和
    local equipCount = 0     -- 统计的装备数量（仅统计有记录的装备等级）
    local hasAnyLink = false -- 是否有任意装备

    for i = 1, 19 do
        local link = GetInventoryItemLink("player", i)
        if link then
            hasAnyLink = true

            local itemID = GetItemIdFromLink(link)

            -- 统计：仅在非排除槽位且有等级记录时计入
            if not excludeSlots[i] and itemID then
                local _, _, _, _, _, _, _, _, _, _, equipItemLevel = GetItemInfo(itemID)
                local itemLevel = equipItemLevel or (Item_Level and Item_Level[itemID])
                if itemLevel then
                    totalItemLevel = totalItemLevel + itemLevel
                    equipCount = equipCount + 1
                end
            end

            -- 尝试立即显示（若缓存命中），否则注册回调；并提供链接名的回退显示
            if itemID then
                local cachedName = GetItemInfo(itemID)
                if cachedName then
                    DoSomethingWithItemInfo(i, itemID)
                else
                    ItemInfoManager:RequestInfo(itemID, function(cbItemID)
                        DoSomethingWithItemInfo(i, cbItemID)
                    end)

                    -- 立即回退：从链接解析名称，使用默认品质颜色
                    local startPos, endPos = string.find(link, "%["), string.find(link, "%]")
                    if startPos and endPos and endPos > startPos then
                        local itemName = string.sub(link, startPos + 1, endPos - 1)
                        local displayName = itemName
                        local ilvl = Item_Level and Item_Level[itemID]
                        if ilvl then displayName = "[" .. ilvl .. "] " .. itemName end
                        itemsList[i]:SetText(displayName)
                        local color = GetItemQualityColor(0)
                        itemsList[i]:SetTextColor(color.r, color.g, color.b)
                        itemsList[i]:Show()
                    end
                end
            else
                -- 没有解析出itemID时的退化显示
                local startPos, endPos = string.find(link, "%["), string.find(link, "%]")
                if startPos and endPos and endPos > startPos then
                    local itemName = string.sub(link, startPos + 1, endPos - 1)
                    itemsList[i]:SetText(itemName)
                    local color = GetItemQualityColor(0)
                    itemsList[i]:SetTextColor(color.r, color.g, color.b)
                    itemsList[i]:Show()
                end
            end
        end
    end

    -- 更新标题，显示装备等级汇总
    local titleText = "已装备物品"
    if equipCount > 0 then
        local avgItemLevel = math.floor((totalItemLevel / equipCount) + 0.5) -- 四舍五入
        titleText = titleText .. " (总等级: " .. totalItemLevel .. ", 平均: " .. avgItemLevel .. ")"
    end
    title:SetText(titleText)

    -- 若完全没有装备，给出提示
    if not hasAnyLink then
        itemsList[1]:SetText("没有装备物品")
        local color = GetItemQualityColor(0)
        itemsList[1]:SetTextColor(color.r, color.g, color.b)
        itemsList[1]:Show()
    end
end

-- 事件处理 - 修改为1.12兼容的事件处理
local updateTimer = nil

local function OnEvent(event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        -- 延迟更新，确保数据已加载
        updateTimer = 1
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" then
        -- 统一通过计时器节流，避免频繁刷新
        if not updateTimer then updateTimer = 0.1 end
    end
end

-- 添加更新计时器处理
EquipmentListFrame:SetScript("OnUpdate", function(elapsed)
    if updateTimer then
        updateTimer = updateTimer - elapsed
        if updateTimer <= 0 then
            updateTimer = nil
            if CharacterFrame:IsVisible() then
                UpdateEquipmentList()
            end
        end
    end
end)

EquipmentListFrame:SetScript("OnEvent", OnEvent)
EquipmentListFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EquipmentListFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
EquipmentListFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

-- 初始隐藏
EquipmentListFrame:Hide()

-- ===== 1.12兼容的角色界面事件处理 =====
-- 保存原始的OnShow和OnHide函数
local originalCharacterFrameOnShow = CharacterFrame:GetScript("OnShow")
local originalCharacterFrameOnHide = CharacterFrame:GetScript("OnHide")

-- 重写OnShow处理
local function CharacterFrameOnShow()
    -- 先调用原始OnShow函数（如果存在）
    if originalCharacterFrameOnShow then
        originalCharacterFrameOnShow()
    end

    -- 更新装备列表
    UpdateEquipmentList()

    -- 显示装备列表
    EquipmentListFrame:Show()
end

-- 重写OnHide处理
local function CharacterFrameOnHide()
    -- 先调用原始OnHide函数（如果存在）
    if originalCharacterFrameOnHide then
        originalCharacterFrameOnHide()
    end

    -- 隐藏装备列表
    EquipmentListFrame:Hide()
end

CharacterFrame:SetScript("OnShow", CharacterFrameOnShow)
CharacterFrame:SetScript("OnHide", CharacterFrameOnHide)
