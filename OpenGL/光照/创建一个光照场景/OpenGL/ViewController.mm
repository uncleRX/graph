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

@property (atomic, strong) ShaderProgram *shaderProgram;
@property (atomic, strong) ShaderProgram *lightShader;

@property (atomic, assign) float cubeAngleX;
@property (atomic, assign) float cubeAngleY;
@property (atomic, assign) float cubeAngleZ;
@property (atomic, assign) float isPressX;


@property (atomic, assign) BOOL rotateXIsOn;
@property (atomic, assign) BOOL rotateYIsOn;
@property (atomic, assign) BOOL rotateZIsOn;

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

// timing
float deltaTime = 0.2f;

@implementation ViewController
{
    GLuint cubeVAO; // 作全局使用
    GLuint lightVAO; // 作全局使用
    id<EAGLDrawable> drawable;
}

- (void)viewDidLoad {
    [super viewDidLoad];

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
    @weakify(self);
    [self.runner setTimerAction:^{
        @strongify(self);
        if (self.rotateXIsOn)
        {
            self.cubeAngleX += 50;
        }
        if (self.rotateYIsOn)
        {
            self.cubeAngleY += 50;
        }
        if (self.rotateZIsOn)
        {
            self.cubeAngleZ += 50;
        }
        [self renderCudeAndLight];
    }];
}

#pragma mark - Action

- (IBAction)z:(UISwitch *)sender {
    self.rotateXIsOn = sender.isOn;
}
- (IBAction)y:(UISwitch *)sender {
    self.rotateYIsOn = sender.isOn;
}
- (IBAction)x:(UISwitch *)sender {
    self.rotateZIsOn = sender.isOn;
}
- (IBAction)rotateX:(id)sender {
    self.cubeAngleX += 50;
}

- (IBAction)rotateY:(id)sender {
    self.cubeAngleY += 50;
}

- (IBAction)rotateZ:(id)sender {
    self.cubeAngleZ += 50;
}

- (IBAction)longPressFront:(id)sender {
}

- (IBAction)longPressLeft:(id)sender {
}

- (IBAction)longPressRight:(id)sender {
    
}

- (IBAction)longPressBack:(id)sender {
}

- (IBAction)forward:(id)sender {
    camera.ProcessKeyboard(Camera_Movement::FORWARD, deltaTime);
}

- (IBAction)back:(id)sender {
    camera.ProcessKeyboard(Camera_Movement::BACKWARD, deltaTime);
}

- (IBAction)left:(id)sender {
    camera.ProcessKeyboard(Camera_Movement::LEFT, deltaTime);
}

- (IBAction)right:(id)sender {
    camera.ProcessKeyboard(Camera_Movement::RIGHT, deltaTime);
}

- (void)prepareData {
    ShaderProgram *shaderProgram = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertex_1"
                                                         fragmentShaderName:@"cube_color"];
    ShaderProgram *lightShader = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertext_light_cube"
                                                         fragmentShaderName:@"fragment_light"];
    self.shaderProgram = shaderProgram;
    self.lightShader = lightShader;
    
    [self begin];
    GLuint VAO,VBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glBindVertexArray(VAO);
    self->cubeVAO = VAO;

    // 复制顶点数据 到顶点缓冲区中
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
    
    unsigned int lightVAO;
    glGenVertexArrays(1, &lightVAO);
    glBindVertexArray(lightVAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    self->lightVAO = lightVAO;
}

- (void)renderCudeAndLight
{
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, width, height);
    glEnable(GL_DEPTH_TEST);
    
    ShaderProgram *shaderProgram = self.shaderProgram;
    ShaderProgram *lightShader = self.lightShader;

    [shaderProgram use];
    [shaderProgram bindVec3:@"objectColor" value: Vec3{1.0, 0.5f, 0.31f}];
    [shaderProgram bindVec3:@"lightColor" value:Vec3{1.0f, 1.0f, 1.0f}];
    [shaderProgram glm_bindVec3:@"lightPos" value:lightPos];
    
    // 绘制立方体
    float aspect = float(width * 1.0 / height);
    glm::mat4 projection = glm::perspective(glm::radians(camera.Zoom), aspect, 0.1f, 100.0f);
    glm::mat4 view = camera.GetViewMatrix();
    [shaderProgram glm_bindMatrix4x4:@"projection" value:projection];
    [shaderProgram glm_bindMatrix4x4:@"view" value:view];
    glm::mat4 model = glm::mat4(1.0f);
    
    model = glm::rotate(model, glm::radians(self.cubeAngleX),  glm::vec3(1.f, 0.f, 0.0f));
    model = glm::rotate(model, glm::radians(self.cubeAngleY),  glm::vec3(0.f, 1.f, 0.0f));
    model = glm::rotate(model, glm::radians(self.cubeAngleZ),  glm::vec3(0.f, 0.f, 1.0f));
    
//    NSLog(@"%f - %f - %f", _cubeAngleX, _cubeAngleY,_cubeAngleZ);
    [shaderProgram glm_bindMatrix4x4:@"model" value:model];
    glBindVertexArray(cubeVAO);
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    // 设置灯源立方体
    {
        [lightShader use];
        [lightShader glm_bindMatrix4x4:@"projection" value:projection];
        [lightShader glm_bindMatrix4x4:@"view" value:view];
        
        glm::mat4 model = glm::mat4(1.0f);
        model = glm::translate(model, lightPos);
        [lightShader glm_bindMatrix4x4:@"model" value:model];
        [lightShader glm_bindVec3:@"lightPos" value:lightPos];
        glBindVertexArray(lightVAO);
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, self->colorBuff);
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
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self->drawable];
    
    GLint t_width = 0;
    GLint t_height = 0;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &t_width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &t_height);
    
    glBindRenderbuffer(GL_RENDERBUFFER, self->deepthBuff);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, t_width, t_height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, self->deepthBuff);
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
