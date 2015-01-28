
#------------------------------------------------------------------------------
# 2D Vector class
#

class Vec2 
    constructor : (_x=0.0, _y=0.0) ->
        @x = _x
        @y = _y
        @

    set : (_x,_y) ->
        @x = _x
        @y = _y
        @

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
    dup  : () ->               new Vec2(@x,@y)
    roundC : () ->             new Vec2(Math.round(@x), Math.round(@y))
    toString : () ->           "["+@x+","+@y+"]"

#------------------------------------------------------------------------------
# 2D Axis aligned bounding box
#
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
            y :  CatmullRom.evaluateSegment( tt, cpy );
        pt




