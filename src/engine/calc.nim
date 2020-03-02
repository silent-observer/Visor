import glm

proc makeStarRotationMatrix*(cameraAzimuth: float, cameraAltitude: float): Mat4f =
  result = mat4f()
  result.rotateInplX(radians(-cameraAltitude))
  result.rotateInplY(radians(-cameraAzimuth))

proc projectionMatrix*(fov: float32): Mat4f = perspective[float32](radians(fov), 16/9, 0.01, 2)
proc projectionPlaneNormals*(fov: float32): array[4, Vec3f] = [
  vec3f(0, cos(radians(fov/2)), -sin(radians(fov/2))),
  vec3f(0, -cos(radians(fov/2)), -sin(radians(fov/2))),
  vec3f(cos(radians(fov/2 * 16/9)), 0, -sin(radians(fov/2 * 16/9))),
  vec3f(-cos(radians(fov/2 * 16/9)), 0, -sin(radians(fov/2 * 16/9)))
]