//
//  ViewController.m
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

#import "ViewController.h"

#import <KinveyKit/KinveyKit.h>

#import "GTMOAuth2ViewControllerTouch.h"
#import "InstatableViewController.h"

#define kKeychainItemName @"KinveyOAuth2Example: Instagram"
#define kInstagramID @"<# Instagram App Id #>" //this is set by Instagram when registering an app with the API
#define kInstagramSecret @"<# Instagram App Secret #>" //this is set by Instagram when registering an app with the API
#define kInstagramCallbackURI @"<#OAuth2 Callback URI specified in App Setup#>"

@interface ViewController () {
    CLLocationManager* _locationManager;
}

@property (nonatomic, retain) NSMutableDictionary* objectNearestMe;

@end

@implementation ViewController
@synthesize objectNearestMe;

- (void)viewDidLoad
{
    [super viewDidLoad];
    //set up the location manager to get the current location
    _locationManager = [[CLLocationManager alloc] init];
    
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingLocation];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (IBAction)getPictures:(id)sender 
{
    [self signInToInstagram];
}

#pragma mark - OAuth stuff
- (void) signOut
{
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
}

- (GTMOAuth2Authentication *) authForInstagram
{
    //This URL is defined by the individual 3rd party APIs, be sure to read their documentation
    NSURL *tokenURL = [NSURL URLWithString:@"https://api.instagram.com/oauth/access_token"];
        
    GTMOAuth2Authentication *auth;
    auth = [GTMOAuth2Authentication authenticationWithServiceProvider:@"Instagram"
                                                             tokenURL:tokenURL
                                                          redirectURI:kInstagramCallbackURI
                                                             clientID:kInstagramID
                                                         clientSecret:kInstagramSecret];
    auth.scope = @"basic";
    return auth;
}

- (void)signInToInstagram
{
    [self signOut];
    
    GTMOAuth2Authentication *auth = [self authForInstagram];    
    if (auth.canAuthorize) {
        //bypass the login
        [self getLocationInfo:[auth accessToken]];
        return;
    }
    
    NSURL *authURL = [NSURL URLWithString:@"https://api.instagram.com/oauth/authorize"];
    
    // Display the authentication view
    GTMOAuth2ViewControllerTouch *viewController;
    viewController = [[GTMOAuth2ViewControllerTouch alloc] initWithAuthentication:auth
                                                                 authorizationURL:authURL
                                                                 keychainItemName:kKeychainItemName
                                                                         delegate:self
                                                                 finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    [self.navigationController pushViewController:viewController animated:YES];
}


- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error
{
   [self.navigationController popToViewController:self animated:NO];
    
    if (error != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error Authorizing with Instagram"
                                                        message:[error localizedDescription] 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        //Authorization was successful - get location information
        [self getLocationInfo:[auth accessToken]];
    }
}

- (void) getLocationInfo:(NSString*)accessToken
{
    KCSCollection* c = [KCSCollection collectionFromString:@"instagram-locations" ofClass:[NSMutableDictionary class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:c options:nil];
    
    CLLocation* loc = [_locationManager location];
    NSNumber* lat = [NSNumber numberWithDouble:loc.coordinate.latitude];
    NSNumber* lon = [NSNumber numberWithDouble:loc.coordinate.longitude];
    
    
    KCSQuery *q = [KCSQuery queryOnField:@"lat" withExactMatchForValue:[lat description]];
    [q addQueryOnField:@"long" withExactMatchForValue:[lon description]];
    [q addQueryOnField:@"oauth_token" withExactMatchForValue:accessToken];
    [store queryWithQuery:q withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (!errorOrNil && objectsOrNil.count > 0) {
            self.objectNearestMe = [objectsOrNil objectAtIndex:0];
            [self loadPictures:accessToken];
        } else {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error retreiving location"
                                                            message:[errorOrNil localizedDescription] 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    } withProgressBlock:nil];
}

- (void) loadPictures:(NSString*)accessToken
{
    KCSCollection* c = [KCSCollection collectionFromString:@"instagram-imagesAtLoc" ofClass:[NSMutableDictionary class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:c options:nil];
    KCSQuery *q = [KCSQuery queryOnField:@"location_id" withExactMatchForValue:[self.objectNearestMe valueForKey:@"id"]];
    [q addQueryOnField:@"oauth_token" withExactMatchForValue:accessToken];
    
    [store queryWithQuery:q withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error retreiving pictures"
                                                            message:[errorOrNil localizedDescription] 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                double delayInSeconds = 2.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    InstatableViewController* tvc = [[InstatableViewController alloc] initWithStyle:UITableViewStylePlain];
                    tvc.array = objectsOrNil;
                    [self.navigationController pushViewController:tvc animated:YES];
                });
            });
        }
    } withProgressBlock:nil];
    
}

#pragma mark - Core Location
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    [manager stopUpdatingLocation];
}

@end
