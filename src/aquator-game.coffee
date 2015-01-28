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
                'explosion2{0}' : { file: "sprites/ex1/image{0}.png", startframe:1, endframe:69 },
                'explosion4{0}' : { file: "sprites/ex2/image{0}.png", startframe:1, endframe:54 },
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
            # predefined movement splines
            movements:
                'm1' : {
                    frames: 350
                    x:[1.2,1.2,1,0.9130859375,0.8349609375,0.744140625,0.654296875,0.55078125,0.451171875,0.3203125,0.2158203125,0.0986328125,0.001953125,-0.2,-0.2],
                    y:[0.2,0.2,0.162109375,0.111328125,0.193359375,0.13671875,0.224609375,0.16796875,0.26953125,0.1875,0.35546875,0.21484375,0.611328125,0.6,0.6],
                },
                'm2' : {
                    frames:350
                    x:[1.2,1.2,1,0.9404296875,0.876953125,0.8046875,0.740234375,0.7158203125,0.7060546875,0.69921875,0.671875,0.6171875,0.5556640625,0.4970703125,0.447265625,0.412109375,0.3623046875,0.2919921875,0.2275390625,0.16796875,0.1123046875,0.060546875,0.009765625,-0.2,-0.2]
                    y:[0.8,0.8,0.865234375,0.865234375,0.869140625,0.849609375,0.796875,0.73828125,0.677734375,0.62109375,0.5546875,0.490234375,0.45703125,0.439453125,0.439453125,0.439453125,0.43359375,0.40234375,0.318359375,0.2265625,0.1328125,0.072265625,0.04296875,-0.2,-0.2]
                },
                'm3' : {
                    frames:500
                    x:[1.2,1.2,0.9970703125,0.5673828125,0.1806640625,0.47265625,0.796875,0.1767578125,0.0029296875,-0.2,-0.2]
                    y:[0.0,0.0,0.072265625,0.095703125,0.576171875,0.912109375,0.626953125,0.099609375,0.00390625,-0.2,-0.2]
                },
                'm4' : {
                    frames:500
                    x:[1.2,1.2,0.9951171875,0.404296875,0.8076171875,0.296875,0.6826171875,0.130859375,0.4736328125,0.2861328125,0.001953125,-0.2,-0.2]
                    y:[0,0,0.076171875,0.203125,0.35546875,0.505859375,0.611328125,0.6640625,0.841796875,0.947265625,0.9824218750,1,1]
                }
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
        #@createAnimatedSprite(new MovingFish('m1'))
        

        # create 10 fishes with movement
        createFishiFishi = (startframe, movement) =>
            for i in [1..5]
                @createEvent(new GameEvent(startframe+i*20, 
                    => @createAnimatedSprite(new MovingFish(movement))))

        createFishiFishi(250,'m2')
        createFishiFishi(800,'m1')
        createFishiFishi(1400,'m3')
        createFishiFishi(2000,'m4')
        createFishiFishi(2500,'m2')
        createFishiFishi(3200,'m4')
        createFishiFishi(4000,'m3')
        createFishiFishi(4400,'m1')
        createFishiFishi(5000,'m4')
        createFishiFishi(5500,'m3')

        # randomly spawn some fishies
        for i in [1..10]
            @createEvent(new GameEvent(200+i*500, => @createAnimatedSprite(new EnemyFish(new Vec2(Math.random()*960,Math.random()*640), new Vec2(0,0))) ))
            @createEvent(new GameEvent(100+i*500, => @createSprite(new EnemyShark(new Vec2(960,Math.random()*640), new Vec2(0,0))) ))

        @createEvent( new GameEvent(200, =>
            @createText(new FadingText(new Vec2(300, 600), "Welcome to AQUATOR"))
        ))

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