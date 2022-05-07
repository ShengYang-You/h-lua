--- 无敌
---@param whichUnit userdata
---@param during number
---@param effect string
hskill.invulnerable = function(whichUnit, during, effect)
    if (whichUnit == nil) then
        return
    end
    if (during < 0) then
        during = 0.00 -- 如果设置持续时间错误，则0秒无敌
    end
    cj.UnitAddAbility(whichUnit, HL_ID.ability_invulnerable)
    if (during > 0 and effect ~= nil) then
        heffect.attach(effect, whichUnit, "origin", during)
    end
    htime.setTimeout(during, function(t)
        t.destroy()
        cj.UnitRemoveAbility(whichUnit, HL_ID.ability_invulnerable)
    end)
end

--- 范围群体无敌
---@param x number
---@param y number
---@param radius number
---@param filter function
---@param during number
---@param effect string
hskill.invulnerableRange = function(x, y, radius, filter, during, effect)
    if (x == nil or y == nil or filter == nil) then
        return
    end
    if (during < 0) then
        during = 0.00 -- 如果设置持续时间错误，则0秒无敌
    end
    local g = hgroup.createByXY(x, y, radius, filter)
    hgroup.forEach(g, function(eu)
        hunit.setInvulnerable(eu, true)
        if (during > 0 and effect ~= nil) then
            heffect.attach(effect, eu, "origin", during)
        end
    end)
    htime.setTimeout(during, function(t)
        t.destroy()
        hgroup.forEach(g, function(eu)
            hunit.setInvulnerable(eu, false)
        end)
        g = nil
    end)
end

--- 暂停效果
---@param whichUnit userdata
---@param during number
---@param pauseColor string | "'black'" | "'blue'" | "'red'" | "'green'"
hskill.pause = function(whichUnit, during, pauseColor)
    if (whichUnit == nil) then
        return
    end
    if (during < 0) then
        during = 0.01 -- 假如没有设置时间，默认打断效果
    end
    local rgba
    if (pauseColor == "black") then
        rgba = { 30, 30, 30 }
    elseif (pauseColor == "blue") then
        rgba = { 30, 30, 220 }
    elseif (pauseColor == "red") then
        rgba = { 220, 30, 30 }
    elseif (pauseColor == "green") then
        rgba = { 30, 220, 30 }
    end
    ---@type Timer
    local prevTimer = hcache.get(whichUnit, CONST_CACHE.SKILL_PAUSE_TIMER)
    local prevTimeRemaining = 0
    if (prevTimer ~= nil) then
        prevTimeRemaining = prevTimer.remain()
        if (prevTimeRemaining > 0) then
            prevTimer.destroy()
            hcache.set(whichUnit, CONST_CACHE.SKILL_PAUSE_TIMER, nil)
        else
            prevTimeRemaining = 0
        end
    end
    local colorBuff
    if (rgba) then
        colorBuff = hunit.setRGBA(whichUnit, rgba[1], rgba[2], rgba[3])
    end
    cj.SetUnitTimeScale(whichUnit, 0.00)
    cj.PauseUnit(whichUnit, true)
    hcache.set(
        whichUnit, CONST_CACHE.SKILL_PAUSE_TIMER,
        htime.setTimeout(during + prevTimeRemaining, function(t)
            t.destroy()
            cj.PauseUnit(whichUnit, false)
            if (colorBuff ~= nil) then
                hunit.delRGBA(whichUnit, colorBuff)
            end
            cj.SetUnitTimeScale(whichUnit, 1)
        end)
    )
end

--- 隐身
---@param whichUnit userdata
---@param during number
---@param transition number
---@param effect string
hskill.invisible = function(whichUnit, during, transition, effect)
    if (whichUnit == nil or during == nil or during <= 0) then
        return
    end
    if (his.dead(whichUnit)) then
        return
    end
    transition = transition or 0
    if (effect ~= nil) then
        heffect.xyz(effect, hunit.x(whichUnit), hunit.y(whichUnit), hunit.z(whichUnit), 0)
    end
    if (transition > 0) then
        htime.setTimeout(transition, function(t)
            t.destroy()
            hskill.add(whichUnit, HL_ID.ability_invisible, 1, during)
        end)
    else
        hskill.add(whichUnit, HL_ID.ability_invisible, 1, during)
    end
end

--- 现形
---@param whichUnit userdata
---@param during number
---@param transition number
---@param effect string
hskill.visible = function(whichUnit, during, transition, effect)
    if (whichUnit == nil or during == nil or during <= 0) then
        return
    end
    if (his.dead(whichUnit)) then
        return
    end
    transition = transition or 0
    if (effect ~= nil) then
        heffect.xyz(effect, hunit.x(whichUnit), hunit.y(whichUnit), hunit.z(whichUnit), 0)
    end
    if (transition > 0) then
        htime.setTimeout(transition, function(t)
            t.destroy()
            hskill.del(whichUnit, HL_ID.ability_invisible, during)
        end)
    else
        hskill.del(whichUnit, HL_ID.ability_invisible, during)
    end
end

--- 为单位添加效果只限技能类(一般使用物品技能<攻击之爪>模拟)一段时间
---@param whichUnit userdata
---@param whichAbility number
---@param abilityLevel number
---@param during number
hskill.modelEffect = function(whichUnit, whichAbility, abilityLevel, during)
    if (whichUnit ~= nil and whichAbility ~= nil and during > 0.03) then
        cj.UnitAddAbility(whichUnit, whichAbility)
        cj.UnitMakeAbilityPermanent(whichUnit, true, whichAbility)
        if (abilityLevel > 0) then
            cj.SetUnitAbilityLevel(whichUnit, whichAbility, abilityLevel)
        end
        htime.setTimeout(during, function(t)
            t.destroy()
            cj.UnitRemoveAbility(whichUnit, whichAbility)
        end)
    end
end

--- 自定义发布技能 - 对单位/对XY/对点
---@param options table
hskill.diy = function(options)
    --[[
        自定义技能 - 对单位/对XY/对点
        options = {
            whichPlayer,
            skillId,
            orderString,
            x,y 创建位置
            targetX,targetY 对XY时可选
            targetLoc, 对点时可选
            targetUnit, 对单位时可选
            during, 马甲生命周期
        }
    ]]
    if (options.whichPlayer == nil or options.skillId == nil or options.orderString == nil) then
        return
    end
    if (options.x == nil or options.y == nil) then
        return
    end
    if (options.during == nil or options.during < 2.00) then
        options.during = 2
    end
    local token = hunit.create({
        register = false,
        whichPlayer = options.whichPlayer,
        id = HL_ID.unit_token,
        x = options.x,
        y = options.y,
        facing = bj_UNIT_FACING,
        during = options.during,
    })
    cj.UnitAddAbility(token, options.skillId)
    if (options.targetUnit ~= nil) then
        cj.IssueTargetOrderById(token, options.orderId, options.targetUnit)
    elseif (options.targetX ~= nil and options.targetY ~= nil) then
        cj.IssuePointOrder(token, options.orderString, options.targetX, options.targetY)
    elseif (options.targetLoc ~= nil) then
        cj.IssuePointOrderLoc(token, options.orderString, options.targetLoc)
    else
        cj.IssueImmediateOrder(token, options.orderString)
    end
end
