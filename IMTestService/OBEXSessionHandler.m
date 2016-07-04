//
//  OBEXSessionHandler.m
//  bt-test
//
//  Created by Richard Li on 11/17/15.
//  Copyright © 2015 Richard Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import	<IOBluetooth/Bluetooth.h>
#import <IOBluetooth/objc/IOBluetoothOBEXSession.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>

#import "OBEXSessionHandler.h"

@implementation OBEXSessionHandler : NSObject

+ (id)initWithSDPServiceRecord:(IOBluetoothSDPServiceRecord*)inSDPServiceRecord {
    return [[OBEXSessionHandler alloc] initWithOBEXSession:[[IOBluetoothOBEXSession alloc] initWithSDPServiceRecord:inSDPServiceRecord]];
}

- (id)initWithOBEXSession:(IOBluetoothOBEXSession *)obexSession {
    self = [super init];
    
    mQueue = dispatch_queue_create("piratobot.bt.btqueue", NULL);
    mBT_sema = dispatch_semaphore_create(0);
    mObexSession = obexSession;
    
    process_queue = dispatch_queue_create("com.example.queue", DISPATCH_QUEUE_CONCURRENT);
    sync_queue = dispatch_queue_create("sync_queue", NULL);
    _mnsDelegate = nil;
    _masDelegate = nil;
    
    return self;
}

- (void)setMnsDelegate:(id<OBEXMNSDelegate>)mnsDelegate {
    NSLog(@"setting mns delegate to %@", mnsDelegate);
    _mnsDelegate = mnsDelegate;
}

- (void)setMasDelegate:(id<OBEXMASDelegate>)masDelegate {
    NSLog(@"setting mas delegate to %@", masDelegate);
    _masDelegate = masDelegate;
}

#define MAS_TARGET_HEADER_UUID "\xBB\x58\x2B\x40\x42\x0C\x11\xDB\xB0\xDE\x08\x00\x20\x0C\x9A\x66"
- (void)connectToBTDevice {
    NSLog(@"connectToBTDevice");
    //dispatch_async(process_queue, ^{
    CFMutableDictionaryRef headers = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
    OBEXAddTargetHeader(MAS_TARGET_HEADER_UUID, 16, headers);
    
    CFMutableDataRef headerBytes = OBEXHeadersToBytes(headers);
    const uint8_t* headerDataPtr = CFDataGetBytePtr(headerBytes);
    NSLog(@"%ld", CFDataGetLength(headerBytes));
    NSLog(@"bytes in hex: %@", headerBytes);
    
    OBEXError status = [mObexSession OBEXConnect:kOBEXOpCodeConnect
                                 maxPacketLength:65534
                                 optionalHeaders:headerDataPtr
                           optionalHeadersLength:CFDataGetLength(headerBytes)
                                   eventSelector:@selector(OBEXConnectHandler:)
                                  selectorTarget:self
                                          refCon:NULL];
    NSLog(@"connect success %d", status);
    //NSLog(@"releasing semaphore");
    //dispatch_semaphore_signal(mBT_sema);
    //});
}

- (void)setPath:(const NSString *)path {
    NSLog(@"setPath %@", path);
    
    dispatch_async(sync_queue, ^{
        dispatch_semaphore_wait(mBT_sema, DISPATCH_TIME_FOREVER);
        NSLog(@"took semaphore in setapath");
        CFMutableDictionaryRef headers3 = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
        
        OBEXAddNameHeader((__bridge CFStringRef)(path), headers3);
        CFMutableDataRef header3Bytes = OBEXHeadersToBytes(headers3);
        const uint8_t* header3DataPtr = CFDataGetBytePtr(header3Bytes);
        OBEXError getstatus2 = [mObexSession OBEXSetPath:kOBEXPutFlagNone
                                               constants:nil
                                         optionalHeaders:(header3Bytes ? (void *)header3DataPtr : NULL)
                                   optionalHeadersLength:(header3Bytes ? CFDataGetLength(header3Bytes) : 0)
                                           eventSelector:@selector(OBEXConnectHandler:)
                                          selectorTarget:self
                                                  refCon:nil];
        NSLog(@"setpath success %d", getstatus2);
        
    });
    
}

- (void)listContents {
    NSLog(@"listcontents");
    
    dispatch_async(sync_queue, ^{
        dispatch_semaphore_wait(mBT_sema, DISPATCH_TIME_FOREVER);
        NSLog(@"took semaphore in listcontents");
        
        CFMutableDictionaryRef headers2 = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
        // bb582b40-420c-11db-b0de-0800200c9a66
        //OBEXAddTargetHeader("bb582b40420c11dbb0de0800200c9a66", strlen("bb582b40420c11dbb0de0800200c9a66"), headers2);
        OBEXAddTypeHeader(CFSTR("x-obex/folder-listing"), headers2);
        OBEXAddConnectionIDHeader(self.mConnectionId, CFDataGetLength(self.mConnectionId), headers2);
        CFMutableDataRef header2Bytes = OBEXHeadersToBytes(headers2);
        const uint8_t* header2DataPtr = CFDataGetBytePtr(header2Bytes);
        mBodyData = [[NSMutableString alloc] initWithCapacity:1024];
        NSLog(@"open session? %hhd", [mObexSession hasOpenOBEXConnection]);
        OBEXError getstatus = [mObexSession OBEXGet:YES
                                            headers:(header2Bytes ? (void *)header2DataPtr : NULL)
                                      headersLength:(header2Bytes ? CFDataGetLength(header2Bytes) : 0)
                                      eventSelector:@selector(OBEXConnectHandler:)
                                     selectorTarget:self
                                             refCon:NULL];
        NSLog(@"get success %d", getstatus);
    });
    
}

- (void)listMessages {
    NSLog(@"listmessages");
    
    dispatch_async(sync_queue, ^{
        dispatch_semaphore_wait(mBT_sema, DISPATCH_TIME_FOREVER);
        NSLog(@"took semaphore in listmessages");
        
        CFMutableDictionaryRef headers2 = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
        // bb582b40-420c-11db-b0de-0800200c9a66
        //OBEXAddTargetHeader("bb582b40420c11dbb0de0800200c9a66", strlen("bb582b40420c11dbb0de0800200c9a66"), headers2);
        OBEXAddTypeHeader(CFSTR("x-bt/MAP-msg-listing"), headers2);
        OBEXAddConnectionIDHeader(self.mConnectionId, CFDataGetLength(self.mConnectionId), headers2);
        CFMutableDataRef header2Bytes = OBEXHeadersToBytes(headers2);
        const uint8_t* header2DataPtr = CFDataGetBytePtr(header2Bytes);
        mBodyData = [[NSMutableString alloc] initWithCapacity:1024];
        OBEXError getstatus = [mObexSession OBEXGet:YES
                                            headers:(header2Bytes ? (void *)header2DataPtr : NULL)
                                      headersLength:(header2Bytes ? CFDataGetLength(header2Bytes) : 0)
                                      eventSelector:@selector(OBEXConnectHandler:)
                                     selectorTarget:self
                                             refCon:NULL];
        NSLog(@"get success %d", getstatus);
    });
}

- (void)getMessage:(const NSString *)messageHandle withDelegate:(id<OBEXMASDelegate>)delegate {
    NSLog(@"getMessage");
    
    dispatch_async(sync_queue, ^{
        dispatch_semaphore_wait(mBT_sema, DISPATCH_TIME_FOREVER);
        NSLog(@"took semaphore in getMessage");
        
        CFMutableDictionaryRef headers2 = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
        // bb582b40-420c-11db-b0de-0800200c9a66
        //OBEXAddTargetHeader("bb582b40420c11dbb0de0800200c9a66", strlen("bb582b40420c11dbb0de0800200c9a66"), headers2);
        OBEXAddTypeHeader(CFSTR("x-bt/message"), headers2);
        OBEXAddNameHeader((__bridge CFStringRef)(messageHandle), headers2);
        OBEXAddApplicationParameterHeader("\x0A\x01\x01\x14\x01\x01", 6, headers2);
        OBEXAddConnectionIDHeader(self.mConnectionId, CFDataGetLength(self.mConnectionId), headers2);
        CFMutableDataRef header2Bytes = OBEXHeadersToBytes(headers2);
        const uint8_t* header2DataPtr = CFDataGetBytePtr(header2Bytes);
        mBodyData = [[NSMutableString alloc] initWithCapacity:1024];
        OBEXError getstatus = [mObexSession OBEXGet:YES
                                            headers:(header2Bytes ? (void *)header2DataPtr : NULL)
                                      headersLength:(header2Bytes ? CFDataGetLength(header2Bytes) : 0)
                                      eventSelector:@selector(OBEXConnectHandler:)
                                     selectorTarget:self
                                             refCon:(__bridge void *)(delegate)];
        NSLog(@"get success %d", getstatus);
    });
}

- (void)getMessage:(const NSString *)messageHandle {
    [self getMessage:messageHandle withDelegate:nil];
}

- (void)sendMessage:(const NSString *)message phonenumber:(const NSString *)phonenumber {
    NSLog(@"sendmessage");
    
    dispatch_async(sync_queue, ^{
        dispatch_semaphore_wait(mBT_sema, DISPATCH_TIME_FOREVER);
        NSLog(@"took semaphore in sendmessage");
        
        CFMutableDictionaryRef headers2 = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
        // bb582b40-420c-11db-b0de-0800200c9a66
        //OBEXAddTargetHeader("bb582b40420c11dbb0de0800200c9a66", strlen("bb582b40420c11dbb0de0800200c9a66"), headers2);
        OBEXAddTypeHeader(CFSTR("x-bt/message"), headers2);
        OBEXAddNameHeader((__bridge CFStringRef)(@"outbox"), headers2);
        OBEXAddApplicationParameterHeader("\x0b\x01\x00\x14\x01\x01", 6, headers2);
        OBEXAddConnectionIDHeader(self.mConnectionId, CFDataGetLength(self.mConnectionId), headers2);
        NSLog(@"connect id is %@", self.mConnectionId);
        
        NSString* formattedMsg = [NSString stringWithFormat:@"BEGIN:BMSG\r\n"
                                  "VERSION:1.0\r\n"
                                  "STATUS:UNREAD\r\n"
                                  "TYPE:SMS_GSM\r\n"
                                  "FOLDER:telecom/msg/outbox\r\n"
                                  "BEGIN:BENV\r\n"
                                  "BEGIN:VCARD\r\n"
                                  "VERSION:3.0\r\n"
                                  "FN:Placeholder\r\n"
                                  "N:Placeholder\r\n"
                                  "TEL:+%@\r\n"
                                  "END:VCARD\r\n"
                                  "BEGIN:BBODY\r\n"
                                  "CHARSET:UTF-8\r\n"
                                  "LENGTH:%lu\r\n"
                                  "BEGIN:MSG\r\n"
                                  "%@\r\n"
                                  "END:MSG\r\n"
                                  "END:BBODY\r\n"
                                  "END:BENV\r\n"
                                  "END:BMSG\r\n", phonenumber, 22+[message length], message];
        NSLog(@"message: %@", formattedMsg);
        
        CFDataRef messageData = (__bridge CFDataRef)([formattedMsg dataUsingEncoding:NSUTF8StringEncoding]);
        //OBEXAddBodyHeader(messageData, CFDataGetLength(messageData), YES, headers2);
        CFMutableDataRef header2Bytes = OBEXHeadersToBytes(headers2);
        const uint8_t* header2DataPtr = CFDataGetBytePtr(header2Bytes);
        const uint8_t* messageDataPtr = CFDataGetBytePtr(messageData);
        NSLog(@"open session? %hhd", [mObexSession hasOpenOBEXConnection]);
        OBEXError getstatus = [mObexSession OBEXPut:YES
                                        headersData:(header2Bytes ? (void *)header2DataPtr : NULL)
                                  headersDataLength:CFDataGetLength(header2Bytes)
                                           bodyData:messageDataPtr
                                     bodyDataLength:CFDataGetLength(messageData)
                                      eventSelector:@selector(OBEXConnectHandler:)
                                     selectorTarget:self
                                             refCon:NULL];
        NSLog(@"send success %d", getstatus);
    });
}

- (void)sendNotificationRegistration {
    dispatch_async(sync_queue, ^{
        dispatch_semaphore_wait(mBT_sema, DISPATCH_TIME_FOREVER);
        NSLog(@"took semaphore in sendNotificationRegistration");
        CFMutableDictionaryRef headers2 = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
        OBEXAddTypeHeader(CFSTR("x-bt/MAP-NotificationRegistration"), headers2);
        OBEXAddApplicationParameterHeader("\x0e\x01\x01", 3, headers2);
        char body[] = {0x30};
        CFMutableDataRef header2Bytes = OBEXHeadersToBytes(headers2);
        const uint8_t* header2DataPtr = CFDataGetBytePtr(header2Bytes);
        OBEXError getstatus = [mObexSession OBEXPut:YES
                                        headersData:(header2Bytes ? (void *)header2DataPtr : NULL)
                                  headersDataLength:CFDataGetLength(header2Bytes)
                                           bodyData:body
                                     bodyDataLength:1
                                      eventSelector:@selector(OBEXConnectHandler:)
                                     selectorTarget:self
                                             refCon:NULL];
        NSLog(@"registration success %d", getstatus);
    });
}

- (void)sendDisconnect {
    OBEXError status;
    status = [mObexSession OBEXDisconnect:NULL
                    optionalHeadersLength:NULL
                            eventSelector:@selector(OBEXConnectHandler:)
                           selectorTarget:self
                                   refCon:NULL];
    NSLog(@"disconnect: %d", status);
    status = [mObexSession closeTransportConnection];
    NSLog(@"disconnect: %d", status);
    
}
#define MNS_TARGET_HEADER_UUID "\xBB\x58\x2B\x41\x42\x0C\x11\xDB\xB0\xDE\x08\x00\x20\x0C\x9A\x66"
#define CONNECTION_ID "\xDE\xAD\xBE\xEF"

- (void)OBEXConnectHandler:(const OBEXSessionEvent*)inSessionEvent {
    NSLog(@"connecthandler...");
    CFDictionaryRef headers;
    switch (inSessionEvent->type)
    {
            // Server cases
        case (kOBEXSessionEventTypeConnectCommandReceived): {
            NSLog(@"kOBEXSessionEventTypeConnectCommandReceived");
            headers = OBEXGetHeaders(inSessionEvent->u.connectCommandData.headerDataPtr, inSessionEvent->u.connectCommandData.headerDataLength);
            CFMutableDictionaryRef headers2 = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
            OBEXAddConnectionIDHeader(CONNECTION_ID, 4, headers2);
            OBEXAddWhoHeader(MNS_TARGET_HEADER_UUID, 16, headers2);
            
            OBEXError status = [mObexSession OBEXConnectResponse:kOBEXResponseCodeSuccessWithFinalBit
                                                           flags:0
                                                 maxPacketLength:inSessionEvent->u.connectCommandData.maxPacketSize
                                                 optionalHeaders:NULL
                                           optionalHeadersLength:NULL
                                                   eventSelector:@selector(OBEXConnectHandler:)
                                                  selectorTarget:self
                                                          refCon:nil];
            NSLog(@"send...OBEXConnectResponse: %d", status);
            break;
        }
            
        case (kOBEXSessionEventTypePutCommandReceived): {
            NSLog(@"kOBEXSessionEventTypePutCommandReceived");
            headers = OBEXGetHeaders(inSessionEvent->u.putCommandData.headerDataPtr, inSessionEvent->u.putCommandData.headerDataLength);
            if(!mPutData) mPutData = [NSMutableDictionary new];
            [self accumulateHeaders:(__bridge NSDictionary *)(headers) in:mPutData];
            NSData *endOfBody = (__bridge NSData*)CFDictionaryGetValue(headers, kOBEXHeaderIDKeyEndOfBody);
            if(endOfBody) {
                NSString *body = [[NSString alloc] initWithData:mPutData[(__bridge NSString*)(kOBEXHeaderIDKeyEndOfBody)] encoding:NSUTF8StringEncoding];
                NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:body options:0 error:nil];
                NSArray *newMessageHandles = [doc nodesForXPath:@".//event[@type='NewMessage' and @folder='telecom/msg/INBOX']/@handle" error:nil];
                if([newMessageHandles count] > 0) {
                    NSString *handle = [[newMessageHandles objectAtIndex:0] stringValue];
                    NSLog(@"mns delegate is %@", _mnsDelegate);
                    if (_mnsDelegate != nil) {
                        [_mnsDelegate receivedMessage:handle];
                    }
                    NSLog(@"received message: '%@'", handle);
                    NSLog(@"full body: '%@'", body);

                }
                //[session sendPutSuccessResponse];
                mPutData = nil;
                [mObexSession OBEXPutResponse:kOBEXResponseCodeSuccessWithFinalBit
                              optionalHeaders:nil
                        optionalHeadersLength:0
                                eventSelector:@selector(OBEXConnectHandler:)
                               selectorTarget:self
                                       refCon:nil];
                
            } else {
                //[session sendPutContinueResponse];
                [mObexSession OBEXPutResponse:kOBEXResponseCodeContinueWithFinalBit
                              optionalHeaders:nil
                        optionalHeadersLength:0
                                eventSelector:@selector(OBEXConnectHandler:)
                               selectorTarget:self
                                       refCon:nil];
                
            }
            break;
        }
            
            
            // Client cases
        case (kOBEXSessionEventTypeConnectCommandResponseReceived):
            NSLog(@"kOBEXSessionEventTypeConnectCommandResponseReceived");
            NSLog(@"opreponse: %hhu", inSessionEvent->u.connectCommandResponseData.serverResponseOpCode);
            NSLog(@"max packet size: %hu", inSessionEvent->u.connectCommandResponseData.maxPacketSize);
            NSLog(@"CONNECT response: <<<<<<");
            headers = OBEXGetHeaders(inSessionEvent->u.connectCommandResponseData.headerDataPtr, inSessionEvent->u.connectCommandResponseData.headerDataLength);
            NSLog(@"%@", headers);
            CFDataRef connectId = CFDictionaryGetValue(headers, kOBEXHeaderIDKeyConnectionID);
            CFShow(connectId);
            self.mConnectionId = connectId;
            self.maxPacketLength = inSessionEvent->u.connectCommandResponseData.maxPacketSize;
            NSLog(@"session connect id is %@", connectId);
            NSLog(@"releasing semaphore2");
            dispatch_semaphore_signal(mBT_sema);
            
            break;
            
        case (kOBEXSessionEventTypeDisconnectCommandResponseReceived):
            NSLog(@"kOBEXSessionEventTypeDisconnectCommandResponseReceived");
            break;
            
        case (kOBEXSessionEventTypeGetCommandResponseReceived):
            NSLog(@"kOBEXSessionEventTypeGetCommandResponseReceived");
            
            NSLog(@"opreponse: %hhu", inSessionEvent->u.getCommandResponseData.serverResponseOpCode);
            NSLog(@"GET response: <<<<<<");
            headers = OBEXGetHeaders(inSessionEvent->u.getCommandResponseData.headerDataPtr, inSessionEvent->u.getCommandResponseData.headerDataLength);
            NSLog(@"%@", headers);
            
            if(headers) {
                CFDataRef bodyDataRef = NULL;
                CFDataRef endOfBodyDataRef = NULL;
                if (CFDictionaryGetCountOfKey(headers, kOBEXHeaderIDKeyBody) > 0) {
                    bodyDataRef = (CFDataRef)(CFDictionaryGetValue(headers, kOBEXHeaderIDKeyBody));
                    if (bodyDataRef) {
                        //CFShow(bodyDataRef);
                        [mBodyData appendString:[[NSString alloc] initWithData:(__bridge_transfer NSData * _Nonnull)(bodyDataRef) encoding:NSUTF8StringEncoding]];
                    }
                }
                
                // get end-of-body-data
                if (CFDictionaryGetCountOfKey(headers, kOBEXHeaderIDKeyEndOfBody) > 0) {
                    endOfBodyDataRef = (CFDataRef)(CFDictionaryGetValue(headers, kOBEXHeaderIDKeyEndOfBody));
                    if (endOfBodyDataRef) {
                        //CFShow(endOfBodyDataRef);
                        [mBodyData appendString:[[NSString alloc] initWithData:(__bridge_transfer NSData * _Nonnull)(endOfBodyDataRef) encoding:NSUTF8StringEncoding]];
                    }
                }
            }
            
            switch (inSessionEvent->u.getCommandResponseData.serverResponseOpCode) {
                case kOBEXResponseCodeContinueWithFinalBit:
                    NSLog(@"[handleGetResponse] kOBEXResponseCodeContinueWithFinalBit");
                    
                    // previous GET was successful, and we need to do another GET
                    // request to get more data.
                    OBEXError status = [mObexSession OBEXGet:TRUE
                                                     headers:NULL
                                               headersLength:0
                                               eventSelector:@selector(OBEXConnectHandler:)
                                              selectorTarget:self
                                                      refCon:NULL];
                    
                    if (status == kOBEXSuccess) {
                        NSLog(@"[handleGetResponse] Sent next OBEXGet request");
                        
                    } else {
                        // quit out of the GET now
                        NSLog(@"Sending of next OBEXGet failed. Error = 0x%x", status);
                    }
                    break;
                    
                case kOBEXResponseCodeSuccessWithFinalBit:
                    NSLog(@"[handleGetResponse] kOBEXResponseCodeSuccessWithFinalBit");
                    NSLog(@"releasing semaphore3");
                    NSLog(@"\n%@", mBodyData);
                    if(_masDelegate != nil) {
                        NSLog(@"things happened???");
                        [_masDelegate dataLoaded:mBodyData];
                    }
                    dispatch_semaphore_signal(mBT_sema);
                    break;
                    
                default:
                {
                    NSLog(@"GET failed, server responded 0x%02x", inSessionEvent->u.getCommandResponseData.serverResponseOpCode);
                    break;
                }
            }
            break;
            
        case (kOBEXSessionEventTypePutCommandResponseReceived):
            NSLog(@"kOBEXSessionEventTypePutCommandResponseReceived");
            NSLog(@"opreponse: %hhu", inSessionEvent->u.putCommandResponseData.serverResponseOpCode);
            NSLog(@"PUT response: <<<<<<");
            headers = OBEXGetHeaders(inSessionEvent->u.putCommandResponseData.headerDataPtr, inSessionEvent->u.putCommandResponseData.headerDataLength);
            NSLog(@"%@", headers);
            NSLog(@"releasing semaphore");
            dispatch_semaphore_signal(mBT_sema);
            break;
            
        case (kOBEXSessionEventTypeAbortCommandResponseReceived):
            NSLog(@"kOBEXSessionEventTypeAbortCommandResponseReceived");
            break;
            
        case (kOBEXSessionEventTypeSetPathCommandResponseReceived):
            NSLog(@"kOBEXSessionEventTypeSetPathCommandResponseReceived");
            dispatch_semaphore_signal(mBT_sema);
            break;
        default:
            NSLog(@"somethingelse");
            break;
    }
    //NSLog(@"releasing semaphore");
    //dispatch_semaphore_signal(mBT_sema);
    
}

- (void)accumulateHeaders:(NSDictionary *)headers in:(NSMutableDictionary *)accumulator {
    NSString *bodyKey = (__bridge NSString *)kOBEXHeaderIDKeyBody;
    NSString *endOfBodyKey = (__bridge NSString *)kOBEXHeaderIDKeyEndOfBody;
    
    for(NSString *k in headers) {
        if([k isEqualToString:bodyKey]) {
            NSMutableData *body = accumulator[k];
            if(!body) accumulator[k] = [NSMutableData dataWithData:headers[k]];
            else [body appendData:headers[k]];
        } else if([k isEqualToString:endOfBodyKey]) {
            NSMutableData *body = accumulator[bodyKey];
            if(body) {
                [body appendData:headers[k]];
                accumulator[k] = body;
                [accumulator removeObjectForKey:bodyKey];
            } else {
                accumulator[k] = headers[k];
            }
        } else {
            accumulator[k] = headers[k];
        }
    }
}

@end
