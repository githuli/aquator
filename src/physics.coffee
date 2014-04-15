#------------------------------------------------------------------------------
# very simple 2D physics
#

class PhysicsObject
    constructor: () ->
        @pos = new Vec2()
        @velocity = new Vec2()
        @force = new Vec2()
        @invMass = 1.0
        @friction = 0.0

    physicsTick : (dt=1.0) ->
        # hypothesize friction forces based on current movement
        f = @force.addC(@velocity.smulC(-@friction))

        # Symplectic Euler
        @velocity.add(f.smulC(@invMass).smulC(dt))
        @pos.add(@velocity.smul(dt))
