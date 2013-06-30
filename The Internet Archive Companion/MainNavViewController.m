//
//  HomeViewController.m
//  IA
//
//  Created by Hunter on 6/29/13.
//  Copyright (c) 2013 Hunter Lee Brown. All rights reserved.
//

#import "MainNavViewController.h"
#import "MainNavTableViewCell.h"
#import "MainNavTableViewHeaderViewCell.h"
#import "ArchiveSearchDoc.h"
#import "IAJsonDataService.h"



@interface MainNavViewController () <UITableViewDataSource, UITableViewDelegate, IADataServiceDelegate>

@property (nonatomic, weak) IBOutlet UITableView *navTable;
@property (nonatomic, strong) NSMutableArray *audioSearchDocuments;
@property (nonatomic, strong) NSMutableArray *videoSearchDocuments;
@property (nonatomic, strong) NSMutableArray *textSearchDocuments;

@property (nonatomic, strong) IAJsonDataService *audioService;
@property (nonatomic, strong) IAJsonDataService *videoService;
@property (nonatomic, strong) IAJsonDataService *textService;

@end


@implementation MainNavViewController

@synthesize navTable;
@synthesize audioSearchDocuments, videoSearchDocuments, textSearchDocuments;
@synthesize audioService, videoService, textService;

- (id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        audioSearchDocuments = [NSMutableArray new];
        videoSearchDocuments = [NSMutableArray new];
        textSearchDocuments = [NSMutableArray new];
        
        audioService = [[IAJsonDataService alloc] initForAllItemsWithCollectionIdentifier:@"audio"];
        videoService = [[IAJsonDataService alloc] initForAllItemsWithCollectionIdentifier:@"movies"];
        textService = [[IAJsonDataService alloc] initForAllItemsWithCollectionIdentifier:@"texts"];

        [audioService setDelegate:self];
        [videoService setDelegate:self];
        [textService setDelegate:self];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [[UITableViewHeaderFooterView appearance] setTintColor:[UIColor blackColor]];

    
    [audioService fetchData];
    [videoService fetchData];
    [textService fetchData];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) dataDidBecomeAvailableForService:(IADataService *)serv{
        
    if(serv == audioService && audioService.rawResults && [audioService.rawResults objectForKey:@"documents"]){
        [audioSearchDocuments removeAllObjects];
        [audioSearchDocuments addObjectsFromArray:[audioService.rawResults objectForKey:@"documents"]];
    }
    if(serv == videoService && videoService.rawResults && [videoService.rawResults objectForKey:@"documents"]){
        [videoSearchDocuments removeAllObjects];
        [videoSearchDocuments addObjectsFromArray:[videoService.rawResults objectForKey:@"documents"]];
    }
    if(serv == textService && textService.rawResults && [textService.rawResults objectForKey:@"documents"]){
        [textSearchDocuments removeAllObjects];
        [textSearchDocuments addObjectsFromArray:[textService.rawResults objectForKey:@"documents"]];
    }
    [navTable reloadData];
    
    
}




#pragma mark - table
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}

- (int) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return [audioSearchDocuments count];
            break;
        case 1:
            return [videoSearchDocuments count];
            break;
        case 2:
            return [textSearchDocuments count];
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MainNavTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mainNavCell"];
    
    ArchiveSearchDoc *doc;
    switch (indexPath.section) {
        case 0:
            doc = [audioSearchDocuments objectAtIndex:indexPath.row];
            break;
        case 1:
            doc = [videoSearchDocuments objectAtIndex:indexPath.row];
            break;
        case 2:
            doc = [textSearchDocuments objectAtIndex:indexPath.row];
            break;
        default:
            break;
    }
    
    
    [cell.navCellTitleLabel setText:doc.title];
    [cell.navImageView setArchiveImage:doc.archiveImage];
    
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return @"Audio Collections";
            break;
        case 1:
            return @"Video Collections";
            break;
        case 2:
            return @"Text Collections";
            break;
        default:
            return 0;
            break;
    }
    
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    MainNavTableViewHeaderViewCell *headerCell = [tableView dequeueReusableCellWithIdentifier:@"mainNavSectionHeader"];
    switch (section) {
        case 0:
            headerCell.sectionLabel.text =  @"Audio Collections";
            break;
        case 1:
            headerCell.sectionLabel.text =  @"Video Collections";
            break;
        case 2:
            headerCell.sectionLabel.text =  @"Text Collections";
            break;
        default:
            headerCell.sectionLabel.text =  @"";
            break;
    }
    return headerCell;

}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    ArchiveSearchDoc *doc;
    switch (indexPath.section) {
        case 0:
            doc = [audioSearchDocuments objectAtIndex:indexPath.row];
            break;
        case 1:
            doc = [videoSearchDocuments objectAtIndex:indexPath.row];
            break;
        case 2:
            doc = [textSearchDocuments objectAtIndex:indexPath.row];
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NavCellNotification" object:doc];
}



@end