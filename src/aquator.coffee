class PlayerShip extends SpriteObject
    defaults:
        asset: "ship"

    update : (game) ->
        # ship movement is controlled by keyboard
        movement = 
            x: 0
            y: 0
        movement.x -= 4.0 if game.keys[37]==1
        movement.y -= 4.0 if game.keys[38]==1
        movement.x += 4.0 if game.keys[39]==1
        movement.y += 4.0 if game.keys[40]==1
        @sprite.position.x += movement.x
        @sprite.position.y += movement.y
        @

class StandardShot extends SpriteObject
    defaults:
        asset: "missile"

    update : (game) ->
        @position.x += 15
        if @position.x > game.canvas.width
            game.createEvent(
                new RemoveSpriteEvent({ sprite: @ })
            )

#------------------------------------------------------------
class Game
    constructor : () ->
        @keys = new Array(256)
        @repository = new GameObjectRepository()
        @eventhandler = new GameEventHandler()
        @assets = new AssetLibrary(
            sprites:
                ship : { file: "ship.png" },
                missile : { file: "missile.png" },
                enemy : { file: "enemy.png" },
                explosion : { file: "plop.png" },
                clip1 : { file: "gfx/test{0}.png", startframe:0, endframe:30 }
            datadir:
                'res/sprites/'
        )

    createEvent : (gevent) ->
        @eventhandler.createEvent(gevent)

    createSprite : (sobj) ->
        # create sprite with texture from asset library
        sobj.sprite = new PIXI.Sprite(@assets.textures[sobj.asset])
        @repository.createGObject(sobj)
        @stage.addChild(sobj.sprite)

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
        @stage = new PIXI.Stage(0x031300);
        @canvas = document.getElementById('glcanvas');
        @renderer = PIXI.autoDetectRenderer(@canvas.width, @canvas.height, @canvas);
        @createSprite(new PlayerShip())
        @mainLoop()
        @

window.AquatorGame = new Game()
window.AquatorGame.start()
