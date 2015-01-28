
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
# Pixi.js Tools
#
#
PixiJSTools =
    getSpriteRect : (sprite) ->
        w = Math.abs(sprite.width)
        h = Math.abs(sprite.height)
        new PIXI.Rectangle( sprite.position.x-(sprite.anchor.x*w), sprite.position.y-(sprite.anchor.y*h), w, h );

#------------------------------------------------------------------------------
# Collision Detection
#
CollisionDetection =
    overlapRect : (RectA, RectB) ->
        (RectA.x < (RectB.x+RectB.width) && (RectA.x+RectA.width) > RectB.x && RectA.y < (RectB.y+RectB.height) && (RectA.y+RectA.height)>RectB.y) 

    collideSprite : (A, B) ->
        recta = PixiJSTools.getSpriteRect(A)
        rectb = PixiJSTools.getSpriteRect(B)
        CollisionDetection.overlapRect(recta, rectb)

#------------------------------------------------------------------------------
# Game Logic Engine
#

###################################################################################################
# - Each GameObject has to define the following parameters
# 'type'       [string] - group of things this GameObject belongs to (internal name)
# 'visualType' [string] - visual representation: 
#                         "Sprite", "AnimatedSprite", "ComposedSprite", "Text"
# TODO: use visualType to distinguish between types for createion in aquator-game,
#       get rid of create'xxx' methods, make "createGameObject" method in engine

# - optional
# 'physics'    [bool]   - if true, the engine maintains a physics state (position/velocity)
#                         that is automatically applied to the visual representation
# 'collideWith'         - if set, the engine performs collision detection with all objects 
#                         of given 'type' value, will call "collision()" of any objects that collide
#                         with the object this property is defined in
# 'destroyOnCollision'  - if set, this object will automatically be destroyed after its collision()
#                         method has been called

# - physics interface (if physics=true), initialize physics values:
# 'initialPosition'
# 'initialForce'    
# 'initialMass'
# 'initialVelocity'

# - it should define the following methods
# 'initialize(game)'          - post initialization callback (sprites/physics have been instantiated)
# 'update(game)'              - internal update method
# 'collision(game, collider)' - collision callback that will be called if "this" object collides with
#                               a object that defines 'collideWith' for objects of "this" type

class GameObject extends Base
    constructor: (@defaults) ->
        @type = 'none'
        @[name] = method for name, method of defaults

    update : (game) ->
        @

    # general update method of each gameobject: 
    # -> sets display container to physics position (if physics object)
    # -> perform collision detection
    updateGO : (game) ->
        @phys.physicsTick() if @phys
        @update(game)
        if @container and @phys
            @container.position.x = @phys.pos.x
            @container.position.y = @phys.pos.y         
        if @.hasOwnProperty('collideWith')
            candidates = game.repository.getGObjects(@collideWith)
            if candidates
                for c in candidates
                    # for now, use bounding box of sprites for collision
                    if @collision and CollisionDetection.collideSprite(@container, c.container)
                        @collision(game,c)
                        if c.hasOwnProperty('destroyOnCollision')
                             game.createEvent(new RemoveGOBEvent(game.repository, c))
        @

    setScale : (x, y) ->
        if @container
            @container.scale.x = x
            @container.scale.y = y
        @
    
    setAnchor : (x, y) ->
        if @container
            @container.anchor.x = x
            @container.anchor.y = y

    getPos : () ->
        if @phys
            return @phys.pos.dup()
        else 
            new Vec2(@container.position.x,@container.position.y)

class GameObjectRepository
    # the storage contains an array for each type of game object
    constructor : ->
        @storage = {}
        @namedObjects = {}

    # Callback for any GOB that gets removed - replace this for each game
    removeGOBCB : (gobj) ->
        @

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
        if gobj.container and gobj.pos
            gobj.container.position.x = gobj.pos.x
            gobj.container.position.y = gobj.pos.y

    removeGObject : (gobj) ->
        if @storage.hasOwnProperty(gobj.type)
            index = @storage[gobj.type].indexOf(gobj)
            if (index > -1)
                @storage[gobj.type].splice(index, 1)
        if gobj.hasOwnProperty('name')
            @namedObjects[gobj.name] = undefined
        # remove game object callback 
        @removeGOBCB(gobj)

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
        @updateCB() if @updateCB
        @ctr--
        if (@ctr < 0)
            @execute()
            return true
        return false

class RemoveGOBEvent extends GameEvent

    constructor : (GOR, gob, delay=0) ->
        @ctr = delay
        @type = 'destroygobj'
        @GOR = GOR
        @gob = gob

    execute : () ->
        if @gob.container and @gob.container.parent
            @gob.container.parent.removeChild(@gob.container)
        @GOR.removeGObject(@gob)

class FadeInEvent extends GameEvent
    constructor : (GOB, duration=30) ->
        @duration = duration
        @ctr = duration
        @type = 'fadein'
        @gob = GOB

    updateCB : () ->
        # fade alpha from 0->1
        @gob.container.alpha = (@duration-@ctr)/@duration

    execute : () ->
        @gob.container.alpha = 1.0
        @

class FadeOutEvent extends GameEvent
    constructor : (GOB, duration=30) ->
        @duration = duration
        @ctr = duration
        @type = 'fadeout'
        @gob = GOB

    updateCB : () ->
        # fade alpha from 0->1
        @gob.container.alpha = @ctr/@duration

    execute : () ->
        @gob.container.alpha = 0.0
        @


#------------------------------------------------------------------------------
# Asset Library
# 
# loads and maintains textures for sprites and animations
#
class AssetLibrary extends Base

    defaults:
        datadir: './',
        textures: {},
        useSpriteSheets: false

    # return list of all asset files, for use with pixi assetloader
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
 
    # initializeAssets: loads assets (single and multiframe) from files and creates 
    # Pixi sprites and layers (for scrolling backgrounds)
    initializeAssets : (stage) ->
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
                        if value.hasOwnProperty('scaleMode')
                            @textures[assetname].baseTexture.scaleMode = value.scaleMode
            else
                if not @textures.hasOwnProperty(name) and value.hasOwnProperty('file')
                    @textures[name] = PIXI.Texture.fromImage(@datadir + value.file)
        # initialize layer objects
        for name of @layers
            @layers[name] = new PIXI.DisplayObjectContainer()
            stage.addChild(@layers[name])
        @
    
#------------------------------------------------------------------------------
# Reusable Game objects

