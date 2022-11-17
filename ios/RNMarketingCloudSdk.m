// RNMarketingCloudSdk.m
//
// Copyright (c) 2019 Salesforce, Inc
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer. Redistributions in binary
// form must reproduce the above copyright notice, this list of conditions and
// the following disclaimer in the documentation and/or other materials
// provided with the distribution. Neither the name of the nor the names of
// its contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "RNMarketingCloudSdk.h"
#import <MarketingCloudSDK/MarketingCloudSDK.h>

const int LOG_LENGTH = 800;

@implementation RNMarketingCloudSdk

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

- (void)log:(NSString *)msg {
    if (@available(iOS 10, *)) {
        if (self.logger == nil) {
            self.logger = os_log_create("com.salesforce.marketingcloudsdk", "ReactNative");
        }
        os_log_info(self.logger, "%@", msg);
    } else {
        NSLog(@"%@", msg);
    }
}
- (void)splitLog:(NSString *)msg {
    NSInteger length = msg.length;
    for (int i = 0; i < length; i += LOG_LENGTH) {
        NSInteger rangeLength = MIN(length - i, LOG_LENGTH);
        [self log:[msg substringWithRange:NSMakeRange((NSUInteger)i, (NSUInteger)rangeLength)]];
    }
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(isPushEnabled
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    BOOL status = [[MobilePushSDK sharedInstance] sfmc_pushEnabled];
    resolve(@(status));
}

RCT_EXPORT_METHOD(enablePush) { [[MobilePushSDK sharedInstance] sfmc_setPushEnabled:YES]; }

RCT_EXPORT_METHOD(disablePush) { [[MobilePushSDK sharedInstance] sfmc_setPushEnabled:NO]; }

RCT_EXPORT_METHOD(getSystemToken
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSString *deviceToken = [[MobilePushSDK sharedInstance] sfmc_deviceToken];
    resolve(deviceToken);
}

RCT_EXPORT_METHOD(setSystemToken : (NSString *_Nonnull)systemToken) {
    // convert NSString to NSData based on https://stackoverflow.com/a/41555957/939304
    NSMutableData *systemTokenData = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0', '\0', '\0'};
    int i;
    for (i = 0; i < [systemToken length] / 2; i++) {
        byte_chars[0] = [systemToken characterAtIndex:i * 2];
        byte_chars[1] = [systemToken characterAtIndex:i * 2 + 1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [systemTokenData appendBytes:&whole_byte length:1];
    }

    [[MobilePushSDK sharedInstance] sfmc_setDeviceToken:systemTokenData];
}

RCT_EXPORT_METHOD(getDeviceID
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSString *deviceID = [[MobilePushSDK sharedInstance] sfmc_deviceIdentifier];
    resolve(deviceID);
}

RCT_EXPORT_METHOD(setContactKey : (NSString *_Nonnull)contactKey) {
    [[SFMCSdk identity] setProfileId:contactKey];
}

RCT_EXPORT_METHOD(getContactKey
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSString *contactKey = [[MobilePushSDK sharedInstance] sfmc_contactKey];
    resolve(contactKey);
}

RCT_EXPORT_METHOD(addTag : (NSString *_Nonnull)tag) {
    [[MobilePushSDK sharedInstance] sfmc_addTag:tag];
}

RCT_EXPORT_METHOD(removeTag : (NSString *_Nonnull)tag) {
    [[MobilePushSDK sharedInstance] sfmc_removeTag:tag];
}

RCT_EXPORT_METHOD(getTags
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSSet *tags = [[MobilePushSDK sharedInstance] sfmc_tags];
    NSArray *arr = [tags allObjects];
    resolve(arr);
}

RCT_EXPORT_METHOD(setAttribute : (NSString *_Nonnull)name value : (NSString *_Nonnull)value) {
    [[SFMCSdk identity] setProfileAttributes:@{name : value}];
}

RCT_EXPORT_METHOD(clearAttribute : (NSString *_Nonnull)name) {
    [[MobilePushSDK sharedInstance] sfmc_clearAttributeNamed:name];
}

RCT_EXPORT_METHOD(getAttributes
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSDictionary *attributes = [[MobilePushSDK sharedInstance] sfmc_attributes];
    resolve((attributes != nil) ? attributes : @[]);
}

RCT_EXPORT_METHOD(enableVerboseLogging) {
    [[MobilePushSDK sharedInstance] sfmc_setDebugLoggingEnabled:YES];
}

RCT_EXPORT_METHOD(disableVerboseLogging) {
    [[MobilePushSDK sharedInstance] sfmc_setDebugLoggingEnabled:NO];
}

RCT_EXPORT_METHOD(logSdkState) {
    [self splitLog:[[MobilePushSDK sharedInstance] sfmc_getSDKState]];
}

RCT_EXPORT_METHOD(getSdkState
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSString *state = [[MobilePushSDK sharedInstance] sfmc_getSDKState];
    resolve(state);
}

RCT_EXPORT_METHOD(track
                  : (NSString *_Nonnull)name withAttributes
                  : (NSDictionary *_Nonnull)attributes) {
    [[MobilePushSDK sharedInstance] sfmc_track:[SFMCEvent customEventWithName:name
                                                               withAttributes:attributes]];
}

RCT_EXPORT_METHOD(refresh
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    [[MobilePushSDK sharedInstance]
        sfmc_refreshWithFetchCompletionHandler:^(UIBackgroundFetchResult result) {
          switch (result) {
              case UIBackgroundFetchResultNoData:
                  resolve(@"throttled");
                  break;

              case UIBackgroundFetchResultNewData:
                  resolve(@"updated");
                  break;

              case UIBackgroundFetchResultFailed:
                  resolve(@"failed");
                  break;

              default:
                  resolve(@"unknown");
          }
        }];
}

@end
