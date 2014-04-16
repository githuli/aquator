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
