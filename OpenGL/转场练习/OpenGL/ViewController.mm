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
#import "Camera.hpp"
#import "ZQThreadRunner.h"
#import "PublicHeader.h"
#import "Define.h"

@interface ViewController ()
{
    EAGLContext *context;
    GLuint frameBuff;
    GLuint colorBuff;
    GLuint deepthBuff;
    int width;
    int height;
    GLuint VAO;
}

@property (nonatomic, strong) IBOutlet CGLView *glView;
@property (weak, nonatomic) IBOutlet UIView *operatorView;
@property (nonatomic, strong) ZQThreadRunner *runner;
@property (atomic, strong) ShaderProgram *shaderProgram1;
@property (atomic, strong) ShaderProgram *shaderProgram2;
@property (atomic, strong) ShaderProgram *shaderProgram3;
@property (atomic, strong) ShaderProgram *shaderProgram4;
@property (atomic, strong) ShaderProgram *currentShaderProgram;


@property (nonatomic, assign) float focusSeconds;

@property (nonatomic, strong) TextureModel *texture1Model;
@property (nonatomic, strong) TextureModel *texture2Model;


@end

float vertices[] = {
    // 后面2个是纹理坐标   // texture coords
    // positions            // texture coords
    1.0f,  1.0f, 0.0f,    1.0f, 1.0f, // top right
    1.0f, -1.0f, 0.0f,    1.0f, 0.0f, // bottom right
    -1.0f, -1.0f, 0.0f,   0.0f, 0.0f, // bottom left
    -1.0f,  1.0f, 0.0f,   0.0f, 1.0f  // top left
};

// 索引缓冲
unsigned int indices[] = { // 注意索引从0开始!
    0, 1, 3, // first triangle
    1, 2, 3  // second triangle
};


@implementation ViewController
{
    id<EAGLDrawable> drawable;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.focusSeconds = 0;

    CGFloat scale = [UIScreen mainScreen].scale;
    width = self.glView.frame.size.width * scale;
    height = self.glView.frame.size.height * scale;
    
    [self _buildRunner];
    self->drawable = (id<EAGLDrawable>)self.glView.layer;
    @weakify(self);
    [self.runner addRunner:^{
        @strongify(self);
        [self _setContext];
        [self _buildGLViewAndBindBuffer];
        [self prepareData];
    }];
    [self.runner start];
}

- (void)_buildRunner
{
    ZQThreadRunner *runner = [ZQThreadRunner buildRunner];
    self.runner = runner;
    self.runner.thread.name = @"OpenGL ES Thread";
    runner.fps = 30;
    @weakify(self);
    [self.runner setTimerAction:^{
        @strongify(self);
        [self renderTarget];
    }];
}

#pragma mark - Action

- (IBAction)scroll:(id)sender {
    [self changeFragShader:self.shaderProgram1];
}

- (IBAction)fadeAction:(id)sender {
    [self changeFragShader:self.shaderProgram2];
}

- (IBAction)wipe:(id)sender {
    [self changeFragShader:self.shaderProgram3];
}

- (IBAction)rotate:(id)sender {
    [self changeFragShader:self.shaderProgram4];
}

- (void)changeFragShader:(ShaderProgram *)pro {
    
    self.currentShaderProgram = pro;
    [self.runner stop];
    [pro use];
    self.focusSeconds = 0.f;
    [self.runner start];
}

- (void)prepareData {
    
    ShaderProgram *shaderProgram1 = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertext_default"
                                                         fragmentShaderName:@"fragment_scroll"];
    ShaderProgram *shaderProgram2 = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertext_default"
                                                         fragmentShaderName:@"fragment_fade"];
    ShaderProgram *shaderProgram3 = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertext_default"
                                                         fragmentShaderName:@"fragment_wipe"];
    ShaderProgram *shaderProgram4 = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertext_default"
                                                         fragmentShaderName:@"fragment_rotate"];

    self.shaderProgram1 = shaderProgram1;
    self.shaderProgram2 = shaderProgram2;
    self.shaderProgram3 = shaderProgram3;
    self.shaderProgram4 = shaderProgram4;
    self.currentShaderProgram = self.shaderProgram1;

    [shaderProgram1 use];
    GLuint VAO,VBO,EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    glBindVertexArray(VAO);
    self->VAO = VAO;

    // 复制顶点数据 到顶点缓冲区中
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    // 绑定EBO 及复制EBO数据
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
    
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"wallhaven-3kvqm9.jpeg" ofType:nil];
    self.texture1Model = [GLESUtil genTexture:0 format:GL_RGBA filePath:path1];
    
    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"wallhaven-2ew8wx.png" ofType:nil];
    self.texture2Model = [GLESUtil genTexture:1 format:GL_RGBA filePath:path2];
}

- (void)renderTarget
{
    self.focusSeconds += 1.0/30;
//    NSLog(@"%f", self.focusSeconds);
    [self.currentShaderProgram use];
    
    [self begin];
    
    glm::mat4 model = glm::mat4(1.0f);
    glm::mat4 view = glm::mat4(1.0f);
    glm::mat4 projection = glm::mat4(1.0f);
    
    [self.currentShaderProgram glm_bindMatrix4x4:@"model" value:model];
    [self.currentShaderProgram glm_bindMatrix4x4:@"view" value:view];
    [self.currentShaderProgram glm_bindMatrix4x4:@"projection" value:projection];
    
    glUniform1i([self.currentShaderProgram findLocation:@"inputTexture1"], 0);
    glUniform1i([self.currentShaderProgram findLocation:@"inputTexture2"], 1);
        
    float completeness = glm::smoothstep(0.f, 6.f, self.focusSeconds);
    glUniform1f([self.currentShaderProgram findLocation:@"completeness"], completeness);

    glBindVertexArray(self->VAO);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, self->colorBuff);
    [context presentRenderbuffer:self->colorBuff];
    if (self.focusSeconds > 6)
    {
        self.focusSeconds = 0.0;
    }
}

#pragma mark - 初始化

- (void)_buildGLViewAndBindBuffer {
    // 生成渲染缓存 - 存储像素数据
    GLuint render[2];
    glGenRenderbuffers(2, render);
    self->colorBuff = render[0];
    self->deepthBuff = render[1];
    
    // 创建帧缓存
    glGenFramebuffers(1, &frameBuff);
        // GL_FRAMEBUFFER
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuff);
    glBindRenderbuffer(GL_RENDERBUFFER, colorBuff);
    // 将渲染缓冲区挂载到当前帧缓冲区上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self->colorBuff);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self->drawable];
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

- (void)begin {
    // 使用renderBuffer为颜色缓冲区
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, width, height);
    // 需要开启混合模式
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)draw {
    // 绑定VAO 数据
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
    glBindRenderbuffer(GL_RENDERBUFFER, self->colorBuff);
    [context presentRenderbuffer:self->colorBuff];
}

@end
