#version 330 core
out vec4 FragColor;

in vec4 fColor;
in vec2 fTexCoord;

uniform sampler2D tex;

void main() {
    FragColor = fColor * texture(tex, fTexCoord);
}