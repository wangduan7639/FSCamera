//
//  RootViewController.m
//  FS
//
//  Created by wangduan on 14-2-18.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import "RootViewController.h"
#import "FSCameraViewController.h"

@interface RootViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    UITableView    * _mTableView;
    NSMutableArray * _mArray;
}
@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _mArray = [[NSMutableArray alloc] initWithObjects:@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"11",@"12",@"13", nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cameraBtn.frame = CGRectMake(100, 100, 100, 44);
    [cameraBtn setTitle:@"camera" forState:UIControlStateNormal];
    [cameraBtn addTarget:self action:@selector(cameraClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraBtn];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    //下面纯属测试这玩。
//    _mTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, [UIScreen mainScreen].bounds.size.height-64) style:UITableViewStylePlain] ;
//    _mTableView.backgroundColor = [UIColor blueColor];
//    _mTableView.delegate   = self;
//    _mTableView.dataSource = self;
//    [self.view addSubview:_mTableView];
//    [_mTableView reloadData];
    
    UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithTitle:@"右键" style:UIBarButtonItemStylePlain target:self action:@selector(rightItem:)];
    self.navigationItem.rightBarButtonItem = item;
    
}
- (void)rightItem:(UIBarButtonItem *)item
{
    
}
- (void)cameraClicked:(UIButton *)sender{
    [UIApplication sharedApplication].statusBarHidden = YES;
    FSCameraViewController * fsCameraVC = [[FSCameraViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:fsCameraVC];
    [self presentViewController:nav animated:YES completion:nil];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return [_mArray count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.0f;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *str = @"strCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:str];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:str];
    }
    cell.backgroundColor = [UIColor redColor];
    cell.textLabel.text = [_mArray objectAtIndex:indexPath.row];
    return cell;
}
@end
