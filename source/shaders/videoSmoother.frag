#pragma header

uniform sampler2D prevTexture;
uniform float blendFactor;

void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec4 currentColor = flixel_texture2D(bitmap, uv);
    vec4 prevColor = texture2D(prevTexture, uv);
    gl_FragColor = mix(prevColor, currentColor, blendFactor);
}
