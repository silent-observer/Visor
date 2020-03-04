#version 330 core
layout (location = 0) in vec3 vertPos;
layout (location = 1) in vec2 texCoord;

uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;
uniform vec4 color;

out vec4 fColor;
out vec2 fTexCoord;

void main() {
    gl_Position = projectionMatrix * viewMatrix * vec4(vertPos, 1);
    fColor = color;
    fTexCoord = texCoord;
}