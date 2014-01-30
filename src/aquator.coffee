#
# GameObjects have to define the following properties:
# type: class of gameobjects this object is associated with
#
# the objects are created using the create[GObjectClass] method of the Game
# class. So far two types are supported:
#
# createSprite -> will create a visible container that uses one texture
# createComposedSprite -> will create an object that is composed of various sprites
#                      composed sprites are stored in an Pixi DisplayObjectContainer
#                      and can therefore be associated with 

# - Each GameObject has to define the following parameters
# 'type'               - group of things this GameObject belongs to
# - it can define the following methods
# 'initialize(game)'   - initialization callback
# 'update()'           - internal update method

# text that fades in at a specific position, displays for a while and fades out
class FadingText extends GameObject 
    constructor: (position, text) ->
        @type = "text"
        @asset = { font: "20px Verdana", align: "center" }
        @text = text
        @pos = position
        @fadetimer = 60
        @displaytimer = 7*text.length

    initialize : (game) ->
        @container.alpha = 0.0
        @container.position.x = @pos.x
        @container.position.y = @pos.y
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
                    game.createEvent(new RemoveSpriteEvent(game.repository, @))
                else
                    @container.alpha = @count/@fadetimer


class StandardShot extends GameObject
    constructor: (position, velocity) ->
        @type = "container"
        @asset = "missile"
        @physics = true
        @initialPosition = position
        @initialVelocity = velocity

    initialize : (game) ->
        @phys.force = new Vec2(0.3,0.0) # apply 
        @update(game)
        @

    update : (game) ->
        @container.position.x = @phys.pos.x
        @container.position.y = @phys.pos.y
        if @container.position.x > game.canvas.width
            game.createEvent(new RemoveSpriteEvent(game.repository, @))

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
            @displacementFilter.scale.x = 30
            @displacementFilter.scale.y = 30
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
            #@containers.background.scale.x = game.canvas.width / @containers.background.texture.width
            #@containers.background.scale.y = game.canvas.height / @containers.background.texture.height
            @displacementFilter.offset.x = @count
            @displacementFilter.offset.y = @count

        # light (dependent from ship position)
        if @useShiplight
            ship = game.repository.getNamedGObject("TheShip")
            @lightFilter.offset.x = -(ship.container.position.x/game.canvas.width)
            @lightFilter.offset.y = +(ship.container.position.y)/(game.canvas.height)-0.68
            @lightFilter.scale.x = 1.5
            @lightFilter.scale.y = 1.5
        @count++
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

class EnemyFish extends GameObject
    constructor : (pos, vel) ->
        @type = 'enemy'
        @asset = 'fish{0}'
        @startframe = 0
        @endframe = 4
        @physics = true
        @initialPosition = pos
        @initialVelocity = vel

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
        @phys.force = ship.phys.pos.addC(@phys.pos.negC())
        @phys.force.normalizeTo(0.1)

        if @phys.velocity.x<0
            @container.scale.x = 0.25
        else
            @container.scale.x = -0.25

        @

class PropulsionBubble extends GameObject
    constructor: (position, velocity) ->
        @type = "container"
        @asset = "bubble2"
        @physics = true
        @initialPosition = position
        @initialVelocity = velocity

    initialize : (game) ->
        @phys.friction = 0
        @container.blendMode = PIXI.blendModes.ADD
        @container.alpha = 1

    update : (game) ->
        @container.alpha -= 0.1
        if @container.alpha < 0
            game.createEvent(new RemoveSpriteEvent(game.repository, @))

class PlayerShip extends GameObject
    constructor: () ->
        @type = "container"
        @asset = "ship"
        @name  = "TheShip"
        @physics = true

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
                ship :    { file: "sprites/ship.png" },
                bubble:   { file: "sprites/ship_tail.png"}
                bubble2:  { file: "sprites/bubble2.png"}
                missile : { file: "sprites/missile.png" },
                enemy :   { file: "sprites/enemy.png" },
                bg1 :     { file: "bg/layer1.png"}
                bg2 :     { file: "bg/layer2.png"}
                bg3 :     { file: "bg/layer3.png"}
                wobble1 : { file: "maps/displacementbg.png"}
                'light':    { file: "maps/light.png"}
                'fish{0}': { file: "sprites/fish{0}.png", startframe:0, endframe:4  }
                'verdana' : { font: "fonts/verdana.xml" }
            datadir: 'res/'
        )

        # initialize movement keys
        @keys[37]=0
        @keys[38]=0
        @keys[39]=0
        @keys[40]=0
        @keys

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
        layer1=@createComposedSprite(new BackgroundLayer(
            assets : [   { asset:"bg3", x:0, y:0, w:2880, h:640 } ],
            useWobble : true,
            #useShiplight : false,
        ))
        layer2=@createComposedSprite(new BackgroundLayer(
            assets : [   { asset:"bg2", x:0, y:0, w:3840, h:640 } ],
            useWobble : true,
            #useShiplight : false,
        ))
        layer3=@createComposedSprite(new BackgroundLayer(
            assets : [   { asset:"bg1", x:0, y:0, w:4800, h:640 } ],
            #useShiplight : true,
        ))
        background = @createGObject( new ParallaxScrollingBackground([layer1,layer2,layer3]) )
        @createSprite(new PlayerShip())
        @createAnimatedSprite(new EnemyFish(new Vec2(960,320), new Vec2(-1,0)))

        # randomly spawn some fishies
        for i in [1..10]
            @createEvent(new GameEvent(i*100, => @createAnimatedSprite(new EnemyFish(new Vec2(Math.random()*960,Math.random()*640), new Vec2(0,0))) ))

        @createEvent( new GameEvent(60, =>
            @createText(new FadingText(new Vec2(300, 600), "Welcome to AQUATOR"))
        ))


        @createEvent( new GameEvent(500, =>
            @createText(new FadingText(new Vec2(200, 600), "So Long, and Thanks For All the Fish"))
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
