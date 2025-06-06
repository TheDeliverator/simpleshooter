local Level = {}
Level.__index = Level

function Level.new(width, height)
    local self = setmetatable({}, Level)
    self.width = width or 5000
    self.height = height or 800
    self.platforms = {}
    self.enemies = {}
    self.spawnX = 100
    self.spawnY = 100
    self:generate()
    return self
end

function Level:generate()
    -- Clear existing platforms
    self.platforms = {}
    self.enemies = {}
    
    -- Generate ground platform at the bottom
    table.insert(self.platforms, {x = 0, y = 500, width = 400, height = 20})
    
    -- Set spawn point
    self.spawnX = 200
    self.spawnY = 400
    
    -- Generate platforms
    local x = 450 -- Start position after initial platform
    local minY = 300   -- Increased minimum height (was 200)
    local maxY = 500
    local minWidth = 100  -- Increased minimum width (was 70)
    local maxWidth = 300
    local minGap = 30     -- Reduced minimum gap (was 50)
    local maxGap = 120    -- Reduced maximum gap (was 200)
    local lastY = 500     -- Track last platform Y to avoid extreme height changes
    
    while x < self.width do
        local platformWidth = math.random(minWidth, maxWidth)
        -- Make Y closer to previous platform's height to avoid extreme jumps
        local platformY = math.max(minY, math.min(maxY, lastY + math.random(-80, 80)))
        lastY = platformY
        
        table.insert(self.platforms, {
            x = x,
            y = platformY,
            width = platformWidth,
            height = 20
        })
        
        -- Randomly place enemies on platforms that are wide enough
        if platformWidth > 100 and math.random() < 0.6 then
            local enemyX = x + math.random(20, platformWidth - 20)
            local enemyY = platformY - 30
            table.insert(self.enemies, {
                x = enemyX,
                y = enemyY,
                width = 30,
                height = 30,
                health = 30,
                speed = 50,
                direction = math.random(0, 1) * 2 - 1, -- -1 or 1
                platformStart = x,
                platformEnd = x + platformWidth,
                color = {1, 0, 0},
                shootCooldown = 0,
                shootRate = 4 -- Increased from 2 to 4 seconds between shots (50% slower)
            })
        end
        
        -- Add occasional small intermediate platforms for difficult jumps
        if math.random() < 0.3 and maxGap > 80 then
            local midX = x + platformWidth + math.random(20, 40)
            local midY = math.random(platformY - 50, platformY + 50)
            
            table.insert(self.platforms, {
                x = midX,
                y = midY,
                width = math.random(50, 80),
                height = 20
            })
        end
        
        -- Move to the next platform position
        x = x + platformWidth + math.random(minGap, maxGap)
    end
end

function Level:update(dt, bullets, enemyBullets)
    -- Get camera position from global variables (set these in main.lua)
    local cameraX = _G.cameraX or 0
    local cameraY = _G.cameraY or 0
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Update enemies
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        
        -- Move enemy back and forth on platform
        enemy.x = enemy.x + enemy.speed * enemy.direction * dt
        
        -- Check if enemy reached platform edge and change direction
        if enemy.x <= enemy.platformStart or enemy.x + enemy.width >= enemy.platformEnd then
            enemy.direction = -enemy.direction
        end
        
        -- Check if enemy is visible on screen
        local isVisible = enemy.x + enemy.width >= cameraX and 
                         enemy.x <= cameraX + screenWidth and
                         enemy.y + enemy.height >= cameraY and
                         enemy.y <= cameraY + screenHeight
        
        -- Enemy shooting only when visible
        enemy.shootCooldown = enemy.shootCooldown - dt
        if isVisible and enemy.shootCooldown <= 0 then
            -- Calculate direction towards player
            local direction = 1
            if _G.playerX then
                direction = (_G.playerX > enemy.x) and 1 or -1
            end
            
            table.insert(enemyBullets, {
                x = enemy.x + enemy.width/2,
                y = enemy.y + enemy.height/2,
                speed = 300,
                direction = direction,
                width = 8,
                height = 4,
                color = {1, 0, 0}
            })
            
            enemy.shootCooldown = enemy.shootRate
        end
        
        -- Check bullet collisions with enemy
        for j = #bullets, 1, -1 do
            local bullet = bullets[j]
            if self:checkCollision(bullet, enemy) then
                enemy.health = enemy.health - 10
                table.remove(bullets, j)
                
                if enemy.health <= 0 then
                    table.remove(self.enemies, i)
                    -- Add score when enemy is killed
                    if _G.addScore then
                        _G.addScore(100)  -- 100 points per enemy kill
                    end
                    break
                end
            end
        end
    end
end

function Level:draw()
    -- Draw platforms
    love.graphics.setColor(0.5, 0.5, 0.5)
    for _, platform in ipairs(self.platforms) do
        love.graphics.rectangle("fill", platform.x, platform.y, platform.width, platform.height)
    end
    
    -- Draw enemies
    for _, enemy in ipairs(self.enemies) do
        love.graphics.setColor(enemy.color)
        love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)
    end
    
    love.graphics.setColor(1, 1, 1)
end

function Level:checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

return Level