#
# GameObjects have to define the following properties:
# type: class of gameobjects this object is associated with
#
# the objects are created using the create[GObjectClass] method of the Game
# class. So far two types are supported:
#
# createSprite -> will create a visible sprite that uses one texture
# createComposedSprite -> will create an object that is composed of various sprites
#                      composed sprites are stored in an Pixi DisplayObjectContainer
#                      and can therefore be associated with 

# - Each GameObject has to define the following parameters
# 'type'               - group of things this GameObject belongs to
# - it can define the following methods
# 'initialize(game)'   - initialization callback
# 'update()'           - internal update method


class StandardShot extends GameObject
    constructor: (position, velocity) ->
        @type = "sprite"
        @asset = "missile"
        @physics = true
        @initialPosition = position
        @initialVelocity = velocity

    initialize : (game) ->
        @phys.force = new Vec2(0.3,0.0) # apply 
        @update(game)
        @

    update : (game) ->
        @sprite.position.x = @phys.pos.x
        @sprite.position.y = @phys.pos.y
        if @sprite.position.x > game.canvas.width
            game.createEvent(new RemoveSpriteEvent(game.repository, @))

class PropulsionBubble extends GameObject
    constructor: (position, velocity) ->
        @type = "sprite"
        @asset = "bubble2"
        @physics = true
        @initialPosition = position
        @initialVelocity = velocity

    initialize : (game) ->
        @phys.friction = 0
        @sprite.blendMode = PIXI.blendModes.ADD
        @sprite.alpha = 1

    update : (game) ->
        @sprite.alpha -= 0.1
        if @sprite.alpha < 0
            game.createEvent(new RemoveSpriteEvent(game.repository, @))

class BackgroundLayer extends GameObject
    # config consists of: assets=[ {x,y,sx,sy} ], useWobble=<bool>, useShiplight=<bool>
    constructor: (config) ->
        @type = 'bglayer'
        @sprites = {}
        @[name] = method for name, method of config
    
    initialize : (game) ->
        # update bbox
        @bbox = new BBox2()
        for a in @assets
            @bbox.insertRect(new PIXI.Rectangle(a.x,a.y,a.w,a.h))
        console.log("background bbox:" + @bbox)
        
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
            #@sprites.background.scale.x = game.canvas.width / @sprites.background.texture.width
            #@sprites.background.scale.y = game.canvas.height / @sprites.background.texture.height
            @displacementFilter.offset.x = @count
            @displacementFilter.offset.y = @count

        # light (dependent from ship position)
        if @useShiplight
            ship = game.repository.getNamedGObject("TheShip")
            @lightFilter.offset.x = -(ship.sprite.position.x/game.canvas.width)
            @lightFilter.offset.y = +(ship.sprite.position.y)/(game.canvas.height)-0.68
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

        @t += 0.0005 if @t<1.0


class PlayerShip extends GameObject
    constructor: () ->
        @type = "sprite"
        @asset = "ship"
        @name  = "TheShip"
        @physics = true

    initialize : (game) ->
        @sprite.scale.x = 0.25
        @sprite.scale.y = 0.25
        @phys.friction = 0.1
        @bubblectr = 1
        @count = 0

    update : (game) ->

        @phys.force.set(0,0)
        # update forces depending on controls
        @phys.force.x -= 1 if game.keys[37] == 1              # left
        @phys.force.x += 1 if game.keys[39] == 1              # right
        @phys.force.y -= 1 if game.keys[38] == 1              # up
        @phys.force.y += 1 if game.keys[40] == 1              # down

        # clamp position
        @phys.pos.x = Tools.clampValue(@phys.pos.x, 0, game.canvas.width-@sprite.width)
        @phys.pos.y = Tools.clampValue(@phys.pos.y, 0, game.canvas.height-@sprite.height)

        # spawn bubble particles
        --@bubblectr
        if @bubblectr < 0
            pos = new Vec2(@sprite.position.x-8, @sprite.position.y+5+Math.sin(@count)*5)
            game.createSprite(new PropulsionBubble(pos, new Vec2(-3,0)))
            @bubblectr = 1
        @count += 1

        # fire shots with space bar
        if game.keys[32]==1
            game.createSprite(new StandardShot(new Vec2(@sprite.position.x+42,@sprite.position.y+20),new Vec2(5,0) ))
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
                bubble: { file: "sprites/ship_tail.png"}
                bubble2: { file: "sprites/bubble.png"}
                missile : { file: "sprites/missile.png" },
                enemy :   { file: "sprites/enemy.png" },
                bg1 : { file: "bg/layer1.png"}
                bg2 : { file: "bg/layer2.png"}
                bg3 : { file: "bg/layer3.png"}
                wobble1 : { file: "maps/displacementbg.png"}
                light: { file: "maps/light.png"}
            datadir:
                'res/'
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
        # create sprite with texture from asset library
        texture = @assets.textures[sobj.asset]
        sobj.sprite = new PIXI.Sprite(texture)
        if sobj.hasOwnProperty('position')
            sobj.sprite.position.x = sobj.position.x
            sobj.sprite.position.y = sobj.position.y
        @repository.createGObject(sobj)
        @stage.addChild(sobj.sprite)
        sobj.initialize(@) if sobj.initialize
        sobj

    createComposedSprite : (sobj) ->
        sobj.container = new PIXI.DisplayObjectContainer();
        sobj.sprites = {}
        for asset in sobj.assets   
           tex = @assets.textures[asset.asset]
           sprite = new PIXI.Sprite(tex)
           sprite.position.x = asset.x if asset.x
           sprite.position.y = asset.y if asset.y
           sprite.scale.x = asset.sx if asset.sx
           sprite.scale.y = asset.sy if asset.sy 
           sobj.sprites[asset.asset] = sprite
           sobj.container.addChild(sprite)
        @repository.createGObject(sobj)
        @stage.addChild(sobj.container)
        sobj.initialize(@) if sobj.initialize
        sobj

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
        ))
        layer2=@createComposedSprite(new BackgroundLayer(
            assets : [   { asset:"bg2", x:0, y:0, w:3840, h:640 } ],
            useWobble : true,
        ))
        layer3=@createComposedSprite(new BackgroundLayer(
            assets : [   { asset:"bg1", x:0, y:0, w:4800, h:640 } ],
        ))
        background = @createGObject( new ParallaxScrollingBackground([layer1,layer2,layer3]) )
        @createSprite(new PlayerShip())
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
