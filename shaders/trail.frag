#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniforms for line segment
uniform vec2 uResolution;  // Canvas size
uniform vec2 uPoint1;      // Start point of line
uniform vec2 uPoint2;      // End point of line
uniform float uThickness;  // Line thickness
uniform vec4 uColor;       // Line color (premultiplied alpha)

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Calculate distance from fragment to line segment
    vec2 pa = fragCoord - uPoint1;
    vec2 ba = uPoint2 - uPoint1;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float dist = length(pa - ba * h);

    // Create smooth line with anti-aliasing
    float line = smoothstep(uThickness + 1.0, uThickness - 1.0, dist);

    // Output color with alpha based on line mask
    fragColor = uColor * line;
}
