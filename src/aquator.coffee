# 
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
        ]
        @sprites = {}
    
    initialize : (game) ->
        @displacementFilter = new PIXI.DisplacementFilter(game.assets.textures["backgrounddm"]);
        @displacementFilter.scale.x = 30
        @displacementFilter.scale.y = 30
        @container.filters = [@displacementFilter]
        @count = 0
        @

    update : (game) ->
        @sprites.background.scale.x = game.canvas.width / @sprites.background.texture.width
        @sprites.background.scale.y = game.canvas.height / @sprites.background.texture.height
        @displacementFilter.offset.x = @count
        @displacementFilter.offset.y = @count
        @count++
        @


class PlayerShip extends GameObject
    constructor: () ->
        @type = "sprite"
        @asset ="ship"

    initialize : (game) ->
        @sprite.scale.x = 0.25
        @sprite.scale.y = 0.25

    update : (game) ->
        # ship movement is controlled by keyboard
        movement = 
            x: 0
            y: 0
        movement.x -= 4.0 if game.keys[37]==1
        movement.y -= 4.0 if game.keys[38]==1
        movement.x += 4.0 if game.keys[39]==1
        movement.y += 4.0 if game.keys[40]==1
        @sprite.position.x = Tools.clampValue(@sprite.position.x+movement.x,0,game.canvas.width-@sprite.width)
        @sprite.position.y = Tools.clampValue(@sprite.position.y+movement.y,0,game.canvas.height-@sprite.height)
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
            datadir:
                'res/sprites/'
        )

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
