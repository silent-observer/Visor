# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import glad/gl
import glfw

glfw.initialize()
var c = DefaultOpenglWindowConfig
c.size = (w: 800, h: 600)
c.title = "Visor"
c.resizable = true
c.version = glv33
c.profile = opCoreProfile

var window = newWindow(c)

if not gladLoadGL(getProcAddress):
  quit "Error initialising OpenGL"

glViewport(0, 0, 800, 600)
proc framebufferSizeCallback(win: Window, res: tuple[w, h: int32]) =
  glViewport(0, 0, res.w, res.h)
window.framebufferSizeCb = framebufferSizeCallback

while not window.shouldClose:
  glfw.swapBuffers(window)
  glfw.pollEvents()

window.destroy()
glfw.terminate()