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
        # initialize distance field data
        if @assets[0].dfield
            img = game.assets.textures[@assets[0].dfield].baseTexture.source
            canvas = document.createElement('canvas');

            canvas.width = screen.width
            canvas.height = screen.height
            context = canvas.getContext('2d');
            context.drawImage(img, 0, 0 );
            @distanceMap = context.getImageData(0, 0, img.width, img.height);
            context = undefined
            canvas = undefined
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

        # Collision detection with player ship is handled here 
        # (TODO: better integration in collision detection )
        ship = game.repository.getNamedGObject("TheShip")
        if ship and @distanceMap
            # get ship position relative to background
            spos = ship.phys.pos.subC(@container.position).roundC()
            offset = (spos.x+spos.y*@distanceMap.width)*4
            dist = @distanceMap.data[offset]
            if dist < ship.collisionRadius
                ship.collision(game, @)
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
        @layer = 'enemies'
        @asset = 'fish{0}'
        @physics = true
        @initialPosition = pos
        @initialVelocity = vel
        @collideWith = 'shot'
        @HP = 50
        @score = 100

    initialize : (game) ->
        @phys.friction = 0.1
        @setAnchor(0.5,0.5)
        @setScale(0.25,0.25)
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
        collider.damage--

        # flash fish
        @container.filters = [game.flashFilter]
        game.createEvent( new GameEvent(10, =>
                @container.filters = null
        ))        
        @


class EnemyShark extends GameObject
    constructor : (pos, vel) ->
        @type = 'enemy'
        @layer = 'enemies'        
        @asset = 'shark'
        @physics = true
        @initialPosition = pos
        @initialVelocity = vel
        @collideWith = 'shot'
        @HP = 100
        @score = 1337
        @count = 150
        @

    initialize : (game) ->
        @phys.friction = 0.03
        @setAnchor(0.5,0.5)
        @setScale(0.25,0.25)
        @wobble = new PIXI.WobbleFilter()
        @wobble.scale.x = 12.0
        @wobble.scale.y = 0.003
        @container.filters = [ @wobble ]
        @wobbleoff = new Vec2(0,0)
        @wobbleinc = new Vec2(0.1,0.1)
        @

    update : (game) ->
        --@count
        if @count < 0
            if Math.random() < 0.5
                ship = game.repository.getNamedGObject("TheShip")
                # move into player direction
                if ship
                    @phys.force = ship.phys.pos.addC(@phys.pos.negC())
                    @phys.force.normalizeTo(0.3)
            else
               # move left
               @phys.force.set(-0.3,0.0)
            # stop force after 10 frames 
            game.createEvent( new GameEvent(13, => @phys.force.set(0,0)) )
            @count = 150

        @container.filters[0].offset = @wobbleoff
        @wobbleoff.add(@wobbleinc)

        # see if we are dead
        if (@HP < 0)
            game.createEvent(new RemoveGOBEvent(game.repository, @))        
            game.createSprite(new Explosion(@phys.pos.dup(), 0.15))        
        @

    collision : (game, collider) ->
        @HP -= collider.damage
        collider.damage--
        # flash fish
        @container.filters = [ @wobble, game.flashFilter ]
        game.createEvent( new GameEvent(10, => @container.filters = [ @wobble ] ) )
        @        

# -----------------------------------------------------------------------------
# PLAYER SHIP, WEAPONS AND PARTICLES

# The "standard" shot, just a horizontally flying projectile
class StandardShot extends GameObject
    constructor: (position, velocity) ->
        @type = 'shot'
        @layer = 'ship'        
        @asset = 'missile'
        @physics = true
        @initialPosition = position
        @initialVelocity = velocity
        @damage = 10
        @destroyOnCollision = true

    initialize : (game) ->
        @phys.force = new Vec2(0.1,0.0)    # standard shot is being accelerated
        @update(game)
        @

    update : (game) ->
        if @container.position.x > game.canvas.width
            game.createEvent(new RemoveGOBEvent(game.repository, @))

# The "beam" shot consists of two parts: charge + shot
# charge is 'chargin' at the ship position (+ increasing size)
# and spawns a BeamShot when spacebar is released
class BeamCharge extends GameObject
    constructor: () ->
        @type = 'shot'
        @asset = 'pullshotload{0}'
        @layer = 'shipfront'
        @physics = true
        @

    initialize : (game) ->
        @setAnchor(0.5,0.5)
        ship = game.repository.getNamedGObject("TheShip")
        if ship
            @setScale(ship.container.scale.x,ship.container.scale.y)
        @ctr = 0
        @container.animationSpeed=0.125
        @container.gotoAndPlay(0)
        @update
        @

    update : (game) ->
        ship = game.repository.getNamedGObject("TheShip")
        if ship
            @phys.pos = ship.phys.pos
        else 
            game.createEvent(new RemoveGOBEvent(game.repository, @))
            return @
        if game.keys[32]==1
            @ctr++ if @ctr < 80
        else
            # release shot
            game.createEvent(new RemoveGOBEvent(game.repository, @))
            if @ctr > 10
                game.createAnimatedSprite(new BeamStart(@ctr))
        @
        
class BeamStart extends GameObject
    constructor: (amount) ->
        @type = 'shot'
        @asset = 'pullshotstart{0}'
        @layer = 'shipfront'
        @physics = true
        @amount = amount
    initialize : (game) ->
        ship = game.repository.getNamedGObject("TheShip")
        @setAnchor(0.5,0.5)
        if ship
            sfact = @amount/80
            @setScale(ship.container.scale.x*sfact,ship.container.scale.y*sfact)
        @container.animationSpeed=0.3
        @container.gotoAndPlay(0)        
        @ctr = 0
        @
    
    update : (game) ->
        ship = game.repository.getNamedGObject("TheShip")        
        if ship
            @phys.pos = ship.phys.pos.addC(new Vec2(25,5))
        @ctr++
        if @ctr > 5
            game.createEvent(new RemoveGOBEvent(game.repository, @))
            game.createAnimatedSprite(new BeamShot(@phys.pos, @amount))
        @

class BeamShot extends GameObject
    constructor: (pos, amount) ->
        @type = 'shot'
        @asset = 'pullshotloop{0}'
        @layer = 'shipback'
        @physics = true
        @initialPosition = new Vec2(pos.x,pos.y)
        @amount = amount
        @damage = amount        
        @

    initialize : (game) ->
        ship = game.repository.getNamedGObject("TheShip")   
        @setAnchor(0.5,0.5)
        if ship
            sfact = @amount/80
            @setScale(ship.container.scale.x*sfact,ship.container.scale.y*sfact)
        @container.animationSpeed=0.25
        @container.gotoAndPlay(0)
        @phys.velocity.set(5.0,0.0)
        @

    update : (game) ->
        if @container.position.x > game.canvas.width or @damage <= 0
            game.createEvent(new RemoveGOBEvent(game.repository, @))
        @



class PropulsionBubble extends GameObject
    constructor: (position, velocity) ->
        @type = 'container'
        @asset = 'bubble2'
        @layer = 'shipback'
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

class PlayerShip extends GameObject
    constructor: () ->
        @type = 'container'
        @asset = 'ship{0}'
        @name  = 'TheShip'
        @layer = 'ship'
        @physics = true
        @collideWith = 'enemy'

    initialize : (game) ->
        @setAnchor(0.5,0.5)
        @setScale(2,2)
        @container.alpha = 0       # fade in
        @phys.pos.x = 200
        @phys.pos.y = game.canvas.height/2
        @phys.friction = 0.1
        @shotctr = 0
        @count = 0
        @collisionRadius = (@container.width+@container.height)/4
        # create health bar
        @energy = game.createComposedSprite(new PlayerHealthbar(new Vec2(150,game.canvas.height-30)))
        @container.animationSpeed=0.1
        @container.gotoAndPlay(0)
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

        pos = new Vec2(@container.position.x-50, @container.position.y-9+Math.sin(@count)*bubbleoff)
        game.createSprite(new PropulsionBubble(pos, new Vec2(-2,0)))
        @count += 1

        # fire shots with space bar
        if game.keys[32]==1
            if @shotctr==0
                game.createSprite(new StandardShot(new Vec2(@container.position.x+10,@container.position.y+15),new Vec2(5,0) ))
                ++@shotctr
            if @shotctr==1
                game.createAnimatedSprite(new BeamCharge(new Vec2(@container.position.x+20,@container.position.y+10)))
                ++@shotctr
        else
           @shotctr=0

        # see if we are dead
        if @energy.energy < 0
            # remove health bar and ship
            game.createEvent(new RemoveGOBEvent(game.repository, @energy))
            game.createEvent(new RemoveGOBEvent(game.repository, @))
            @container.alpha = 0.0
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
#                'ship'    : { file: "sprites/ship.png" },
                'ship{0}' : { file: "sprites/ship{0}.png", startframe:0, endframe:5, scaleMode:PIXI.BaseTexture.SCALE_MODE.NEAREST  },
                'bubble'  : { file: "sprites/ship_tail.png"},
                'bubble2' : { file: "sprites/bubble2.png"},
                'missile' : { file: "sprites/missile.png" },
                'beam'    : { file: "sprites/beam.png" },
                'explosion1' : { file: "sprites/explosion1.png"},
                'bg1'     : { file: "bg/layer1.png"},
                'bg-middle': { file: "bg/bg-middle.png"},
                'bg1dist' : { file: "bg/layer1-dist.png"},
                'bg2'     : { file: "bg/layer2.png"},
                'bg1-3'   : { file: "bg/bg1-3.png"},
                'bg-far'  : {file:  'bg/bg-far.png', scaleMode:PIXI.BaseTexture.SCALE_MODE.NEAREST},
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
            layers:         # layers are from front to back
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
            assets : [   { asset:"bg-middle", sx:3, sy:3, x:0, y:0, w:4800, h:640, dfield:"bg1dist" } ],
            useCollision : true,
            layer : 'back1'
            #useShiplight : true,
        ))
#        layer3=@createComposedSprite(new BackgroundLayer(
#            assets : [   { asset:"bg1", x:0, y:0, w:4800, h:640, dfield:"bg1dist" } ],
#            useCollision : true,
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
