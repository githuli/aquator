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
    defaults:
        type: 'none'

    update : ->
        @

    activate : (stage) ->
        @

    deactivate : (stage) ->
        @

class SpriteObject extends GameObject
    defaults:
        type: 'sprite'

    setFromTexture : (tex) ->
        @sprite = new PIXI.Sprite(shiptexture)
        @

    activate : (stage) ->
        stage.addChild(@sprite)
        @

    deactivate : () ->
        if (@sprite.parent != null)
            @sprite.parent.removeChild(@sprite)
        @


class AnimatedSpriteObject extends GameObject
    defaults:
        type: 'spriteclip'

    setFromTextures : (texarr) ->
        @clip = new PIXI.MovieClip(texarr)

    activate : (stage) ->
       stage.addChild(@clip)

    deactivate : () ->
        if (@clip.parent != null)
            @clip.parent.removeChild(@clip)
        @


class GameObjectRepository
    # the storage contains an array for each type of game object
    constructor : ->
        @storage = {}

    # every GameObject has to supply a member named 'type'
    createGObject : (gobj) ->
        @storage[gobj.type].push(gobj)

    removeGObject : (gobj) ->
        if @storage.hasOwnProperty(gobj.type)
            index = @storage[gobj].indexOf(gobj)
            if (index > -1)
                @storage[gobj].splice(index, 1)

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
        gevent.update() for gevent in events
        @

class GameEvent extends Base
    defaults:
       ctr: 0,
       type: 'void'

    execute : () ->
        @

    update : () ->
        @ctr--
        if (@ctr < 0)
            @execute()
        @

class RemoveSpriteEvent extends GameEvent
    defaults:
        ctr: 10,
        type: 'destroygobj',
        sprite: null,
        container: null

    execute : () ->
        if @sprite != null
            @sprite.parent.removeChild(@sprite)
        GOR.removeGObject(@sprite)

#------------------------------------------------------------------------------
# Asset Library

class AssetLibrary extends Base

    defaults:
        datadir: './',
        textures: {},
        sprites:  {},
        useSpriteSheets: false

    init : () ->
        # load from files        
        for name, value of @sprites
            if value.hasOwnProperty('endframe')
                # animated sprite

            else
                if !@textures.hasOwnProperty(name) and value.hasOwnProperty('file')
                    @textures[name] = new PIXI.Texture.fromImage(@datadir + value.file)
