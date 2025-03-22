function love.conf(t)
    t.title = "Platform Shooter"
    t.version = "11.4"
    t.window.width = 800
    t.window.height = 600
    t.window.vsync = 1
    t.console = true -- Enable console for debugging
    
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = true
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.window = true
end