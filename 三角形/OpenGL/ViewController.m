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
    [self _drawATriangle];
    [self _addGesture];
}

- (void)_addGesture {
    self.glView.userInteractionEnabled = NO;
    self.view.userInteractionEnabled = YES;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAct:)];
    [self.view addGestureRecognizer:panGesture];
}

// 单指拖动
- (void)panAct:(UIPanGestureRecognizer *)sender {
    // 禁止画布操作
    CGPoint point = [sender locationInView:self.view];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            self.lastPoint = point;
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint offsetPoint = CGPointMake(point.x - self.lastPoint.x, point.y - self.lastPoint.y);
            float vertices[] = {
                -1.f, -1, 0.0f, 0, 0, 0, 1,
                1.f, -1, 0.0f, 0, 0, 0, 1,
                0.0f, 1, 0.0f, 0, 0, 0, 1
            };
            // 更新uniform颜色
            NSTimeInterval time =  [NSDate timeIntervalSinceReferenceDate];
            float greenValue = sin(time) / 2.0f + 0.5f;
            int vertexColorLocation = glGetUniformLocation(shaderProgram, "ourColor");
            glUniform4f(vertexColorLocation, 0.0f, greenValue, 0.0f, 1.0f);
            
            glUseProgram(shaderProgram);

            glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertices), &vertices);
            glDrawArrays(GL_TRIANGLES, 0, 3);

            [context presentRenderbuffer:renderBuff];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
    self.lastPoint = point;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    [context presentRenderbuffer:renderBuff];
}

- (void)_drawATriangle {
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, (GLsizei)self.view.frame.size.width, (GLsizei)self.view.frame.size.height);
    // 指定顶点数据
    float vertices[] = {
        -0.5f, -0.5f, 0.0f, 1, 1, 0, 1,
        0.5f, -0.5f, 0.0f,  1, 1, 0, 1,
        0.0f, 0.5f, 0.0f, 0, 0, 1, 1
    };
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // 复制顶点数据到缓存对象中供GPU使用
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    //  链接顶点属性,指定输入的数据,那部分是对应着色器的哪个一个顶点属性.现在有顶点数据,但是不知道顶点数据是干嘛的,需要指定其如何解析
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, (3 + 4) * sizeof(float), (void*)0);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, (4 + 3) * sizeof(float), (void*)3);
    // 顶点属性默认是禁用的
    glEnableVertexAttribArray(0);
    glUseProgram(shaderProgram);
    // 如果顶点数组过多,会很麻烦,所以需要一个顶点数组描述好所有的顶点对象,再 glBindVertexArray 绑定VAO就行,只用调用一次,切换也很方便
    glDrawArrays(GL_TRIANGLES, 0, 3);
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
