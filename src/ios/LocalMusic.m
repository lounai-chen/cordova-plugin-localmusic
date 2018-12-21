#import <Cordova/CDV.h>
#import "LocalMusic.h"

@implementation LocalMusic

@synthesize musicPlayer, currendTrackId;

-(void)init:(CDVInvokedUrlCommand *)command{
    musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:nil];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)currentTrackInfo:(CDVInvokedUrlCommand *)command{
    NSMutableDictionary *trackInfo = [[NSMutableDictionary alloc] init];
    
    NSNumber *duration = [NSNumber numberWithDouble:(isnan(musicPlayer.currentPlaybackTime) ? 0.0 : musicPlayer.currentPlaybackTime*1000)];
    [trackInfo setObject:duration forKey:@"currentPosition"];
    
    BOOL isPlaying = YES;
    BOOL isPaused = NO;
    if([musicPlayer playbackState] == MPMusicPlaybackStatePlaying){
        isPlaying = YES;
        isPaused = NO;
    }else if([musicPlayer playbackState] == MPMusicPlaybackStatePaused || [musicPlayer playbackState]==MPMusicPlaybackStateInterrupted){
        isPlaying = [[[musicPlayer nowPlayingItem] valueForKey:MPMediaItemPropertyPlaybackDuration] doubleValue] <= [duration doubleValue] ? YES : NO;
        isPaused = YES;
    }else{
        isPlaying = NO;
        isPaused = NO;
    }
    [trackInfo setValue:[NSNumber numberWithBool:isPlaying] forKey:@"isPlaying"];
    [trackInfo setValue:[NSNumber numberWithBool:isPaused] forKey:@"isPaused"];
    currendTrackId = [NSString stringWithFormat:@"%@",[[musicPlayer nowPlayingItem] valueForKey:MPMediaItemPropertyPersistentID]];
    if (currendTrackId == nil) {
        currendTrackId = @"-1";
    }
    [trackInfo setObject:currendTrackId forKey:@"id"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:trackInfo];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


-(void)getMusicList:(CDVInvokedUrlCommand *)command{
    NSLog(@"开始获取...");
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [everything items];
    NSMutableArray *allSongs = [[NSMutableArray alloc] init];
    for (MPMediaItem *song in itemsFromGenericQuery) {
        NSLog(@"%@",song.title);
        NSMutableDictionary *songDictionary = [[NSMutableDictionary alloc] init];
        NSString *songId = [NSString stringWithFormat:@"%@",[song valueForProperty:MPMediaEntityPropertyPersistentID]];
        NSString *albumId = [NSString stringWithFormat:@"%@",[song valueForProperty:MPMediaItemPropertyAlbumPersistentID]];
        NSString *artistId = [NSString stringWithFormat:@"%@",[song valueForProperty:MPMediaItemPropertyArtistPersistentID]];
        NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
        NSString *albumTitle = [NSString stringWithFormat:@"%@ ",[song valueForProperty: MPMediaItemPropertyAlbumTitle]];
        NSString *artistTitle = [NSString stringWithFormat:@"%@ ",[song valueForProperty: MPMediaItemPropertyArtist]];
        NSNumber *duration = [NSNumber numberWithLong:[[song valueForKey:MPMediaItemPropertyPlaybackDuration] longValue] * 1000];
        //链接    注意: 如果后面不调用 absoluteString ,播放会崩溃
        NSString *url = [[song valueForProperty: MPMediaItemPropertyAssetURL] absoluteString];

        [songDictionary setObject:songId forKey:@"id"];
        [songDictionary setObject:albumId forKey:@"album_id"];
        [songDictionary setObject:artistId forKey:@"artist_id"];
        [songDictionary setObject:songTitle forKey:@"displayName"];
        [songDictionary setObject:albumTitle forKey:@"albumName"];
        [songDictionary setObject:artistTitle forKey:@"artistName"];
        [songDictionary setObject:duration forKey:@"duration"];
        [songDictionary setObject:url forKey:@"url"];

        [allSongs addObject:songDictionary];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[allSongs copy]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)getAlbums:(CDVInvokedUrlCommand *)command{
    NSMutableArray *allAlbums = [[NSMutableArray alloc] init];
    for (MPMediaItemCollection *collection in [[MPMediaQuery albumsQuery] collections]) {
        
        NSMutableDictionary *albumDictionary = [[NSMutableDictionary alloc] init];
        MPMediaItem *album = [collection representativeItem];
        UIImage *image = [[album valueForProperty:MPMediaItemPropertyArtwork] imageWithSize:CGSizeMake(100, 100)];
        NSData *data = UIImagePNGRepresentation(image);
        NSString *encodedString = [NSString stringWithFormat:@"data:image/png;base64,%@",[data base64Encoding]];
        NSString *albumId = [NSString stringWithFormat:@"%@",[album valueForProperty:MPMediaItemPropertyAlbumPersistentID]];
        NSString *albumTitle = [album valueForKey:MPMediaItemPropertyAlbumTitle];
        NSString *artistTitle = [NSString stringWithFormat:@"%@ ",[album valueForProperty: MPMediaItemPropertyArtist]];
        NSNumber *noOfSongs = [album valueForKey:MPMediaItemPropertyAlbumTrackCount];

        [albumDictionary setObject:albumId forKey:@"id"];
        [albumDictionary setObject:albumTitle forKey:@"displayName"];
        [albumDictionary setObject:encodedString forKey:@"image"];
        [albumDictionary setObject:artistTitle forKey:@"artist"];
        [albumDictionary setObject:noOfSongs forKey:@"noOfSongs"];
        [allAlbums addObject:albumDictionary];
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[allAlbums copy]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)getArtists:(CDVInvokedUrlCommand *)command{
    NSMutableArray *allArtists = [[NSMutableArray alloc] init];
    for (MPMediaItemCollection *collection in [[MPMediaQuery artistsQuery] collections]) {
        NSMutableDictionary *artistDictionary = [[NSMutableDictionary alloc] init];
        MPMediaItem *artist = [collection representativeItem];
        NSString *artistId = [NSString stringWithFormat:@"%@",[artist valueForProperty:MPMediaItemPropertyArtistPersistentID]];
        NSString *artistTitle = [NSString stringWithFormat:@"%@ ",[artist valueForProperty: MPMediaItemPropertyArtist]];
        
        [artistDictionary setObject:artistId forKey:@"id"];
        [artistDictionary setObject:artistTitle forKey:@"artistName"];
        [allArtists addObject:artistDictionary];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[allArtists copy]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)playSong:(CDVInvokedUrlCommand *)command{
    [musicPlayer play];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:nil];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)pause:(CDVInvokedUrlCommand *)command{
    [musicPlayer pause];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:nil];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)resume:(CDVInvokedUrlCommand *)command{
    [musicPlayer play];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:nil];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)changeSong:(CDVInvokedUrlCommand *)command{
    NSMutableDictionary* options = [command.arguments objectAtIndex:0];
    NSString *songId = [options valueForKey:@"_id"];
    MPMediaPropertyPredicate *predicate;
    MPMediaQuery *songQuery;
    currendTrackId = songId;
    predicate = [MPMediaPropertyPredicate predicateWithValue: songId forProperty:MPMediaItemPropertyPersistentID comparisonType:MPMediaPredicateComparisonEqualTo];
    songQuery = [[MPMediaQuery alloc] init];
    [songQuery addFilterPredicate: predicate];
    [musicPlayer setQueueWithQuery:songQuery];
    [musicPlayer play];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:nil];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
