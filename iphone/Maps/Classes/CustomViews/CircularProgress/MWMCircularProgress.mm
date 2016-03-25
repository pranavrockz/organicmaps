#import "MWMCircularProgress.h"
#import "MWMCircularProgressView.h"

namespace
{
UINib * const progressViewNib = [UINib nibWithNibName:@"MWMCircularProgress" bundle:[NSBundle mainBundle]];
} // namespace

@interface MWMCircularProgressView ()

@property (nonatomic) BOOL suspendRefreshProgress;

@end

@interface MWMCircularProgress ()

@property (nonatomic) IBOutlet MWMCircularProgressView * rootView;
@property (nonatomic) NSNumber * nextProgressToAnimate;

@end

@implementation MWMCircularProgress

+ (nonnull instancetype)downloaderProgressForParentView:(nonnull UIView *)parentView
{
  MWMCircularProgress * progress = [[MWMCircularProgress alloc] initWithParentView:parentView];

  progress.rootView.suspendRefreshProgress = YES;

  [progress setImage:[UIImage imageNamed:@"ic_download"]
           forStates:{MWMCircularProgressStateNormal, MWMCircularProgressStateSelected}];
  [progress setImage:[UIImage imageNamed:@"ic_close_spinner"]
           forStates:{MWMCircularProgressStateProgress, MWMCircularProgressStateSpinner}];
  [progress setImage:[UIImage imageNamed:@"ic_download_error"]
           forStates:{MWMCircularProgressStateFailed}];
  [progress setImage:[UIImage imageNamed:@"ic_check"]
           forStates:{MWMCircularProgressStateCompleted}];

  [progress setColoring:MWMButtonColoringBlack
              forStates:{MWMCircularProgressStateNormal, MWMCircularProgressStateSelected,
                         MWMCircularProgressStateProgress, MWMCircularProgressStateSpinner}];
  [progress setColoring:MWMButtonColoringOther forStates:{MWMCircularProgressStateFailed}];
  [progress setColoring:MWMButtonColoringBlue forStates:{MWMCircularProgressStateCompleted}];

  progress.rootView.suspendRefreshProgress = NO;

  return progress;
}

- (nonnull instancetype)initWithParentView:(nonnull UIView *)parentView
{
  self = [super init];
  if (self)
  {
    [progressViewNib instantiateWithOwner:self options:nil];
    [parentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [parentView addSubview:self.rootView];
    self.state = MWMCircularProgressStateNormal;
  }
  return self;
}

- (void)dealloc
{
  [self.rootView removeFromSuperview];
}

- (void)reset
{
  _progress = 0.;
  [self.rootView updatePath:0.];
  self.nextProgressToAnimate = nil;
}

- (void)setImage:(nonnull UIImage *)image forStates:(MWMCircularProgressStateVec const &)states
{
  for (auto const & state : states)
    [self.rootView setImage:image forState:state];
}

- (void)setColor:(nonnull UIColor *)color forStates:(MWMCircularProgressStateVec const &)states
{
  for (auto const & state : states)
    [self.rootView setColor:color forState:state];
}

- (void)setColoring:(MWMButtonColoring)coloring forStates:(MWMCircularProgressStateVec const &)states
{
  for (auto const & state : states)
    [self.rootView setColoring:coloring forState:state];
}

- (void)setInvertColor:(BOOL)invertColor
{
  self.rootView.isInvertColor = invertColor;
}

#pragma mark - Animation

- (void)animationDidStop:(CABasicAnimation *)anim finished:(BOOL)flag
{
  if (self.nextProgressToAnimate)
  {
    self.progress = self.nextProgressToAnimate.doubleValue;
    self.nextProgressToAnimate = nil;
  }
}

#pragma mark - Actions

- (IBAction)buttonTouchUpInside:(UIButton *)sender
{
  [self.delegate progressButtonPressed:self];
}

#pragma mark - Properties

- (void)setProgress:(CGFloat)progress
{
  if (progress < _progress || progress <= 0)
  {
    self.state = MWMCircularProgressStateSpinner;
    return;
  }
  self.rootView.state = MWMCircularProgressStateProgress;
  if (self.rootView.animating)
  {
    if (progress > self.nextProgressToAnimate.floatValue)
      self.nextProgressToAnimate = @(progress);
  }
  else
  {
    dispatch_async(dispatch_get_main_queue(), ^
    {
      [self.rootView animateFromValue:self->_progress toValue:progress];
      self->_progress = progress;
    });
  }
}

- (void)setState:(MWMCircularProgressState)state
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self reset];
    self.rootView.state = state;
  });
}

- (MWMCircularProgressState)state
{
  return self.rootView.state;
}

@end
