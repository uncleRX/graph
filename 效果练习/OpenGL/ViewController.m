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

@interface ViewController ()
{
    EAGLContext *context;
    GLuint shaderProgram;
    GLuint frameBuff;
    GLuint renderBuff;
}
@property (nonatomic, strong) CGLView *glView;
@property (nonatomic, assign) CGPoint lastPoint;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _setContext];
    [self _buildGLViewAndBindBuffer];
    [self _loadShader];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _drawATriangle];
    });
}

- (void)_drawATriangle {
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    float width = self.view.frame.size.width;
    float height = self.view.frame.size.height;
    glViewport(0, 0, width, height);
    // 指定顶点数据
    float vertices[] = {
        // 第一个三角形
        0.5f, 0.5f, 0.0f,   // 右上角
         0.5f, -0.5f, 0.0f,  // 右下角
         -0.5f, -0.5f, 0.0f, // 左下角
         -0.5f, 0.5f, 0.0f   // 左上角
    };
    
    unsigned int indices[] = {
      0, 1, 2, //第一个三角形
    0,2,3 // 第二个三角形
    };
    unsigned int EBO;
    glGenBuffers(1, &EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    // 复制索引数据
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    // 顶点数组缓存
    GLuint VAO;
    glGenBuffers(1, &VAO);
    glBindVertexArray(VAO);
    
    // 顶点缓存
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // 复制顶点数据到缓存对象中供GPU使用
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    //  链接顶点属性,指定输入的数据,那部分是对应着色器的哪个一个顶点属性.现在有顶点数据,但是不知道顶点数据是干嘛的,需要指定其如何解析
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, (3) * sizeof(float), (void*)0);

    // 顶点属性默认是禁用的
    glEnableVertexAttribArray(0);
    glUseProgram(shaderProgram);
//    glDrawArrays(GL_TRIANGLES, 0, 3);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    // 解绑
    glBindVertexArray(0);
    [context presentRenderbuffer:renderBuff];
}

#pragma mark - 初始化

- (void)_buildGLViewAndBindBuffer {
    CGLView *glView = [CGLView new];
    [self.view addSubview:glView];
    glView.frame = self.view.bounds;
    
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
