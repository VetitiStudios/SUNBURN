local ffi = require("ffi")

-- GLFW bindings (minimal subset)
ffi.cdef[[
typedef struct GLFWwindow GLFWwindow;

int glfwInit(void);
void glfwTerminate(void);

GLFWwindow* glfwCreateWindow(int width, int height, const char* title, void* monitor, void* share);
void glfwMakeContextCurrent(GLFWwindow* window);

int glfwWindowShouldClose(GLFWwindow* window);
void glfwSwapBuffers(GLFWwindow* window);
void glfwPollEvents(void);

double glfwGetTime(void);
]]

local glfw = ffi.load("glfw")

-- OpenGL (minimal)
ffi.cdef[[
void glClearColor(float r, float g, float b, float a);
void glClear(unsigned int mask);
]]

local gl = ffi.load("GL")

local GL_COLOR_BUFFER_BIT = 0x00004000

-- init
assert(glfw.glfwInit() == 1, "GLFW init failed")

local window = glfw.glfwCreateWindow(800, 600, "SUNBURN", nil, nil)
assert(window ~= nil, "Window creation failed")

glfw.glfwMakeContextCurrent(window)

-- main loop
while glfw.glfwWindowShouldClose(window) == 0 do
    gl.glClearColor(0.1, 0.2, 0.3, 1.0)
    gl.glClear(GL_COLOR_BUFFER_BIT)

    glfw.glfwSwapBuffers(window)
    glfw.glfwPollEvents()
end

glfw.glfwTerminate()