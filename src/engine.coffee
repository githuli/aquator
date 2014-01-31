
String.prototype.format = ->
  args = arguments
  return this.replace /{(\d+)}/g, (match, number) ->
    return if typeof args[number] isnt 'undefined' then args[number] else match

#------------------------------------------------------------------------------
# Base Class
#
class Base
    constructor: () ->
        mixin = {}
        initArgs = []

        isFirst = true
        for arg in arguments
            # If the first argument is an object
            # use it to extend this new Instance
            if typeof arg == 'object' && isFirst
                mixin = arg
            # Otherwise add it to an array that we'll
            # pass to the objects init method 
            else
                initArgs.push arg
            isFirst = false
         
        # set defaults
        @[name] = method for name, method of @defaults
        # merge mixin
        @[name] = method for name, method of mixin    

        # If this class has an init method it will
        # it will be called with initArgs
        if(@['init'])
            @init.apply(@, initArgs)
        if (@['_init'])
            @_init.apply(@)

#------------------------------------------------------------------------------
# 
#
Tools = 
    clampValue : (val, min, max) ->
        if val<min
            return min
        if val>max
            return max
        return val

#------------------------------------------------------------------------------
# Catmull-Rom Splines
#

CatmullRom =
    evaluateSegment : (t, P) ->
        0.5 * (  (2.0*P[1]) + (P[2]-P[0])*t + (2.0*P[0]-5.0*P[1]+4.0*P[2]-P[3])*t*t + (3.0*P[1]-P[0]-3*P[2]+P[3])*t*t*t )
    
    evaluateSpline : (t, CPX, CPY) ->
        numcp = CPX.length
        numsegments = numcp-3
        # calculate segment
        tt = t*numsegments
        i = Math.floor(tt)
        tt = tt-i
        # create and evaluate segment
        cpx = [ CPX[i], CPX[i+1], CPX[i+2], CPX[i+3] ]
        cpy = [ CPY[i], CPY[i+1], CPY[i+2], CPY[i+3] ];

        pt = 
            x :  CatmullRom.evaluateSegment( tt, cpx );
            y :  CatmullRom.evaluateSegment( tt, cpx );
        pt

#------------------------------------------------------------------------------
# Pixi.js Tools
#
#
PixiJSTools =
    getSpriteRect : (sprite) ->
        new PIXI.Rectangle( sprite.position.x, sprite.position.y, sprite.width, sprite.height );

#------------------------------------------------------------------------------
# Physics Engine & Collision Detection
#
CollisionDetection =
    overlapRect : (RectA, RectB) ->
        (RectA.x < (RectB.x+RectB.width) && (RectA.x+RectA.width) > RectB.x && RectA.y < (RectB.y+RectB.height) &&         (RectA.y+RectA.height) >RectB.y) 

    collideSprite : (A, B) ->
        CollisionDetection.overlapRect(PixiJSTools.getSpriteRect(A), PixiJSTools.getSpriteRect(B))

class Vec2 
    constructor : (_x=0.0, _y=0.0) ->
        @x = _x
        @y = _y
        @

    set : (x,y) ->
        @x = x
        @y = y

    #inplace operations
    smul : (scalar) ->
        @x *= scalar
        @y *= scalar
        @

    add : (vec) ->
        @x += vec.x
        @y += vec.y
        @

    length2 : () ->       @x*@x+@y*@y

    length : () ->        Math.sqrt(@length2())

    normalizeTo : (length) ->
        f = length/@length()
        @x *= f
        @y *= f
        @

    #const operations
    smulC : (scalar) ->        new Vec2(@x*scalar,@y*scalar)
    addC : (vec) ->            new Vec2(@x+vec.x,@y+vec.y)
    subC : (vec) ->            new Vec2(@x-vec.x,@y-vec.y)
    negC : () ->               new Vec2(-@x,-@y)
    toString : () ->           "["+@x+","+@y+"]"

class BBox2
    constructor : () ->
        @min = new Vec2(+Infinity,+Infinity)
        @max = new Vec2(-Infinity,-Infinity)
        @
    
    valid : () ->
        @min.x!=+Infinity or @max.y!=-Infinity

    width : () ->
        @max.x-@min.x
    height : () ->
        @max.y-@min.y

    insertPoint : (vec) ->
        @min.x = vec.x if vec.x<@min.x
        @min.y = vec.y if vec.y<@min.y
        @max.x = vec.x if vec.x>@max.x
        @max.y = vec.y if vec.y>@max.y
        @
    # insert pixi rectangle
    insertRect : (rect) ->
        @min.x = rect.x if rect.x<@min.x
        @min.y = rect.y if rect.y<@min.y
        @max.x = (rect.x+rect.width) if (rect.x+rect.width)>@max.x
        @max.y = (rect.y+rect.height) if (rect.y+rect.height)>@max.y    
        @
    # insert BBox2
    insertBBox : (bbox) ->
        @min.x = bbox.min.x if bbox.min.x<@min.x
        @min.y = bbox.min.y if bbox.min.y<@min.y
        @max.x = bbox.max.x if bbox.max.x>@max.x
        @max.y = bbox.max.y if bbox.max.y>@max.y    
        @
    
    toString : () ->
        "min:" + @min + " max:" + @max

class PhysicsObject
    constructor: () ->
        @pos = new Vec2()
        @velocity = new Vec2()
        @force = new Vec2()
        @invMass = 1.0
        @friction = 0.0

    physicsTick : (dt=1.0) ->
        # recalculate friction forces based on current movement
        # f = @force # 
        f = @force.add(@velocity.smulC(-@friction))
        #console.log("f: " + f)
        # Symplectic Euler
        @velocity.add(f.smulC(@invMass).smulC(dt))
        @pos.add(@velocity.smul(dt))

#------------------------------------------------------------------------------
# Game Logic Engine
#
# physics interface:
# member: 
#   physics {boolean} -> initialize a physics object
#   [initialPosition]
#   [initialForce]    
#   [initialMass]
#   [initialVelocity]

class GameObject extends Base
    constructor: () ->
        @type = 'none'

    updateGO : (game) ->
        @phys.physicsTick() if @phys
        @update(game)
        if @container and @phys
            @container.position.x = @phys.pos.x
            @container.position.y = @phys.pos.y            
        @

class GameObjectRepository
    # the storage contains an array for each type of game object
    constructor : ->
        @storage = {}
        @namedObjects = {}

    # every GameObject has to supply a member named 'type'
    createGObject : (gobj) ->
        if !@storage.hasOwnProperty(gobj.type)
            @storage[gobj.type]=[]
        @storage[gobj.type].push(gobj)
        if gobj.hasOwnProperty('name')
            @namedObjects[gobj.name] = gobj
        if gobj.hasOwnProperty('physics')
            gobj.phys = new PhysicsObject()
            gobj.phys.pos = gobj.initialPosition if gobj.initialPosition
            gobj.phys.velocity = gobj.initialVelocity if gobj.initialVelocity
            gobj.phys.force = gobj.initialForce if gobj.initialForce
            gobj.phys.invMass = 1.0/gobj.initialMass if gobj.initialMass
        if gobj.container and gobj.phys
            gobj.container.position.x = gobj.phys.pos.x
            gobj.container.position.y = gobj.phys.pos.y

    removeGObject : (gobj) ->
        if @storage.hasOwnProperty(gobj.type)
            index = @storage[gobj.type].indexOf(gobj)
            if (index > -1)
                @storage[gobj.type].splice(index, 1)
        if gobj.hasOwnProperty('name')
            @namedObjects[gobj.name] = undefined

    getNamedGObject : (name) ->
        @namedObjects[name]

    getGObjects : (type) ->
        @storage[type]

    getAllGobjects : () ->
        obj = []
        obj = obj.concat(value) for name, value of @storage
        obj

#------------------------------------------------------------------------------
# GameEvent Mechanism

class GameEventHandler
    constructor : ->
        @events = []

    update : ->
        remove = []
        for gevent in @events
            if gevent.update() 
                remove.push(gevent)
        # remove finished events
        for removeme in remove
            @events.splice(@events.indexOf(removeme),1)
        @

    createEvent : (e) ->
        @events.push(e)

class GameEvent extends Base

    constructor : (count, callback) ->
        if count
            @ctr = count
        else 
            @ctr = 0
        @type = 'void'
        if callback
            @execute = callback

    execute : () ->
        @

    update : () ->
        @ctr--
        if (@ctr < 0)
            @execute()
            return true
        return false

class RemoveSpriteEvent extends GameEvent

    constructor : (GOR, gob) ->
        @ctr = 0
        @type = 'destroygobj'
        @GOR = GOR
        @gob = gob

    execute : () ->
        if @gob.container != null and @gob.container.parent != null
            @gob.container.parent.removeChild(@gob.container)
        @GOR.removeGObject(@gob)

#------------------------------------------------------------------------------
# Asset Library

class AssetLibrary extends Base

    defaults:
        datadir: './',
        textures: {},
        useSpriteSheets: false

    getAssetLoaderList : () ->
        assets = []
        for name, value of @sprites
            if value.hasOwnProperty('endframe')
                endframe = value.endframe
                startframe = 0
                if value.hasOwnProperty('startframe')
                    startframe = value.startframe
                for i in [startframe..endframe]
                    filename = (@datadir + value.file).format(i)
                    assets.push(filename)
            else
                assets.push(@datadir + value.file) if value.hasOwnProperty('file')
                assets.push(@datadir + value.font) if value.hasOwnProperty('font')
        assets

    initializeAssets : () ->
        # load from files        
        for name, value of @sprites
            if value.hasOwnProperty('endframe')
                endframe = value.endframe
                startframe = 0
                if value.hasOwnProperty('startframe')
                    startframe = value.startframe
                for i in [startframe..endframe]
                    assetname = name.format(i)
                    filename = (@datadir + value.file).format(i)
                    if not @textures.hasOwnProperty(name) and value.hasOwnProperty('file')
                        @textures[assetname] = PIXI.Texture.fromImage(filename)
            else
                if not @textures.hasOwnProperty(name) and value.hasOwnProperty('file')
                    @textures[name] = PIXI.Texture.fromImage(@datadir + value.file)

    
