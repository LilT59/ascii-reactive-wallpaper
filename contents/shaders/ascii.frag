#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    float qt_Opacity;
    float iTime;
    float iDetail;
    float iMode;
    vec4 iColor;
};

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float starfield(vec2 cell)
{
    float seed = hash21(cell);
    if (seed > 0.06)
        return 0.0;
    float pulse = 0.5 + 0.5 * sin(iTime * (1.5 + seed * 4.0) + seed * 30.0);
    return 0.15 + pulse * 0.85;
}

float matrixRain(vec2 cell)
{
    float column = hash21(vec2(cell.x, 7.1));
    float speed = 4.0 + column * 9.0;
    float period = 18.0 + floor(column * 15.0);
    float head = mod(iTime * speed + column * 80.0, period);
    float distanceBehind = head - cell.y;
    if (distanceBehind < 0.0)
        distanceBehind += period;
    return clamp(1.0 - distanceBehind / 10.0, 0.0, 1.0);
}

float plasma(vec2 cell)
{
    vec2 p = cell * 0.12;
    float value = sin(p.x + iTime) + sin(p.y * 1.3 - iTime * 0.7);
    value += sin((p.x + p.y) * 0.7 + iTime * 0.5);
    return clamp(value / 6.0 + 0.5, 0.0, 1.0);
}

float pixel(vec2 p, float x, float y)
{
    return float(abs(p.x - x) < 0.5 && abs(p.y - y) < 0.5);
}

float horizontal(vec2 p, float y)
{
    return float(p.x >= 1.0 && p.x <= 3.0 && abs(p.y - y) < 0.5);
}

float vertical(vec2 p, float x)
{
    return float(p.y >= 1.0 && p.y <= 5.0 && abs(p.x - x) < 0.5);
}

float glyph(vec2 uv, float index)
{
    vec2 p = floor(uv * vec2(5.0, 7.0));
    if (index < 0.5)
        return 0.0;
    if (index < 1.5)
        return pixel(p, 2.0, 5.0);
    if (index < 2.5)
        return max(pixel(p, 2.0, 2.0), pixel(p, 2.0, 5.0));
    if (index < 3.5)
        return horizontal(p, 3.0);
    if (index < 4.5)
        return max(horizontal(p, 2.0), horizontal(p, 4.0));
    if (index < 5.5)
        return max(horizontal(p, 3.0), vertical(p, 2.0));
    if (index < 6.5) {
        float diagonal = float(abs(p.x - p.y + 1.0) < 0.5 || abs((4.0 - p.x) - p.y + 1.0) < 0.5);
        return max(diagonal, max(horizontal(p, 3.0), vertical(p, 2.0)));
    }
    if (index < 7.5) {
        float bars = max(vertical(p, 1.0), vertical(p, 3.0));
        return max(bars, max(horizontal(p, 2.0), horizontal(p, 4.0)));
    }
    if (index < 8.5) {
        float dots = max(pixel(p, 1.0, 1.0), pixel(p, 3.0, 5.0));
        return max(dots, float(abs(p.x + p.y - 6.0) < 0.5));
    }

    float ring = float((p.x == 0.0 || p.x == 4.0) && p.y >= 1.0 && p.y <= 5.0);
    ring = max(ring, float((p.y == 0.0 || p.y == 6.0) && p.x >= 1.0 && p.x <= 3.0));
    return max(ring, max(vertical(p, 2.0), horizontal(p, 3.0)));
}

void main()
{
    float columns = iDetail < 0.5 ? 220.0 : (iDetail < 1.5 ? 150.0 : 96.0);
    vec2 grid = vec2(columns, columns * 0.42);
    vec2 gridCoord = qt_TexCoord0 * grid;
    vec2 cell = floor(gridCoord);
    vec2 cellUv = fract(gridCoord);

    float brightness;
    vec3 foreground = max(iColor.rgb, vec3(0.2, 0.65, 0.8));
    if (iMode < 0.5) {
        brightness = starfield(cell);
    } else if (iMode < 1.5) {
        brightness = matrixRain(cell);
        foreground *= mix(0.35, 1.35, brightness);
    } else {
        brightness = plasma(cell);
        foreground = mix(iColor.rgb * 0.35, iColor.rgb, brightness);
    }

    float charIndex = floor(clamp(brightness, 0.0, 1.0) * 9.0);
    float glyphMask = glyph(cellUv, charIndex);

    vec3 background = vec3(0.006, 0.009, 0.015);
    vec3 outputColor = mix(background, foreground, glyphMask);
    fragColor = vec4(outputColor, 1.0);
}
