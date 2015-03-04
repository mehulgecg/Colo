//
//  CollectionViewController.m
//  Colo
//
//  Created by Wongzigii on 11/25/14.
//  Copyright (c) 2014 Wongzigii. All rights reserved.
//

#import "CollectionViewController.h"
#import "ColorCell.h"
#import "Parser.h"
#import <QuartzCore/QuartzCore.h>
#import "BouncePresentAnimation.h"
#import "NormalDismissAnimation.h"
#import "SwipeUpInteractionTransition.h"
#import "DetailViewController.h"
#import "SettingsViewController.h"
#import "BaseNavigationController.h"
#import "MMPickerView.h"
#import "XHTwitterPaggingViewer.h"
#import "WZCoreDataManager.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>

#define kDeviceWidth  self.view.frame.size.width
#define kDeviceHeight self.view.frame.size.height
#define CocoaJSHandler       @"mpAjaxHandler"

static NSString *JSHandler;
static NSString *CellIdentifier = @"ColorCell";

@interface CollectionViewController ()<UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate, ModalViewControllerDelegate>

@property (strong, nonatomic) UITableView    *tableView;
@property (strong, nonatomic) UIView         *bottomView;
@property (strong, nonatomic) UIButton       *settingsButton;
@property (strong, nonatomic) UIButton       *chooseButton;

@property (copy,   nonatomic) NSMutableArray *objectArray;
@property (copy,   nonatomic) NSMutableArray *titleArray;
@property (copy,   nonatomic) NSMutableArray *likesArray;
@property (copy,   nonatomic) NSArray        *pickerArray;
@property (copy,   nonatomic) NSString       *selectedString;

@property (strong, nonatomic) BouncePresentAnimation *presentAnimation;
@property (strong, nonatomic) NormalDismissAnimation *dismissAnimation;
@property (strong, nonatomic) SwipeUpInteractionTransition *transitionController;

@property (strong, nonatomic) NSMutableArray *objects;

@end

@implementation CollectionViewController
#pragma mark - LifeCycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _presentAnimation     = [BouncePresentAnimation new];
        _dismissAnimation     = [NormalDismissAnimation new];
        _transitionController = [SwipeUpInteractionTransition new];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //UI
    [self initializeUI];
    [self addConstraints];
    
    _objectArray = [[NSMutableArray alloc] initWithArray:[Parser groupedTheArray:[Parser parseWithHTMLString]
                                                                   andTitleArray:[Parser parsewithTitle]
                                                                   andStarsArray:[Parser parsewithLikes]]];
    self.objects = [NSMutableArray new];
    [self.tableView reloadData];
    
    [self saveData];
    /// CoreData
    [self fetchDataFromCoreData];
}

- (void)initializeUI
{
    self.tableView      = [UITableView new];
    self.bottomView     = [UIView      new];
    self.settingsButton = [UIButton    new];
    self.chooseButton   = [UIButton    new];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 144.0;
    self.tableView.showsVerticalScrollIndicator = YES;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[ColorCell class] forCellReuseIdentifier:CellIdentifier];
    
    self.bottomView.backgroundColor = [UIColor blackColor];
    self.bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.settingsButton setImage:[UIImage imageNamed:@"gear.png"] forState:UIControlStateNormal];
    [self.settingsButton addTarget:self action:@selector(clickSettingsButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.chooseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.chooseButton setImage:[UIImage imageNamed:@"star.png"] forState:UIControlStateNormal];
    [self.chooseButton addTarget:self action:@selector(triggerUIPickerView) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view       addSubview:self.tableView];
    [self.view       addSubview:self.bottomView];
    [self.bottomView addSubview:self.settingsButton];
    [self.bottomView addSubview:self.chooseButton];
}

- (void)fetchDataFromCoreData
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Color"
                                                         inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSSortDescriptor *indexSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
    request.sortDescriptors = @[indexSortDescriptor];
    
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];

    if (!objects){
        NSLog(@"There was an error.");
    }
    
    for (NSManagedObject *oneObject in objects){
        
        NSString *title       = [oneObject valueForKey:@"title"];
        NSString *star        = [oneObject valueForKey:@"star"];
        NSString *index       = [oneObject valueForKey:@"index"];
        NSString *firstColor  = [oneObject valueForKey:@"firstColor"];
        NSString *secondColor = [oneObject valueForKey:@"secondColor"];
        NSString *thirdColor  = [oneObject valueForKey:@"thirdColor"];
        NSString *fourthColor = [oneObject valueForKey:@"fourthColor"];
        NSString *fifthColor  = [oneObject valueForKey:@"fifthColor"];
        int i = [index intValue];
        NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
        //ColorCell *cell = (ColorCell *)[self.tableView cellForRowAtIndexPath:path];
        
        UIColor *first  = [Parser translateStringToColor:firstColor];
        UIColor *second = [Parser translateStringToColor:secondColor];
        UIColor *third  = [Parser translateStringToColor:thirdColor];
        UIColor *fourth = [Parser translateStringToColor:fourthColor];
        UIColor *fifth  = [Parser translateStringToColor:fifthColor];
        
//        cell.firstColor.backgroundColor  = first;
//        cell.secondColor.backgroundColor = second;
//        cell.thirdColor.backgroundColor  = third;
//        cell.fourthColor.backgroundColor = fourth;
//        cell.fifthColor.backgroundColor  = fifth;
        NSArray *array = @[first, second, third, fourth, fifth];
        
        [self.objects addObject:array];
    }
}

- (void)saveData
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    
    NSError *error;
    NSUInteger count = [_objectArray count];
    for (NSUInteger index = 0; index < count; index ++)
    {
        //Create fetch request.
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        //Create entity description for context.
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Color"
                                                             inManagedObjectContext:context];
        //Set entity for request.
        [request setEntity:entityDescription];
        
        //确定持久库中是否存在与此字段相对应的托管对象，所以创建一个谓词来确定字段的正确对象：
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"index == %d",index];
        [request setPredicate:pred];
        
        //Declare a pointer.(for loading managed object or creating a new managed objcet)
        NSManagedObject *managedObject;
        
        //Execute fetch request.
        NSArray *objects = [context executeFetchRequest:request error:&error];
        
        if (!objects){
            NSLog(@"There was an error!");
        }
        
        //Check out objects which return from context by request, if so, load it, otherwise, initilize a new one to store.
        if ([objects count] > 0){
            managedObject = [objects objectAtIndex:0];
        }else{
            managedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Color"
                                                    inManagedObjectContext:context];
        }
        
        //datasource
        ColorModel *model = [_objectArray objectAtIndex:index];
        //Key-Value-Coding
        NSLog(@"%lu",(unsigned long)index);
        [managedObject setValue:[NSNumber numberWithUnsignedInteger:index] forKey:@"index"];
        [managedObject setValue:[model.colorArray objectAtIndex:0] forKey:@"firstColor"];
        [managedObject setValue:[model.colorArray objectAtIndex:1] forKey:@"secondColor"];
        [managedObject setValue:[model.colorArray objectAtIndex:2] forKey:@"thirdColor"];
        [managedObject setValue:[model.colorArray objectAtIndex:3] forKey:@"fourthColor"];
        [managedObject setValue:[model.colorArray objectAtIndex:4] forKey:@"fifthColor"];
        [managedObject setValue:model.title      forKey:@"title"];
        [managedObject setValue:model.star       forKey:@"star"];
        //[theLine setValue:model            forKey:@"id"];
        NSLog(@"%@",managedObject);
    }
    //error dealing
    [context save:&error];
    if (![context save:&error]) {
        NSLog(@"Can't save : %@", [error localizedDescription]);
    }
}

- (void)clickSettingsButton
{
    SettingsViewController *vc = [[SettingsViewController alloc] init];
    vc.delegate = self;
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self.transitionController wireToViewController:vc];
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)addConstraints
{
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_tableView, _bottomView, _settingsButton,_chooseButton);
    
    NSString *format;
    NSArray *constraintsArray;
    
    format = @"V:|[_tableView][_bottomView(49)]|";
    constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:viewsDictionary];
    [self.view addConstraints:constraintsArray];
    
    format = @"H:|[_tableView(_bottomView)]|";
    constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:viewsDictionary];
    [self.view addConstraints:constraintsArray];
    
    format = @"H:|[_bottomView]|";
    constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:viewsDictionary];
    [self.view addConstraints:constraintsArray];
    
//    [_tableView addConstraint:[NSLayoutConstraint constraintWithItem:_activityView
//                                                           attribute:NSLayoutAttributeCenterX
//                                                           relatedBy:NSLayoutRelationEqual
//                                                              toItem:_tableView
//                                                           attribute:NSLayoutAttributeCenterX
//                                                          multiplier:1.0f
//                                                            constant:0.0f]];
//    
//    [_tableView addConstraint:[NSLayoutConstraint constraintWithItem:_activityView
//                                                           attribute:NSLayoutAttributeCenterY
//                                                           relatedBy:NSLayoutRelationEqual
//                                                              toItem:_tableView
//                                                           attribute:NSLayoutAttributeCenterY
//                                                          multiplier:1.0f
//                                                            constant:0.0f]];

    
    
    //settings button
    format = @"V:[_settingsButton(20)]";
    constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:viewsDictionary];
    [self.view addConstraints:constraintsArray];
    
    [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_settingsButton
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_bottomView
                                                            attribute:NSLayoutAttributeCenterY
                                                           multiplier:1.0f
                                                             constant:0.0f]];
    
    //choose button
    format = @"V:[_chooseButton(17)]";
    constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:viewsDictionary];
    [self.view addConstraints:constraintsArray];
    
    [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_chooseButton
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_bottomView
                                                            attribute:NSLayoutAttributeCenterY
                                                           multiplier:1.0f
                                                             constant:0.0f]];
    
    format = @"H:|-[_chooseButton(17)]";
    constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:viewsDictionary];
    [_bottomView addConstraints:constraintsArray];
    
    format = @"H:[_settingsButton(20)]-|";
    constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:viewsDictionary];
    [_bottomView addConstraints:constraintsArray];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView = nil;
    self.settingsButton = nil;
    self.chooseButton = nil;
    self.bottomView = nil;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //return [_objectArray count];
    return [self.objects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ColorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    //http://objccn.io/issue-1-2/#separatingconcerns
    //[cell configureForColor:[_objectArray objectAtIndex:indexPath.row]];
    cell.firstColor.backgroundColor  = [[self.objects objectAtIndex:[indexPath row]] objectAtIndex:0];
    cell.secondColor.backgroundColor = [[self.objects objectAtIndex:[indexPath row]] objectAtIndex:1];
    cell.thirdColor.backgroundColor  = [[self.objects objectAtIndex:[indexPath row]] objectAtIndex:2];
    cell.fourthColor.backgroundColor = [[self.objects objectAtIndex:[indexPath row]] objectAtIndex:3];
    cell.fifthColor.backgroundColor  = [[self.objects objectAtIndex:[indexPath row]] objectAtIndex:4];
    //Auto Layout
    [cell setNeedsUpdateConstraints];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //XHTwitterPaggingViewer *pagging = [[XHTwitterPaggingViewer alloc] init];
    DetailViewController *vc = [[DetailViewController alloc] init];
//    SecondDetailViewController *second = [[SecondDetailViewController alloc] init];
//    NSArray *arrary = @[vc, second];
//    pagging.viewControllers = arrary;
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    vc.delegate = self;
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self.transitionController wireToViewController:vc];
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - UIViewControllerTransitioningDelegate
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self.presentAnimation;
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self.dismissAnimation;
}

-(id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    return self.transitionController.interacting ? self.transitionController : nil;
}

#pragma mark - ModalViewControllerDelegate
-(void)modalViewControllerDidClickedDismissButton:(ModalViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate
//statusBar animation
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y < 0 && scrollView.tracking == YES){
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }else{
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }
}

//#pragma mark - UIPickerViewDelegate
//- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
//{
//    
//}
//
//- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
//{
//    return 40.f;
//}
//
//#pragma mark - UIPickerViewDataSource
//- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
//{
//    return 2;
//}
//
//- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
//{
//    int number = 0;
//    switch (component) {
//        case 0:
//            number = 17;
//            break;
//        case 1:
//            number = 3;
//            break;
//    }
//    return number;
//}
//
//- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    NSString *string;
//    NSArray *titleArray = @[@"Dansk", @"Deutsch", @"English", @"Español", @"Français", @"Italiano", @"Nederlands", @"Norsk", @"Polski", @"Português", @"Suomi", @"Svenska", @"Türkçe", @"Pусский", @"繁體中文", @"日本語", @"한국어"];
//    NSArray *popularityArray = @[@"周", @"月", @"全部"];
//    switch (component) {
//        //Country
//        case 0:
//            string = [titleArray objectAtIndex:row];
//            break;
//        //Popularity
//        case 1:
//            string = [popularityArray objectAtIndex:row];
//            break;
//    }
//    return string;
//}

@end
