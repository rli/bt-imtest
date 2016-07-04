#import "OBEXMNSServer.h"
#import "OBEXSessionHandler.h"
#import <IOBluetooth/objc/IOBluetoothOBEXSession.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>


@interface OBEXMNSServer() {
    BluetoothRFCOMMChannelID mServerChannelID;
    BluetoothSDPServiceRecordHandle mServerHandle;
    IOBluetoothUserNotification *mIncomingChannelNotification;
    
    OBEXSessionHandler *mObexSession;
    id<OBEXMNSDelegate> mMnsDelegate;
}

@property (nonatomic, retain) IOBluetoothSDPServiceRecord *sdpRecord;
@property (nonatomic, retain) NSMutableDictionary *mnsSessions;
@end


@implementation OBEXMNSServer

- (id)init {
    self = [super init];
    if(self) {
        self.mnsSessions = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)initWithMNSDelegate:(id<OBEXMNSDelegate>)mnsDelegate {
    self = [super init];
    if(self) {
        self.mnsSessions = [NSMutableDictionary dictionary];
    }
    mMnsDelegate = mnsDelegate;
    return self;
}

- (BOOL)isPublished {
    return !!_sdpRecord;
}

- (OBEXSessionHandler*)getObexSession {
    return mObexSession;
}

- (void)publishService
{
    // Build SDP record attributes
    NSDictionary *recordAttributes = @{
                                       @"0001 - ServiceClassIDList": @[
                                               [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassMessageNotificationServer]
                                               ],
                                       @"0004 - ProtocolDescriptorList": @[
                                               @[[IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16L2CAP]],
                                               @[
                                                   [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16RFCOMM],
                                                   @{@"DataElementSize": @1, @"DataElementType": @1, @"DataElementValue": @10}
                                                   ],
                                               @[[IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16OBEX]]
                                               ],
                                       @"0009 - BluetoothProfileDescriptorList": @[
                                               @[
                                                   [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassMessageAccessProfile],
                                                   @(0x100) // v1.0
                                                   ]
                                               ],
                                       @"0100 - ServiceName*": @"CSMNSService"
                                       };
    
    // Publish SDP record
    IOBluetoothSDPServiceRecord *serviceRecord = [IOBluetoothSDPServiceRecord publishedServiceRecordWithDictionary: recordAttributes];
    
    
    
    // Preserve the RFCOMM channel assigned to this service.
    // A header file contains the following declaration:
    // IOBluetoothRFCOMMChannelID mServerChannelID;
    [serviceRecord getRFCOMMChannelID:&mServerChannelID];
    
    // Preserve the service-record handle assigned to this
    // service.
    // A header file contains the following declaration:
    // IOBluetoothSDPServiceRecordHandle mServerHandle;
    [serviceRecord getServiceRecordHandle:&mServerHandle];
    
    // Register for channel-open notifications
    mIncomingChannelNotification = [IOBluetoothRFCOMMChannel
                                    registerForChannelOpenNotifications:self
                                    selector:@selector(newRFCOMMChannelOpened:channel:)
                                    withChannelID:mServerChannelID
                                    direction:kIOBluetoothUserNotificationChannelDirectionIncoming];
}

- (void)unpublishService {
    // Unpublish service
    [mIncomingChannelNotification unregister];
    [mObexSession sendDisconnect];
    IOBluetoothRemoveServiceWithRecordHandle(mServerHandle);
}

- (void)newRFCOMMChannelOpened:(IOBluetoothUserNotification *)notification channel:(IOBluetoothRFCOMMChannel *)channel {
    // Get PublishedService - ignore connect if we can't get it
    BluetoothRFCOMMChannelID serviceValue = mServerChannelID;
    if(!serviceValue) return;
    
    // Create CSBluetoothOBEXSession
    OBEXSessionHandler *session = [OBEXSessionHandler alloc];
    IOBluetoothOBEXSession *s = [IOBluetoothOBEXSession withIncomingRFCOMMChannel:channel
                                                                 eventSelector:@selector(OBEXConnectHandler:)
                                                                selectorTarget:session
                                                                        refCon:nil];

    mObexSession = [session initWithOBEXSession:s];
    [mObexSession setMnsDelegate:mMnsDelegate];
}

//- (void)OBEXSession:(OBEXSessionHandler *)session receivedPut:(NSDictionary *)headers {
//    NSData *endOfBody = headers[(id)kOBEXHeaderIDKeyEndOfBody];
//    if(endOfBody) {
//        NSString *body = [[NSString alloc] initWithData:endOfBody encoding:NSUTF8StringEncoding];
//        NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:body options:0 error:nil];
//        NSArray *newMessageHandles = [doc nodesForXPath:@".//event[@type='NewMessage']/@handle" error:nil];
//        if([newMessageHandles count] > 0) {
//            NSString *handle = [[newMessageHandles objectAtIndex:0] stringValue];
//            if([_delegate respondsToSelector:@selector(mnsServer:receivedMessage:fromDevice:)]) {
//                [_delegate mnsServer:self receivedMessage:handle fromDevice:[session getDevice]];
//            }
//        }
//        
//        [session sendPutSuccessResponse];
//    } else {
//        [session sendPutContinueResponse];
//    }
//}
//
//- (void)OBEXSession:(OBEXSessionHandler *)session receivedDisconnect:(NSDictionary *)headers {
//    IOBluetoothDevice *device = [session getDevice];
//    [_mnsSessions removeObjectForKey:device];
//    if([_delegate respondsToSelector:@selector(mnsServer:deviceDisconnected:)]) {
//        [_delegate mnsServer:self deviceDisconnected:device];
//    }
//}
//
//- (void)OBEXSession:(OBEXSessionHandler *)session receivedError:(NSError *)error {
//    if([_delegate respondsToSelector:@selector(mnsServer:sessionError:device:)]) {
//        [_delegate mnsServer:self sessionError:error device:[session getDevice]];
//    }
//}

- (void)dealloc {
    self.mnsSessions = nil;
    [self unpublishService];
}

@end