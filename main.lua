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
end

-- Update game logic
function love.update(dt)
    if gameState == "paused" then return end
    
    -- Store player position in global variables for enemies to target
    _G.playerX = player.x
    _G.playerY = player.y
    
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
    
    -- Check game over conditions
    if player.health <= 0 then
        gameState = "gameover"
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
    
    if key == "r" then
        level:generate()  -- Regenerate level with a new random layout
        player:respawn(level)
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
    
    -- Display score
    love.graphics.print("Score: " .. score, 20, 50)
    
    -- Display controls hint
    love.graphics.print("WASD/Arrows: Move | Space: Jump | Shift: Shoot | R: New Level | Esc: Pause", 20, love.graphics.getHeight() - 30)
    
    -- Game state overlays
    if gameState == "paused" then
        drawCenteredText("PAUSED", "Press ESC to resume")
    elseif gameState == "gameover" then
        drawCenteredText("GAME OVER", "Press ENTER to restart")
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
    level:generate()
    player:respawn(level)
    gameState = "playing"
end