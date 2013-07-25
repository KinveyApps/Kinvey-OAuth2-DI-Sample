//
//  InstatableViewController.m
//  OAuth2Example
//
//  Created by Michael Katz on 7/23/12.
//
//  Copyright 2013 Kinvey, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "InstatableViewController.h"

#import <KinveyKit/KinveyKit.h>

@interface InstatableViewController ()

@end

@implementation InstatableViewController
@synthesize array;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.array = [NSArray array];
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSMutableDictionary* thisItem = [array objectAtIndex:indexPath.row];
    NSDictionary* captionDict = [thisItem valueForKey:@"caption"];
    if ([captionDict isEqual:[NSNull null]] == NO) {
        //unfortunately this protection is necessary as Instagram can provide empty captions
        NSString* caption = [captionDict valueForKey:@"text"];
        if ([caption isEqual:[NSNull null]] == NO) {
            cell.textLabel.text = caption;        
        }
    }
    NSString* imageUrl = [[[thisItem valueForKey:@"images"] valueForKey:@"thumbnail"] valueForKey:@"url"];

    NSData * d =[NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
    UIImage* thumb = [UIImage imageWithData:d];
    cell.imageView.image = thumb;
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Push the bigger image on selection
    KCSEntityDict* thisItem = [array objectAtIndex:indexPath.row];
    NSString* imageUrl = [[[thisItem valueForKey:@"images"] valueForKey:@"standard_resolution"] valueForKey:@"url"];
    NSData * d =[NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
    UIImage* standardImage = [UIImage imageWithData:d];
    
    UIViewController* vc = [[UIViewController alloc] init];
    UIImageView* im = [[UIImageView alloc] initWithImage:standardImage];
    vc.view = im;

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
