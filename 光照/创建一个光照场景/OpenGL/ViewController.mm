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

#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
#import <glm/gtc/type_ptr.hpp>
#import "Camera.hpp"
#import "ZQThreadRunner.h"

#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.heigh

#define ScreenScale(value) [UIScreen mainScreen].scale * value

#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

@interface ViewController ()
{
    EAGLContext *context;
    GLuint frameBuff;
    
    GLuint colorBuff;
    GLuint deepthBuff;
    
    int width;
    int height;
}

@property (nonatomic, strong) IBOutlet CGLView *glView;
@property (weak, nonatomic) IBOutlet UIView *operatorView;
@property (nonatomic, strong) ZQThreadRunner *runner;

@property (nonatomic, strong) ShaderProgram *shaderProgram;
@property (nonatomic, strong) ShaderProgram *lightShader;

@end

float vertices[] = {
    -0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f,
     0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f,
     0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f,
     0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f,
    -0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f,

    -0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f,
     0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f,
     0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f,
     0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f,
    -0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f,
    -0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f,

    -0.5f,  0.5f,  0.5f, -1.0f,  0.0f,  0.0f,
    -0.5f,  0.5f, -0.5f, -1.0f,  0.0f,  0.0f,
    -0.5f, -0.5f, -0.5f, -1.0f,  0.0f,  0.0f,
    -0.5f, -0.5f, -0.5f, -1.0f,  0.0f,  0.0f,
    -0.5f, -0.5f,  0.5f, -1.0f,  0.0f,  0.0f,
    -0.5f,  0.5f,  0.5f, -1.0f,  0.0f,  0.0f,

     0.5f,  0.5f,  0.5f,  1.0f,  0.0f,  0.0f,
     0.5f,  0.5f, -0.5f,  1.0f,  0.0f,  0.0f,
     0.5f, -0.5f, -0.5f,  1.0f,  0.0f,  0.0f,
     0.5f, -0.5f, -0.5f,  1.0f,  0.0f,  0.0f,
     0.5f, -0.5f,  0.5f,  1.0f,  0.0f,  0.0f,
     0.5f,  0.5f,  0.5f,  1.0f,  0.0f,  0.0f,

    -0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f,
     0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f,
     0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f,
     0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f,
    -0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f,
    -0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f,

    -0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f,
     0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f,
     0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f,
     0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f,
    -0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f,
    -0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f
};

// 定义摄像机坐标
Camera camera(glm::vec3(0.0f, 0.0f, 60.f));

// 光源位置
glm::vec3 lightPos(1.2f, 1.0f, 2.0f);

@implementation ViewController
{
    GLuint VBO; // 作全局使用
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGFloat scale = [UIScreen mainScreen].scale;
    width = self.glView.frame.size.width * scale;
    height = self.glView.frame.size.height * scale;
    [self _setContext];
    [self _buildGLViewAndBindBuffer];
    [self prepareData];
    [self _buildRunnerAndStart];
}

- (void)_buildRunnerAndStart
{
    ZQThreadRunner *runner = [ZQThreadRunner buildRunner];
    self.runner = runner;
    @weakify(self);
    [self.runner setTimerAction:^{
        @strongify(self);
        [self renderCudeAndLight];
    }];
    [runner start];
}

#pragma mark - Action

- (IBAction)testAction:(id)sender {

}

- (void)prepareData {
    ShaderProgram *shaderProgram = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertex_1"
                                                         fragmentShaderName:@"cube_color"];
    ShaderProgram *lightShader = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertex_1"
                                                         fragmentShaderName:@"fragment_light"];
    self.shaderProgram = shaderProgram;
    self.lightShader = lightShader;
    
    [self begin];
    GLuint VAO,VBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glBindVertexArray(VAO);
    self->VBO = VBO;

    // 复制顶点数据 到顶点缓冲区中
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
}

- (void)renderCudeAndLight
{
    ShaderProgram *shaderProgram = self.shaderProgram;
    ShaderProgram *lightShader = self.lightShader;

    [shaderProgram use];
    [shaderProgram bindVec3:@"objectColor" value: Vec3{1.0, 0.5f, 0.31f}];
    [shaderProgram bindVec3:@"lightColor" value:Vec3{1.0f, 1.0f, 1.0f}];
    [shaderProgram glm_bindVec3:@"lightPos" value:lightPos];
    
    float aspect = float(width * 1.0 / height);
    glm::mat4 projection = glm::perspective(glm::radians(camera.Zoom), aspect, 0.1f, 100.0f);
    glm::mat4 view = camera.GetViewMatrix();
    [shaderProgram glm_bindMatrix4x4:@"projection" value:projection];
    [shaderProgram glm_bindMatrix4x4:@"view" value:view];
    glm::mat4 model = glm::mat4(1.0f);
    [shaderProgram glm_bindMatrix4x4:@"model" value:model];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    // 设置灯源立方体
    {
        unsigned int lightVAO;
        glGenVertexArrays(1, &lightVAO);
        glBindVertexArray(lightVAO);
        glBindBuffer(GL_ARRAY_BUFFER, VBO);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
        glEnableVertexAttribArray(0);

        [lightShader use];
        [lightShader glm_bindMatrix4x4:@"projection" value:projection];
        [lightShader glm_bindMatrix4x4:@"view" value:view];
        
        glm::mat4 model = glm::mat4(1.0f);
        model = glm::translate(model, lightPos);
        [lightShader glm_bindMatrix4x4:@"model" value:model];
        [lightShader glm_bindVec3:@"lightPos" value:lightPos];
        
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
    [context presentRenderbuffer:self->colorBuff];
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
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, self->deepthBuff);
    
    // 将可绘制对象的存储绑定到OpenGL ES renderbuffer对象。 传递层对象作为参数来分配其存储空间。宽度，高度和像素格式取自层，用于为renderbuffer分配存储空间
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.glView.layer];
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
    glEnable(GL_DEPTH_TEST);
}

- (void)draw {
    // 绑定VAO 数据
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
    glBindRenderbuffer(GL_RENDERBUFFER, self->colorBuff);
    [context presentRenderbuffer:self->colorBuff];
}

@end
