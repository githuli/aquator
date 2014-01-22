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
# Collision Detection
#
CollisionDetection =
    overlapRect : (RectA, RectB) ->
        (RectA.x < (RectB.x+RectB.width) && (RectA.x+RectA.width) > RectB.x && RectA.y < (RectB.y+RectB.height) &&         (RectA.y+RectA.height) >RectB.y) 

    collideSprite : (A, B) ->
        CollisionDetection.overlapRect(PixiJSTools.getSpriteRect(A), PixiJSTools.getSpriteRect(B))

#------------------------------------------------------------------------------
# Game Logic Engine
#

class GameObject extends Base
    @constructor: () ->
        @type = 'none'

    update : (game) ->
        @

    activate : (stage) ->
        @

    deactivate : (stage) ->
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

    constructor : () ->
        @ctr = 0
        @type = 'void'

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
        if @gob.sprite != null and @gob.sprite.parent != null
            @gob.sprite.parent.removeChild(@gob.sprite)
        @GOR.removeGObject(@gob)

#------------------------------------------------------------------------------
# Asset Library

class AssetLibrary extends Base

    defaults:
        datadir: './',
        textures: {},
        useSpriteSheets: false

    init : () ->
        # load from files        
        for name, value of @sprites
            if value.hasOwnProperty('endframe')
                # animated sprite
                # TODO
            else
                if !@textures.hasOwnProperty(name) and value.hasOwnProperty('file')
                    @textures[name] = PIXI.Texture.fromImage(@datadir + value.file)

    
