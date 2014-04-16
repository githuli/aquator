#
# GameObjects have to define the following properties:
# type: class of gameobjects this object is associated with
#
# the objects are created using the createGO method of the Game
# class. 

#
# - Each GameObject has to define the following parameters
# 'type'       [string] - group of things this GameObject belongs to (internal name)
# 'visualType' [string] - visual representation: 
#                         "Sprite", "AnimatedSprite", "ComposedSprite", "Text"

# - optional
# 'physics'    [bool]   - if true, the engine maintains a physics state (position/velocity)
#                         that is automatically applied to the visual representation

# - it should define the following methods
# 'initialize(game)'   - post initialization callback (sprites/physics have been instantiated)
# 'update()'           - internal update method


# -----------------------------------------------------------------------------
# Player Score & Energy
class PlayerScore extends GameObject
    constructor: (pos) ->
        @type = 'score'
        @name = 'score'
        @score = 0
        @visualType = "Text"
        @asset = { font: "15px Verdana", align: "left" }
        @pos = pos
        @layer = 'ui'

    initialize: (game) ->
        @addScore(0)
        @

    update: (game) ->
        @

    addScore: (value) ->
        @score += value
        @text = "Score: " + @score
        @container.setText(@text)

# health bar is a composite sprite
class PlayerHealthbar extends GameObject
    constructor: (pos) ->
        @type = 'energy'
        @name = 'energy'
        @assets = [ { asset:"hbarl", x:0, y:0 }, { asset:"hbarm", x:0, y:0 }, { asset:"hbarr", x:0, y:0 } ]
        @energy = 0
        @pos = pos
        @layer = 'ui'        

    initialize: (game) ->
        @offL = @sprites.hbarl.width
        @sprites.hbarm.position.x = @offL
        @addEnergy(100)
        @container.alpha = 0.0
        game.createEvent(new FadeInEvent(@))
        @

    update: (game) ->
        @

    addEnergy: (value) ->
        @energy += value
        @sprites.hbarm.scale.x = @energy
        @sprites.hbarr.position.x = @offL+@energy
        @

class Explosion extends GameObject
    constructor: (pos, size) ->
        @type = 'explosion'
        @asset = 'explosion1'
        @pos = pos
        @size = size
        @count = 0
    initialize: (game) ->
        @setScale(@size,@size)
        @setAnchor(0.5,0.5)
        @dpFilter = new PIXI.DisplacementFilter(game.assets.textures["wobble1"]);
        @dpFilter.scale.x = 10
        @dpFilter.scale.y = 10
        @dpFilter.offset.x = Math.random()
        @dpFilter.offset.y = Math.random() 
        @container.filters = [@dpFilter]
    update: (game) ->
        @count+=10
        @dpFilter.offset.x = @count
        @dpFilter.offset.y = @count
        @container.alpha -= 0.02
        if @container.apha < 0
            game.createEvent(new RemoveGOBEvent(game.repository, @))
