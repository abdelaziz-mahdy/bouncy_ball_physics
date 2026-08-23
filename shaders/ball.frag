#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniforms for ball position, radius, and color
uniform vec2 uResolution;  // Canvas size
uniform vec2 uPosition;    // Ball center position
uniform float uRadius;     // Ball radius
uniform vec4 uColor;       // Ball color (premultiplied alpha)

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Calculate distance from fragment to ball center
    float dist = distance(fragCoord, uPosition);

    // Create smooth circle with anti-aliasing
    float circle = smoothstep(uRadius + 1.0, uRadius - 1.0, dist);

    // Output color with alpha based on circle mask
    fragColor = uColor * circle;
}
