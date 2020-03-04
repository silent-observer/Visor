#version 330 core

#define M_PI 3.1415926535897932384626433832795
#define VERTEX_COUNT 100
#define MERIDIAN_COUNT (18 / 2)

uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

out vec4 fColor;

void main() {
    float azimuthAngle = (M_PI / MERIDIAN_COUNT) * gl_InstanceID;
    float mainAngle = (2 * M_PI / VERTEX_COUNT) * gl_VertexID;
    vec4 pos = vec4(
        cos(mainAngle) * cos(azimuthAngle),
        sin(mainAngle),
        cos(mainAngle) * sin(azimuthAngle),
        1
    );
    gl_Position = projectionMatrix * viewMatrix * pos;
    fColor = vec4(0, 1, 0, 0.2);
}