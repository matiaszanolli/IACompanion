//
//  HomeContentViewController.m
//  IA
//
//  Created by Hunter on 5/17/13.
//  Copyright (c) 2013 Hunter Lee Brown. All rights reserved.
//

#import "HomeContentViewController.h"
#import "HomeContentCell.h"
#import "ArchiveDetailedViewController.h"
#import "ArchiveCollectionDetailedViewController.h"

@interface HomeContentViewController ()

@end

@implementation HomeContentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    

}

- (void) viewDidAppear:(BOOL)animated{

    NSURL *blogUrl = [NSURL URLWithString:@"http://blog.archive.org/category/announcements/"];
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:blogUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    [_homeContentView.iABlogWebView loadRequest:req];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotNavCellSelectNotification:) name:@"CollectionCellNotification" object:nil];

    
}

- (void) viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CollectionCellNotification" object:nil];

    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void) gotNavCellSelectNotification:(NSNotification *)notification{

    
    ArchiveSearchDoc *aDoc = notification.object;
    HomeContentCell *cell = [HomeContentCell new];
    [cell setDoc:aDoc];
    
    
    if(aDoc.type == MediaTypeCollection){
        [self performSegueWithIdentifier:@"homeCollectionDetailPush" sender:cell];
    } else {
        [self performSegueWithIdentifier:@"homeCellPush" sender:cell];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([[segue identifier] isEqualToString:@"homeCellPush"]){
        
        HomeContentCell *cell = (HomeContentCell *)sender;
        ArchiveSearchDoc *doc = cell.doc;
        
        ArchiveDetailedViewController *detailViewController = [segue destinationViewController];
        //[detailViewController setTitle:doc.title];
        [detailViewController setIdentifier:doc.identifier];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"MoveOverNotification" object:nil];

    }

    if([[segue identifier] isEqualToString:@"homeCollectionDetailPush"]){
        
        HomeContentCell *cell = (HomeContentCell *)sender;
        ArchiveSearchDoc *doc = cell.doc;
        
        ArchiveCollectionDetailedViewController *detailViewController = [segue destinationViewController];
        //[detailViewController setTitle:doc.title];
        [detailViewController setIdentifier:doc.identifier];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MoveOverNotification" object:nil];
        
    }
    
    
}

@end