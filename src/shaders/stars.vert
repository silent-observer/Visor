#version 330 core
layout (location = 0) in vec2 vertPos;
layout (location = 1) in vec2 texCoord;

layout (location = 2) in vec3 starPos;
layout (location = 3) in float size;
layout (location = 4) in vec3 color;

uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

out vec3 fColor;
out vec2 fTexCoord;

void main() {
    vec4 realStarPos = viewMatrix * vec4(starPos, 1.0);
    gl_Position = projectionMatrix * (realStarPos + size * vec4(vertPos, 0.0, 0.0));
    fColor = color;
    fTexCoord = texCoord;
}