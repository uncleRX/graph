//
//  ViewController.m
//  DrawPicture
//
//  Created by 任迅 on 2022/3/25.
//

#import "ViewController.h"
#import "Render/Renderer.h"

@import MetalKit;

#define PlatformLabel NSTextField
#define MakeRect      NSMakeRect

@implementation ViewController
{
    MTKView         *_view;

    Renderer* _renderer;
    CGPoint _readRegionBegin;
    __weak IBOutlet NSTextField *_infoLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    MTKView *mtView = (MTKView *)self.view;
    _view = mtView;
    mtView.device = MTLCreateSystemDefaultDevice();
    
    _renderer = [[Renderer alloc] initWithMTKView:mtView];
    mtView.delegate = _renderer;
    [_renderer mtkView:mtView drawableSizeWillChange:mtView.drawableSize];
}

#pragma mark Region Selection and Reading Methods

CGRect validateSelectedRegion(CGPoint begin, CGPoint end, CGSize drawableSize)
{
    CGRect region;

    // Ensure that the end point is within the bounds of the drawable.
    if (end.x < 0)
    {
        end.x = 0;
    }
    else if (end.x > drawableSize.width)
    {
        end.x = drawableSize.width;
    }

    if (end.y < 0)
    {
        end.y = 0;
    }
    else if (end.y > drawableSize.height)
    {
        end.y = drawableSize.height;
    }

    // Ensure that the lower-right corner is always larger than the upper-left
    // corner.
    CGPoint lowerRight;
    lowerRight.x = begin.x > end.x ? begin.x : end.x;
    lowerRight.y = begin.y > end.y ? begin.y : end.y;

    CGPoint upperLeft;
    upperLeft.x = begin.x < end.x ? begin.x : end.x;
    upperLeft.y = begin.y < end.y ? begin.y : end.y;

    region.origin = upperLeft;
    region.size.width = lowerRight.x - upperLeft.x;
    region.size.height = lowerRight.y - upperLeft.y;

    // Ensure that the width and height are at least 1.
    if (region.size.width < 1)
    {
        region.size.width = 1;
    }

    if (region.size.height < 1)
    {
        region.size.height = 1;
    }

    return region;
}

-(void)beginReadRegion:(CGPoint)point
{
    _readRegionBegin = point;
    _renderer.outlineRect = CGRectMake(_readRegionBegin.x, _readRegionBegin.y, 1, 1);
    _renderer.drawOutline = YES;
}

-(void)moveReadRegion:(CGPoint)point
{
    _renderer.outlineRect = validateSelectedRegion(_readRegionBegin, point, _view.drawableSize);
}

-(void)endReadRegion:(CGPoint)point
{
    _renderer.drawOutline = NO;

    CGRect readRegion = validateSelectedRegion(_readRegionBegin, point, _view.drawableSize);

    // Perform read with the selected region.
    AAPLImage *image = [_renderer renderAndReadPixelsFromView:_view
                                                   withRegion:readRegion];

    // Output pixels to file or Photos library.
    {
        NSURL *location;

        // In macOS, store the read pixels in an image file and save it
        // to the user's desktop.
        location = [[NSFileManager defaultManager] homeDirectoryForCurrentUser];
        location = [location URLByAppendingPathComponent:@"Desktop"];
        location = [location URLByAppendingPathComponent:@"ReadPixelsImage.tga"];
        [image saveToTGAFileAtLocation:location];
        NSMutableString *labelText =
            [[NSMutableString alloc] initWithFormat:@"%d x %d pixels read at (%d, %d)\n"
                                                     "Saved file to Desktop/ReadPixelsImage.tga",
             (uint32_t)readRegion.size.width, (uint32_t)readRegion.size.height,
             (uint32_t)readRegion.origin.x, (uint32_t)readRegion.origin.y];

        _infoLabel.stringValue = labelText;
        _infoLabel.textColor = [NSColor whiteColor];
    }
}

#pragma mark macOS UI Methods

- (void)viewDidAppear
{
    // Make the view controller the window's first responder so that it can
    // handle the Key events.
    [_view.window makeFirstResponder:self];
}

// Accept first responder so the view controller can respond to UI events.
- (BOOL)acceptsFirstResponder
{
    return YES;
}


- (void)mouseDown:(NSEvent*)event
{
    CGPoint bottomUpPixelPosition = [_view convertPointToBacking:event.locationInWindow];
    CGPoint topDownPixelPosition = CGPointMake(bottomUpPixelPosition.x,
                                               _view.drawableSize.height - bottomUpPixelPosition.y);
    [self beginReadRegion:topDownPixelPosition];
}


- (void)mouseDragged:(NSEvent*)event
{
    CGPoint bottomUpPixelPosition = [_view convertPointToBacking:event.locationInWindow];
    CGPoint topDownPixelPosition = CGPointMake(bottomUpPixelPosition.x,
                                               _view.drawableSize.height - bottomUpPixelPosition.y);
    [self moveReadRegion:topDownPixelPosition];
}

-(void)mouseUp:(NSEvent*)event
{
    CGPoint bottomUpPixelPosition = [_view convertPointToBacking:event.locationInWindow];
    CGPoint topDownPixelPosition = CGPointMake(bottomUpPixelPosition.x,
                                               _view.drawableSize.height - bottomUpPixelPosition.y);
    [self endReadRegion:topDownPixelPosition];
}


@end
