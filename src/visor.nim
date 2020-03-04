# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import openglConfiguration
import glfw
import opengl
import engine/[calc, db]
import times
import sequtils
import glm
import globalVars
from math import `^`

const TargetFramerate = 60

proc main() =
  let starMap = readStarMap("data/stars.map")
  var data = initEverything()

  var lastTimeFPS = epochTime()
  var lastTimeFrameLimiter = epochTime()
  var frameCount = 0

  while not data.window.shouldClose:
    let currTime = epochTime()
    if currTime - lastTimeFrameLimiter <= 1 / TargetFramerate:
      continue
    lastTimeFrameLimiter += 1 / TargetFramerate

    glClearColor(0, 0, 0, 1)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    let viewMatrix = makeStarRotationMatrix(cameraAzimuth, cameraAltitude)
    let viewMatrixInverse = inverse(viewMatrix)
    let projectionMatrix = projectionMatrix(fov)

    let newNormals = projectionPlaneNormals(fov).map(
      proc (n: Vec3f): Vec3f =
        let v = viewMatrixInverse * vec4f(n, 1)
        return vec3f(v.x, v.y, v.z)
    )

    let starRegions = whichAreInsideRect(newNormals)
    let minMag = int((2.04 / (0.0016 * fov + 0.47))^5)
    let stars = starRegions.mapIt(starMap.map[it]).concat().filterIt(it.mag < minMag)

    data.drawStars(stars.starDataToVBO, viewMatrix, projectionMatrix)
    data.drawLines(viewMatrix, projectionMatrix)
    data.drawGround(viewMatrix, projectionMatrix)

    data.window.swapBuffers()
    glfw.pollEvents()

    frameCount.inc
    if currTime - lastTimeFPS >= 1:
      echo "FPS: ", frameCount, ", ", stars.len, " stars"
      if stars.len < 10:
        echo stars
      lastTimeFPS += 1
      frameCount = 0
  
  data.window.destroy()
  glfw.terminate()
main()