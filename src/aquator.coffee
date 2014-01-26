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

class StandardShot extends GameObject
    constructor: (x, y) ->
        @type = "sprite"
        @asset = "missile"
        @position = 
          x: x
          y: y

    initialize : (game) ->
        @

    update : (game) ->
        @sprite.position.x += 15
        if @sprite.position.x > game.canvas.width
            game.createEvent(
                new RemoveSpriteEvent(game.repository, @)
            )

class Background extends GameObject
    constructor: () ->
        @type = "background"
        @assets = [ 
            { asset:"background", x:0, y:0 },
            { asset:"bg1", x:200, y:500, sx:0.3, sy:0.3 },
            { asset:"bg2", x:410, y:470, sx:0.35, sy:0.35 },
            { asset:"bg3", x:800, y:500, sx:0.3, sy:0.3 },
            { asset:"bg1", x:630, y:530, sx:0.2, sy:0.2 },
            { asset:"bg3", x:42, y:530, sx:0.25, sy:0.25 },
        ]
        @sprites = {}
    
    initialize : (game) ->
        @displacementFilter = new PIXI.DisplacementFilter(game.assets.textures["backgrounddm"]);
        @displacementFilter.scale.x = 30
        @displacementFilter.scale.y = 30

        @lightFilter = new PIXI.UnderwaterLightFilter(game.assets.textures["light"])
        @

        @container.filters = [@displacementFilter,@lightFilter]
        @count = 0
        @

    update : (game) ->
        # water effect
        @sprites.background.scale.x = game.canvas.width / @sprites.background.texture.width
        @sprites.background.scale.y = game.canvas.height / @sprites.background.texture.height
        @displacementFilter.offset.x = @count
        @displacementFilter.offset.y = @count
        @count++

        # light (dependent from ship position)
        ship = game.repository.getNamedGObject("TheShip")
        @lightFilter.offset.x = -(ship.sprite.position.x/game.canvas.width)
        @lightFilter.offset.y = +(ship.sprite.position.y)/(game.canvas.height)-0.68
        @lightFilter.scale.x = 1.5
        @lightFilter.scale.y = 1.5

        @


class PlayerShip extends GameObject
    constructor: () ->
        @type = "sprite"
        @asset = "ship"
        @name  = "TheShip"
        @movement =
            vx: 0.0
            vy: 0.0
            ax: 0.0
            ay: 0.0
            tx: 0.5    # configure thrust x here
            ty: 0.5    # configure thrust y here
            decay: 1.5

    initialize : (game) ->
        @sprite.scale.x = 0.25
        @sprite.scale.y = 0.25

    update : (game) ->

        # ship movement is controlled by keyboard, update acceleration
        if game.keys[37] == 1              # left
            @movement.ax -= @movement.tx
        if game.keys[39] == 1              # right
            @movement.ax += @movement.tx
        if game.keys[37]==0 and game.keys[39]==0
            @movement.ax /= @movement.decay # decay

        if game.keys[38] == 1              # up
            @movement.ay -= @movement.ty
        if game.keys[40] == 1              # down
            @movement.ay += @movement.ty
        if game.keys[38]==0 and game.keys[40]==0
            @movement.ay /= @movement.decay        # decay

        if Math.abs(@movement.ax) < 0.1 
            @movement.vx /= @movement.decay
            @movement.ax = 0

        if Math.abs(@movement.ay) < 0.1            
            @movement.vy /= @movement.decay
            @movement.ay = 0

        @movement.ax = Tools.clampValue(@movement.ax, -3, 3)
        @movement.ay = Tools.clampValue(@movement.ay, -3, 3)

        # we assume that update is called for a timestep dt=1
        @movement.vx = @movement.vx + @movement.ax
        @movement.vy = @movement.vy + @movement.ay

        @movement.vx = Tools.clampValue(@movement.vx, -5, 5)
        @movement.vy = Tools.clampValue(@movement.vy, -5, 5)

        @sprite.position.x = Tools.clampValue(@sprite.position.x+@movement.vx,0,game.canvas.width-@sprite.width)
        @sprite.position.y = Tools.clampValue(@sprite.position.y+@movement.vy,0,game.canvas.height-@sprite.height)
        # fire shots with space bar
        if game.keys[32]==1
            game.createSprite(new StandardShot(@sprite.position.x+42,@sprite.position.y+20))
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
                ship :    { file: "ship.png" },
                missile : { file: "missile.png" },
                enemy :   { file: "enemy.png" },
                explosion : { file: "plop.png" },
                background : { file: "background.png"}
                backgrounddm : { file: "displacementbg.png"}
                bg1 : { file: "bg_1.png"}
                bg2 : { file: "bg_2.png"}
                bg3 : { file: "bg_3.png"}
                light: { file: "light.png"}
            datadir:
                'res/sprites/'
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

    update : () ->
        # global update function
        # update all game objects
        for gobj in @repository.getAllGobjects()
            gobj.update(@)

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

    start : () ->
        console.log("starting up AQUATOR..")
        document.onkeydown = @keyDownHandler
        document.onkeyup = @keyUpHandler
        @stage = new PIXI.Stage(0x0E111E);
        @canvas = document.getElementById('glcanvas');
        @renderer = PIXI.autoDetectRenderer(@canvas.width, @canvas.height, @canvas);
        @createComposedSprite(new Background())
        @createSprite(new PlayerShip())
        @mainLoop()
        @

window.Tools = Tools
window.AquatorGame = new Game()
window.AquatorGame.start()
