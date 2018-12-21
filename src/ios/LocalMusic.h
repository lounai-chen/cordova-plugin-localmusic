#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>
#import <MediaPlayer/MediaPlayer.h>

@interface LocalMusic : CDVPlugin

@property (nonatomic, retain) MPMusicPlayerController *musicPlayer;
@property (strong, atomic) NSString *currendTrackId;

-(void)init:(CDVInvokedUrlCommand *)command;
-(void)getMusicList:(CDVInvokedUrlCommand *)command;
-(void)getAlbums:(CDVInvokedUrlCommand *)command;
-(void)getArtists:(CDVInvokedUrlCommand *)command;

-(void)playSong:(CDVInvokedUrlCommand *)command;
-(void)pause:(CDVInvokedUrlCommand *)command;
-(void)resume:(CDVInvokedUrlCommand *)command;
-(void)changeSong:(CDVInvokedUrlCommand *)command;
-(void)currentTrackInfo:(CDVInvokedUrlCommand *)command;


@end
