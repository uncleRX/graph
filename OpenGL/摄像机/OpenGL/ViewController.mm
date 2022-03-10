//
//  ViewController.m
//  OpenGL
//
//  Created by 任迅 on 2021/9/14.
//

#import "ViewController.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import "CGLView.h"
#import "GLESUtil.h"
#import "FileLoader.h"
#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
#import <glm/gtc/type_ptr.hpp>
#include <stdio.h>


#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define CHECK_ERROR     int result = glGetError(); \
                        NSLog(@"result = %d",result);

glm::vec3 cubePositions[] = {
    glm::vec3( 0.0f,  0.0f,  0.0f),
    glm::vec3( 0.4f,  0.6f, -15.0f),
    glm::vec3(-1.5f, -2.2f, -2.5f),
    glm::vec3(-3.8f, -2.0f, -12.3f),
    glm::vec3( 2.4f, -0.4f, -3.5f),
    glm::vec3(-1.7f,  3.0f, -7.5f),
    glm::vec3( 1.3f, -2.0f, -2.5f),
    glm::vec3( 1.5f,  -0.4f, -2.5f),
    glm::vec3( 1.5f,  0.2f, -1.5f),
    glm::vec3(-1.3f,  1.0f, -1.5f)
};

float vertices[] = {
    -0.5f, -0.5f, -0.5f,  0.0f, 0.0f,
     0.5f, -0.5f, -0.5f,  1.0f, 0.0f,
     0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
     0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
    -0.5f,  0.5f, -0.5f,  0.0f, 1.0f,
    -0.5f, -0.5f, -0.5f,  0.0f, 0.0f,

    -0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
     0.5f, -0.5f,  0.5f,  1.0f, 0.0f,
     0.5f,  0.5f,  0.5f,  1.0f, 1.0f,
     0.5f,  0.5f,  0.5f,  1.0f, 1.0f,
    -0.5f,  0.5f,  0.5f,  0.0f, 1.0f,
    -0.5f, -0.5f,  0.5f,  0.0f, 0.0f,

    -0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
    -0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
    -0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
    -0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
    -0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
    -0.5f,  0.5f,  0.5f,  1.0f, 0.0f,

     0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
     0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
     0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
     0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
     0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
     0.5f,  0.5f,  0.5f,  1.0f, 0.0f,

    -0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
     0.5f, -0.5f, -0.5f,  1.0f, 1.0f,
     0.5f, -0.5f,  0.5f,  1.0f, 0.0f,
     0.5f, -0.5f,  0.5f,  1.0f, 0.0f,
    -0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,  0.0f, 1.0f,

    -0.5f,  0.5f, -0.5f,  0.0f, 1.0f,
     0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
     0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
     0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
    -0.5f,  0.5f,  0.5f,  0.0f, 0.0f,
    -0.5f,  0.5f, -0.5f,  0.0f, 1.0f
};

@interface ViewController ()
{
    EAGLContext *context;
    GLuint shaderProgram;
    GLuint frameBuff;
    
    GLuint colorBuff;
    GLuint deepthBuff;
    GLuint VAO;
}

@property (nonatomic, strong) CGLView *glView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) float aspect;
@property (nonatomic, assign) float glWidth;
@property (nonatomic, assign) float glHeight;

// 移动的值
@property (nonatomic, assign) float moveX;
@property (nonatomic, assign) float moveY;
@property (nonatomic, assign) float moveZ;
@property (weak, nonatomic) IBOutlet UIButton *upButton;
@property (weak, nonatomic) IBOutlet UIButton *downButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self _prepareData];
    [self _setContext];
    [self _buildGLViewAndBindBuffer];
    [self _loadShader];
    [self _drawATriangle];
}

- (IBAction)yUp:(id)sender {
    self.moveY += 10.f;
    [self renderWithCamera];
}

- (IBAction)yDown:(id)sender {
    self.moveY -= 10.f;
    [self renderWithCamera];
}

- (void)_prepareData {
    float scale = [UIScreen mainScreen].scale;
    float width = self.view.frame.size.width * scale;
    float height = self.view.frame.size.height * scale;
    float aspect = width / height;
    self.glWidth = width;
    self.glHeight = height;
    self.aspect = aspect;
    
    //移动值初始化
    self.moveX = 0.0f;
    self.moveY = 0.0f;
    self.moveZ = -500;
}

- (IBAction)forward:(id)sender {
    self.moveZ += 10;
    [self renderWithCamera];
}

- (IBAction)back:(id)sender {
    self.moveZ -= 10;
    [self renderWithCamera];
}

- (IBAction)left:(id)sender {
    self.moveX -= 10;
    [self renderWithCamera];
}

- (IBAction)right:(id)sender {
    self.moveX += 10;
    [self renderWithCamera];
}


- (void)renderWithCamera {
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram(shaderProgram);
    
    // 创建mvp矩阵 (先初始化单位矩阵再做变换)
    glm::mat4 view          = glm::mat4(1.0f);
    glm::mat4 projection    = glm::mat4(1.0f);
    
    glm::vec3 cameraPos = glm::vec3(self.moveX, self.moveY, self.moveZ);
    glm::vec3 cameraTarget = glm::vec3(0.0f, 0.0f, 0.0f);
    glm::vec3 up = glm::vec3(0.0f, 1.0f, 0.0f);
    
    view = glm::lookAt(cameraPos, cameraTarget, up);
    
    projection = glm::perspective(glm::radians(45.0f), self.aspect, 0.1f, 1000.f);
    glBindVertexArray(VAO);
    unsigned int viewLoc = glGetUniformLocation(shaderProgram, "view");
    unsigned int projectionLoc = glGetUniformLocation(shaderProgram, "projection");
    glUniformMatrix4fv(viewLoc, 1, GL_FALSE, &view[0][0]);
    glUniformMatrix4fv(projectionLoc, 1, GL_FALSE, glm::value_ptr(projection));
    
    for (int i = 0; i < 10; ++i) {
        // calculate the model matrix for each object and pass it to shader before drawing
        glm::mat4 model = glm::mat4(1.0f);
        model = glm::translate(model, cubePositions[i]);
        float angle = 60.0f * i;
        model = glm::rotate(model, glm::radians(angle), glm::vec3(1.0f, 0.3f, 0.5f));
        unsigned int modelLoc = glGetUniformLocation(shaderProgram, "model");
        glUniformMatrix4fv(modelLoc, 1, GL_FALSE, glm::value_ptr(model));
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
    // 重新绑定颜色缓冲
    [context presentRenderbuffer:self->colorBuff];
}

- (IBAction)addCamera:(id)sender {
    [self.link setPaused:YES];
    [self renderWithCamera];
}

- (void)_drawATriangle {
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // 顶点缓存
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glUseProgram(shaderProgram);
    
    GLint podsL = glGetAttribLocation(shaderProgram, "aPos");
    GLint coordL = glGetAttribLocation(shaderProgram, "aTexCoord");

    // 复制顶点数据到缓存对象中供GPU使用
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(podsL, 3, GL_FLOAT, GL_FALSE, (3+2) * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    
    // 纹理数据
    glVertexAttribPointer(coordL, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
    
    // 生成纹理1
    GLuint texture1;
    glGenTextures(1, &texture1);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture1);
    
    // 为当前绑定的纹理对象设置环绕、过滤方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    ImageFile *file1 = [FileLoader loadImage:@"wall" type:@"jpeg"];
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, file1.width, file1.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, file1.byte);
    
    // 生成纹理2
    GLuint texture2;
    glGenTextures(1, &texture2);
    // 看这里激活的哪个单元,到时候就使用哪个单元.
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, texture2);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    ImageFile *file2 = [FileLoader loadImage:@"awesomeface" type:@"png"];
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, file2.width, file2.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, file2.byte);
    glGenerateMipmap(GL_TEXTURE_2D);

    //告诉OpenGL每个着色器采样器属于哪个纹理单元
    unsigned int location1 = glGetUniformLocation(shaderProgram, "texture1");
    unsigned int location2 = glGetUniformLocation(shaderProgram, "texture2");

    glUniform1i(location1, 0);
    glUniform1i(location2, 4);
    glm::mat4 view          = glm::mat4(1.0f);
    glm::mat4 projection    = glm::mat4(1.0f);
    
    view = glm::translate(view, glm::vec3(0.0f, 0.0f, self.moveZ));
    projection = glm::perspective(glm::radians(45.0f), self.aspect, 0.1f, 1000.f);
    unsigned int viewLoc = glGetUniformLocation(shaderProgram, "view");
    unsigned int projectionLoc = glGetUniformLocation(shaderProgram, "projection");

    glUniformMatrix4fv(viewLoc, 1, GL_FALSE, &view[0][0]);
    glUniformMatrix4fv(projectionLoc, 1, GL_FALSE, glm::value_ptr(projection));
    
    for (int i = 0; i < 10; ++i) {
        glm::mat4 model = glm::mat4(1.0f);
        model = glm::translate(model, cubePositions[i]);
        float angle = 60.0f * i;
        model = glm::rotate(model, glm::radians(angle), glm::vec3(1.0f, 0.3f, 0.5f));
        
        unsigned int modelLoc = glGetUniformLocation(shaderProgram, "model");
        glUniformMatrix4fv(modelLoc, 1, GL_FALSE, glm::value_ptr(model));
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
    glBindRenderbuffer(GL_RENDERBUFFER, self->colorBuff);
    [context presentRenderbuffer:self->colorBuff];
}

#pragma mark - 初始化

- (void)_buildGLViewAndBindBuffer {
    CGLView *glView = [CGLView new];
    glView.backgroundColor = UIColor.lightGrayColor;
    [self.view addSubview:glView];
    [self.view sendSubviewToBack:glView];
    glView.frame = CGRectMake(0, 0, kWidth, kHeight);
    
    // 创建渲染缓存 - 存储像素数据
    GLuint render[2];
    glGenRenderbuffers(2, render);
    self->colorBuff = render[0];
    self->deepthBuff = render[1];
    
    // 创建帧缓存
    glGenFramebuffers(1, &frameBuff);
    
    // GL_FRAMEBUFFER
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuff);
    glBindRenderbuffer(GL_RENDERBUFFER, colorBuff);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self->colorBuff);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)glView.layer];
    
    GLint width = 0;
    GLint height = 0;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    glBindRenderbuffer(GL_RENDERBUFFER, deepthBuff);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, self->deepthBuff);
    
    glViewport(0,0, self.glWidth, self.glHeight);
    glEnable(GL_DEPTH_TEST);
}

- (void)_setContext {
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 3.0 context");
        return;
    }
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set context");
        return;
    }
}

- (void)_loadShader {
    self->shaderProgram = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertexShader"
                                                         fragmentShaderName:@"fragmentShader"];
}



@end
