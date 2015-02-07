
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


class Explosion2 extends GameObject
    constructor: (pos, size) ->
        @type = 'explosion'
        @asset = 'explosion2{0}'
        @pos = pos
        @size = size
        @count = 0
    initialize: (game) ->
        @setScale(@size,@size)
        @setAnchor(0.5,0.5)
        @container.loop = false
        @container.animationSpeed = 1.0
        @container.gotoAndPlay(0)

    update: (game) ->
        if ++@count > 69
            game.createEvent(new RemoveGOBEvent(game.repository, @))

class Explosion4 extends GameObject
    constructor: (pos, size) ->
        @type = 'explosion'
        @asset = 'explosion4{0}'
        @pos = pos
        @size = size
        @count = 0
    initialize: (game) ->
        @setScale(@size,@size)
        @setAnchor(0.5,0.5)
        @container.loop = false
        @container.animationSpeed = 1.0
        @container.gotoAndPlay(0)

    update: (game) ->
        if ++@count > 54
            game.createEvent(new RemoveGOBEvent(game.repository, @))


class FadingSprite extends GameObject
    constructor: (position) ->
        @type = "sprite"
        @pos  = position
        @fadetimer = 60
        @displaytimer = 5*60

    initialize : (game) ->
        @container.alpha = 0.0
        @count = @fadetimer
        @state = 0             # 0: fadein, 1: display, 2:fadeout
        @

    update : (game) ->
        --@count
        switch @state
            when 0     # fade in
                if (@count<0)
                    @state=1
                    @count=@displaytimer
                else
                    @container.alpha = 1.0 - @count/@fadetimer
            when 1
                if (@count<0)
                    @state=2
                    @count=@fadetimer
            when 2
                if (@count<0)
                    game.createEvent(new RemoveGOBEvent(game.repository, @))
                else
                    @container.alpha = @count/@fadetimer


# text that fades in at a specific position, displays for a while and fades out
class FadingText extends FadingSprite 
    constructor: (position, text) ->
        super(position)
        @type = "text"
        @visualType = "Text"
        @asset = { font: "20px Verdana", align: "center" }
        @text = text
        @pos = position
        @fadetimer = 60
        @displaytimer = 7*text.length


class FadingImage extends FadingSprite
    constructor: (position, asset) ->
        super(position)
        @asset = asset

    initialize: (game) ->
        super(game)
        @setAnchor(0.5,0.5)
        @wobble = new PIXI.WobbleFilter()
        @wobble.scale.x = 0.001
        @wobble.scale.y = 0.001
        @container.filters = [ @wobble ]
        @wobbleoff = new Vec2(0.1,0.0)
        @wobbleinc = new Vec2(0.01,0.05)

    update: (game) ->
        @wobble.offset = @wobbleoff
        @wobbleoff.add(@wobbleinc)        
        super(game)

# a "normal" sprite that blinks a given amount of times and then disappears
class BlinkingSprite extends GameObject
    constructor : (pos, asset="getready", count=3) ->
        @type = "blink"
        @asset = asset
        @count = count
        @pos = pos

    initialize : (game) ->
        for i in [0..(@count-1)]
            game.createEvent(new GameEvent(i*30, => @container.alpha = 0.0 ))
            game.createEvent(new GameEvent(i*30+15, => @container.alpha = 1.0 ))
        game.createEvent(new RemoveGOBEvent(game.repository, @, @count*30))
        @

    update : (game) ->
        @
