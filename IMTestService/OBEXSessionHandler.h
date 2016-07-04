//
//  OBEXSessionHandler.h
//  bt-test
//
//  Created by Richard Li on 11/17/15.
//  Copyright © 2015 Richard Li. All rights reserved.
//

#ifndef OBEXSessionHandler_h
#define OBEXSessionHandler_h

#import <IOBluetooth/objc/IOBluetoothOBEXSession.h>


@protocol OBEXMASDelegate <NSObject>

@optional

- (void)dataLoaded:(NSString *)messageData;

@end


@protocol OBEXMNSDelegate <NSObject>
@required
- (void)receivedMessage:(NSString *)messageHandle;
@end


@interface OBEXSessionHandler : NSObject {
    IOBluetoothOBEXSession *mObexSession;
    dispatch_queue_t mQueue;
    dispatch_semaphore_t mBT_sema;
    
    dispatch_queue_t process_queue;
    dispatch_queue_t sync_queue;
    
    NSMutableString *mBodyData;
    NSMutableDictionary *mPutData;
    bool gettingData;
    
}
@property CFDataRef mConnectionId;
@property (nonatomic, assign) OBEXMaxPacketLength maxPacketLength;
@property (nonatomic, assign) id<OBEXMNSDelegate> mnsDelegate;
@property (nonatomic, assign) id<OBEXMASDelegate> masDelegate;

- (void)setMnsDelegate:(id<OBEXMNSDelegate>)mnsDelegate;
- (void)setMasDelegate:(id<OBEXMASDelegate>)masDelegate;


- (void)OBEXConnectHandler:(const OBEXSessionEvent*)inSessionEvent;

+ (id)initWithSDPServiceRecord:(IOBluetoothSDPServiceRecord*)inSDPServiceRecord;
- (id)initWithOBEXSession:(IOBluetoothOBEXSession *)obexSession;
- (void)connectToBTDevice;
- (void)setPath:(const NSString *)path;
- (void)listContents;
- (void)listMessages;
- (void)getMessage:(const NSString *)messageHandle withDelegate:(id<OBEXMASDelegate>)delegate;
- (void)getMessage:(const NSString *)messageHandle;
- (void)sendMessage:(const NSString *)message phonenumber:(const NSString *)phonenumber;
- (void)sendNotificationRegistration;
- (void)sendDisconnect;

@end

#endif /* OBEXSessionHandler_h */
