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
     
    @name = method for name, method of mixin    

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
