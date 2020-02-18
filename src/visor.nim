# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import opengl
import glfw

proc main() =
  glfw.initialize()
  var c = DefaultOpenglWindowConfig
  c.size = (w: 800, h: 600)
  c.title = "Visor"
  c.resizable = true
  c.version = glv33
  c.profile = opCoreProfile

  var window = newWindow(c)

  loadExtensions()

  glViewport(0, 0, 800, 600)
  proc framebufferSizeCallback(win: Window, res: tuple[w, h: int32]) =
    glViewport(0, 0, res.w, res.h)
  window.framebufferSizeCb = framebufferSizeCallback

  glfw.swapInterval(1)

  while not window.shouldClose:
    glfw.pollEvents()

    glClearColor(0.2, 0.3, 0.3, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

    glfw.swapBuffers(window)
  window.destroy()
  glfw.terminate()

main()