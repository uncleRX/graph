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
#import "UIImage+Util.h"
#import "ImageHelper.h"

#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()
{
    EAGLContext *context;
    GLuint shaderProgram;
    GLuint frameBuff;
    GLuint renderBuff;
    
    // FBO test
    GLuint textureID1;
    GLuint frameBufferID;
    
    GLuint textureID2;
    GLuint renderBufferID2;
    
    
    int width;
    int height;

}
@property (nonatomic, strong) CGLView *glView;
@property (nonatomic, assign) CGPoint lastPoint;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    width = self.view.frame.size.width * scale;
    height = self.view.frame.size.height * scale;
    
    [self _setContext];
    [self _buildGLViewAndBindBuffer];
    
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [self.view addSubview:btn];
    btn.frame = CGRectMake(100, 100, 80, 60);
    [self.view addSubview:btn];
    
}

- (IBAction)useFBOAction:(id)sender {
    [self drawFBO1];
    [self drawFBO2];
    [self mixDraw];
}

- (void)mixDraw {
    
    // 使用renderBuffer为颜色缓冲区
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuff);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuff);
    glBindBuffer(GL_FRAMEBUFFER, frameBuff);
    
    self->shaderProgram = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertexShader2"
                                                         fragmentShaderName:@"fragmentShader2"];
    glClearColor(1, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, width, height);
    glUseProgram(shaderProgram);
    
    // 指定顶点数据
    float vertices[] = {
        // 后面2个是纹理坐标   // texture coords
        // positions            // texture coords
        1.0f,  0.5f, 0.0f,    1.0f, 1.0f, // top right
        1.0f, -0.5f, 0.0f,    1.0f, 0.0f, // bottom right
        -1.0f, -0.5f, 0.0f,   0.0f, 0.0f, // bottom left
        -1.0f,  0.5f, 0.0f,   0.0f, 1.0f  // top left
    };
    
    // 索引缓冲
    unsigned int indices[] = { // 注意索引从0开始!
        0, 1, 3, // first triangle
        1, 2, 3  // second triangle
    };
    GLuint VAO, VBO, EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);
    
    // 先绑定VAO
    glBindVertexArray(VAO);
    
    // 复制顶点数据 到顶点缓冲区中
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    // 绑定EBO 及复制EBO数据
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    // 设置顶点属性指针
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    // 设置纹理坐标
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE,  5 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    // 处理纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureID1);
    glUniform1i(glGetUniformLocation(shaderProgram, "texture1"), 0); // 手动设置

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, textureID2);
    glUniform1i(glGetUniformLocation(shaderProgram, "texture2"), 1); // 手动设置

    // 给采样器设置纹理单元
    glBindVertexArray(VAO);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
    [context presentRenderbuffer:frameBuff];
}

- (void)drawFBO1 {
    
    glGenTextures(1, &textureID1);
    glBindTexture(GL_TEXTURE_2D, textureID1);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//    // 设置纹理数据
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);

    GLuint frameBuffer1;
    glGenFramebuffers(1, &frameBuffer1);
    glBindBuffer(GL_FRAMEBUFFER, frameBuffer1);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureID1, 0);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)
    {
        fprintf(stderr, "GLEW Error: %s\n", "FRAME BUFFER STATUS Error!");
        return;
    }

    self->shaderProgram = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertexShader2"
                                                         fragmentShaderName:@"fragmentShader2"];
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, width, height);
    glUseProgram(shaderProgram);
    
    // 指定顶点数据
    float vertices[] = {
        // 后面2个是纹理坐标   // texture coords
        // positions            // texture coords
        1.0f,  0.5f, 0.0f,    1.0f, 1.0f, // top right
        1.0f, -0.5f, 0.0f,    1.0f, 0.0f, // bottom right
        -1.0f, -0.5f, 0.0f,   0.0f, 0.0f, // bottom left
        -1.0f,  0.5f, 0.0f,   0.0f, 1.0f  // top left
    };
    
    // 索引缓冲
    unsigned int indices[] = { // 注意索引从0开始!
        0, 1, 3, // first triangle
        1, 2, 3  // second triangle
    };
    GLuint VAO, VBO, EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);
    
    // 先绑定VAO
    glBindVertexArray(VAO);
    
    // 复制顶点数据 到顶点缓冲区中
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    // 绑定EBO 及复制EBO数据
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    // 设置顶点属性指针
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    // 设置纹理坐标
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE,  5 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    // 处理纹理
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"wall.jpeg" ofType:nil];
    [GLESUtil genTexture:0 format:GL_RGBA filePath:path1];
    
    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"awesomeface.png" ofType:nil];
    [GLESUtil genTexture:1 format:GL_RGBA filePath:path2];

    glUniform1i(glGetUniformLocation(shaderProgram, "texture1"), 0); // 手动设置
    glUniform1i(glGetUniformLocation(shaderProgram, "texture2"), 1); // 手动设置
    
    glBindVertexArray(VAO);

    // 给采样器设置纹理单元
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindBuffer(GL_FRAMEBUFFER, 0);
}

- (void)drawFBO2
{
    glGenTextures(1, &textureID2);
    glBindTexture(GL_TEXTURE_2D, textureID2);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    // 设置纹理数据
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    // 取消绑定
    glBindTexture(GL_TEXTURE_2D, 0);
    
    GLuint frameBuffer2;
    glGenFramebuffers(1, &frameBuffer2);
    glBindBuffer(GL_FRAMEBUFFER, frameBuffer2);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureID2, 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)
    {
        fprintf(stderr, "GLEW Error: %s\n", "FRAME BUFFER STATUS Error!");
        return;
    }
    
    self->shaderProgram = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertexShader2"
                                                         fragmentShaderName:@"fragmentShader2"];
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    glViewport(0, 0, width, height);
    glUseProgram(shaderProgram);
    
    // 指定顶点数据
    float vertices[] = {
        // 后面2个是纹理坐标   // texture coords
        // positions            // texture coords
        1.0f,  0.5f, 0.0f,    1.0f, 1.0f, // top right
        1.0f, -0.5f, 0.0f,    1.0f, 0.0f, // bottom right
        -1.0f, -0.5f, 0.0f,   0.0f, 0.0f, // bottom left
        -1.0f,  0.5f, 0.0f,   0.0f, 1.0f  // top left
    };
    
    // 索引缓冲
    unsigned int indices[] = { // 注意索引从0开始!
        0, 1, 3, // first triangle
        1, 2, 3  // second triangle
    };
    GLuint VAO, VBO, EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);
    
    // 先绑定VAO
    glBindVertexArray(VAO);
    
    // 复制顶点数据 到顶点缓冲区中
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    // 绑定EBO 及复制EBO数据
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    // 设置顶点属性指针
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    // 设置纹理坐标
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE,  5 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    // 处理纹理
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"王路飞.jpeg" ofType:nil];
    [GLESUtil genTexture:0 format:GL_RGB filePath:path1];
    
    // 给采样器设置纹理单元
    glBindVertexArray(VAO);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
}

#pragma mark - 初始化
- (void)_buildGLViewAndBindBuffer {
    CGLView *glView = [CGLView new];
    glView.backgroundColor = UIColor.lightGrayColor;
    [self.view addSubview:glView];
    glView.frame = CGRectMake(0, 0, kWidth, kHeight);
    // 生成渲染缓存 - 存储像素数据
    glGenRenderbuffers(1, &renderBuff);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuff);
    // 创建帧缓存
    glGenFramebuffers(1, &frameBuff);
    // GL_FRAMEBUFFER
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuff);
    // 将渲染缓冲区挂载到当前帧缓冲区上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuff);
    // 将可绘制对象的存储绑定到OpenGL ES renderbuffer对象。 传递层对象作为参数来分配其存储空间。宽度，高度和像素格式取自层，用于为renderbuffer分配存储空间
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)glView.layer];
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

@end
