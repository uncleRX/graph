//
//  main.cpp
//  RenderModel
//
//  Created by 任迅 on 2022/6/23.
//

#include "Depends.h"
#include "shader_m.h"
#include "camera.h"
#include "model.h"
#include <iostream>
#include <string>
#include "GLUT/glut.h"
#include "TextureModel.hpp"
#include <time.h>
#include <math.h>
#include "DrawPicture.hpp"
#include "DrawAlembic.hpp"


using namespace AbcModule;
using namespace Alembic::Abc;
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void mouse_callback(GLFWwindow* window, double xpos, double ypos);
void scroll_callback(GLFWwindow* window, double xoffset, double yoffset);
void processInput(GLFWwindow *window);

// settings
const unsigned int SCR_WIDTH = 1080/2;
const unsigned int SCR_HEIGHT = 1920/2;

// camera
Camera camera(glm::vec3(0.0f, 0.0f, 0.0f));
float lastX = SCR_WIDTH / 2.0f;
float lastY = SCR_HEIGHT / 2.0f;
bool firstMouse = true;

// timing
float deltaTime = 0.0f;
float lastFrame = 0.0f;

//String abc_path = "/Users/renxun/Desktop/测试素材/跟踪尺寸测试/c4d.abc";
//String abc_path = "/Users/renxun/Desktop/测试素材/跟踪尺寸测试/1080x1920/lockdown.abc";

String abc_path = "/Users/renxun/Desktop/测试素材/跟踪尺寸测试/1080x1920/lockdown_中间.abc";
//String abc_path = "/Users/renxun/Desktop/测试素材/跟踪尺寸测试/1080x1920/左上lockdown.abc";
//String abc_path = "/Users/renxun/Desktop/测试素材/跟踪尺寸测试/1080x1920/lockdown_3个点.abc";

//String abc_path = "/Users/renxun/Desktop/测试素材/跟踪尺寸测试/1080x1920/lockdown底部.abc";

//String abc_path = "/Users/renxun/Desktop/测试素材/跟踪尺寸测试/1080x1920/右下lockdown.abc";
//String abc_path = "/Users/renxun/Desktop/测试素材/跟踪尺寸测试/1080x1920/无遮挡25fps.abc";

//String abc_bg_path = "/Users/renxun/Desktop/测试素材/爱思壁纸_932223.jpg";
//String abc_bg_path = "/Users/renxun/Desktop/测试素材/跟踪尺寸测试/1080x1920/bg_左上.png";
String abc_bg_path = "/Users/renxun/Desktop/测试素材/跟踪尺寸测试/1080x1920/bg_4.png";

String bg_path = "/Users/renxun/Desktop/测试素材/跟踪尺寸测试/1080x1920/bg.png";

int main() {
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif
    // 创建窗口
    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "RenderSomething", nullptr, nullptr);
    if (window == nullptr)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    
    // glad: load all OpenGL function pointers
    // ---------------------------------------
    //把OpenGL的函数指针导入给GLAD
    if(!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
        std::cout << "Failed to initialize GLAD" << std::endl;
        return -1;
    }
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    glfwSetCursorPosCallback(window, mouse_callback);
    glfwSetScrollCallback(window, scroll_callback);
    
    DrawOnePicture bg(bg_path);
    DrawAlembic abc(abc_path, abc_bg_path);
    bg.prepare();
    //循环渲染
    while(!glfwWindowShouldClose(window)) {
        processInput(window);
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        bg.draw();
        abc.draw();
        //交换缓存
        glfwSwapBuffers(window);
        //事件处理
        glfwPollEvents();
    }
    glfwTerminate();
    return 0;
}

void processInput(GLFWwindow *window) {
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
    {
        glfwSetWindowShouldClose(window, true);
    }
    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
    {
        camera.ProcessKeyboard(FORWARD, deltaTime);
    }
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
    {
        camera.ProcessKeyboard(BACKWARD, deltaTime);
    }
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
    {
        camera.ProcessKeyboard(LEFT, deltaTime);
    }
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
    {
        camera.ProcessKeyboard(RIGHT, deltaTime);
    }
    if (glfwGetKey(window, GLFW_KEY_LEFT) == GLFW_PRESS)
    {
    }
    if (glfwGetKey(window, GLFW_KEY_RIGHT) == GLFW_PRESS)
    {
    }
}

// glfw: whenever the window size changed (by OS or user resize) this callback function executes
// ---------------------------------------------------------------------------------------------
void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    // make sure the viewport matches the new window dimensions; note that width and
    // height will be significantly larger than specified on retina displays.
    glViewport(0, 0, width, height);
}

// glfw: whenever the mouse moves, this callback is called
// -------------------------------------------------------
void mouse_callback(GLFWwindow* window, double xposIn, double yposIn)
{
    float xpos = static_cast<float>(xposIn);
    float ypos = static_cast<float>(yposIn);
    
    if (firstMouse)
    {
        lastX = xpos;
        lastY = ypos;
        firstMouse = false;
    }
    
    float xoffset = xpos - lastX;
    float yoffset = lastY - ypos; // reversed since y-coordinates go from bottom to top
    
    lastX = xpos;
    lastY = ypos;
    
    camera.ProcessMouseMovement(xoffset, yoffset);
}

// glfw: whenever the mouse scroll wheel scrolls, this callback is called
// ----------------------------------------------------------------------
void scroll_callback(GLFWwindow* window, double xoffset, double yoffset)
{
    camera.ProcessMouseScroll(static_cast<float>(yoffset));
}
