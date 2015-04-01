//
//  SessionManager.h
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/4/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//
@import MultipeerConnectivity;

#import <Foundation/Foundation.h>
#import "Profile.h"

@protocol SessionClientProtocol
-(void) processData: (NSData *) data fromPeer:(MCPeerID *)peer;
-(void) updateContactList;
- (void) exchangeProfileWithName:(NSString *)profileName andContactList:(NSArray *)contactList withDestPeerName:(NSString *)destPeerName;
@end

@interface SessionManager : NSObject<MCSessionDelegate,MCNearbyServiceAdvertiserDelegate,MCNearbyServiceBrowserDelegate>
@property (strong,nonatomic) NSMutableArray *displayNames;
@property (strong,nonatomic) MCSession * session;
@property (strong,nonatomic) MCNearbyServiceAdvertiser *nearbyAdvertiser;
@property (strong,nonatomic) MCNearbyServiceBrowser *nearbyBrowser;
@property (strong,nonatomic) id<SessionClientProtocol> client;

- (id)initWithDisplayName:(NSString *)displayName andInvitation:(NSNumber *) acceptInviation;
- (BOOL) hasPeers;
- (void) sendData: (NSData *) data;
- (void) sendMessage :(NSData *)data toDestPeer :(NSString *)destPeerName;
- (void) forwardMessage :(NSData *)data toDestPeer :(NSString *)destPeerName;
- (void) exchangeData:(NSData *)data withDestPeerName:(NSString *)destPeerName;
- (void) alertAdvertiserStatus:(NSNumber *) advertiseStatus;
- (void) connect;

@end
