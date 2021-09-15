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
    [self _drawATriangle];
}

- (void)_drawATriangle {
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    CGFloat scale = [UIScreen mainScreen].scale;
    float width = self.view.frame.size.width * scale;
    float height = self.view.frame.size.height * scale;
    glViewport(0, 0, width, height);
    
    glUseProgram(shaderProgram);
    
    // 指定顶点数据
    float vertices[] = {
        // 后面2个时纹理坐标
        0.0f, 0.5f, 0.0f, 0.5f, 1.f,
         0.5f, -0.5f, 0.0f, 1.f, 0.f,
        -0.5f, -0.5f, 0.0f, 0.f, 0.f
    };
    
    // 顶点缓存
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    
    // 复制顶点数据到缓存对象中供GPU使用
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, (3+2) * sizeof(float), (void*)0);
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
    
    // 生成纹
    NSString *path = [[NSBundle mainBundle] pathForResource:@"王路飞" ofType:@"jpeg"];
    NSData *textureData = [NSData dataWithContentsOfFile:path];
    UIImage *img = [UIImage imageWithData:textureData];
    width = CGImageGetWidth(img.CGImage);
    height = CGImageGetHeight(img.CGImage);
    
    CGImageRef cgImage = img.CGImage;
    uint32_t stride = (uint32_t)CGImageGetBytesPerRow(cgImage);
    CFDataRef provider  = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    GLubyte* imageData = (GLubyte *)CFDataGetBytePtr(provider);
        
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
//    glGenerateMipmap(GL_TEXTURE_2D);
    

    int ourTextureLocation = glGetUniformLocation(shaderProgram, "ourTexture");
    glUniform1i(ourTextureLocation, 0);
    
    int result = glGetError();
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    // 解绑
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
