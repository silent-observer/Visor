#version 330 core
out vec4 FragColor;

in vec3 fColor;
in vec2 fTexCoord;

uniform sampler2D alphaTexture;

void main() {
    vec4 alpha = texture(alphaTexture, fTexCoord);
    FragColor = vec4(fColor, alpha.r);
}