#import <Cordova/CDV.h>
#import "LocalMusic.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MPRemoteCommandCenter.h>
#import <MediaPlayer/MPRemoteCommand.h>

@interface LocalMusic : CDVPlugin<AVAudioPlayerDelegate,AVAudioPlayerDelegate,UITableViewDelegate, UIAlertViewDelegate> {
     NSString *callbackId_all;
}

@property (nonatomic, retain) MPMusicPlayerController *musicPlayer;
@property (strong, atomic) NSString *currendTrackId;


-(void)getMusicList:(CDVInvokedUrlCommand *)command;
-(void)getAlbums:(CDVInvokedUrlCommand *)command;
-(void)getArtists:(CDVInvokedUrlCommand *)command;




/** 音频播放器 */
@property (nonatomic, strong) AVAudioPlayer *player;
@property (strong, nonatomic) NSMutableArray *allMusicArrM;

//表示进度的slider
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
//计时器
@property (nonatomic, strong) NSTimer *timer;

//播放标记
@property (nonatomic, weak) NSString *isPlaying; // 1 正在播放
//播放标记
@property (nonatomic, weak) NSString *songPId; // 正在播放的歌曲ID

//存储音乐url的数组
@property (nonatomic, strong) NSMutableArray *musicArray;
//音乐的下标
@property (nonatomic, assign) NSInteger index;

@property (nonatomic, assign) NSInteger selectedSegmentIndex; //  0顺序播放  1随机  2单曲循环

@property (nonatomic,assign) NSTimeInterval  currentPlayTime; //当前音乐播放的时间
@property (nonatomic,assign) BOOL  isPause;

@end

@implementation LocalMusic



-(NSMutableArray *)musicArray
{
    if (!_musicArray) {
        _musicArray = [NSMutableArray array];
    }
    return _musicArray;
}

- (void)sendEvent:(NSString *)dict {
    if (!callbackId_all) return;
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:dict];
    [result setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId_all];
    
}

- (BOOL)loadMusic {
    //创建一个错误对象,用来接收错误信息
    NSError *error;
    //创建播放器对象 传入本地url
    if(self.musicArray.count > 0){
        NSDictionary *dir = [NSDictionary dictionaryWithDictionary:self.musicArray[self.index]];
        NSURL *soundUrl = [self convertToMp3:[dir objectForKey:@"id"]];
        //NSLog(@".........---路径：%@",soundUrl);
        if(!soundUrl){
            return NO;
        }
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:&error];
    
    //设置代理
    self.player.delegate = self;
    //打印错误信息
    if (error) {
        NSLog(@"%@",error);
    }
    //创建一个计时器,用于记录播放进度--在计时器方法里把currentTime赋值给slider的value
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sliderDisplay) userInfo:nil repeats:YES];
    //设置slider的最大值
    self.progressSlider.maximumValue = self.player.duration;
     
    //播放进度监听
//    if(self.playerTimer){
//        [self.playerTimer invalidate];
//    }
//    self.playerTimer =  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(handleActionTime:) userInfo:_playerItem repeats:YES];
    
    //锁屏信息
    MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter defaultCenter];
    //MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"openword_bg"]];
    NSString *artistName = [dir objectForKey:@"artistName"];
 
    if(!artistName || [artistName isEqualToString:@"(null) "]){
        artistName = @"";
    }
 
        Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
        
        if (playingInfoCenter) {
            NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
            //UIImage *image = [UIImage imageNamed:@"image"];
           // MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:image];
            //歌曲名称
            [songInfo setObject:[dir objectForKey:@"displayName"] forKey:MPMediaItemPropertyTitle];
            //演唱者
            [songInfo setObject:artistName forKey:MPMediaItemPropertyArtist];
            //专辑名
            [songInfo setObject:[dir objectForKey:@"albumName"] forKey:MPMediaItemPropertyAlbumTitle];
            //专辑缩略图
            //[songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
            //[songInfo setObject:[NSNumber numberWithDouble:[self.player.currentTime]] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime]; //音乐当前已经播放时间
            [songInfo setObject:[NSNumber numberWithFloat:1.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];//进度光标的速度 （这个随 自己的播放速率调整，我默认是原速播放）
            //[songInfo setObject:[NSNumber numberWithDouble:[audioY getAudioDuration]] forKey:MPMediaItemPropertyPlaybackDuration];//歌曲总时间设置
            // [songInfo setObject:@(240) forKey:MPMediaItemPropertyPlaybackDuration];//歌曲总时间设置
            //音乐剩余时长
            [songInfo setObject:[NSNumber numberWithDouble:self.player.duration] forKey:MPMediaItemPropertyPlaybackDuration];
            //音乐当前播放时间 在计时器中修改
            [songInfo setObject:[NSNumber numberWithDouble: self.player.currentTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
             //        设置锁屏状态下屏幕显示音乐信息
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
        }
    }
    
    return YES;
}

//计时器修改进度
- (void)changeProgress:(NSTimer *)sender{
    if(self.player){
        //当前播放时间
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo]];
        [dict setObject:[NSNumber numberWithDouble:self.player.currentTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime]; //音乐当前已经过时间
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dict];
        
    }
}


//开始播放按钮
- (void)startClick {
    if ([self.isPlaying isEqualToString:@"1"] && ![self.player isPlaying]) {
        [self loadMusic];
        //准备播放, 可不写 为了规范要写.
        [self.player prepareToPlay];
        //播放
        if(self.isPause){
            self.player.currentTime = self.currentPlayTime;
            self.isPause = NO;
        }
        [self.player play];
        self.isPlaying = @"0";
        [self sendEvent:@"play"];
    } else {
        self.currentPlayTime = self.player.currentTime;
        NSLog(@"%f",self.currentPlayTime);
        self.isPause = YES;
        [self.player pause];
        self.isPlaying = @"1";
        [self sendEvent:@"pause"];
    }
    
}

/** 计时器调用的显示slider的方法 */
- (void)sliderDisplay {
    //赋值
    self.progressSlider.value = self.player.currentTime;
    //转换时间格式
    NSString *curren = [self timeFormatted:self.player.currentTime];
    NSString *all = [self timeFormatted:self.player.duration];
}
/** 拖动进度条 */
- (IBAction)slideProgress:(UISlider *)sender {
    //将当前的播放时间设置为slider的value
    self.player.currentTime = sender.value;
}
/** 将秒数转换为分秒格式的时间字符串 */
- (NSString *)timeFormatted:(int)totalSeconds
{
    //将秒数转换为时间
    NSDate  *date = [NSDate dateWithTimeIntervalSince1970:totalSeconds];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: date];
    NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
    //设置时间格式
    NSDateFormatter *dateformmatter = [[NSDateFormatter alloc] init];
    dateformmatter.dateFormat = @"mm:ss";
    NSString *time = [dateformmatter stringFromDate:localeDate];
    
    return time;
}
//上一曲
- (void)lastMusicClick {
   // NSLog(@"%d",self.index);
    self.currentPlayTime = 0;
    if (self.selectedSegmentIndex == 0) { //顺序播放
        if (self.index <= 0) {
            self.index = self.musicArray.count - 1;
        } else {
            self.index--;
        }
    } else  if (self.selectedSegmentIndex == 1){ //随机播放
        NSInteger index = arc4random() % self.musicArray.count;
        self.index = index;
    }
    [self getCurrentSongId];
    [self loadMusic];
    [self.player play];
    [self sendEvent:self.songPId];
}

//下一曲
- (void)nextMusicClick {
     //NSLog(@"%d",self.index);
    self.currentPlayTime = 0;
    if (self.selectedSegmentIndex == 0) { //顺序播放
        if (self.index >= self.musicArray.count - 1) {
            self.index = 0;
        } else {
            self.index++;
        }
    } else  if (self.selectedSegmentIndex == 1){ //随机播放
        NSInteger index = arc4random() % self.musicArray.count;
        self.index = index;
    }
    [self getCurrentSongId];
    [self loadMusic];
    [self.player play];
    [self sendEvent:self.songPId];
}

- (void) getCurrentSongId{
    for(int i = 0; i < self.musicArray.count; i++){
        NSDictionary *dir = [NSDictionary dictionaryWithDictionary:self.musicArray[i]];
        if(self.index == i){
            self.songPId = [dir objectForKey:@"id"];
            break;
        }
     }
}

#pragma mark - 播放结束调用的方法
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
   // NSLog(@"播放结束、自动下一曲");
    [self nextMusicClick];
    
    // 音频播放完成时，调用该方法。
    // 参数flag：如果音频播放无法解码时，该参数为NO。
    //当音频被终端时，该方法不被调用。而会调用audioPlayerBeginInterruption方法
    // 和audioPlayerEndInterruption方法
    
}



// 未触发
//Used delegate method to handle iPhone control, like play and pause while doble tap on the home button
- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    //if it is a remote control event handle it correctly
    NSLog(@"进入监听...");
    //NSlog(@"%@",event.subtype);
    if (event.type == UIEventTypeRemoteControl) {
        if (event.subtype == UIEventSubtypeRemoteControlPlay) {
            //[audioPlayer play];
            NSLog(@"播放play");
        } else if (event.subtype == UIEventSubtypeRemoteControlPause) {
            //[audioPlayer stop];
            NSLog(@"暂停pause");
        } else if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
            NSLog(@"事件toggle");
        } else if (event.subtype == UIEventSubtypeRemoteControlNextTrack) {
            NSLog(@"事件-下一曲-UIEventSubtypeRemoteControlNextTrack");
        } else if (event.subtype == UIEventSubtypeRemoteControlPreviousTrack) {
            NSLog(@"事件-上一曲-UIEventSubtypeRemoteControlPreviousTrack");
        } else if (event.subtype == UIEventSubtypeRemoteControlBeginSeekingBackward) {
            NSLog(@"事件，开始后退 ，UIEventSubtypeRemoteControlBeginSeekingBackward");
        } else if (event.subtype == UIEventSubtypeRemoteControlEndSeekingBackward) {
            NSLog(@"事件，结束后退，UIEventSubtypeRemoteControlEndSeekingBackward");
        }
        
        else if (event.subtype == UIEventSubtypeRemoteControlBeginSeekingForward) {
            NSLog(@"事件，开始快进 ，UIEventSubtypeRemoteControlBeginSeekingForward");
        } else if (event.subtype == UIEventSubtypeRemoteControlEndSeekingForward) {
            NSLog(@"事件，结束快进，UIEventSubtypeRemoteControlEndSeekingForward");
        }
    }
}

-(bool) canBecomeFirstResponder{
    return YES;
}

// 在需要处理远程控制事件的具体控制器或其它类中实现
- (void)remoteControlEventHandler
{
    // 直接使用sharedCommandCenter来获取MPRemoteCommandCenter的shared实例
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    // 启用播放命令 (锁屏界面和上拉快捷功能菜单处的播放按钮触发的命令)
    commandCenter.playCommand.enabled = YES;
    // 为播放命令添加响应事件, 在点击后触发
    [commandCenter.playCommand addTarget:self action:@selector(startClick)];
    
    // 播放, 暂停, 上下曲的命令默认都是启用状态, 即enabled默认为YES
    // 为暂停, 上一曲, 下一曲分别添加对应的响应事件
    [commandCenter.pauseCommand addTarget:self action:@selector(startClick)];
    [commandCenter.previousTrackCommand addTarget:self action:@selector(lastMusicClick)];
    [commandCenter.nextTrackCommand addTarget:self action:@selector(nextMusicClick)];

    // 启用耳机的播放/暂停命令 (耳机上的播放按钮触发的命令)
    commandCenter.togglePlayPauseCommand.enabled = YES;
   
}

// 播放 暂停
-(void)playOrPause:(CDVInvokedUrlCommand *)command{
    //后台监听暂停、播放、下一首、上一首
    //[需要 AVAudioPlayer 方式播放才能监听到，而此方式播放的音乐是APP系统的资源文件，并不是手机上Itues的音乐文件]
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self.viewController becomeFirstResponder];

    // 获取传来的参数
    [self.commandDelegate runInBackground:^{
        callbackId_all = command.callbackId;
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [result setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId_all];
    }];
    NSString *sid = [command.arguments objectAtIndex:0];
    self.isPlaying = [command.arguments objectAtIndex:1];  // 当前需要的播放状态。1播放，0暂停
    if(![sid isEqualToString:self.songPId] && self.songPId){
        self.currentPlayTime = 0;
        self.isPlaying = @"1";
        [self.player pause];
    }
    self.songPId = [command.arguments objectAtIndex:0];
    Boolean isHave = NO;
    for(int i = 0; i < self.musicArray.count; i++){
        NSDictionary *dir = [NSDictionary dictionaryWithDictionary:self.musicArray[i]];
        if([self.songPId isEqualToString:[dir objectForKey:@"id"]]){
            self.index = i;
            isHave = YES;
            break;
        }
    }
    if(!isHave){
        NSLog(@"error:队列中未找到歌曲%@",self.songPId);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@":队列中未找到歌曲"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

    
    [self startClick];
}

// //0顺序播放 1随机。2循环。
-(void)setSelectedSegmentIndexs:(CDVInvokedUrlCommand *)command{
  // 获取传来的参数
  self.selectedSegmentIndex  = [[command.arguments objectAtIndex:0] intValue];
  // NSLog(@"%d",self.selectedSegmentIndex);
}

// 快进 or 后退
-(void) speedOrBack:(CDVInvokedUrlCommand *)command{
    NSLog(@"快进 or 后退.");
    [self.player pause];
    double music_times = [[command.arguments objectAtIndex:0] doubleValue];
    self.player.currentTime = music_times;
    NSLog(@"%f",music_times);
    [self.player play];
}

// 下一曲
-(void)nextSong:(CDVInvokedUrlCommand *)command{
    NSLog(@"下一曲..");
    [self.commandDelegate runInBackground:^{
        callbackId_all = command.callbackId;
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [result setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId_all];
    }];
    [self nextMusicClick];
}

// 上一曲
-(void)prevSong:(CDVInvokedUrlCommand *)command{
    NSLog(@"上一曲..");
    [self.commandDelegate runInBackground:^{
        callbackId_all = command.callbackId;
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [result setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId_all];
    }];

    [self lastMusicClick];
}


-(void)getMusicList:(CDVInvokedUrlCommand *)command{
    NSLog(@"开始获取...");
    
    // 开启后台播放
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    
    [self remoteControlEventHandler];
    
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [everything items];
    NSMutableArray *allSongs = [[NSMutableArray alloc] init];
    
    for (MPMediaItem *song in itemsFromGenericQuery) {
        NSLog(@"%@",song.title);
        NSMutableDictionary *songDictionary = [[NSMutableDictionary alloc] init];
        NSString *songId = [NSString stringWithFormat:@"%@", [song valueForProperty: MPMediaEntityPropertyPersistentID]];
        NSString *albumId = [NSString stringWithFormat:@"%@",[song valueForProperty:MPMediaItemPropertyAlbumPersistentID]];
        NSString *artistId = [NSString stringWithFormat:@"%@",[song valueForProperty:MPMediaItemPropertyArtistPersistentID]];
        NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
        NSString *albumTitle = [NSString stringWithFormat:@"%@ ",[song valueForProperty: MPMediaItemPropertyAlbumTitle]];
        NSString *artistTitle = [NSString stringWithFormat:@"%@ ",[song valueForProperty: MPMediaItemPropertyArtist]];
        NSNumber *duration = [NSNumber numberWithLong:[[song valueForKey:MPMediaItemPropertyPlaybackDuration] longValue] * 1000];
        NSString *lyrics = [NSString stringWithFormat:@"%@ ",[song valueForProperty: MPMediaItemPropertyLyrics]];
        //调用 absoluteString 转换为字符串
        NSString *url = [[song valueForProperty: MPMediaItemPropertyAssetURL] absoluteString];
 
        //NSString *dataUrl = [[self convertToMp3:song] absoluteString]; //考虑到一次全部export过来，手机内存不够，故注释
        //NSString *dataUrl = nil;
      
        [songDictionary setObject:songId forKey:@"id"];
        [songDictionary setObject:albumId forKey:@"album_id"];
        [songDictionary setObject:artistId forKey:@"artist_id"];
        [songDictionary setObject:songTitle forKey:@"displayName"];
        [songDictionary setObject:albumTitle forKey:@"albumName"];
        [songDictionary setObject:artistTitle forKey:@"artistName"];
        [songDictionary setObject:duration forKey:@"duration"];
        [songDictionary setObject:lyrics forKey:@"lyrics"];
        [songDictionary setObject:url forKey:@"url"];
        //[songDictionary setObject:dataUrl forKey:@"data"]; // 可H5标签audio播放的路径
        [self.musicArray addObject: songDictionary];
        [allSongs addObject:songDictionary];
    }
 
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[allSongs copy]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
   
}

- (NSURL *) convertToMp3: (NSString*)ToSongId{
    
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [everything items];
    NSMutableArray *allSongs = [[NSMutableArray alloc] init];
    for (MPMediaItem *song in itemsFromGenericQuery) {
        NSString *songId = [NSString stringWithFormat:@"%@",[song valueForProperty:MPMediaEntityPropertyPersistentID]];
        if([songId isEqualToString:ToSongId]){
            
                NSURL *url = [song valueForProperty:MPMediaItemPropertyAssetURL];
                AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:url options:nil];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES); // 去存放沙盒里面的音乐
                NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
                //NSLog(@"compatible presets for songAsset: %@",[AVAssetExportSession exportPresetsCompatibleWithAsset:songAsset]);
                NSArray *ar = [AVAssetExportSession exportPresetsCompatibleWithAsset: songAsset];
                //NSLog(@"%@", ar);
                AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset: songAsset presetName:AVAssetExportPresetAppleM4A];
                //NSLog(@"created exporter. supportedFileTypes: %@", exporter.supportedFileTypes);
                exporter.outputFileType=@"com.apple.m4a-audio";
            
                NSString *exportFile = [documentsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",[song valueForProperty:MPMediaEntityPropertyPersistentID]]];
                NSURL *urlPath = [NSURL fileURLWithPath:exportFile];
                exporter.outputURL=urlPath;
            
                NSLog(@"---------%@",urlPath);
            
                // 取得沙盒目录
                NSString *localPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                // 要检查的文件目录
                NSString *toFileName = [NSString stringWithFormat:@"%@%@",ToSongId,@".m4a"];
            
                NSString *filePath = [localPath  stringByAppendingPathComponent:toFileName];
                NSFileManager *fileManagerCom = [NSFileManager defaultManager];
                if ([fileManagerCom fileExistsAtPath:filePath]) {
                    NSLog(@"文件存在:%@",filePath);
                }
                else {
                    NSLog(@"文件不存在:%@",filePath);
                    
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
                                    NSLog(@"AVAssetExportSessionStatusCompleted");
                                    //export完成后，重新调用播放
                                    [self startClick];
                                    break;
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
                }
            
            return urlPath;
            
        }
    }
    return  nil;
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
        NSLog(@"encodedString@%@",encodedString);
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


@end
