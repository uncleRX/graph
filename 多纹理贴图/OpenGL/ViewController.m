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

#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()
{
    EAGLContext *context;
    GLuint shaderProgram;
    GLuint frameBuff;
    GLuint renderBuff;
}

@property (nonatomic, strong) CGLView *glView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _setContext];
    [self _buildGLViewAndBindBuffer];
    [self _loadShader];
    [self _drawATriangle];
}

- (void)_drawATriangle {
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    CGFloat scale = [UIScreen mainScreen].scale;
    float width = self.view.frame.size.width * scale;
    float height = self.view.frame.size.height * scale;
    glViewport(0, 0, width, height);
    
    // 指定顶点数据
    float vertices[] = {
        0.9f, 0.5f, 0.0f, 1.f, 0.f,
        0.9f, -0.5f, 0.0f, 1.f, 1.f,
        -0.9f, -0.5f, 0.0f, 0.f, 1.f,
        -0.9f, 0.5f, 0.0f, 0.f, 0.f,
    };
    
    int indices[] = {
        0 , 1, 2, // 第一个三角形
        2, 3, 0 // 第二个三角形
    };

    // 顶点缓存
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    
    GLuint EBO;
    glGenBuffers(1, &EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // 复制顶点数据到缓存对象中供GPU使用
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, (3+2) * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    
    // 纹理数据
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
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
    int location1 = glGetUniformLocation(shaderProgram, "texture1");
    int location2 = glGetUniformLocation(shaderProgram, "texture2");
     
    glUseProgram(shaderProgram);
    glUniform1i(location1, 0);
    glUniform1i(location2, 4);

    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    [context presentRenderbuffer:renderBuff];
}

#pragma mark - 初始化

- (void)_buildGLViewAndBindBuffer {
    CGLView *glView = [CGLView new];
    glView.backgroundColor = UIColor.lightGrayColor;
    [self.view addSubview:glView];
    glView.frame = CGRectMake(0, 0, kWidth, kHeight);
    // 创建渲染缓存 - 存储像素数据
    glGenRenderbuffers(1, &renderBuff);
    // 创建帧缓存
    glGenFramebuffers(1, &frameBuff);
    // GL_FRAMEBUFFER
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuff);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuff);
    // 建立关系 renderBuff frameBuff , 深度,
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuff);
    //renderBuff 绑定给layer
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:glView.layer];
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
