#version 330 core

#define M_PI 3.1415926535897932384626433832795
#define VERTEX_COUNT 100
#define PARALLEL_COUNT 9

uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

out vec4 fColor;

void main() {
    int id = gl_InstanceID - 8;
    float altitudeAngle = (M_PI/2 / PARALLEL_COUNT) * id;
    float mainAngle = (2 * M_PI / VERTEX_COUNT) * gl_VertexID;
    vec4 pos = vec4(
        cos(altitudeAngle) * cos(mainAngle),
        sin(altitudeAngle),
        cos(altitudeAngle) * sin(mainAngle),
        1
    );
    gl_Position = projectionMatrix * viewMatrix * pos;
    if (id == 0)
        fColor = vec4(1, 0, 0, 0.2);
    else
        fColor = vec4(0, 1, 0, 0.2);
}