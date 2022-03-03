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
    GLuint shaderProgram;
    GLuint frameBuff;
    GLuint renderBuff;
    
    GLuint textureID1;
    GLuint textureID2;
    
    int width;
    int height;
    
    GLuint VAO;
}

typedef enum ContentMode
{
    ContentModeRaw = 1,   ///< 锚点原点在中心，位置在合成中心， 原始尺寸 .
    ContentModeScaleToFill = 2,   ///< 锚点原点在中心，位置在合成中心， 平铺充满, 内容会有拉伸 .
    ContentModeScaleAspectFit = 3,   ///< 锚点原点在中心，位置在合成中心，内容会全部显示, 会有上下或者左右空白 .
    ContentModeScaleAspectFill = 4    ///< 锚点原点在中心，位置在合成中心，内容缩放充满容器, 内容可能不完全显示 .
}ContentMode;

@property (nonatomic, strong) IBOutlet CGLView *glView;
@property (weak, nonatomic) IBOutlet UIView *operatorView;
@property (nonatomic, assign) CGPoint lastPoint;
@property (weak, nonatomic) IBOutlet UISlider *slder1;
@property (weak, nonatomic) IBOutlet UISlider *slider2;
@property (weak, nonatomic) IBOutlet UISlider *slider3;
@property (weak, nonatomic) IBOutlet UISlider *slider4;

@property (nonatomic, assign) ContentMode showMode;

@end

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

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initSlider];

    CGFloat scale = [UIScreen mainScreen].scale;
    width = self.glView.frame.size.width * scale;
    height = self.glView.frame.size.height * scale;
    self.showMode = ContentModeScaleAspectFill;
    
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

- (IBAction)waterAction:(id)sender {
    self->shaderProgram = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertex_1_map"
                                                         fragmentShaderName:@"drawOnePicture"];
    [self begin];

    // 加载图片内容
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"wallhaven-3kvqm9.jpeg" ofType:nil];
    TextureModel *contentTexture = [GLESUtil genTexture:0 format:GL_RGBA filePath:path1];
    
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    if (self.showMode == ContentModeScaleAspectFit)
    {
        // 用最长的那边来做缩放, 可以保证显示完整
        if (contentTexture.width >= contentTexture.height) {
            float newHeight = width * contentTexture.height / contentTexture.width;
            scaleY = newHeight / height;
        }
        
    }else if (self.showMode == ContentModeScaleAspectFill)
    {
        // 短的那边要填充
        if (contentTexture.width >= contentTexture.height) {
            float newW = height * contentTexture.width / contentTexture.height;
            scaleX = newW / width;
        }
    }

    // 居中充满, 不拉伸图片
    glm::mat4 mvpMatrix;
    mvpMatrix = glm::scale(mvpMatrix, glm::vec3(scaleX, scaleY, 1.0));
    
    // 设置缩放矩阵,保证图片的显示效果
    glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "mvpMatrix"), 1, GL_FALSE, glm::value_ptr(mvpMatrix));
    
    // 采样
    glUniform1i(glGetUniformLocation(self->shaderProgram, "texture1"), 0);
    [self draw];
    
    // 再绘制一次水印
 
    // 水印 138 * 72;
    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"watermark_icon_doupai.png" ofType:nil];
    TextureModel *model = [GLESUtil genTexture:1 format:GL_RGBA filePath:path2];
    
    float sx = float(model.width) / width;
    float sy = model.height * 1.0 / height;
    
    glUniform1i(glGetUniformLocation(self->shaderProgram, "texture1"), 1);
    
    glm::mat4 mvpMatrix2;
    
    // 平移到右下角去
    float tx = float(width - model.width - ScreenScale(20)) / width ;
    float ty = float(height - model.height - ScreenScale(20)) / height ;
    mvpMatrix2 = glm::translate(mvpMatrix2, glm::vec3(tx, -ty, 0));
    mvpMatrix2 = glm::scale(mvpMatrix2, glm::vec3(sx, sy, 1.0));
    glUniformMatrix4fv(glGetUniformLocation(self->shaderProgram, "mvpMatrix"), 1, GL_FALSE, glm::value_ptr(mvpMatrix2));
    // 再次绘制
    [self draw];
}

- (IBAction)mosaicAction:(id)sender {
    
}

- (IBAction)GaussianBlurAction:(id)sender {
    
}

- (IBAction)mirrorAction:(id)sender {
    
}

- (IBAction)splitAction:(id)sender {
    
}

- (void)updateTranscation:(void(^)(void))codeBlock {
    [self begin];
    codeBlock();
    [self draw];
}

- (void)begin {
    // 使用renderBuffer为颜色缓冲区
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, width, height);
    glUseProgram(self->shaderProgram);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)drawWithVAO:(GLuint)vao {
    // 绑定VAO 数据
    glBindVertexArray(vao);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
    [context presentRenderbuffer:frameBuff];
}

- (void)draw {
    // 绑定VAO 数据
    glBindVertexArray(VAO);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
    [context presentRenderbuffer:frameBuff];
}

- (void)drawMixImage {
    self->shaderProgram = [GLESUtil creatShaderProgramWithVertextShaderName:@"vertexShader"
                                                         fragmentShaderName:@"fragmentShader"];
    [self begin];
    
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
    [GLESUtil genTexture:0 format:GL_RGBA filePath:path1];

    
    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"awesomeface.png" ofType:nil];
    [GLESUtil genTexture:1 format:GL_RGBA filePath:path2];

    glUniform1i(glGetUniformLocation(self->shaderProgram, "texture1"), 0); // 手动设置
    glUniform1i(glGetUniformLocation(self->shaderProgram, "texture2"), 1); // 手动设置

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
