local Camera = {}
Camera.__index = Camera

function Camera.new()
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    self.scale = 1
    self.rotation = 0
    self.shakeDuration = 0
    self.shakeMagnitude = 0
    return self
end

function Camera:update(dt)
    -- Camera shake effect
    if self.shakeDuration > 0 then
        self.shakeDuration = self.shakeDuration - dt
        if self.shakeDuration <= 0 then
            self.shakeDuration = 0
            self.shakeMagnitude = 0
        end
    end
end

function Camera:follow(x, y, width, height)
    -- Center the camera on the target, with optional width and height for centering
    local w, h = love.graphics.getDimensions()
    self.x = x - w / 2 + (width or 0) / 2
    self.y = y - h / 2 + (height or 0) / 2
end

function Camera:shake(duration, magnitude)
    self.shakeDuration = duration
    self.shakeMagnitude = magnitude
end

function Camera:set()
    love.graphics.push()
    
    -- Apply camera translation
    local w, h = love.graphics.getDimensions()
    
    -- Add shake effect when active
    local shakeOffsetX = 0
    local shakeOffsetY = 0
    if self.shakeDuration > 0 then
        shakeOffsetX = love.math.random(-self.shakeMagnitude, self.shakeMagnitude)
        shakeOffsetY = love.math.random(-self.shakeMagnitude, self.shakeMagnitude)
    end
    
    love.graphics.translate(-self.x + shakeOffsetX, -self.y + shakeOffsetY)
    
    -- Apply other transformations
    love.graphics.scale(self.scale)
    love.graphics.rotate(self.rotation)
end

function Camera:unset()
    love.graphics.pop()
end

-- Helper function to convert screen coordinates to world coordinates
function Camera:screenToWorld(x, y)
    return x + self.x, y + self.y
end

-- Helper function to convert world coordinates to screen coordinates
function Camera:worldToScreen(x, y)
    return x - self.x, y - self.y
end

return Camera