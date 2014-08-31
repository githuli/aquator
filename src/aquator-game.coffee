#------------------------------------------------------------
# The main game class holds state and 

class Game
    constructor : () ->
        @keys = new Array(256)
        @repository = new GameObjectRepository()
        @eventhandler = new GameEventHandler()
        @assets = new AssetLibrary(
            sprites:
#                'ship'    : { file: "sprites/ship.png" },
                'ship{0}' : { file: "sprites/ship{0}.png", startframe:0, endframe:5, scaleMode:PIXI.BaseTexture.SCALE_MODE.NEAREST  },
                'bubble'  : { file: "sprites/ship_tail.png"},
                'bubble2' : { file: "sprites/bubble2.png"},
                'missile' : { file: "sprites/missile.png" },
                'beam'    : { file: "sprites/beam.png" },
                'explosion1' : { file: "sprites/explosion1.png"},
                'bg1'     : { file: "bg/layer1.png"},
                'bg-middle': { file: "bg/bg-middle.png", scaleMode:PIXI.BaseTexture.SCALE_MODE.NEAREST },
                'bg1dist' : { file: "bg/layer1-dist.png"},
                'bg2'     : { file: "bg/layer2.png"},
                'bg1-3'   : { file: "bg/bg1-3.png"},
                'bg-far'  : {file:  'bg/bg-far.png' },
                'wobble1' : { file: "maps/displacementbg.png"},
                'light'   : { file: "maps/light.png"},
                'fish{0}' : { file: "sprites/fish{0}.png", startframe:0, endframe:4  },
                'pullshotload{0}' : { file: "sprites/pullshot/pull_shot_loading{0}.png", startframe:0, endframe:10, scaleMode:PIXI.BaseTexture.SCALE_MODE.NEAREST  },
                'pullshotstart{0}' : { file: "sprites/pullshot/pull_shot_start{0}.png", startframe:0, endframe:1, scaleMode:PIXI.BaseTexture.SCALE_MODE.NEAREST  },
                'pullshotloop{0}' : { file: "sprites/pullshot/pull_shot_loop{0}.png", startframe:0, endframe:4, scaleMode:PIXI.BaseTexture.SCALE_MODE.NEAREST  },
                'verdana' : { font: "fonts/verdana.xml" },
                'getready' : { file: "fonts/getready.png" },
                'hbarl'   : { file: "ui/hbarl.gif" },
                'hbarm'   : { file: "ui/hbarm.gif" },
                'hbarr'   : { file: "ui/hbarr.gif" },
                'shark'   : { file: "sprites/shark.png" },
            datadir: 'res/'
            layers:         # layers are rendered from front to back
                'back0' : {}
                'back1' : {}
                'back2' : {}
                'default' : {}
                'enemies' : {}
                'shipback'  : {}
                'ship'  : {}
                'shipfront' : {}
                'front'  : {}
                'ui'   : {}
                'text' : {}
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
        if sobj.layer
            @assets.layers[sobj.layer].addChild(sobj.container)
        else    
            @assets.layers['default'].addChild(sobj.container)
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
        if sobj.layer
            @assets.layers[sobj.layer].addChild(sobj.container)
        else    
            @assets.layers['default'].addChild(sobj.container)
        sobj

    createAnimatedSprite : (sobj) ->
        # create a container composed of multiple sprites
        tex = []
        ass = @assets.sprites[sobj.asset]
        for i in [ass.startframe..ass.endframe]
            tex.push(@assets.textures[sobj.asset.format(i)])
        sobj.container = new PIXI.MovieClip(tex)
        @repository.createGObject(sobj)
        sobj.initialize(@) if sobj.initialize
        if sobj.layer
            @assets.layers[sobj.layer].addChild(sobj.container)
        else    
            @assets.layers['default'].addChild(sobj.container)
        @

    createText : (tobj) ->
        tobj.container = new PIXI.BitmapText(tobj.text, tobj.asset)
        @repository.createGObject(tobj)
        tobj.initialize(@) if tobj.initialize
        @assets.layers['text'].addChild(tobj.container)
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
        @renderer.render(@stage)
        requestAnimFrame(@mainLoop)

    run : () =>
        # assets have been loaded
        document.onkeydown = @keyDownHandler
        document.onkeyup = @keyUpHandler
        @stage = new PIXI.Stage(0x14184a);
        @assets.initializeAssets(@stage)
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
            assets : [   { asset:"bg-far", x:0, y:0, w:2300, h:240, sx: 3, sy: 3 } ],
            useWobble : true,
            layer : 'back0'
            #useShiplight : false,
        ))
        layer3=@createComposedSprite(new BackgroundLayer(
            assets : [   { asset:"bg-middle", sx:3, sy:3, x:0, y:0, w:4800, h:640 } ],   #, dfield:"bg1dist"
            layer : 'back1'
            #useShiplight : true,
        ))
#        layer3=@createComposedSprite(new BackgroundLayer(
#            assets : [   { asset:"bg1", x:0, y:0, w:4800, h:640, dfield:"bg1dist" } ],
#            layer : 'back1'
#            #useShiplight : true,
#        ))
        # [layer1,layer2,layer3]
        background = @createGObject( new ParallaxScrollingBackground([layer1,layer3]) )
        
        # initialize state per game objects
        score = @createText(new PlayerScore(new Vec2(20,@canvas.height-30)))

        @createSprite(new BlinkingSprite(new Vec2(400,300), "getready", 3))
        # spawn ship
        @createEvent( new GameEvent(5*30, => @createAnimatedSprite(new PlayerShip())))        

        #@createAnimatedSprite(new EnemyFish(new Vec2(960,320), new Vec2(-1,0)))

        # randomly spawn some fishies
        for i in [1..10]
            @createEvent(new GameEvent(150+i*200, => @createAnimatedSprite(new EnemyFish(new Vec2(Math.random()*960,Math.random()*640), new Vec2(0,0))) ))
            @createEvent(new GameEvent(100+i*200, => @createSprite(new EnemyShark(new Vec2(960,Math.random()*640), new Vec2(0,0))) ))            

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