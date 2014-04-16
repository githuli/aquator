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
        @type = 'charge'  # should not collide with enemies
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
        @type = 'charge'
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
        @damage = amount/4
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

#
# The actual player ship
#

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
        acceleration = 0.5
        # update forces depending on controls
        @phys.force.x -= acceleration if game.keys[37] == 1              # left
        @phys.force.x += acceleration if game.keys[39] == 1              # right
        @phys.force.y -= acceleration if game.keys[38] == 1              # up
        @phys.force.y += acceleration if game.keys[40] == 1              # down

        # clamp position
        @phys.pos.x = Tools.clampValue(@phys.pos.x, 0, game.canvas.width-@container.width)
        @phys.pos.y = Tools.clampValue(@phys.pos.y, 0, game.canvas.height-@container.height)

        # spawn bubble particles
        bubbleoff= 1
        bubbleoff = 5 if @phys.force.length2() > 0.1

        pos = new Vec2(@container.position.x-50, @container.position.y-9+Math.sin(@count)*bubbleoff)
        game.createSprite(new PropulsionBubble(pos, new Vec2(-3,0)))
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
