#import <Cordova/CDV.h>
#import "LocalMusic.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>

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
        //调用 absoluteString 转换为字符串
        NSString *url = [[song valueForProperty: MPMediaItemPropertyAssetURL] absoluteString];
 
        NSString *dataUrl = [[self convertToMp3:song] absoluteString];
        
        [songDictionary setObject:songId forKey:@"id"];
        [songDictionary setObject:albumId forKey:@"album_id"];
        [songDictionary setObject:artistId forKey:@"artist_id"];
        [songDictionary setObject:songTitle forKey:@"displayName"];
        [songDictionary setObject:albumTitle forKey:@"albumName"];
        [songDictionary setObject:artistTitle forKey:@"artistName"];
        [songDictionary setObject:duration forKey:@"duration"];
        [songDictionary setObject:url forKey:@"url"];
        [songDictionary setObject:dataUrl forKey:@"data"]; // 可H5标签audio播放的路径
        
        [allSongs addObject:songDictionary];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[allSongs copy]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSURL *) convertToMp3: (MPMediaItem*)song{
    NSURL *url = [song valueForProperty:MPMediaItemPropertyAssetURL];
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
    //NSLog(@"compatible presets for songAsset: %@",[AVAssetExportSession exportPresetsCompatibleWithAsset:songAsset]);
    NSArray *ar = [AVAssetExportSession exportPresetsCompatibleWithAsset: songAsset];
    //NSLog(@"%@", ar);
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset: songAsset presetName:AVAssetExportPresetAppleM4A];
    //NSLog(@"created exporter. supportedFileTypes: %@", exporter.supportedFileTypes);
    exporter.outputFileType=@"com.apple.m4a-audio";
 
    NSString *exportFile = [documentsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",[song valueForProperty:MPMediaEntityPropertyPersistentID]]];
    NSURL *urlPath= [NSURL fileURLWithPath:exportFile];
    exporter.outputURL=urlPath;
    NSLog(@"---------%@",urlPath);
   
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSData *data1 = [NSData dataWithContentsOfFile:exportFile];
        //NSLog(@"==================data1:%@",data1);
        int exportStatus = exporter.status;
        switch(exportStatus)
        {
            case AVAssetExportSessionStatusFailed: {
            // log error to text view
        
                NSError *exportError = exporter.error;
                NSLog(@"AVAssetExportSessionStatusFailed: %@", exportError);
                break;
            }
            
            case AVAssetExportSessionStatusCompleted: {
                NSLog(@"AVAssetExportSessionStatusCompleted");break;
            }
            
            case AVAssetExportSessionStatusUnknown:
            {
                NSLog(@"AVAssetExportSessionStatusUnknown");
                break;
                
            }
            
            case AVAssetExportSessionStatusExporting:
            {
                NSLog(@"AVAssetExportSessionStatusExporting");
                break;
                
            }
            
            caseAVAssetExportSessionStatusCancelled:
            {
                NSLog(@"AVAssetExportSessionStatusCancelled");
                break;
            }
                
            case AVAssetExportSessionStatusWaiting:
            {
                NSLog(@"AVAssetExportSessionStatusWaiting");
                break;
            }
                
            default:
            {NSLog(@"didn't get export status");break;}
                
        }
        
    }
];

    
    return urlPath;
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
