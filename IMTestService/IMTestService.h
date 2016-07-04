//
//  IMTestService.h
//  IMTestService
//
//  Created by Taras Kalapun on 10.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <IMServicePlugIn/IMServicePlugIn.h>
#import <IMServicePlugIn/IMServicePlugInFileTransferSessionSupport.h>
#import <IMServicePlugIn/IMServicePlugInChatRoomSupport.h>

#import "OBEXSessionHandler.h"
#import "OBEXMNSServer.h"


@interface IMTestService : NSObject <IMServicePlugIn, IMServicePlugInGroupListSupport, IMServicePlugInGroupListEditingSupport, IMServicePlugInGroupListAuthorizationSupport, IMServicePlugInInstantMessagingSupport, IMServicePlugInPresenceSupport, IMServicePlugInFileTransferSessionSupport,IMServicePlugInChatRoomSupport, OBEXMNSDelegate, OBEXMASDelegate>


@property (assign) id <IMServiceApplicationGroupListAuthorizationSupport, IMServiceApplicationInstantMessagingSupport, IMServiceApplicationFileTransferSessionSupport, IMServiceApplicationChatRoomSupport> application;
@property (retain) NSDictionary* accountSettings;
@property (retain) OBEXSessionHandler* obexHandler;
@property (retain) OBEXMNSServer* mObexMNSServer;


@end
