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

#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height

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
    GLuint shaderProgram;
    GLuint frameBuff;
    GLuint renderBuff;
    
    GLuint textureID1;
    GLuint textureID2;
    
    int width;
    int height;
    
    GLuint VAO;
}
@property (nonatomic, strong) IBOutlet CGLView *glView;
@property (weak, nonatomic) IBOutlet UIView *operatorView;
@property (nonatomic, assign) CGPoint lastPoint;
@property (weak, nonatomic) IBOutlet UISlider *slder1;
@property (weak, nonatomic) IBOutlet UISlider *slider2;
@property (weak, nonatomic) IBOutlet UISlider *slider3;
@property (weak, nonatomic) IBOutlet UISlider *slider4;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initSlider];

    CGFloat scale = [UIScreen mainScreen].scale;
    width = self.glView.frame.size.width * scale;
    height = self.glView.frame.size.height * scale;
    [self _setContext];
    [self _buildGLViewAndBindBuffer];
    
    // draw
    [self drawMixImage];
}

- (void)initSlider {
    self.slder1.minimumValue = -1.0;
    self.slder1.value = 0;
    self.slder1.maximumValue = 1.0;

    self.slider2.minimumValue = -1.0;
    self.slider2.value = 0;
    self.slider2.maximumValue = 1.0;
    
    self.slider3.minimumValue = -1.0;
    self.slider3.value = 0;
    self.slider3.maximumValue = 1.0;
    
    self.slider4.minimumValue = -1.0;
    self.slider4.value = 0;
    self.slider4.maximumValue = 1.0;
}

#pragma mark - Action

- (IBAction)sliderChange1:(UISlider *)sender {
    @weakify(self);
    [self updateTranscation:^{
        @strongify(self);
        float value = 1.f + sender.value;
        glUniform1i(glGetUniformLocation(self->shaderProgram, "texture1"), 0); // 手动设置
        glUniform1i(glGetUniformLocation(self->shaderProgram, "texture2"), 1); // 手动设置
        glm::mat4 scale;
        glm::mat4 rotation;
        glm::mat4 translation;
        scale = glm::scale(scale, glm::vec3(value, value, value));
        glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "scale"), 1, GL_FALSE, glm::value_ptr(scale));
        glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "rotation"), 1, GL_FALSE, glm::value_ptr(rotation));
        glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "translation"), 1, GL_FALSE, glm::value_ptr(translation));
    }];
}

- (IBAction)slider2Change:(UISlider *)sender {
    @weakify(self);
    [self updateTranscation:^{
        @strongify(self);
        float value = 1.f + sender.value;
        glUniform1i(glGetUniformLocation(self->shaderProgram, "texture1"), 0); // 手动设置
        glUniform1i(glGetUniformLocation(self->shaderProgram, "texture2"), 1); // 手动设置
        glm::mat4 scale;
        glm::mat4 rotation;
        glm::mat4 translation;
        static float angle = 0;
        angle += 10;
        rotation = glm::rotate(rotation, angle, glm::vec3(0.0f, 0.0f, 1.0f));
        glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "scale"), 1, GL_FALSE, glm::value_ptr(scale));
        glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "rotation"), 1, GL_FALSE, glm::value_ptr(rotation));
        glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "translation"), 1, GL_FALSE, glm::value_ptr(translation));
    }];
}

- (IBAction)slider3Change:(UISlider *)sender {
    @weakify(self);
    [self updateTranscation:^{
        @strongify(self);
        float value = 1.f + sender.value;
        glUniform1i(glGetUniformLocation(self->shaderProgram, "texture1"), 0); // 手动设置
        glUniform1i(glGetUniformLocation(self->shaderProgram, "texture2"), 1); // 手动设置
        glm::mat4 scale;
        glm::mat4 rotation;
        glm::mat4 translation;
        translation = glm::translate(translation, glm::vec3(value, value, 1.0));
        glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "scale"), 1, GL_FALSE, glm::value_ptr(scale));
        glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "rotation"), 1, GL_FALSE, glm::value_ptr(rotation));
        glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "translation"), 1, GL_FALSE, glm::value_ptr(translation));
    }];
}

- (IBAction)slider4Change:(UISlider *)sender {
    
}

- (void)updateTranscation:(void(^)(void))codeBlock {
    [self begin];
    codeBlock();
    [self draw];
}

- (void)begin {
    // 使用renderBuffer为颜色缓冲区
    self->shaderProgram = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertexShader2"
                                                         fragmentShaderName:@"fragmentShader2"];
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, width, height);
    glUseProgram(self->shaderProgram);
}

- (void)draw {
    // 绑定VAO 数据
    glBindVertexArray(VAO);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
    [context presentRenderbuffer:frameBuff];
}

- (void)drawMixImage {
    [self begin];
    
    // 指定顶点数据
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
    GLuint VAO, VBO, EBO;
    glGenVertexArrays(1, &VAO);
    self->VAO = VAO;
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
    
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"wall.jpeg" ofType:nil];
    textureID1 = [GLESUtil genTexture:0 format:GL_RGBA filePath:path1];

    
    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"awesomeface.png" ofType:nil];
    textureID2 = [GLESUtil genTexture:1 format:GL_RGBA filePath:path2];

    

    glUniform1i(glGetUniformLocation(self->shaderProgram, "texture1"), 0); // 手动设置
    glUniform1i(glGetUniformLocation(self->shaderProgram, "texture2"), 1); // 手动设置

    glUniform1f(glGetUniformLocation(self->shaderProgram, "s"), 1);
    glm::mat4 scale;
    glm::mat4 rotation;
    glm::mat4 translation;
    glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "scale"), 1, GL_FALSE, glm::value_ptr(scale));
    glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "rotation"), 1, GL_FALSE, glm::value_ptr(rotation));
    glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "translation"), 1, GL_FALSE, glm::value_ptr(translation));

    [self draw];
}

#pragma mark - 初始化
- (void)_buildGLViewAndBindBuffer {
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

@end
