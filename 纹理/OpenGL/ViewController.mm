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
#import "Std_image/stb_image.h"

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
@property (nonatomic, assign) CGPoint lastPoint;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _setContext];
    [self _buildGLViewAndBindBuffer];
    [self _loadShader];
    [self _EBOdrawATriangle];
}

- (void)_EBOdrawATriangle {
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    CGFloat scale = [UIScreen mainScreen].scale;
    float width = self.view.frame.size.width * scale;
    float height = self.view.frame.size.height * scale;
    glViewport(0, 0, width, height);
    glUseProgram(shaderProgram);
    
    // 指定顶点数据
    float vertices[] = {
        // 后面2个是纹理坐标
        1.0f, -0.5f, 0.0f, 1.f, 0.f,
        1.0f, 0.5f, 0.0f, 1.f, 1.f,
        -1.f, -0.5f, 0.0f, 0.f, 0.f
        -1.f, 0.5f, 0.0f, 0.f, 1.f
    };
    
    // 索引缓冲
    unsigned int indices[] = { // 注意索引从0开始!
        0, 1, 2, // 第一个三角形
        1, 2, 3  // 第二个三角形
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
    // 启用顶点数组
    glEnableVertexAttribArray(0);

    // 生成纹理
    GLuint texture;
    glGenTextures(1, &texture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE,  5 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
    
    // 为当前绑定的纹理对象设置环绕、过滤方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // 生成纹理
    int width, height, 
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"4K_老虎.JPG" ofType:nil];
    NSData *textureData = [NSData dataWithContentsOfFile:path];
    UIImage *img = [UIImage imageWithData:textureData];
    UIImage *flipImage = [img rotate:(UIImageOrientationDownMirrored)];

    width = CGImageGetWidth(flipImage.CGImage);
    height = CGImageGetHeight(flipImage.CGImage);
    
    CGImageRef cgImage = flipImage.CGImage;
    CFDataRef provider  = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    GLubyte* imageData = (GLubyte *)CFDataGetBytePtr(provider);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    int ourTextureLocation = glGetUniformLocation(shaderProgram, "ourTexture");
    glUniform1i(ourTextureLocation, 0);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    [context presentRenderbuffer:renderBuff];
}


- (void)_EAOdrawATriangle {
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    CGFloat scale = [UIScreen mainScreen].scale;
    float width = self.view.frame.size.width * scale;
    float height = self.view.frame.size.height * scale;
    glViewport(0, 0, width, height);
    glUseProgram(shaderProgram);
    
    // 指定顶点数据
    float vertices[] = {
        // 后面2个是纹理坐标
        1.0f, -0.5f, 0.0f, 1.f, 0.f,
        1.0f, 0.5f, 0.0f, 0.5f, 1.f,
        -1.f, -0.5f, 0.0f, 0.f, 0.f
        -1.f, 0.5f, 0.0f, 0.f, 0.f
    };
    // 复制数据
    GLuint VAOs[2], VBOs[2];
    glGenVertexArrays(2, VAOs);
    glGenBuffers(2, VBOs);
    
    // ----- 第一个三角形
    glBindVertexArray(VAOs[0]);
    // OpenGL有很多缓冲对象类型，顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER。OpenGL允许我们同时绑定多个缓冲，只要它们是不同的缓冲类型。我们可以使用glBindBuffer函数把新创建的缓冲绑定到GL_ARRAY_BUFFER目标上
    glBindBuffer(GL_ARRAY_BUFFER, VBOs[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, (3+2) * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
//    // 解绑????
//    glBindVertexArray(0);
    
    // 第二个三角形
//    glBindVertexArray(VAOs[1]);
//    glBindBuffer(GL_ARRAY_BUFFER, VBOs[1]);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
//    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, (3+2) * sizeof(float), (void*)5);
//    glEnableVertexAttribArray(0);

    // 生成纹理
    GLuint texture;
    glGenTextures(1, &texture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE,  5 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
    
    // 为当前绑定的纹理对象设置环绕、过滤方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // 生成纹理
    NSString *path = [[NSBundle mainBundle] pathForResource:@"4K_老虎.JPG" ofType:nil];
    NSData *textureData = [NSData dataWithContentsOfFile:path];
    UIImage *img = [UIImage imageWithData:textureData];
    UIImage *flipImage = [img rotate:(UIImageOrientationDownMirrored)];

    width = CGImageGetWidth(flipImage.CGImage);
    height = CGImageGetHeight(flipImage.CGImage);
    
    CGImageRef cgImage = flipImage.CGImage;
    CFDataRef provider  = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    GLubyte* imageData = (GLubyte *)CFDataGetBytePtr(provider);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    int ourTextureLocation = glGetUniformLocation(shaderProgram, "ourTexture");
    glUniform1i(ourTextureLocation, 0);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    [context presentRenderbuffer:renderBuff];
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
