-- Import required modules
local Player = require('player')
local Level = require('level')
local Camera = require('camera')

-- Game state
local player
local level
local camera
local bullets = {}
local enemyBullets = {}
local gameState = "playing"  -- playing, paused, gameover
local score = 0
local levelCount = 1        -- Track number of levels completed
local lives = 3           -- Initial number of lives
local maxLives = 3        -- Maximum number of lives

-- Initialize the game
function love.load()
    -- Seed the random number generator
    math.randomseed(os.time())
    
    -- Create level with random generation
    level = Level.new(10000, 1000)
    
    -- Store level in global variable for access from player module
    _G.currentLevel = level
    
    -- Create player at spawn position
    player = Player.new(level.spawnX, level.spawnY)
    
    -- Create camera
    camera = Camera.new()
    
    -- Make score function available globally
    _G.addScore = function(points)
        score = score + points
    end

    -- Make lives management available globally
    _G.lives = lives
    _G.updateLives = function(newLives)
        lives = newLives
        _G.lives = newLives
        if lives <= 0 then
            gameState = "gameover"
        end
    end
end

-- Update game logic
function love.update(dt)
    if gameState == "paused" then return end
    
    -- Store player position in global variables for enemies to target
    _G.playerX = player.x
    _G.playerY = player.y
    
    -- Store camera position in global variables for enemy visibility checks
    _G.cameraX = camera.x
    _G.cameraY = camera.y
    
    -- Check for Shift key to shoot
    if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
        player:shoot(bullets)
    end
    
    -- Update player
    player:update(dt, level)
    
    -- Update level and enemies
    level:update(dt, bullets, enemyBullets)
    
    -- Update bullets
    updateBullets(bullets, dt)
    updateBullets(enemyBullets, dt)
    
    -- Check if enemy bullets hit player
    for i = #enemyBullets, 1, -1 do
        local bullet = enemyBullets[i]
        if checkCollision(bullet, player) then
            player:takeDamage(10)
            table.remove(enemyBullets, i)
            camera:shake(0.2, 5)  -- Shake effect on hit
        end
    end
    
    -- Update camera to follow player
    camera:follow(player.x, player.y, player.width, player.height)
    camera:update(dt)
    
    -- Keep global lives in sync
    _G.lives = lives
    
    -- Update game state based on lives
    if lives <= 0 then
        gameState = "gameover"
    end
    
    -- Check for level completion
    if player.x >= level.width - player.width - 50 then
        -- Award bonus points based on current level
        local levelBonus = 1000 * levelCount
        score = score + levelBonus
        levelCount = levelCount + 1
        
        -- Generate new level
        level:generate()
        player:respawn(level)
        
        -- Show level completion message
        _G.levelCompletionMessage = {
            text = string.format("Level %d Complete! Bonus: %d", levelCount - 1, levelBonus),
            timer = 3  -- Show for 3 seconds
        }
    end
    
    -- Update level completion message timer
    if _G.levelCompletionMessage and _G.levelCompletionMessage.timer > 0 then
        _G.levelCompletionMessage.timer = _G.levelCompletionMessage.timer - dt
        if _G.levelCompletionMessage.timer <= 0 then
            _G.levelCompletionMessage = nil
        end
    end
end

-- Handle player input
function love.keypressed(key)
    if key == "escape" then
        if gameState == "playing" then
            gameState = "paused"
        elseif gameState == "paused" then
            gameState = "playing"
        end
    end
    
    if gameState == "gameover" then
        if key == "return" then
            resetGame()
        end
        return
    end
    
    if key == "space" or key == "up" or key == "w" then
        player:jump()
    end
end

-- Update all bullets
function updateBullets(bulletsList, dt)
    for i = #bulletsList, 1, -1 do
        local bullet = bulletsList[i]
        bullet.x = bullet.x + bullet.speed * bullet.direction * dt
        
        -- Remove bullets that go off screen
        if bullet.x < -100 or bullet.x > level.width + 100 then
            table.remove(bulletsList, i)
        end
    end
end

-- Helper function to check collision
function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

-- Draw the game
function love.draw()
    -- Apply camera transformations
    camera:set()
    
    -- Draw level (platforms and enemies)
    level:draw()
    
    -- Draw player
    player:draw()
    
    -- Draw bullets
    drawBullets(bullets, {1, 0.8, 0})  -- Player bullets
    drawBullets(enemyBullets, {1, 0, 0})  -- Enemy bullets
    
    -- Reset camera
    camera:unset()
    
    -- Draw UI elements (not affected by camera)
    drawUI()
end

-- Draw all bullets
function drawBullets(bulletsList, color)
    love.graphics.setColor(color)
    for _, bullet in ipairs(bulletsList) do
        love.graphics.rectangle("fill", bullet.x, bullet.y, bullet.width, bullet.height)
    end
    love.graphics.setColor(1, 1, 1)  -- Reset color
end

-- Draw UI elements
function drawUI()
    -- Display health bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 20, 20, 200, 20)
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 20, 20, player.health * 2, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Health", 25, 22)
    
    -- Display score and level
    love.graphics.print("Score: " .. score, 20, 50)
    love.graphics.print("Level: " .. levelCount, 20, 80)
    
    -- Display lives (never show negative)
    love.graphics.print("Lives: " .. math.max(0, lives), 20, 110)
    
    -- Display controls hint (removed R key)
    love.graphics.print("WASD/Arrows: Move | Space: Jump | Shift: Shoot | Esc: Pause", 20, love.graphics.getHeight() - 30)
    
    -- Game state overlays
    if gameState == "paused" then
        drawCenteredText("PAUSED", "Press ESC to resume")
    elseif gameState == "gameover" then
        drawCenteredText("GAME OVER", "Press ENTER to restart")
    end
    
    -- Display level completion message
    if _G.levelCompletionMessage and _G.levelCompletionMessage.timer > 0 then
        local text = _G.levelCompletionMessage.text
        local w = love.graphics.getWidth()
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(text)
        
        -- Draw with a shadow effect
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.print(text, w/2 - textWidth/2 + 2, 102)
        love.graphics.setColor(1, 1, 0) -- Yellow text
        love.graphics.print(text, w/2 - textWidth/2, 100)
        love.graphics.setColor(1, 1, 1) -- Reset color
    end
end

-- Helper function to draw centered text
function drawCenteredText(mainText, subText)
    local w, h = love.graphics.getDimensions()
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.getFont()
    local mainWidth = font:getWidth(mainText)
    local subWidth = font:getWidth(subText)
    
    love.graphics.print(mainText, w/2 - mainWidth/2, h/2 - 30)
    love.graphics.print(subText, w/2 - subWidth/2, h/2)
    
    love.graphics.setColor(1, 1, 1)
end

-- Reset the game
function resetGame()
    bullets = {}
    enemyBullets = {}
    score = 0
    lives = maxLives
    level:generate()
    player:respawn(level)
    gameState = "playing"
    levelCount = 1
end