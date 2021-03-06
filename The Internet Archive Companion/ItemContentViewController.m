//
//  ItemContentViewController.m
//  IA
//
//  Created by Hunter on 6/30/13.
//  Copyright (c) 2013 Hunter Lee Brown. All rights reserved.
//

#import "ItemContentViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ArchiveFile.h"
#import "MediaFileCell.h"
#import "MediaFileHeaderCell.h"
#import "MediaImageViewController.h"
#import "ArchivePageViewController.h"
#import <Social/Social.h>
#import "MediaUtils.h"
#import "FontMapping.h"
#import "CollectionDataHandlerAndHeaderView.h"
#import "StringUtils.h"
#import "AppDelegate.h"
#import "AppCoreDataManager.h"



@interface ItemContentViewController () <UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate>

@property (nonatomic, strong) NSMutableArray *mediaFiles;
@property (nonatomic, strong) NSMutableDictionary *organizedMediaFiles;
@property (nonatomic, weak) IBOutlet UITableView *mediaTable;
@property (nonatomic, weak) IBOutlet UIView *collectionHolderView;

@property (nonatomic, strong) NSURL *externalUrl;

@property (nonatomic, weak) IBOutlet UIButton *searchCollectionButton;

@property (nonatomic, weak) IBOutlet CollectionDataHandlerAndHeaderView *collectionHandlerView;
@property (nonatomic, strong) IAJsonDataService *service;

//  [(MyAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];

@property (nonatomic, weak) IBOutlet ArchiveImageView *titleImage;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *titleImageBottom;

@property (nonatomic, weak) IBOutlet UIView *titleImageOverlay;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *titleOverlayHeight;

@property (nonatomic) BOOL weAreObserving;

@property (nonatomic, strong) CAGradientLayer *overlayGradient;
@property (nonatomic, weak) IBOutlet UIView *blackOut;

@property (nonatomic) BOOL thisIsAFavorite;

@property (nonatomic, strong) UIColor *adjColor;

@end

@implementation ItemContentViewController
@synthesize mediaFiles, organizedMediaFiles, mediaTable;

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
    self.title = @"ITEM";
    [super viewDidLoad];

    self.navigationItem.title = @"";

	// Do any additional setup after loading the view.

    self.backButton = [[UIBarButtonItem alloc] initWithTitle:BACK style:UIBarButtonItemStylePlain target:self action:@selector(didPressBackButton)];
    [self.backButton setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"Iconochive-Regular" size:30.0]} forState:UIControlStateNormal];

    [self.navigationItem setLeftBarButtonItems:@[self.backButton]];


    mediaFiles = [NSMutableArray new];
    organizedMediaFiles = [NSMutableDictionary new];

    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowLoadingIndicator" object:[NSNumber numberWithBool:YES]];

    if ([self.mediaTable respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.mediaTable setSeparatorInset:UIEdgeInsetsZero];
    }
    
    NSLog(@"---->parent: %@", self.parentViewController.restorationIdentifier);
    if([self.parentViewController.restorationIdentifier isEqualToString:@"searchNav"])
    {
        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:CLOSE style:UIBarButtonSystemItemCancel target:self action:@selector(closeSearch)];
        [closeItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"Iconochive-Regular" size:20.0]} forState:UIControlStateNormal];
    }

    [self.navigationItem setRightBarButtonItems:nil];
    
    if(self.searchCollectionButton){
        [self.searchCollectionButton setTintColor:BUTTON_DEFAULT_SELECT_COLOR];
    }


//    [self.descriptionButton setSelected:YES];
    [self.folderButton setSelected:YES];
    

    [self.itemWebView setOpaque:NO];
    self.itemWebView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    [self.itemWebView setBackgroundColor:[UIColor whiteColor]];

    self.itemWebView.alpha = 0;
    self.collectionHolderView.alpha = 0;
    self.mediaTable.alpha = 1.0;
    
//    self.imageView.layer.cornerRadius = self.imageView.bounds.size.width / 2;
//    self.imageView.layer.masksToBounds = YES;

    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    [self.collectionHandlerView setParentViewController:self];

    self.mediaTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.titleImage.archiveImage = self.searchDoc.archiveImage;
    

    if(self.overImage && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && self.searchDoc.archiveImage)
    {
        [self.overImage setArchiveImage:self.searchDoc.archiveImage];
    } else
    {
        self.overImage.hidden = YES;
    }
    
    [self doGradientWithColor:[UIColor clearColor]];
    self.blackOut.alpha = 0.0;
    
    
    self.mediaTable.rowHeight = UITableViewAutomaticDimension;
    self.mediaTable.estimatedRowHeight = 44;
    
    [self.service fetchData];

    
    
}



- (void)viewDidLayoutSubviews
{
    

    self.titleImageBottom.constant = self.mediaTable.frame.origin.y + self.mediaTable.bounds.size.height;
    [self.titleImage layoutIfNeeded];
    
    self.titleOverlayHeight.constant = self.titleImageBottom.constant;
    [self.titleImageOverlay layoutIfNeeded];
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];

    
    self.overlayGradient.frame = self.view.bounds;
    
    [super viewDidLayoutSubviews];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.blackOut.alpha = 1.0;
    self.titleImage.hidden = YES;
    [super viewWillDisappear:animated];
}


- (void) viewDidDisappear:(BOOL)animated{
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeStatusBarBlack" object:nil];

    [super viewDidDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    if(self.titleImage.archiveImage.downloaded)
    {
        self.blackOut.alpha = 0.0;
    }

    self.navigationController.view.backgroundColor = [UIColor clearColor];

    [self makeTranslToolbar:self.navigationController.navigationBar];

    [self.itemToolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    self.itemToolbar.backgroundColor = [UIColor clearColor];
    [self.itemToolbar setTintColor:[UIColor whiteColor]];
    
    self.titleImage.hidden = NO;

    
}

- (void)makeTranslToolbar:(UINavigationBar *)toolbar
{
    [toolbar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    toolbar.backgroundColor = [UIColor clearColor];
    [toolbar setTintColor:[UIColor whiteColor]];

    toolbar.shadowImage = [UIImage new];
    toolbar.translucent = YES;
}


- (void) viewDidAppear:(BOOL)animated{
    

//    [super viewDidAppear:animated];

}

- (IBAction)closeVC:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) setSearchDoc:(ArchiveSearchDoc *)searchDoc{
    _searchDoc = searchDoc;
    self.service = nil;
    self.service = [[IAJsonDataService alloc] initForMetadataDocsWithIdentifier:_searchDoc.identifier];
    [self.service setDelegate:self];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        self.overImage.hidden  = YES;
    }
    
//    self.titleImage.archiveImage = self.searchDoc.archiveImage;

}


- (void) didPressMPButton {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenMediaPlayer" object:nil];
}

- (void)closeSearch
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchViewControllerClose" object:nil];
    [(UINavigationController*)self.parentViewController popViewControllerAnimated:NO];
}


- (void) didPressBackButton{
    [self.collectionHandlerView.service stopFetchingData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowLoadingIndicator" object:[NSNumber numberWithBool:NO]];
    [self.navigationController popViewControllerAnimated:YES];
}



- (IBAction)addFavorite:(id)sender{
    

    if(!self.thisIsAFavorite)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddFavoriteNotification" object:self.detDoc];
    } else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveFavoriteNotification" object:self.detDoc];
    }

    self.thisIsAFavorite = [[AppCoreDataManager sharedInstance] hasFavoritesIdentifier:self.searchDoc.identifier];
    [self adjustButtonColorsWithColor:self.adjColor];
    
    
    NSString *addFavorite = @"Item added to your favorites list.  Find your favorites on the left hand nav of the main screen. Press the Internet Archive logo at the top of the page.";
    
    NSString *removeFavorite = @"Item removed from your favorites list.";
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Favorites" message:self.thisIsAFavorite ? addFavorite : removeFavorite delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    
    [alert show];
    
}


#pragma mark - Results

- (void) dataDidBecomeAvailableForService:(IADataService *)service{
    
    
    if([[((IAJsonDataService *)service).rawResults objectForKey:@"documents"] objectAtIndex:0] == nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NotifyUser" object:@"We caught an error in the data from the Internet Archive. \n \n Content not available."];
        return;
    }
    
    
    self.detDoc = [[((IAJsonDataService *)service).rawResults objectForKey:@"documents"] objectAtIndex:0];
    
    self.titleLabel.text = self.detDoc.title;
    if(self.detDoc.archiveImage){
        [self.imageView setArchiveImage:self.detDoc.archiveImage];
        self.itemImageUrl = self.detDoc.archiveImage.urlPath;
        self.itemImageWidth = 300.0f;

    }


    BOOL gotAnImage = NO;
    NSMutableArray *files = [NSMutableArray new];
    
    for(ArchiveFile *file in self.detDoc.files){
        if(file.format != FileFormatOther){
            [files addObject:file];
            
            if(self.detDoc.type != MediaTypeCollection) {
                if((file.format == FileFormatJPEG || file.format == FileFormatPNG || file.format == FileFormatImage) && ![[file.file objectForKey:@"source"] isEqualToString: @"derivative"]) {
                    if(gotAnImage == NO)
                    {
                        gotAnImage = YES;
                        self.itemImageUrl = file.url;
                        self.itemImageWidth = self.view.bounds.size.width > 320 ? ceil(self.view.bounds.size.width * 0.75)  : 300;
                    }
                }
            }
        }
    }



    self.typeLabel.text = [MediaUtils iconStringFromMediaType:self.detDoc.type];
    [self.typeLabel setTextColor:[MediaUtils colorFromMediaType:self.detDoc.type]];

    if(self.detDoc.creator)
    {
        NSString *creator = self.detDoc.creator;
        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", @"by", creator]];
        [attString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, [@"by" length])];

        if(self.detDoc.type == MediaTypeCollection) {
            [attString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(3, creator.length)];
        } else {
            [attString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(3, creator.length)];
        }
        
        NSMutableAttributedString *selAtt = [[NSMutableAttributedString alloc] initWithAttributedString:attString];
        [selAtt addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:NSMakeRange(3, creator.length)];
        
        NSShadow *shadow = [NSShadow new];
        [shadow setShadowColor : [UIColor darkGrayColor]];
        [shadow setShadowOffset : CGSizeMake(1.0f, 1.0f)];
        
        [attString addAttribute:NSShadowAttributeName value:shadow range:NSMakeRange(0, creator.length + 3)];

        [self.creatorButton setAttributedTitle:attString forState:UIControlStateNormal];
        [self.creatorButton setAttributedTitle:selAtt forState:UIControlStateHighlighted];

    }




    NSLog(@"------> imageWidth:%f", self.itemImageWidth);

    NSString *imgHtml = [NSString stringWithFormat:@"<img style='display:block; margin-left:auto; margin-right:auto; width:%fpx; max-width:%fpx;' src='%@'/><br/>", self.itemImageWidth, self.itemImageWidth, self.itemImageUrl];


    if(self.detDoc.type == MediaTypeCollection)
    {
        imgHtml = @"";
        [self.typeLabel setTextColor:[UIColor whiteColor]];
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        [self.titleLabel setText:[NSString stringWithFormat:@"%@ Collection", self.detDoc.title]];

        [self.collectionHandlerView setIdentifier:self.searchDoc.identifier];

        self.imageView.hidden = YES;
        self.typeLabel.hidden = NO;

        [self toggleViews:self.collectionButton];
        
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeStatusBarWhite" object:nil];
        
    }
    else
    {
        NSString *date = [StringUtils displayDateFromArchiveDateString:self.detDoc.publicDate];
        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", @"Archived", date]];
        [attString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, [@"Archived" length])];
        [self.dateLabel setAttributedText:attString];

        self.imageView.hidden = YES;
        
        NSMutableArray *mItems = [NSMutableArray new];
        for (UIBarButtonItem *i in self.itemToolbar.items) {
            if(i != self.collectionBarButton)
            {
                [mItems addObject:i];
            }
        }
        [self.itemToolbar setItems:mItems];
        
        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
        {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeStatusBarWhite" object:nil];
        }
        
    }

    
    
    NSString *html = [NSString stringWithFormat:@"<html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'/><style>img{max-width:%fpx !important;} a:link{color:#666; text-decoration:none;} p{padding:5px;}</style></head><body style='margin-left:10px; margin-right:10px; background-color:#fff; color:#000; font-size:15px; font-family:\"Helvetica\"'>%@</body></html>", self.itemImageWidth, [StringUtils htmlStringByAddingBreaks:self.detDoc.details]];
    

    NSURL *theBaseURL = [NSURL URLWithString:@"http://archive.org"];
    
    [self.itemWebView loadData:[html dataUsingEncoding:NSUTF8StringEncoding]
                             MIMEType:@"text/html"
                     textEncodingName:@"UTF-8"
                              baseURL:theBaseURL];
    

    
//    [self.titleImage setAlpha:0.0];
    

    
    if(self.titleImage.archiveImage.downloaded)
    {
        [self fadeInEverything];
    } else
    {
        if(!self.titleImage.archiveImage)
        {
            self.titleImage.archiveImage = self.detDoc.archiveImage;
            [self.titleImage.archiveImage startDownloading];
        }
        
        [self.titleImage.archiveImage addObserver:self forKeyPath:@"downloaded" options:NSKeyValueObservingOptionNew context:NULL];
        self.weAreObserving = YES;
    }
    
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"track" ascending:YES];
    [mediaFiles addObjectsFromArray:[files sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]]];
    
    [self orgainizeMediaFiles:mediaFiles];

    if(organizedMediaFiles.count == 0)
    {
        self.folderButton.hidden = YES;
        self.mediaTable.hidden = YES;
        self.itemWebView.hidden = NO;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowLoadingIndicator" object:[NSNumber numberWithBool:NO]];

 
    if(self.navigationController.navigationBarHidden)
    {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
    

}


#pragma mark - Handling Fading in Background Image, etc

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if(object == self.detDoc.archiveImage && [keyPath isEqualToString:@"downloaded"]){
        [self fadeInEverything];
    }

}

- (void) fadeInEverything
{
    NSOperationQueue *queue = [NSOperationQueue new];
    ItemContentViewController __weak *weakSelf = self;
    // Querying favorites can take a little bit of time, so putting this on a background thread.
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        weakSelf.thisIsAFavorite = [[AppCoreDataManager sharedInstance] hasFavoritesIdentifier:weakSelf.searchDoc.identifier];
        [weakSelf performSelectorOnMainThread:@selector(extraFade) withObject:nil waitUntilDone:NO];
    }];
    [queue addOperation:operation];
    
}

- (void)extraFade
{

    BOOL isDark = NO;
    UIColor *avColor;
    CGFloat hue, saturation, brightness, alpha;
    
    
    if([self isGrayScaleImage:self.detDoc.archiveImage.contentImage])
    {
        avColor = [UIColor whiteColor];
        self.adjColor = [UIColor whiteColor];
        isDark = NO;
    }
    else
    {
        avColor = [self averageColor:self.detDoc.archiveImage.contentImage];
        
        if ([avColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
            brightness += (1.5-1.0);
            brightness = MAX(MIN(brightness, 1.0), 0.0);
            self.adjColor =  [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
        }
    }
    
    [UIView animateWithDuration:0.33 animations:^{
        
        [self.titleLabel setTextColor:self.adjColor];
        
        [self.collectionHandlerView.filters setTintColor:self.adjColor];
        [self.collectionHandlerView.countLabel setTextColor:self.adjColor];
        
        [self adjustButtonColorsWithColor:self.adjColor];
        
        self.titleImage.alpha = 1.0;
        
        if(self.overImage)
        {
            self.overImage.alpha = 0.0;
        }
        
    } completion:nil];

}


- (void)adjustButtonColorsWithColor:(UIColor *)adjColor
{

    for(UIButton *butt in @[self.wwwButton, self.descriptionButton, self.folderButton, self.favoritesButton, self.shareButton, self.searchCollectionButton])
    {
        [butt setTitleColor:adjColor forState:UIControlStateNormal];
    }
    if(self.thisIsAFavorite)
    {
        [self.favoritesButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    
}


// http://stackoverflow.com/questions/16768739/how-to-detect-image-is-grayscale
- (BOOL)isGrayScaleImage:(UIImage *)image{
    
    @autoreleasepool {
        
        CGImageRef imageRef = [image CGImage];
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
        
        if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelRGB)
        {
            
            CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
            CFDataRef imageData = CGDataProviderCopyData(dataProvider);
            const UInt8 *rawData = CFDataGetBytePtr(imageData);
            
            size_t width = CGImageGetWidth(imageRef);
            size_t height = CGImageGetHeight(imageRef);
            
            int byteIndex = 0;
            BOOL allPixelsGrayScale = YES;
            for(int ii = 0 ; ii <width*height; ++ii)
            {
                int r = rawData[byteIndex];
                int g = rawData[byteIndex+1];
                int b = rawData[byteIndex+2];
                if (!((r == g)&&(g == b))) {
                    allPixelsGrayScale = NO;
                    break;
                }
                byteIndex += 4;
            }

            return allPixelsGrayScale;
        }
        else if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome)
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }

}


- (void)doGradientWithColor:(UIColor *)color
{
    
    UIColor *topColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.33];
    UIColor *upperMiddleColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.65];
    UIColor *middleColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.85];
    UIColor *bottomColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0];
//
//    UIColor *topColor = [color colorWithAlphaComponent:0.33];
//    UIColor *upperMiddleColor = [color colorWithAlphaComponent:0.65];
//    UIColor *middleColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.85];
//    UIColor *bottomColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0];
    
    self.overlayGradient = [CAGradientLayer layer];
    self.overlayGradient.frame = self.view.bounds;
    self.overlayGradient.colors = [NSArray arrayWithObjects: (id)topColor.CGColor, (id)upperMiddleColor.CGColor, (id)middleColor.CGColor, (id)bottomColor.CGColor, nil];
    [self.titleImageOverlay.layer insertSublayer:self.overlayGradient atIndex:0];

}


//http://stackoverflow.com/questions/13694618/objective-c-getting-least-used-and-most-used-color-in-a-image
- (UIColor *)averageColor:(UIImage *)image {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char rgba[4];
    CGContextRef context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), image.CGImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    if(rgba[3] > 0) {
        CGFloat alpha = ((CGFloat)rgba[3])/255.0;
        CGFloat multiplier = alpha/255.0;
        return [UIColor colorWithRed:((CGFloat)rgba[0])*multiplier
                               green:((CGFloat)rgba[1])*multiplier
                                blue:((CGFloat)rgba[2])*multiplier
                               alpha:alpha];
    }
    else {
        return [UIColor colorWithRed:((CGFloat)rgba[0])/255.0
                               green:((CGFloat)rgba[1])/255.0
                                blue:((CGFloat)rgba[2])/255.0
                               alpha:((CGFloat)rgba[3])/255.0];
    }
}



#pragma mark - toggle about and folders

- (IBAction)toggleViews:(id)sender
{
    self.mediaTable.hidden = sender != self.folderButton;
    self.itemWebView.hidden = sender != self.descriptionButton;
    self.collectionHolderView.hidden = sender != self.collectionButton;

    self.folderButton.selected = sender == self.folderButton;
    self.descriptionButton.selected = sender == self.descriptionButton;
    self.collectionButton.selected = sender == self.collectionButton;

    [UIView animateWithDuration:0.33 animations:^{



        self.itemWebView.alpha = sender == self.descriptionButton ? 1.0 : 0;
        self.collectionHolderView.alpha = sender == self.collectionButton ? 1.0 : 0;
        self.mediaTable.alpha = sender == self.folderButton ? 1.0 : 0;

    }];

}

#pragma mark - creator button
- (IBAction)didPressCreatorButton:(id)sender
{
//    NSString *encode = [self.detDoc.creator stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSCharacterSet *customAllowedSet =  [NSCharacterSet characterSetWithCharactersInString:@"=\"#%/&<>?@\\^`{|}"].invertedSet;
    NSString *sEncode = [self.detDoc.creator stringByAddingPercentEncodingWithAllowedCharacters:customAllowedSet];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchViewControllerCreator" object:[NSString stringWithFormat:@"creator:\"%@\"", sEncode]];
}


#pragma mark - massaging files and file data

- (void) orgainizeMediaFiles:(NSMutableArray *)files{
    for(ArchiveFile *f in files){
        if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:f.format]] != nil){

            if(f.format == FileFormatPNG && [[f.file objectForKey:@"source"] isEqualToString: @"derivative"] )
            { } else {
            [[organizedMediaFiles objectForKey:[NSNumber numberWithInt:f.format]] addObject:f];
            }

        } else {

            if(f.format == FileFormatPNG && [[f.file objectForKey:@"source"] isEqualToString: @"derivative"] )
            { } else {
                NSMutableArray *filesForFormat = [NSMutableArray new];
                [filesForFormat addObject:f];
                [organizedMediaFiles setObject:filesForFormat forKey:[NSNumber numberWithInt:f.format]];            }
        }
    }
    
//    FileFormat64KbpsMP3 = 8,
//    FileFormat128KbpsMP3 = 12,
//    FileFormatMP3 = 13,
//    FileFormat96KbpsMP3 = 14,
//
    // REMOVING ALL AUDIO BESIDES VBR MP3
    if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormat128KbpsMP3]] != nil){
        [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormat128KbpsMP3]];
    }
    if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormatMP3]] != nil){
        [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormatMP3]];
    }
    if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormat96KbpsMP3]] != nil){
        [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormat96KbpsMP3]];
    }
    if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormat64KbpsMP3]] != nil){
        [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormat64KbpsMP3]];
    }
    
    if(self.detDoc.type != MediaTypeTexts)
    {
        if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormatDjVuTXT]] != nil){
            [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormatDjVuTXT]];
        }
        if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormatTxt]] != nil){
            [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormatTxt]];
        }
    }
    
    
    if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormatVBRMP3]] != nil)
    {
        // Filtering out repeated titles in VBR List
        NSArray *vbrs = [organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormatVBRMP3]];
        NSMutableSet* existingNames = [NSMutableSet set];
        NSMutableArray* filteredArray = [NSMutableArray array];
        for (ArchiveFile *file in vbrs) {
            if (![existingNames containsObject:file.title]) {
                [existingNames addObject:file.title];
                [filteredArray addObject:file];
            }
        }
        [organizedMediaFiles setObject:filteredArray forKey:[NSNumber numberWithInt:FileFormatVBRMP3]];
    }
        
    [mediaTable reloadData];
    
}

#pragma mark - Table Stuff
- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(organizedMediaFiles.count == 0){
        return @"";
    }
    
    ArchiveFile *firstFile;
    firstFile = [[organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:section]] objectAtIndex:0];
    return [firstFile.file objectForKey:@"format"];
  
} 

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MediaFileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mediaFileCell"];
    
    if(organizedMediaFiles.count > 0){
        ArchiveFile *aFile = [[organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];

//        cell.fileTitle.text = aFile.title;
        cell.fileTitle.text = [NSString stringWithFormat:@"%@%@",aFile.track ? [NSString stringWithFormat:@"%ld ",(long)aFile.track] : @"",aFile.title];
        cell.fileFormat.text = [aFile.file objectForKey:@"format"];
        cell.durationLabel.text = [aFile.file objectForKey:@"duration"];
        cell.fileName.text = aFile.name;
        
    }
    
    
    return cell;

}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(organizedMediaFiles.count > 0){
        ArchiveFile *aFile = [[organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        if(aFile.format == FileFormatJPEG || aFile.format == FileFormatGIF || aFile.format == FileFormatPNG || aFile.format == FileFormatImage) {
            MediaImageViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"mediaImageViewController"];
            [vc setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
            ArchiveImage *image = [[ArchiveImage alloc] initWithUrlPath:aFile.url];
            [vc setImage:image];
            [self presentViewController:vc animated:YES completion:nil];
        } else if (aFile.format == FileFormatDjVuTXT || aFile.format == FileFormatProcessedJP2ZIP || aFile.format == FileFormatTxt) {
            ArchivePageViewController *pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"archivePageViewController"];
            [pageViewController setIdentifier:self.searchDoc.identifier];
            [pageViewController setBookFile:aFile];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenBookViewer" object:pageViewController];
        } else if (aFile.format == FileFormatEPUB) {
            self.externalUrl = [NSURL URLWithString:aFile.url];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Open Web Page To Save EPUB Book" message:@"Do you want to open Safari?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            [alert show];

        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AddToPlayerListFileAndPlayNotification" object:aFile];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenMediaPlayer" object:nil];
        }
    }
}


- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    MediaFileHeaderCell *headerCell = [tableView dequeueReusableCellWithIdentifier:@"mediaFileHeaderCell"];

    if(organizedMediaFiles.count > 0){
        ArchiveFile *firstFile;
        firstFile = [[organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:section]] objectAtIndex:0];
        NSString *format = [firstFile.file objectForKey:@"format"];

        headerCell.sectionHeaderLabel.text = format;
        [headerCell setTypeLabelIconFromFileTypeString:format];

        MediaType type = [MediaUtils mediaTypeFromFileFormat:[MediaUtils formatFromString:format]];
        headerCell.sectionPlayAllButton.hidden = type == MediaTypeNone || type == MediaTypeTexts;
        [headerCell.sectionPlayAllButton setTag:section];
        [headerCell.sectionPlayAllButton addTarget:self action:@selector(playAll:) forControlEvents:UIControlEventTouchUpInside];
    }
    return headerCell;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return organizedMediaFiles.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(organizedMediaFiles.count == 0){
        return 0;
    }

    return [[organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:section]] count];
}


#pragma mark -


- (IBAction)playAll:(id)sender
{
    


    UIButton *button = sender;
    NSArray *files = [organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:button.tag]];
    for(ArchiveFile *aFile in files)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddToPlayerListFileNotification" object:aFile];
    }

    [button.titleLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
    [button setTitle:[NSString stringWithFormat:@"%lu file%@ added to media player", (unsigned long)files.count, files.count > 1 ? @"s" : @""] forState:UIControlStateNormal];

    [self performSelector:@selector(changeTextBackForButton:) withObject:button afterDelay:3.0];

}


- (void)changeTextBackForButton:(UIButton *)button
{
    [button setTitle:@"" forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont fontWithName:ICONOCHIVE size:20]];
    [button setTitle:PLUS forState:UIControlStateNormal];

}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}



- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 0 || buttonIndex == 1) {
        
        NSString *serviceType = buttonIndex == 0 ? SLServiceTypeFacebook : SLServiceTypeTwitter;
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:serviceType];
        
        NSString *archiveUrl = [NSString stringWithFormat:@"http://archive.org/details/%@", self.detDoc.identifier];
        [controller addURL:[NSURL URLWithString:archiveUrl]];
  //      [controller setInitialText:[NSString stringWithFormat:@"Internet Archive - %@", self.detDoc.title]];
        

        [self presentViewController:controller animated:YES completion:nil];
        
    }  else if (buttonIndex == 2) {
        
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
            mailViewController.mailComposeDelegate = self;
            [mailViewController setSubject:self.detDoc.title];
            [mailViewController setMessageBody:[self shareMessage] isHTML:YES];
            [self presentViewController:mailViewController animated:YES completion:nil];
        } else {
            [self displayUnableToSendEmailMessage];
        }
    }
    
}

- (void)displayEmailSentMessage {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Sent"
                                                    message:@"Your message was successfully sent."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:( MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultCancelled:
            //  NSLog(@"Message Canceled");
            break;
        case MFMailComposeResultSaved:
            //  NSLog(@"Message Saved");
            break;
        case MFMailComposeResultSent:
            [self displayEmailSentMessage];
            break;
        case MFMailComposeResultFailed:
            [self displayUnableToSendEmailMessage];
            break;
        default:
            //  NSLog(@"Message Not Sent");
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)displayUnableToSendEmailMessage {
    NSString *errorMessage = @"The device is unable to send email in its current state.";
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Send Email"
                                                    message:errorMessage
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}




- (IBAction)showWeb:(id)sender
{
    self.externalUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://archive.org/details/%@", self.detDoc.identifier]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Open Web Page" message:@"Do you want to view this web page with Safari?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

    if(buttonIndex == 1){
        [[UIApplication sharedApplication] openURL:self.externalUrl];

    }
}
- (NSString *)shareMessage{
    
    return [NSString stringWithFormat:@"From the Internet Archive: %@", [NSString stringWithFormat:@"http://archive.org/details/%@", self.detDoc.identifier]];
}


#pragma mark - web view delegate


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSString *urlString = request.URL.absoluteString;
    if(navigationType == UIWebViewNavigationTypeLinkClicked){
        
        NSString *detailURL;
        
        NSArray *slashes = [urlString componentsSeparatedByString:@"/"];
        
        for(int i=0; i < [slashes count]; i++){
            NSString *slash = [slashes objectAtIndex:i];
            NSRange textRange;
            textRange = [slash rangeOfString:@"details"];
            
            if(textRange.location != NSNotFound) {
                NSString *secondSlash = [slashes objectAtIndex:i+1];
                if([secondSlash rangeOfString:@"#"].length != 0)
                {
                    self.externalUrl = request.URL;
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Open Web Page" message:@"Do you want to view this web page with Safari?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
                    [alert show];
                    return NO;
                }
                
                NSLog(@"  second slash: %@", secondSlash);
                NSString *identifier = [slashes objectAtIndex:i+1];
                ArchiveSearchDoc *doc = [ArchiveSearchDoc new];
                doc.identifier = identifier;

                
                ItemContentViewController *cvc = [self.storyboard instantiateViewControllerWithIdentifier:@"itemViewController"];
                [cvc setSearchDoc:doc];
                [self.navigationController pushViewController:cvc animated:YES];
                
                return NO;
            }
            
        }
        if(detailURL){
            
        } else {
            self.externalUrl = request.URL;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Open Web Page" message:@"Do you want to view this web page with Safari?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            [alert show];
            
        }
        return NO;
    }
    return YES;
}



- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    
    [self.collectionHandlerView.collectionView.collectionViewLayout invalidateLayout];
    
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    if(self.weAreObserving)
    {
        [self.detDoc.archiveImage removeObserver:self forKeyPath:@"downloaded"];
    }
}

@end
