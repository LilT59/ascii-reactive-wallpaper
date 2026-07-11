#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    float qt_Opacity;
};

void main()
{
    vec2 tile = floor(qt_TexCoord0 * 16.0);
    float checker = mod(tile.x + tile.y, 2.0);
    fragColor = mix(vec4(1.0, 0.0, 0.7, 1.0),
                    vec4(0.0, 0.8, 1.0, 1.0), checker);
}
