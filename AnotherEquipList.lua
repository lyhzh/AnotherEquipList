-- 创建主框架，作为角色界面的子框架
local EquipmentListFrame = CreateFrame("Frame", "EquipmentListFrame", CharacterFrame)
EquipmentListFrame:SetWidth(200)
EquipmentListFrame:SetHeight(500)
EquipmentListFrame:SetPoint("TopLeft", CharacterFrame, "TopRight", 0, 0)

-- ===== 添加背景 =====
-- 创建背景纹理
local background = EquipmentListFrame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints(EquipmentListFrame)  -- 背景填充整个框架
background:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")  -- 使用标准工具提示背景
background:SetVertexColor(0.05, 0.05, 0.05, 0.8)  -- 深灰色，半透明

-- 创建标题
local title = EquipmentListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("Top", EquipmentListFrame, "Top", 0, -10)
title:SetText("已装备物品")

-- 创建装备列表的容器
local itemsList = {}
for i = 1, 19 do  -- 1.12版本有19个装备槽位
    itemsList[i] = EquipmentListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    itemsList[i]:SetPoint("TOPLEFT", EquipmentListFrame, "TOPLEFT", 10, -30 - (i-1)*15)
    itemsList[i]:SetWidth(180)
    itemsList[i]:SetJustifyH("LEFT")
    itemsList[i]:Hide()
end

-- 获取物品颜色的函数（1.12中物品质量值：0=普通, 1=优秀, 2=精良, 3=史诗, 4=传说）
local function GetItemQualityColor(quality)
    quality = quality or 0  -- 如果质量值为nil，默认为普通
    
    local colors = {
        [0] = {r = 1.0, g = 1.0, b = 1.0},    -- 普通（白色）
        [1] = {r = 0.0, g = 1.0, b = 0.0},    -- 优秀（绿色）
        [2] = {r = 0.0, g = 0.5, b = 1.0},    -- 精良（蓝色）
        [3] = {r = 0.7, g = 0.0, b = 1.0},    -- 史诗（紫色）
        [4] = {r = 1.0, g = 0.5, b = 0.0},    -- 传说（橙色）
    }
    
    return colors[quality] or colors[0]
end

-- 显示装备列表的函数
local function UpdateEquipmentList()
    -- 隐藏所有已显示的物品
    for i = 1, 19 do
        itemsList[i]:Hide()
    end
    
    local slotIndex = 1
    local hasItems = false
    -- 遍历所有19个装备槽位
    for i = 1, 19 do
        local link = GetInventoryItemLink("player", i)

        if link then
            -- 获取物品名称
            local name = GetItemInfo(link)
            
            print(name)
        end
    end
    
    -- 如果没有找到任何有效装备，显示提示
    if not hasItems then
        itemsList[1]:SetText("没有装备物品")
        itemsList[1]:SetTextColor(1.0, 1.0, 1.0)
        itemsList[1]:Show()
    end
end

-- 事件处理
local function OnEvent(self, event)
    if event == "PLAYER_ENTERING_WORLD" or event == "UNIT_INVENTORY_CHANGED" then
        if CharacterFrame:IsVisible() then
            UpdateEquipmentList()
        end
    end
end

EquipmentListFrame:SetScript("OnEvent", OnEvent)
EquipmentListFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
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
    
    -- 然后执行我们的操作
    EquipmentListFrame:Show()
    UpdateEquipmentList()
end

-- 重写OnHide处理
local function CharacterFrameOnHide()
    -- 先调用原始OnHide函数（如果存在）
    if originalCharacterFrameOnHide then
        originalCharacterFrameOnHide()
    end
    
    -- 然后执行我们的操作
    EquipmentListFrame:Hide()
end

CharacterFrame:SetScript("OnShow", CharacterFrameOnShow)
CharacterFrame:SetScript("OnHide", CharacterFrameOnHide)
