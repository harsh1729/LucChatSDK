/*
 
 Copyright 2018 Lintel 

 

 
 */

#import "RoomPreviewData.h"

@implementation RoomPreviewData

- (instancetype)initWithRoomId:(NSString *)roomId andSession:(MXSession *)mxSession
{
    self = [super init];
    if (self)
    {
        _roomId = roomId;
        _mxSession = mxSession;
        _numJoinedMembers = -1;
    }
    return self;
}

- (instancetype)initWithRoomId:(NSString *)roomId emailInvitationParams:(NSDictionary *)emailInvitationParams andSession:(MXSession *)mxSession
{
    self = [self initWithRoomId:roomId andSession:mxSession];
    if (self)
    {
        _emailInvitation = [[RoomEmailInvitation alloc] initWithParams:emailInvitationParams];

        // Report decoded data
        _roomName = _emailInvitation.roomName;
        _roomAvatarUrl = _emailInvitation.roomAvatarUrl;
    }
    return self;
}

- (instancetype)initWithPublicRoom:(MXPublicRoom*)publicRoom andSession:(MXSession*)mxSession
{
    self = [self initWithRoomId:publicRoom.roomId andSession:mxSession];
    if (self)
    {
        // Report public room data
        _roomName = publicRoom.name;
        _roomAvatarUrl = publicRoom.avatarUrl;
        _roomTopic = publicRoom.topic;
        _roomAliases = publicRoom.aliases;
        _numJoinedMembers = publicRoom.numJoinedMembers;
        
        if (!_roomName.length)
        {
            // Consider the room aliases to define a default room name.
            _roomName = _roomAliases.firstObject;
        }
    }
    return self;
}

- (void)dealloc
{
    if (_roomDataSource)
    {
        [_roomDataSource destroy];
        _roomDataSource = nil;
    }
    
    _emailInvitation = nil;
}

- (void)peekInRoom:(void (^)(BOOL succeeded))completion
{
    MXWeakify(self);
    [_mxSession peekInRoomWithRoomId:_roomId success:^(MXPeekingRoom *peekingRoom) {
        MXStrongifyAndReturnIfNil(self);

        // Create the room data source
        MXWeakify(self);
        [RoomDataSource loadRoomDataSourceWithPeekingRoom:peekingRoom andInitialEventId:self.eventId onComplete:^(id roomDataSource) {
            MXStrongifyAndReturnIfNil(self);

            self->_roomDataSource = roomDataSource;

            [self.roomDataSource finalizeInitialization];
            self.roomDataSource.markTimelineInitialEvent = YES;

            self->_roomName = peekingRoom.summary.displayname;
            self->_roomAvatarUrl = peekingRoom.summary.avatar;

            self->_roomTopic = [MXTools stripNewlineCharacters:peekingRoom.summary.topic];;
            self->_roomAliases = peekingRoom.summary.aliases;

            // Room members count
            // Note that room members presence/activity is not available
            self->_numJoinedMembers = peekingRoom.summary.membersCount.joined;

            completion(YES);
        }];

    } failure:^(NSError *error) {
        MXStrongifyAndReturnIfNil(self);
        
        self->_roomName = self->_roomId;
        completion(NO);
    }];
}

@end
