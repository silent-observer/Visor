import opengl
import glfw
import stb_image/read as stbi
import glm
import engine/calc
from engine/db import StarData
import globalVars

const MaxStarsPerScreen = 20000

type
  OpenGLData = object
    window*: Window
    starTexture: GLuint
    starArrayObject: GLuint
    starShader: GLuint
    starPositionBuffer: GLuint
    lineArrayObject: GLuint
    meridianShader: Gluint
    parallelShader: GLuint
    groundArrayObject: Gluint
    groundTexture: Gluint
    groundShader: Gluint

proc createTexture(filename: string): GLuint =
  var w, h, channels: int
  var data = stbi.load(filename, w, h, channels, stbi.Default)
  echo w, ":", h, ", ", channels
  let format = case channels:
    of 1: GL_RED
    of 2: GL_RG
    of 3: GL_RGB
    of 4: GL_RGBA
    else: GL_RGB
  
  glGenTextures(1, addr result)
  glBindTexture(GL_TEXTURE_2D, result)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

  glTexImage2D(GL_TEXTURE_2D, 0, format.GLint, 
               w.GLsizei, h.GLsizei, 
               0, format, GL_UNSIGNED_BYTE, addr data[0])

proc createShaders(vertexText: string, fragmentText: string): GLuint =
  let vertexShader = glCreateShader(GL_VERTEX_SHADER)
  let vertexShaderSrc = allocCStringArray([vertexText])
  glShaderSource(vertexShader, 1, vertexShaderSrc, nil)
  glCompileShader(vertexShader)
  var success: Glint
  glGetShaderiv(vertexShader, GL_COMPILE_STATUS, addr success)
  if success == 0:
    var info = newString(512)
    glGetShaderInfoLog(vertexShader, 512, nil, info)
    echo "Error 1: ", info
    quit(1)
  vertexShaderSrc.deallocCStringArray()
  
  let fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
  let fragmentShaderSrc = allocCStringArray([fragmentText])
  glShaderSource(fragmentShader, 1, fragmentShaderSrc, nil)
  glCompileShader(fragmentShader)
  glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, addr success)
  if success == 0:
    var info = newString(512)
    glGetShaderInfoLog(fragmentShader, 512, nil, info)
    echo "Error 2: ", info
    quit(1)
  fragmentShaderSrc.deallocCStringArray()

  result = glCreateProgram()
  glAttachShader(result, vertexShader)
  glAttachShader(result, fragmentShader)
  glLinkProgram(result)
  glGetProgramiv(result, GL_LINK_STATUS, addr success)
  if success == 0:
    var info = newString(512)
    glGetProgramInfoLog(result, 512, nil, info)
    echo "Error 3: ", info
    quit(1)
  glDeleteShader(vertexShader)
  glDeleteShader(fragmentShader)

proc configureStarBuffers(data: var OpenGLData) =
  glGenVertexArrays(1, addr data.starArrayObject)
  glBindVertexArray(data.starArrayObject)

  var starVertexBuffer: GLuint
  var starVertexData = [
    0.005'f, 0.005, 1.0, 1.0,
    0.005, -0.005, 1.0, 0.0,
    -0.005, -0.005, 0.0, 0.0,

    0.005'f, 0.005, 1.0, 1.0,
    -0.005, 0.005, 0.0, 1.0,
    -0.005, -0.005, 0.0, 0.0,
  ]
  glGenBuffers(1, addr starVertexBuffer)
  glBindBuffer(GL_ARRAY_BUFFER, starVertexBuffer)
  glBufferData(GL_ARRAY_BUFFER, sizeof(starVertexData), addr starVertexData[0], GL_STATIC_DRAW)
  glBindBuffer(GL_ARRAY_BUFFER, 0)

  glGenBuffers(1, addr data.starPositionBuffer)
  glBindBuffer(GL_ARRAY_BUFFER, data.starPositionBuffer)
  glBufferData(GL_ARRAY_BUFFER, sizeof(Vec3f) * MaxStarsPerScreen, nil, GL_STREAM_DRAW)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  
  const starShaderVertexText = staticRead"shaders/stars.vert"
  const starShaderFragText = staticRead"shaders/stars.frag"
  data.starShader = createShaders(starShaderVertexText, starShaderFragText)
  
  glBindBuffer(GL_ARRAY_BUFFER, starVertexBuffer)
  glVertexAttribPointer(0, 2, cGL_FLOAT, GL_FALSE, 4 * float32.sizeof, cast[pointer](0))
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(1, 2, cGL_FLOAT, GL_FALSE, 4 * float32.sizeof, cast[pointer](2 * float32.sizeof))
  glEnableVertexAttribArray(1)
  glBindBuffer(GL_ARRAY_BUFFER, 0)

  glBindBuffer(GL_ARRAY_BUFFER, data.starPositionBuffer)
  glVertexAttribPointer(2, 3, cGL_FLOAT, GL_FALSE, 7 * float32.sizeof, cast[pointer](0))
  glEnableVertexAttribArray(2)
  glVertexAttribPointer(3, 1, cGL_FLOAT, GL_FALSE, 7 * float32.sizeof, cast[pointer](3 * float32.sizeof))
  glEnableVertexAttribArray(3)
  glVertexAttribPointer(4, 3, cGL_FLOAT, GL_FALSE, 7 * float32.sizeof, cast[pointer](4 * float32.sizeof))
  glEnableVertexAttribArray(4)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glVertexAttribDivisor(2, 1)
  glVertexAttribDivisor(3, 1)
  glVertexAttribDivisor(4, 1)

proc configureLineBuffers(data: var OpenGLData) =
  glGenVertexArrays(1, addr data.lineArrayObject)
  glBindVertexArray(data.lineArrayObject)

  const meridianShaderVertexText = staticRead"shaders/meridian.vert"
  const parallelShaderVertexText = staticRead"shaders/parallel.vert"
  const basicShaderFragText = staticRead"shaders/basic.frag"
  data.meridianShader = createShaders(meridianShaderVertexText, basicShaderFragText)
  data.parallelShader = createShaders(parallelShaderVertexText, basicShaderFragText)
  glBindBuffer(GL_ARRAY_BUFFER, 0)

proc configureGroundBuffers(data: var OpenGLData) =
  glGenVertexArrays(1, addr data.groundArrayObject)
  glBindVertexArray(data.groundArrayObject)

  const basicTextureShaderVertexText = staticRead"shaders/basicTexture.vert"
  const basicTextureShaderFragText = staticRead"shaders/basicTexture.frag"
  data.groundShader = createShaders(basicTextureShaderVertexText, basicTextureShaderFragText)
  
  var groundVertexBuffer: GLuint
  var groundVertexData = [
    1'f, -0.02, 1, 5.0, 5.0,
    -1'f, -0.02, 1, 0.0, 5.0,
    1'f, -0.02, -1, 5.0, 0.0,

    -1'f, -0.02, 1, 0.0, 5.0,
    1'f, -0.02, -1, 5.0, 0.0,
    -1'f, -0.02, -1, 0.0, 0.0,
  ]
  glGenBuffers(1, addr groundVertexBuffer)
  glBindBuffer(GL_ARRAY_BUFFER, groundVertexBuffer)
  glBufferData(GL_ARRAY_BUFFER, sizeof(groundVertexData), addr groundVertexData[0], GL_STATIC_DRAW)

  glVertexAttribPointer(0, 3, cGL_FLOAT, GL_FALSE, 5 * float32.sizeof, cast[pointer](0))
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(1, 2, cGL_FLOAT, GL_FALSE, 5 * float32.sizeof, cast[pointer](3 * float32.sizeof))
  glEnableVertexAttribArray(1)

proc initEverything*(): OpenGLData =
  glfw.initialize()
  var c = DefaultOpenglWindowConfig
  c.size = (w: 1280, h: 720)
  c.title = "Visor"
  c.resizable = true
  c.version = glv33
  c.profile = opCoreProfile

  var window = newWindow(c)

  loadExtensions()

  glViewport(0, 0, 1280, 720)
  proc framebufferSizeCallback(win: Window, res: tuple[w, h: int32]) =
    glViewport(0, 0, res.w, res.h)
  
  var lastX, lastY: float64
  var isFirstMouse = true
  proc mouseCallback(win: Window, pos: tuple[x, y: float64]) =
    if not win.mouseButtonDown(mbLeft):
      isFirstMouse = true
      return
    if isFirstMouse:
      isFirstMouse = false
      lastX = pos.x
      lastY = pos.y
    let offsetX = pos.x - lastX
    let offsetY = pos.y - lastY
    let sensitivity = fov / 800
    cameraAzimuth += sensitivity * offsetX / cos(radians(cameraAltitude)).clamp(0.995, 1)
    cameraAltitude += sensitivity * offsetY
    cameraAltitude = cameraAltitude.clamp(-89, 89)
    lastX = pos.x
    lastY = pos.y
  proc scrollCallback(win: Window, offset: tuple[x, y: float64]) =
    fov -= offset.y
    fov = fov.clamp(1, 60)
    
  window.framebufferSizeCb = framebufferSizeCallback
  window.cursorPositionCb = mouseCallback
  window.scrollCb = scrollCallback

  result.window = window
  result.starTexture = createTexture("textures/star16x16.png")
  result.groundTexture = createTexture("textures/water_texture.jpg")
  glGenerateMipmap(GL_TEXTURE_2D)

  result.configureStarBuffers()
  result.configureLineBuffers()
  result.configureGroundBuffers()

  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

proc configureMatrices(shader: GLuint, viewMatrix: Mat4f, projectionMatrix: Mat4f) =
  glUniformMatrix4fv(glGetUniformLocation(shader, "projectionMatrix"),
                     1, GL_FALSE, projectionMatrix.arr[0].arr[0].unsafeAddr)
  glUniformMatrix4fv(glGetUniformLocation(shader, "viewMatrix"),
                     1, GL_FALSE, viewMatrix.arr[0].arr[0].unsafeAddr)

proc activateStars(data: OpenGLData, viewMatrix: Mat4f, projectionMatrix: Mat4f) =
  glUseProgram(data.starShader)
  data.starShader.configureMatrices(viewMatrix, projectionMatrix)
  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, data.starTexture)

proc drawStars*(data: OpenGLData, starData: seq[float32], viewMatrix: Mat4f, projectionMatrix: Mat4f) =
  if starData.len > 0:
    data.activateStars(viewMatrix, projectionMatrix)
    glBindBuffer(GL_ARRAY_BUFFER, data.starPositionBuffer)
    glBufferData(GL_ARRAY_BUFFER, 7 * sizeof(float32) * MaxStarsPerScreen, nil, GL_STREAM_DRAW)
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(float32) * starData.len.GLsizei, unsafeAddr starData[0])
    glBindVertexArray(data.starArrayObject)
    glDrawArraysInstanced(GL_TRIANGLES, 0, 6, starData.len.GLsizei div 7)

proc drawLines*(data: OpenGLData, viewMatrix: Mat4f, projectionMatrix: Mat4f) =
  glUseProgram(data.meridianShader)
  data.meridianShader.configureMatrices(viewMatrix, projectionMatrix)
  glBindVertexArray(data.lineArrayObject)
  glDrawArraysInstanced(GL_LINE_LOOP, 0, 100, 9)

  glUseProgram(data.parallelShader)
  data.parallelShader.configureMatrices(viewMatrix, projectionMatrix)
  glDrawArraysInstanced(GL_LINE_LOOP, 0, 100, 17)

proc drawGround*(data: OpenGLData, viewMatrix: Mat4f, projectionMatrix: Mat4f) =
  glUseProgram(data.groundShader)
  data.groundShader.configureMatrices(viewMatrix, projectionMatrix)
  glUniform4f(glGetUniformLocation(data.groundShader, "color"), 0.7 * 0.8, 0.9 * 0.8, 0.8, 0.8)

  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, data.groundTexture)

  glBindVertexArray(data.groundArrayObject)
  glDrawArrays(GL_TRIANGLES, 0, 6)

proc starDataToVBO*(starData: seq[StarData]): seq[float32] =
  result = newSeqOfCap[float32](starData.len * 7)
  for s in starData:
    result &= [s.pos.x, s.pos.y, s.pos.z]
    result &= 1.5 * (1 - 0.0006 * float32(s.mag + 146)) * (fov / 40)
    result &= (case s.starClass[0]:
      of 'O': [0.607'f, 0.690, 1]
      of 'B': [0.666'f, 0.749, 1]
      of 'A': [0.792'f, 0.843, 1]
      of 'F': [0.972'f, 0.968, 1]
      of 'G': [1'f, 0.956, 0.917]
      of 'K': [1'f, 0.823, 0.631]
      of 'M': [1'f, 0.8  , 0.435]
      else: [1'f, 1, 1])