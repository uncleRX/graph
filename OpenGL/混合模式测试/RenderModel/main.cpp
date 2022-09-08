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
#include "AbcModule/ABCScene.hpp"
#include <math.h>

using namespace AbcModule;

void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void mouse_callback(GLFWwindow* window, double xpos, double ypos);
void scroll_callback(GLFWwindow* window, double xoffset, double yoffset);
void processInput(GLFWwindow *window);

// settings
const unsigned int SCR_WIDTH = 1280;
const unsigned int SCR_HEIGHT = 720;

// camera
Camera camera(glm::vec3(0.0f, 0.0f, 0.0f));
float lastX = SCR_WIDTH / 2.0f;
float lastY = SCR_HEIGHT / 2.0f;
bool firstMouse = true;

// timing
float deltaTime = 0.0f;
float lastFrame = 0.0f;

float currentTime = 0;

// bg
float fps = 25.f;
int bgPathStartIndex = 0;
String base_bgPath = "/Users/renxun/Desktop/测试素材/测试视频/results/1080x1920/遮罩在 layer1_";
String abc_path = "/Users/renxun/Desktop/xxx.abc";
AbcScene *g_scene;

void getConeVertext(int segmentation, float radius, float* outVertexData, int* outIndexData);

template<class... T>
std::string format(const char *fmt, const T&...t)
{
    const auto len = snprintf(nullptr, 0, fmt, t...);
    std::string r;
    r.resize(static_cast<size_t>(len) + 1);
    snprintf(&r.front(), len + 1, fmt, t...);  // Bad boy
    r.resize(static_cast<size_t>(len));
    return r;
}

String getBgPath() {
    return base_bgPath + format("%000d.png", bgPathStartIndex);
}

TextureModel* bgTexture;

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
    
    g_scene = new AbcScene(abc_path);
    g_scene->setTime(0);
    Shader shader("/Users/renxun/Desktop/file/Repository/音视频学习/图形API/OpenGL/混合模式测试/RenderModel/shader/simple.vs", "/Users/renxun/Desktop/file/Repository/音视频学习/图形API/OpenGL/混合模式测试/RenderModel/shader/simple.fs");

    bgTexture = new TextureModel("/Users/renxun/Desktop/20210323000614736.png");
    


    unsigned int VAO,VBO,EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    float vertices[] = {
          // Positions
        1.0,  1.0, -1.0f,   1.0f, 1.0f, // Top Right
        1.0, -1.0, -1.0f,   1.0f, 0.0f, // Bottom Right
        -1.0, -1.0, -1.0f,   0.0f, 0.0f, // Bottom Left
        -1.0,  1.0, -1.0f,   0.0f, 1.0f  // Top Left
      };

    int indices[] = {
        0, 1, 3,
        1, 2, 3
    };
    {
        glBindVertexArray(VAO);
        glBindBuffer(GL_ARRAY_BUFFER, VBO);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
        
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
        glEnableVertexAttribArray(1);
        glBindVertexArray(0);
    }
    bgTexture->load();
    glm::mat4 projection = glm::perspective(0.3887779116630554f, 1280.f/720.f, 0.1f, 100000.f);
    glm::mat4 view = camera.GetViewMatrix();
    glm::mat4 model = glm::mat4(1.0f);
    
    float scaleX = 1.0;
    float scaleY = 1.0;
    // 用最长的那边来做缩放, 可以保证显示完整
//    if (bgTexture->width >= bgTexture->height) {
//        float newHeight = SCR_WIDTH * bgTexture->height / bgTexture->width;
//        scaleY = newHeight / SCR_HEIGHT;
//    }
//
//    if (bgTexture->height >= bgTexture->width) {
//        float newWidth = SCR_HEIGHT * bgTexture->width / bgTexture->height;
//        scaleX = newWidth / SCR_WIDTH;
//    }
//    model = glm::scale(model, glm::vec3(scaleX, scaleY, 1.0));
    glm::mat4 mvp = projection * view * model;
    mvp = glm::mat4(1.0f);
    mvp = glm::scale(mvp, glm::vec3(scaleX, scaleY, 1.0));
    
    TextureModel bgTexture1("/Users/renxun/Desktop/截屏2022-03-07 下午3.56.12.png");
    bgTexture1.load();

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    //循环渲染
    while(!glfwWindowShouldClose(window)) {
        processInput(window);
        shader.use();
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, bgTexture->textureID);
        shader.setInt("texture1", 0);
        shader.setMat4("mvp", mvp);
        shader.setFloat("alpha", 1.0f);
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindVertexArray(VAO);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
        
        glBindTexture(GL_TEXTURE_2D, bgTexture1.textureID);
        shader.setInt("texture1", 0);
        shader.setMat4("mvp", mvp);
        shader.setFloat("alpha", 0.0f);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

        glBindVertexArray(0);
//        g_scene->draw();
        
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
        currentTime -= 1.0 / fps;
        bgPathStartIndex -= 1;
        if(currentTime < 0)
        {
            currentTime = 0;
            bgPathStartIndex = 0;
        }
        bgTexture->update(getBgPath());
        g_scene->setTime(currentTime);
    }
    if (glfwGetKey(window, GLFW_KEY_RIGHT) == GLFW_PRESS)
    {
        currentTime += 1.0 / fps;
        bgPathStartIndex += 1;
        if(currentTime > 10.0)
        {
            currentTime = 0;
            bgPathStartIndex=0;
        }
        bgTexture->update(getBgPath());
        g_scene->setTime(currentTime);
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
