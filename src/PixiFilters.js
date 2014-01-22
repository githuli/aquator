/**
 *
 * The UnderwaterLightFilter class uses the pixel values from the specified texture (called the light map) to perform a special lighting.
 * @class UnderwaterLightFilter
 * @contructor
 * @param texture {Texture} The texture used for the lighting map * must be power of 2 texture at the moment
 */
PIXI.UnderwaterLightFilter = function(texture)
{
    PIXI.AbstractFilter.call( this );

    this.passes = [this];
    texture.baseTexture._powerOf2 = true;

    // set the uniforms
    //console.log()
    this.uniforms = {
        lightMap: {type: 'sampler2D', value:texture},
        scale:           {type: '2f', value:{x:1, y:1}},
        offset:          {type: '2f', value:{x:0, y:0}},
        mapDimensions:   {type: '2f', value:{x:1, y:1}},
        dimensions:   {type: '4fv', value:[0,0,0,0]}
    };

    if(texture.baseTexture.hasLoaded)
    {
        this.uniforms.mapDimensions.value.x = texture.width;
        this.uniforms.mapDimensions.value.y = texture.height;
    }
    else
    {
        this.boundLoadedFunction = this.onTextureLoaded.bind(this);
        texture.baseTexture.on('loaded', this.boundLoadedFunction);
    }

    this.fragmentSrc = [
        'precision mediump float;',
        'varying vec2 vTextureCoord;',
        'varying vec4 vColor;',
        'uniform sampler2D lightMap;',
        'uniform sampler2D uSampler;',
        'uniform vec2 scale;',
        'uniform vec2 offset;',
        'uniform vec4 dimensions;',
        'uniform vec2 mapDimensions;',// = vec2(256.0, 256.0);',
        // 'const vec2 textureDimensions = vec2(750.0, 750.0);',

        'void main(void) {',
        '    vec4 col   = texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y));',
        '    vec2 lightTexCoord = clamp(vec2(vTextureCoord.x*scale.x+offset.x*scale.x, vTextureCoord.y*scale.y+offset.y*scale.y),vec2(0,0),vec2(1,1));',
        '    vec4 light = texture2D(lightMap, lightTexCoord);',
        '    vec4 blue  = vec4(col.x/20.0,col.y/20.0,col.z/2.0,1.0);',
        '    gl_FragColor = mix(col,blue,1.0-light.r);',
        '}'
    ];
};

PIXI.UnderwaterLightFilter.prototype = Object.create( PIXI.AbstractFilter.prototype );
PIXI.UnderwaterLightFilter.prototype.constructor = PIXI.UnderwaterLightFilter;

PIXI.UnderwaterLightFilter.prototype.onTextureLoaded = function()
{
    this.uniforms.mapDimensions.value.x = this.uniforms.lightMap.value.width;
    this.uniforms.mapDimensions.value.y = this.uniforms.lightMap.value.height;

    this.uniforms.lightMap.value.baseTexture.off('loaded', this.boundLoadedFunction);
};

/**
 * The texture used for the displacemtent map * must be power of 2 texture at the moment
 *
 * @property map
 * @type Texture
 */
Object.defineProperty(PIXI.UnderwaterLightFilter.prototype, 'map', {
    get: function() {
        return this.uniforms.lightMap.value;
    },
    set: function(value) {
        this.uniforms.lightMap.value = value;
    }
});

/**
 * The multiplier used to scale the displacement result from the map calculation.
 *
 * @property scale
 * @type Point
 */
Object.defineProperty(PIXI.UnderwaterLightFilter.prototype, 'scale', {
    get: function() {
        return this.uniforms.scale.value;
    },
    set: function(value) {
        this.uniforms.scale.value = value;
    }
});

/**
 * The offset used to move the displacement map.
 *
 * @property offset
 * @type Point
 */
Object.defineProperty(PIXI.UnderwaterLightFilter.prototype, 'offset', {
    get: function() {
        return this.uniforms.offset.value;
    },
    set: function(value) {
        this.uniforms.offset.value = value;
    }
});
