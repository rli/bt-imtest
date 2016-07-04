//
//  OBEXMNSServer.h
//  bt-test
//
//  Created by Richard Li on 11/20/15.
//  Copyright © 2015 Richard Li. All rights reserved.
//

#ifndef OBEXMNSServer_h
#define OBEXMNSServer_h

#import <Foundation/Foundation.h>
#import	<IOBluetooth/Bluetooth.h>
#import	<IOBluetooth/objc/IOBluetoothDevice.h>

#import "OBEXSessionHandler.h"

@protocol OBEXMNSServerDelegate;


@interface OBEXMNSServer : NSObject

@property (nonatomic, assign) id<OBEXMNSServerDelegate> delegate;
@property (nonatomic, readonly, assign) BOOL isPublished;
- (id)initWithMNSDelegate:(id<OBEXMNSDelegate>)mnsDelegate;

- (void)publishService;
- (void)unpublishService;
- (OBEXSessionHandler*)getObexSession;

@end


@protocol OBEXMNSServerDelegate <NSObject>

@optional

- (void)mnsServer:(OBEXMNSServer *)server listeningToDevice:(IOBluetoothDevice *)device;
- (void)mnsServer:(OBEXMNSServer *)server receivedMessage:(NSString *)messageHandle fromDevice:(IOBluetoothDevice *)device;
- (void)mnsServer:(OBEXMNSServer *)server deviceDisconnected:(IOBluetoothDevice *)device;
- (void)mnsServer:(OBEXMNSServer *)server sessionError:(NSError *)error device:(IOBluetoothDevice *)device;
- (void)newRFCOMMChannelOpened: (IOBluetoothRFCOMMChannel *)channel;

@end

#endif /* OBEXMNSServer_h */
