-- 物品信息请求管理器（独立文件）

-- 全局表，便于其它文件直接使用
ItemInfoManager = ItemInfoManager or {}

-- 用来存储回调函数。键是itemID，值是成功后要执行的函数。
ItemInfoManager.pendingRequests = ItemInfoManager.pendingRequests or {}

-- 监听 GET_ITEM_INFO_RECEIVED 事件
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")

eventFrame:SetScript("OnEvent", function(self, event, itemID, success)
    if event == "GET_ITEM_INFO_RECEIVED" and success and ItemInfoManager.pendingRequests[itemID] then
        local callback = ItemInfoManager.pendingRequests[itemID]
        ItemInfoManager.pendingRequests[itemID] = nil
        callback(itemID)
    end
end)

---
-- 公开的请求函数
-- @param itemID (number): 你要查询的物品ID
-- @param callback (function): 获取成功后要执行的函数，它会接收itemID作为参数
---
function ItemInfoManager:RequestInfo(itemID, callback)
    if not itemID or type(itemID) ~= "number" then
        -- 可选：打印调试信息
        -- print("请求错误: 无效的 itemID")
        return
    end

    -- 尝试直接获取信息（命中缓存）
    local itemName = GetItemInfo(itemID)
    if itemName then
        callback(itemID)
    else
        -- 未命中缓存时挂起
        self.pendingRequests[itemID] = callback
    end
end
