//
//  TKMessageManager.m
//  WeChatPlugin
//
//  Created by TK on 2018/4/23.
//  Copyright © 2018年 tk. All rights reserved.
//

#import "TKMessageManager.h"
#import "WeChatTweak.h"

#define WXLocalizedString(key)  [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

@implementation TKMessageManager

+ (instancetype)shareManager {
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)sendTextMessageToSelf:(id)msgContent {
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    [self sendTextMessage:msgContent toUsrName:currentUserName delay:0];
}

- (void)sendTextMessage:(id)msgContent toUsrName:(id)toUser delay:(NSInteger)delayTime {
    FFProcessReqsvrZZ *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("FFProcessReqsvrZZ")];
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    
    if (delayTime == 0) {
        [service FFProcessTReqZZ:currentUserName toUsrName:toUser msgText:msgContent atUserList:nil];
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [service FFProcessTReqZZ:currentUserName toUsrName:toUser msgText:msgContent atUserList:nil];
        });
    });
}

- (void)clearUnRead:(id)arg1 {
    FFProcessReqsvrZZ *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("FFProcessReqsvrZZ")];
    if ([service respondsToSelector:@selector(ClearUnRead:FromCreateTime:ToCreateTime:)]) {
        [service ClearUnRead:arg1 FromCreateTime:0 ToCreateTime:0];
    } else if ([service respondsToSelector:@selector(ClearUnRead:FromID:ToID:)]) {
        [service ClearUnRead:arg1 FromID:0 ToID:0];
    }
}

- (NSString *)getMessageContentWithData:(MessageData *)msgData {
    if (!msgData) return @"";
    
    NSString *msgContent = [msgData summaryString:NO] ?: @"";
    if (msgData.m_nsTitle && (msgData.isAppBrandMsg || [msgContent isEqualToString:WXLocalizedString(@"Message_type_unsupport")])){
        NSString *content = msgData.m_nsTitle ?:@"";
        if (msgContent) {
            if (msgData.m_nsSourceDisplayname.length > 0) {
                msgContent = [msgContent stringByAppendingFormat:@"%@：", msgData.m_nsSourceDisplayname];
            } else if (msgData.m_nsAppName.length > 0) {
                msgContent = [msgContent stringByAppendingFormat:@"%@：", msgData.m_nsAppName];
            }
            msgContent = [msgContent stringByAppendingString:content];
        }
    }
    
    if ([msgData respondsToSelector:@selector(isChatRoomMessage)] && msgData.isChatRoomMessage && msgData.groupChatSenderDisplayName) {
         if (msgData.groupChatSenderDisplayName.length > 0 && msgContent) {
            msgContent = [NSString stringWithFormat:@"%@：%@",msgData.groupChatSenderDisplayName, msgContent];
        }
    }
    
    return msgContent;
}

- (NSArray <MessageData *> *)getMsgListWithChatName:(id)arg1 minMesLocalId:(unsigned int)arg2 limitCnt:(NSInteger)arg3 {
    FFProcessReqsvrZZ *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("FFProcessReqsvrZZ")];
    char hasMore = '1';
    NSArray *array = @[];
    if ([service respondsToSelector:@selector(GetMsgListWithChatName:fromCreateTime:localId:limitCnt:hasMore:sortAscend:)]) {
        array = [service GetMsgListWithChatName:arg1 fromCreateTime:arg2 localId:arg2 limitCnt:arg3 hasMore:&hasMore sortAscend:YES];
    }

    return [[array reverseObjectEnumerator] allObjects];
}


@end
