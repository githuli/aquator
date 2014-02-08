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


# -----------------------------------------------------------------------------
# Parallax scrolling background + effects 

class BackgroundLayer extends GameObject
    # config consists of: assets=[ {x,y,sx,sy} ], useWobble=<bool>, useShiplight=<bool>
    constructor: (config) ->
        @type = 'bglayer'
        @containers = {}
        @[name] = method for name, method of config
    
    initialize : (game) ->
        # update bbox
        @bbox = new BBox2()
        for a in @assets
            @bbox.insertRect(new PIXI.Rectangle(a.x,a.y,a.w,a.h))
        filters = []
        if @useWobble
            @displacementFilter = new PIXI.DisplacementFilter(game.assets.textures["wobble1"]);
            @displacementFilter.scale.x = 20
            @displacementFilter.scale.y = 20
            filters.push(@displacementFilter)
        if @useShiplight
            @lightFilter = new PIXI.UnderwaterLightFilter(game.assets.textures["light"])
            filters.push(@lightFilter)
        @container.filters = filters if filters.length>0 
        @count = 0
        @

    update : (game) ->
        if @useWobble
            # water effect
            @displacementFilter.offset.x = @count
            @displacementFilter.offset.y = @count

        # light (dependent from ship position)
        if @useShiplight
            ship = game.repository.getNamedGObject("TheShip")
            @lightFilter.offset.x = -(ship.container.position.x/game.canvas.width)
            @lightFilter.offset.y = +(ship.container.position.y)/(game.canvas.height)-0.68
            @lightFilter.scale.x = 1.5
            @lightFilter.scale.y = 1.5
        @count += 0.5
        @

class ParallaxScrollingBackground extends GameObject
    constructor : (layers) ->
        @type = 'background'
        @layers = layers
        @

    initialize : (game) ->
        @t = 0.0
        @

    update : (game) ->
        # update background layers t=0.. links, t=1.0.. rechts
        for l in @layers
            # determine canvas position
            offset = (l.bbox.width() - game.canvas.width) * @t
            l.container.position.x = -offset
        @t += 0.0001 if @t<1.0

# -----------------------------------------------------------------------------
# ENEMIES

class EnemyFish extends GameObject
    constructor : (pos, vel) ->
        @type = 'enemy'
        @asset = 'fish{0}'
        @startframe = 0
        @endframe = 4
        @physics = true
        @initialPosition = pos
        @initialVelocity = vel
        @collideWith = 'shot'
        @HP = 50
        @score = 1337

    initialize : (game) ->
        @phys.friction = 0.1
        @container.anchor.x = 0.5
        @container.anchor.y = 0.5
        @container.scale.x = 0.25
        @container.scale.y = 0.25
        @container.animationSpeed=0.25
        @container.gotoAndPlay(0)
        @

    update : (game) ->
        # make enemy move into player direction
        ship = game.repository.getNamedGObject("TheShip")
        if ship
            @phys.force = ship.phys.pos.addC(@phys.pos.negC())
            @phys.force.normalizeTo(0.1)
        else
            @phys.force.set(0,0)

        if @phys.velocity.x<0
            @container.scale.x = 0.25
        else
            @container.scale.x = -0.25

        # introduce a 'repelling' force between fishes
        fishes = game.repository.getGObjects('enemy')
        for fish in fishes
            if fish != @
                f = @phys.pos.subC(fish.phys.pos)
                @phys.force.add( f.smulC(0.5/f.length2()) )

        # see if we are dead
        if (@HP < 0)
            game.createEvent(new RemoveGOBEvent(game.repository, @))        
            game.createSprite(new Explosion(@phys.pos.dup(), 0.15))        
        @

    collision : (game, collider) ->
        @HP -= collider.damage

        # flash fish
        @container.filters = [game.flashFilter]
        game.createEvent( new GameEvent(10, =>
                @container.filters = null
        ))        
        @

# -----------------------------------------------------------------------------
# PLAYER SHIP, WEAPONS AND PARTICLES

# The "standard" shot, just a horizontally flying projectile
class StandardShot extends GameObject
    constructor: (position, velocity) ->
        @type = "shot"
        @asset = "missile"
        @physics = true
        @initialPosition = position
        @initialVelocity = velocity
        @damage = 10
        @destroyOnCollision = true

    initialize : (game) ->
        @phys.force = new Vec2(0.3,0.0)    # standard shot is being accelerated
        @update(game)
        @

    update : (game) ->
        if @container.position.x > game.canvas.width
            game.createEvent(new RemoveGOBEvent(game.repository, @))


class PropulsionBubble extends GameObject
    constructor: (position, velocity) ->
        @type = "container"
        @asset = "bubble2"
        @physics = true
        @initialPosition = position
        @initialVelocity = velocity

    initialize : (game) ->
        @phys.friction = 0
        @container.blendMode = PIXI.blendModes.SCREEN
        @container.alpha = 1

    update : (game) ->
        @container.alpha -= 0.1
        if @container.alpha < 0
            game.createEvent(new RemoveGOBEvent(game.repository, @))

class Explosion extends GameObject
    constructor: (pos, size) ->
        @type = 'explosion'
        @asset = 'explosion1'
        @pos = pos
        @size = size
        @count = 0
    initialize: (game) ->
        @container.scale.x = @size
        @container.scale.y = @size
        @container.anchor.x = 0.5
        @container.anchor.y = 0.5
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

class PlayerShip extends GameObject
    constructor: () ->
        @type = "container"
        @asset = "ship"
        @name  = "TheShip"
        @physics = true
        @collideWith = 'enemy'

    initialize : (game) ->
        @container.anchor.x = 0.5
        @container.anchor.y = 0.5
        @container.scale.x = 0.25
        @container.scale.y = 0.25
        @container.alpha = 0       # fade in
        @phys.pos.x = 100
        @phys.pos.y = game.canvas.height/2
        @phys.friction = 0.1
        @shotctr = 0
        @count = 0
        # create health bar
        @energy = game.createComposedSprite(new PlayerHealthbar(new Vec2(150,game.canvas.height-30)))
        @

    collision : (game, collider) ->
        @energy.addEnergy(-1)
        @

    update : (game) ->
        @container.alpha += 0.05 if @container.alpha < 1.0

        @phys.force.set(0,0)
        # update forces depending on controls
        @phys.force.x -= 1 if game.keys[37] == 1              # left
        @phys.force.x += 1 if game.keys[39] == 1              # right
        @phys.force.y -= 1 if game.keys[38] == 1              # up
        @phys.force.y += 1 if game.keys[40] == 1              # down

        # clamp position
        @phys.pos.x = Tools.clampValue(@phys.pos.x, 0, game.canvas.width-@container.width)
        @phys.pos.y = Tools.clampValue(@phys.pos.y, 0, game.canvas.height-@container.height)

        # spawn bubble particles
        bubbleoff= 1
        bubbleoff = 5 if @phys.force.length2() > 0

        pos = new Vec2(@container.position.x-28, @container.position.y-9+Math.sin(@count)*bubbleoff)
        game.createSprite(new PropulsionBubble(pos, new Vec2(-2,0)))
        @count += 1

        # fire shots with space bar
        if game.keys[32]==1
            if @shotctr==0
                game.createSprite(new StandardShot(new Vec2(@container.position.x+20,@container.position.y),new Vec2(5,0) ))
                ++@shotctr
        else
           @shotctr=0

        # see if we are dead
        if @energy.energy < 0
            # remove health bar and ship
            game.createEvent(new RemoveGOBEvent(game.repository, @energy))
            game.createEvent(new RemoveGOBEvent(game.repository, @))
            # create explosion
            game.createSprite(new Explosion(@phys.pos.dup(), 0.25))
        @


#------------------------------------------------------------
# The main game class holds state and 

class Game
    constructor : () ->
        @keys = new Array(256)
        @repository = new GameObjectRepository()
        @eventhandler = new GameEventHandler()
        @assets = new AssetLibrary(
            sprites:
                'ship'    : { file: "sprites/ship.png" },
                'bubble'  : { file: "sprites/ship_tail.png"}
                'bubble2' : { file: "sprites/bubble2.png"}
                'missile' : { file: "sprites/missile.png" },
                'explosion1' : { file: "sprites/explosion1.png"}
                'bg1'     : { file: "bg/layer1.png"}
                'bg2'     : { file: "bg/layer2.png"}
                'bg1-3'   : { file: "bg/bg1-3.png"}
                'wobble1' : { file: "maps/displacementbg.png"}
                'light'   : { file: "maps/light.png"}
                'fish{0}' : { file: "sprites/fish{0}.png", startframe:0, endframe:4  }
                'verdana' : { font: "fonts/verdana.xml" }
                'getready' : { file: "fonts/getready.png" }
                'hbarl'   : { file: "ui/hbarl.gif" }
                'hbarm'   : { file: "ui/hbarm.gif" }
                'hbarr'   : { file: "ui/hbarr.gif" }
            datadir: 'res/'
        )

        @flashFilter = new PIXI.ColorMatrixFilter()
        @flashFilter.matrix =  [2.0,0,0,0,0,2.0,0,0,0,0,2.0,0,0,0,0,1]

        # initialize movement keys
        @keys[37]=0
        @keys[38]=0
        @keys[39]=0
        @keys[40]=0
        @

    createEvent : (gevent) ->
        @eventhandler.createEvent(gevent)

    createSprite : (sobj) ->
        # create container with texture from asset library
        texture = @assets.textures[sobj.asset]
        sobj.container = new PIXI.Sprite(texture)
        if sobj.hasOwnProperty('position')
            sobj.container.position.x = sobj.position.x
            sobj.container.position.y = sobj.position.y
        @repository.createGObject(sobj)
        @stage.addChild(sobj.container)
        sobj.initialize(@) if sobj.initialize
        sobj

    createComposedSprite : (sobj) ->
        # create multiple sprites in a display object container
        sobj.container = new PIXI.DisplayObjectContainer();
        sobj.sprites = {}
        for asset in sobj.assets   
           tex = @assets.textures[asset.asset]
           container = new PIXI.Sprite(tex)
           container.position.x = asset.x if asset.x
           container.position.y = asset.y if asset.y
           container.scale.x = asset.sx if asset.sx
           container.scale.y = asset.sy if asset.sy 
           sobj.sprites[asset.asset] = container
           sobj.container.addChild(container)
        @repository.createGObject(sobj)
        sobj.initialize(@) if sobj.initialize
        @stage.addChild(sobj.container)
        sobj

    createAnimatedSprite : (sobj) ->
        # create a container composed of multiple sprites
        tex = []
        for i in [sobj.startframe..sobj.endframe]
            tex.push(@assets.textures[sobj.asset.format(i)])
        sobj.container = new PIXI.MovieClip(tex)
        @repository.createGObject(sobj)
        sobj.initialize(@) if sobj.initialize
        @stage.addChild(sobj.container)
        @

    createText : (tobj) ->
        tobj.container = new PIXI.BitmapText(tobj.text, tobj.asset)
        @repository.createGObject(tobj)
        tobj.initialize(@) if tobj.initialize
        @stage.addChild(tobj.container)
        tobj

    createGObject: (gobj) ->
        @repository.createGObject(gobj)
        gobj.initialize(@) if gobj.initialize
        gobj

    update : () ->
        # global update function
        # update all game objects
        for gobj in @repository.getAllGobjects()
            gobj.updateGO(@)

        # process game events
        @eventhandler.update()

    keyDownHandler : (e) =>
        @keys[e.keyCode] = 1
        #console.log('keydown ' + e.keyIdentifier)
        @

    keyUpHandler : (e) =>
        @keys[e.keyCode] = 0
        #console.log('keyup ' + e.keyIdentifier)
        @

    mainLoop : () =>
        @update()
        ship = @repository.getNamedGObject("TheShip")
        if ship
            @stage.removeChild(ship.container)
            @stage.addChild(ship.container)
        @renderer.render(@stage)
        requestAnimFrame(@mainLoop)

    run : () =>
        # assets have been loaded
        @assets.initializeAssets()
        document.onkeydown = @keyDownHandler
        document.onkeyup = @keyUpHandler
        @stage = new PIXI.Stage(0x14184a);
        @canvas = document.getElementById('glcanvas');
        @renderer = PIXI.autoDetectRenderer(@canvas.width, @canvas.height, @canvas);

        @repository.removeGOBCB = (gobj) =>
            # add this objects score to global score if it exists
            if gobj.score
                score = @repository.getNamedGObject('score')
                if score
                    score.addScore(gobj.score)

        # initialize level

        layer1=@createComposedSprite(new BackgroundLayer(
            assets : [   { asset:"bg1-3", x:0, y:0, w:2880, h:640 } ],
            useWobble : true,
            #useShiplight : false,
        ))
        # layer2=@createComposedSprite(new BackgroundLayer(
        #     assets : [   { asset:"bg2", x:0, y:0, w:3840, h:640 } ],
        #     useWobble : true,
        #     #useShiplight : false,
        # ))
        #layer3=@createComposedSprite(new BackgroundLayer(
        #    assets : [   { asset:"bg1", x:0, y:0, w:4800, h:640 } ],
        #    #useShiplight : true,
        #))
        # [layer1,layer2,layer3]
        background = @createGObject( new ParallaxScrollingBackground([layer1]) )
        
        # initialize state per game objects
        score = @createText(new PlayerScore(new Vec2(20,@canvas.height-30)))

        @createSprite(new BlinkingSprite(new Vec2(400,300), "getready", 3))
        # spawn ship
        @createEvent( new GameEvent(5*30, => @createSprite(new PlayerShip())))        

        #@createAnimatedSprite(new EnemyFish(new Vec2(960,320), new Vec2(-1,0)))

        # randomly spawn some fishies
        for i in [1..10]
            @createEvent(new GameEvent(500+i*100, => @createAnimatedSprite(new EnemyFish(new Vec2(Math.random()*960,Math.random()*640), new Vec2(0,0))) ))

        #@createEvent( new GameEvent(200, =>
        #    @createText(new FadingText(new Vec2(300, 600), "Welcome to AQUATOR"))
        #))

        @createEvent( new GameEvent(500, =>
            @createText(new FadingText(new Vec2(2000, 600), "So Long, and Thanks For All the Fish"))
        ))

        @renderer.render(@stage)
        @mainLoop()
        @

    start : () ->
        console.log("starting up AQUATOR..")
        # load assets
        loader = new PIXI.AssetLoader(@assets.getAssetLoaderList());
        loader.onComplete = @run
        loader.load();


window.Tools = Tools
window.AquatorGame = new Game()
window.AquatorGame.start()
