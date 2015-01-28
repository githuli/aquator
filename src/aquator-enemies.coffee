# -----------------------------------------------------------------------------
# ENEMIES


# movement behavior is coded in the parent class

class Enemy extends GameObject
    constructor : () ->
        @type = 'enemy'
        @layer = 'enemies'
        @count = 0
        @collideWith = 'shot'
        @

    initialize : (game) ->
        @


    update : (game) ->
        switch @movementBehaviour
            when "swarm2player1"
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
                # introduce a 'repelling' force between enemies
                enemies = game.repository.getGObjects('enemy')
                for enemy in enemies
                    if enemy != @
                        f = @phys.pos.subC(enemy.getPos())
                        @phys.force.add( f.smulC(0.5/f.length2()) )

            when "random1"
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

            when "predefined"
                ++@count
                if @count < @movement.frames
                    @pos = CatmullRom.evaluateSpline(@count/@movement.frames, @movement.x, @movement.y)
                    @container.position.x = @pos.x * game.canvas.width
                    @container.position.y = @pos.y * game.canvas.height
                else 
                    # movement done, remove sprite
                    game.createEvent(new RemoveGOBEvent(game.repository, @))                            

        # see if we are dead
        if (@HP < 0)
            game.createEvent(new RemoveGOBEvent(game.repository, @))        
            #game.createSprite(new Explosion(@phys.pos.dup(), 0.15))  
            @explosion.pos = @getPos()
            game.createAnimatedSprite(@explosion)
        @

    collision : (game, collider) ->
        if not collider.damage
            console.log("wtf.")

        @HP -= collider.damage
        collider.damage--

        # flash fish
        if not @container.filters
            @container.filters = [ game.flashFilter ]
        else
            switch @container.filters.length
                when 1
                    @container.filters = [ @container.filters[0], game.flashFilter ]
                when 2
                    @container.filters = [ @container.filters[0], @container.filters[1], game.flashFilter ]

        game.createEvent( new GameEvent(10, =>
            if @container.filters
                switch @container.filters.length
                    when 1
                        @container.filters = null
                    when 2
                        @container.filters = [ @container.filters[0] ]
                    when 3
                        @container.filters = [ @container.filters[0], @container.filters[1] ]
        ))        
        @


# enemies defined here


# swarm fishies
class EnemyFish extends Enemy
    constructor : (pos, vel) ->
        super
        @asset = 'fish{0}'
        @physics = true
        @initialPosition = pos
        @initialVelocity = vel
        @HP = 50
        @score = 100
        @movementBehaviour = "swarm2player1"
        @explosion = new Explosion2(new Vec2(0,0), 1.0)

    initialize : (game) ->
        @phys.friction = 0.1
        @setAnchor(0.5,0.5)
        @setScale(0.25,0.25)
        @container.animationSpeed=0.25
        @container.gotoAndPlay(0)
        @

class MovingFish extends Enemy
    constructor : (movement) ->
        super
        @asset = 'fish{0}'
        @HP = 20
        @score = 100
        @movementBehaviour = "predefined"
        @movement = movement
        @explosion = new Explosion2(new Vec2(0,0), 1.0)
        @playerDamage = 5

    initialize : (game) ->
        @setAnchor(0.5,0.5)
        @setScale(0.25,0.25)
        @container.animationSpeed=0.25
        @container.gotoAndPlay(0)
        @movement = game.assets.movements[@movement]
        @

# randomly moving wobbling sharks
class EnemyShark extends Enemy
    constructor : (pos, vel) ->
        super
        @type = 'enemy'
        @layer = 'enemies'        
        @asset = 'shark'
        @physics = true
        @initialPosition = pos
        @initialVelocity = vel
        @HP = 100
        @score = 1337
        @count = 150
        @movementBehaviour = "random1"
        @explosion = new Explosion4(new Vec2(0,0), 1.0)

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
        @wobble.offset = @wobbleoff
        @wobbleoff.add(@wobbleinc)
        super(game)

