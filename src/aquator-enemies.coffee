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
        if not collider.damage
            console.log("wtf.")
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
