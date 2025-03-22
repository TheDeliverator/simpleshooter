local Player = {}
Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.width = 32
    self.height = 48
    self.speed = 200
    self.jumpPower = 900     -- Adjusted to a more reasonable value (was 1800)
    self.gravity = 12
    self.velocityX = 0
    self.velocityY = 0
    self.onGround = false
    self.health = 100
    self.facingRight = true
    self.shootCooldown = 0
    self.shootCooldownMax = 0.2 -- seconds between shots
    self.color = {1, 1, 1} -- White color for the player
    self.canDoubleJump = false  -- Track if player can double jump
    self.jumpCount = 0          -- Track number of jumps
    return self
end

function Player:update(dt, level)
    -- Handle shooting cooldown
    if self.shootCooldown > 0 then
        self.shootCooldown = self.shootCooldown - dt
    end
    
    -- Reset horizontal velocity
    self.velocityX = 0
    
    -- Handle horizontal movement
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        self.velocityX = -self.speed
        self.facingRight = false
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        self.velocityX = self.speed
        self.facingRight = true
    end
    
    -- Apply gravity
    self.velocityY = self.velocityY + self.gravity
    
    -- Move player
    self.x = self.x + self.velocityX * dt
    self.y = self.y + self.velocityY * dt
    
    -- Check if player is on the ground
    self.onGround = false
    for _, platform in ipairs(level.platforms) do
        if self:checkPlatformCollision(platform) then
            self.onGround = true
            self.velocityY = 0
            self.y = platform.y - self.height
            self.jumpCount = 0  -- Reset jump count when on ground
            self.canDoubleJump = false
        end
    end
    
    -- Check boundaries
    if self.x < 0 then
        self.x = 0
    elseif self.x > level.width - self.width then
        self.x = level.width - self.width
    end
    
    -- Death by falling
    if self.y > level.height + 200 then
        self:respawn(level)
    end
end

function Player:jump()
    if self.onGround then
        self.velocityY = -self.jumpPower
        self.onGround = false
        self.jumpCount = 1
        self.canDoubleJump = true
    elseif self.canDoubleJump and self.jumpCount == 1 then
        self.velocityY = -self.jumpPower * 0.8  -- Slightly weaker double jump
        self.jumpCount = 2
        self.canDoubleJump = false
    end
end

function Player:shoot(bullets)
    if self.shootCooldown <= 0 then
        local bulletX = self.x + self.width/2
        local bulletY = self.y + self.height/2
        local direction = self.facingRight and 1 or -1
        
        table.insert(bullets, {
            x = bulletX,
            y = bulletY,
            speed = 500,
            direction = direction,
            width = 8,
            height = 4,
            color = {1, 0.8, 0}
        })
        
        self.shootCooldown = self.shootCooldownMax
    end
end

function Player:draw()
    -- Draw player
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw eyes to show facing direction
    love.graphics.setColor(0, 0, 0)
    if self.facingRight then
        love.graphics.rectangle("fill", self.x + self.width - 12, self.y + 10, 6, 6)
    else
        love.graphics.rectangle("fill", self.x + 6, self.y + 10, 6, 6)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function Player:checkPlatformCollision(platform)
    return self.x < platform.x + platform.width and
           self.x + self.width > platform.x and
           self.y + self.height <= platform.y + 5 and
           self.y + self.height + self.velocityY * love.timer.getDelta() >= platform.y
end

function Player:takeDamage(amount)
    self.health = self.health - amount
    if self.health <= 0 then
        -- Access the global level variable from main.lua
        local level = _G.currentLevel
        if level then
            self:respawn(level)
        else
            -- Fallback if level is not accessible
            self.health = 100
            self.velocityX = 0
            self.velocityY = 0
        end
    end
end

function Player:respawn(level)
    self.health = 100
    self.x = level.spawnX
    self.y = level.spawnY
    self.velocityX = 0
    self.velocityY = 0
end

return Player