package org.apache.cordova.localMusic;

import android.Manifest;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.AudioManager;
import android.media.MediaMetadataRetriever;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.WindowInsets;

// import com.duanqu.qupai.utils.BitmapUtil;
// import com.duntuo.SmartVoiceAPP.MainActivity;
// import com.duntuo.SmartVoiceAPP.R;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;


import java.io.File;
import java.io.IOException;
import java.lang.reflect.Method;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Random;
import java.util.Timer;
import java.util.TimerTask;

import static android.content.Context.BIND_AUTO_CREATE;


/**
 * This class echoes a string called from JavaScript.
 */
public class LocalMusic extends CordovaPlugin {

  public static final String LOG_TAG  = "LOCALMUSIC";
  public static Uri ALL_SONGS_URI = android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
  public static Uri ALBUMS_URI = android.provider.MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI;
  public static Uri ARTISTS_URI = android.provider.MediaStore.Audio.Artists.EXTERNAL_CONTENT_URI;
  //获取焦点
  // AudioManager mAudioManager = (AudioManager) cordova.getContext().getSystemService(Context.AUDIO_SERVICE);
  private AudioManager mAudioManager;
  final MediaPlayer mMediaPlayer = new MediaPlayer();
  private ArrayList<String> musicList;
  private ArrayList<String> musicIds;
  private String isPlaying;    // 1 正在播放
  private String songId;    // 标记当前歌曲的序号
  private String musicType="song";    //播放来源的类别 song 单曲，art 歌手，album 专辑
  private String typeId;      //  musicType ！= song 。 typeid 表示的是artid, albumid
  private int selectedSegmentIndex=0; //  0 顺序播放  1 随机  2 单曲循环
  private int songIndex;
  public static int musicPosition;
  JSONArray allMusic = new JSONArray();
  private MediaSessionCompat mMediaSession;
  private CallbackContext BleButtonCallbackContext = null;
  public static final int SEEK_CLOSEST   = 0x03;
  public boolean execute(String action, JSONArray args,CallbackContext callbackContext) throws JSONException {
    //mAudioManager.requestAudioFocus(mAudioFocusChange, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN);
    //requestFocus();
    //初始化AudioManager对象
    mAudioManager = (AudioManager)  cordova.getContext().getSystemService(Context.AUDIO_SERVICE);
    //申请焦点
    mAudioManager.requestAudioFocus(mAudioFocusChange, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT);
    //判断权限够不够，不够就给
    if (ContextCompat.checkSelfPermission(cordova.getContext(), Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
      ActivityCompat.requestPermissions(cordova.getActivity(), new String[]{
              Manifest.permission.WRITE_EXTERNAL_STORAGE
      }, 1);
    }

    if("getMusicList".equals(action)) {
      musicPosition=0;
      allMusic = this.getJsonListOfSongs();
      callbackContext.success(allMusic);
    } else if("getAlbums".equals(action)){
      musicPosition=0;
      JSONArray allAlbums = this.getJsonListOfAlbums();
      callbackContext.success(allAlbums);
    } else if("getArtists".equals(action)){
      musicPosition=0;
      JSONArray allAlbums = this.getJsonListOfArtists();
      callbackContext.success(allAlbums);
    }
    //   播放 、 暂停
    else if("playOrPause".equals(action)){
      songId =  args.getString(0);
      isPlaying =  args.getString(1);
      musicType =  args.getString(2);
      typeId =  args.getString(3);
      //Log.e(null,"第几首歌："+songId+" 播放暂停："+isPlaying);
      if(allMusic.length()==0){
        allMusic = this.getJsonListOfSongs();
      }

      //开始播放
      if (isPlaying.equals("1") && musicPosition!=0){
        mMediaPlayer.start();
      } else {
        playMusic(false);
      }

    }
    //上一曲
    else if("prevSong".equals(action)){
      isPlaying = "1";
      musicPosition=0;
      musicType =  args.getString(0);
      typeId =  args.getString(1);
      preciousMusic();
      callbackContext.success(songId);
    }
    //下一曲
    else if("nextSong".equals(action)){
      isPlaying = "1";
      musicPosition=0;
      musicType =  args.getString(0);
      typeId =  args.getString(1);
      nextMusic(false);
      callbackContext.success(songId);
    }
    // 0顺序播放 1随机。2循环。
    else if("setSelectedSegmentIndexs".equals(action)){
      musicPosition=0;
      selectedSegmentIndex = Integer.parseInt(args.getString(0));
    }
    // 快进 or 后退
    else if("speedOrBack".equals(action)){
       Log.e(null,args.getString(0));
      //mMediaPlayer.pause();
      mMediaPlayer.seekTo(Integer.parseInt(args.getString(0))); //SEEK_CLOSEST
      //mMediaPlayer.start();
    }
    // 开启媒体按键监听 android
    if (action.equals("start")) {
      if (this.BleButtonCallbackContext != null) {
        removeBleButtonListener();
      }
      this.BleButtonCallbackContext = callbackContext;
      Context context = this.cordova.getContext();
      mMediaSession = new MediaSessionCompat(context,LOG_TAG);
      mMediaSession.setFlags(MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS | MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS);
      mMediaSession.setCallback(new MediaSessionCompat.Callback() {
        @Override
        public boolean onMediaButtonEvent(Intent intent) {
          String action = intent.getAction();
          if (action.equals(Intent.ACTION_MEDIA_BUTTON)) {
            // 获得KeyEvent对象
            KeyEvent key = intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT);

            if (key == null) {
              return false;
            }
            if (key.getAction() != KeyEvent.ACTION_DOWN) {
              int keycode = key.getKeyCode();
              if (keycode == KeyEvent.KEYCODE_MEDIA_NEXT) {
                // 下一首按键
                sendUpdate("PRESS_NEXT", true);
              } else if (keycode == KeyEvent.KEYCODE_MEDIA_PREVIOUS) {
                // 上一首按键
                sendUpdate("PRESS_PREVIOUS", true);
              } else if (keycode == KeyEvent.KEYCODE_MEDIA_PLAY) {
                // 播放按键
                sendUpdate("PRESS_PLAY", true);
              } else if (keycode == KeyEvent.KEYCODE_MEDIA_PAUSE) {
                // 暂停按键
                sendUpdate("PRESS_PAUSE", true);
              } else if (keycode == KeyEvent.KEYCODE_VOLUME_UP) {
                // 暂停按键
                sendUpdate("PRESS_VOLUME_UP", true);
              } else if (keycode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                // 暂停按键
                sendUpdate("PRESS_VOLUME_DOWN", true);
              }
              // 还可以添加更多按键操作，可以参阅 KeyEvent 类
            }
          }
          return true;
        }
      });
      mMediaSession.setActive(true);
    }
    else {
      return false;
    }
    return true;
  }

  /**
   * 焦点变化监听器
   */
  private AudioManager.OnAudioFocusChangeListener mAudioFocusChange = new AudioManager.OnAudioFocusChangeListener() {
    @Override
    public void onAudioFocusChange(int focusChange) {
      switch (focusChange){
        case AudioManager.AUDIOFOCUS_LOSS:
          //长时间丢失焦点
          Log.d(null, "AUDIOFOCUS_LOSS");
          stop();
          //释放焦点
          mAudioManager.abandonAudioFocus(mAudioFocusChange);
          break;
        case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT:
          //短暂性丢失焦点
          stop();
          Log.d(null, "AUDIOFOCUS_LOSS_TRANSIENT");
          break;
        case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK:
          //短暂性丢失焦点并作降音处理
          Log.d(null, "AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK");
          break;
        case AudioManager.AUDIOFOCUS_GAIN:
          //重新获得焦点
          Log.d(null, "AUDIOFOCUS_GAIN");
          start();
          break;
      }
    }
  };

  private void start() {
    mAudioManager.requestAudioFocus(mAudioFocusChange, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN);
    mMediaPlayer.start();
  }

  private void stop() {
    mMediaPlayer.pause();

  }
 

  private void sendUpdate(String message, boolean keepCallback) {
    if (this.BleButtonCallbackContext != null) {
      PluginResult result = new PluginResult(PluginResult.Status.OK, message);
      result.setKeepCallback(keepCallback);
      this.BleButtonCallbackContext.sendPluginResult(result);
    }
  }
  private void removeBleButtonListener() {
    if(mMediaSession != null) {
      mMediaSession.setCallback(null);
      mMediaSession.setActive(false);
      mMediaSession.release();
    }
  }
  public JSONArray getJsonListOfSongs(){
    ContentResolver contentResolver = this.cordova.getActivity().getContentResolver();
    Cursor cursor = contentResolver.query(ALL_SONGS_URI, null, (android.provider.MediaStore.Audio.Media.IS_MUSIC+" = ?"), new String[]{"1"}, null);
    allMusic = new JSONArray();
    musicList = new ArrayList<String>();   //音乐列表
    musicIds = new ArrayList<String>();
    if (cursor == null){

    }else if (!cursor.moveToFirst()){

    }else{
      int idColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media._ID);
      int titleColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.TITLE);
      int albumIdColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.ALBUM_ID);
      int albumColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.ALBUM);
      int artistIdColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.ARTIST_ID);
      int artistColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.ARTIST);
      int durationColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.DURATION);
      int dataColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Media.DATA);
      //int dataImgUrl = cursor.getColumnIndex(android.provider.MediaStore.Audio.Thumbnails);

      do {
        JSONObject music = new JSONObject();
        try {
          if(cursor.getLong(idColumn)>0){
            music.put("id", cursor.getLong(idColumn));
            music.put("displayName", cursor.getString(titleColumn));
            music.put("album_id", cursor.getLong(albumIdColumn));
            music.put("albumName", cursor.getString(albumColumn));
            music.put("artist_id", cursor.getLong(artistIdColumn));
            music.put("artistName", cursor.getString(artistColumn));
            music.put("duration", cursor.getLong(durationColumn));
            music.put("data", cursor.getString(dataColumn));
            music.put("albumsImgUrl", MediaStore.Video.Thumbnails.getContentUri(cursor.getString(titleColumn)));
            allMusic.put(music);
            musicList.add(cursor.getString(dataColumn));
            musicIds.add(Long.toString(cursor.getLong(idColumn)));
            Log.e( null ,music.getString("displayName"));
            Log.e( null ,music.getString("data"));
          }
        } catch (JSONException e) {
          e.printStackTrace();
        }
      } while (cursor.moveToNext());
    }
    // 释放资源
    cursor.close();
    return allMusic;
  }

  /**
   根据歌曲路径获得专辑封面
   * @Description 获取专辑封面
   * @param filePath 文件路径，like XXX/XXX/XX.mp3
   * @return 专辑封面bitmap
   */
  public static Bitmap createAlbumArt(final String filePath) {
    Bitmap bitmap = null;
    //能够获取多媒体文件元数据的类
    MediaMetadataRetriever retriever = new MediaMetadataRetriever();
    try {
      retriever.setDataSource(filePath); //设置数据源
      byte[] embedPic = retriever.getEmbeddedPicture(); //得到字节型数据
      bitmap = BitmapFactory.decodeByteArray(embedPic, 0, embedPic.length); //转换为图片
      //要优化后再加载
      //bitmap=BitmapUtil.decodeBitmapByByteArray(embedPic,80,80);
    } catch (Exception e) {
      e.printStackTrace();
    } finally {
      try {
        retriever.release();
      } catch (Exception e2) {
        e2.printStackTrace();
      }
    }
    return bitmap;
  }


  public JSONArray getJsonListOfAlbums(){
    ContentResolver contentResolver = this.cordova.getActivity().getContentResolver();
    Cursor cursor = contentResolver.query(ALBUMS_URI, null, null, null, null);
    JSONArray allAlbums = new JSONArray();
    if (cursor == null){

    }else if (!cursor.moveToFirst()){

    }else{
      int idColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Albums._ID);
      int titleColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Albums.ALBUM);
      int albumArtColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Albums.ALBUM_ART);
      int noOfSongsColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Albums.NUMBER_OF_SONGS);
      int artistColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Albums.ARTIST);
      do {
        JSONObject album = new JSONObject();
        try {

          album.put("id", cursor.getLong(idColumn));
          album.put("displayName", cursor.getString(titleColumn));
          album.put("image", cursor.getString(albumArtColumn));
          album.put("noOfSongs", cursor.getLong(noOfSongsColumn));
          album.put("artist", cursor.getString(artistColumn));
          allAlbums.put(album);
        } catch (JSONException e) {
          e.printStackTrace();
        }
      } while (cursor.moveToNext());
    }
    return allAlbums;
  }

  public JSONArray getJsonListOfArtists(){
    ContentResolver contentResolver = this.cordova.getActivity().getContentResolver();
    Cursor cursor = contentResolver.query(ARTISTS_URI, null, null, null, null);
    JSONArray allArtists = new JSONArray();
    if (cursor == null){

    }else if (!cursor.moveToFirst()){

    }else{
      int idColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Artists._ID);
      int artistColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Artists.ARTIST);
      int noOfSongsColumn = cursor.getColumnIndex(android.provider.MediaStore.Audio.Artists.NUMBER_OF_TRACKS);
      do {
        JSONObject artist = new JSONObject();
        try {

          artist.put("id", cursor.getLong(idColumn));
          artist.put("artistName", cursor.getString(artistColumn));
          artist.put("noOfSongs", cursor.getLong(noOfSongsColumn));
          allArtists.put(artist);
        } catch (JSONException e) {
          e.printStackTrace();
        }
      } while (cursor.moveToNext());
    }
    return allArtists;
  }

  /**
   * 播放\暂停音乐
   */
  public void playMusic(boolean isAutoNextPlay) {
    Log.e(null,"开始播放-暂停音乐"+isPlaying);
    if (isPlaying.equals("1")) {
      //如果还没开始播放，就开始
      Log.e(null,"开始播放");
      mMediaPlayer.reset();
      iniMediaPlayerFile(songId);
      if(musicPosition!=0){
        mMediaPlayer.seekTo(musicPosition);
      }
      else {
        mMediaPlayer.start();
      }
      isPlaying = "0";
    }
    // 暂停播放
    else {
      mMediaPlayer.pause();
      musicPosition = mMediaPlayer.getCurrentPosition();
      Log.e(null,"暂停"+musicPosition);
      isPlaying = "1";
    }

    //播放完成事件
    mMediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
      @Override
      public void onCompletion(MediaPlayer mediaPlayer) {
        Log.e(null,"播放结束，自动下一曲");
        isPlaying = "1";
        musicPosition = 0;
        nextMusic(true);
      }
    });

    //播放跳转事件
//    mMediaPlayer.setOnSeekCompleteListener(new MediaPlayer.OnSeekCompleteListener(){
//      @Override
//      public void onSeekComplete(MediaPlayer mp) {
//        //TODO: Your code here
//        mMediaPlayer.start();
//      }
//    });


  }


  /**
   * 下一首
   */
  public void nextMusic(boolean isAutoNextPlay) {

    if (mMediaPlayer != null) {
      int countMusicSize = allMusic.length();
      if(musicType.equals("art")){
        try {
          countMusicSize = 0;
          for (int i = 0; i < allMusic.length(); i++) {
            JSONObject jsonObject = allMusic.getJSONObject(i);
            String artist_id = jsonObject.getString("artist_id"); //歌手
            if( artist_id.equals(typeId)){
              countMusicSize++;
            }
          }
        } catch (JSONException e) {
          e.printStackTrace();
        }
      } else  if(musicType.equals("album")){
        try {
          countMusicSize = 0;
          for (int i = 0; i < allMusic.length(); i++) {
            JSONObject jsonObject = allMusic.getJSONObject(i);
            String artist_id = jsonObject.getString("album_id"); //专辑
            if( artist_id.equals(typeId)){
              countMusicSize++;
            }
          }
        } catch (JSONException e) {
          e.printStackTrace();
        }
      }
      if (selectedSegmentIndex == 0) { //顺序播放
        if (songIndex >= countMusicSize - 1) {
          songIndex = 0;
        } else {
          songIndex++;
        }
      }
      else if (selectedSegmentIndex == 1) { //随机播放
        int max= countMusicSize - 1;
        Random random = new Random();
        songIndex = random.nextInt(max)%(max+1);
      }
      int countTypes = 0;
      for(int i = 0; i <allMusic.length(); i++) {
          try {
            if(musicType.equals("art")) {
              if(typeId.equals(allMusic.getJSONObject(i).getString("artist_id"))) {
                if(countTypes == songIndex) {
                  songId = allMusic.getJSONObject(i).getString("id");
                  //Log.e(null,allMusic.getJSONObject(i).getString("displayName"));
                  break;
                }
                countTypes++;
              }
            } else if(musicType.equals("album")) {
              if(typeId.equals(allMusic.getJSONObject(i).getString("album_id"))) {
                if(countTypes == songIndex) {
                  songId = allMusic.getJSONObject(i).getString("id");
                  break;
                }
                countTypes++;
              }
            } else if(musicType.equals("song")) {
              if(songIndex == i){
                songId = allMusic.getJSONObject(i).getString("id");
                break;
              }
            }
          }catch (JSONException e) {
            e.printStackTrace();
          }
      }
      playMusic(isAutoNextPlay);
      if(isAutoNextPlay){
        sendUpdate(songId,true);
      }
    }

  }

  /**
   * 上一首
   */
  public void preciousMusic() {

    if (mMediaPlayer != null){
      int countMusicSize = allMusic.length();
      if(musicType.equals("art")){
        countMusicSize = 0;
        try {
          for (int i = 0; i < allMusic.length(); i++) {
            JSONObject jsonObject = allMusic.getJSONObject(i);
            String artist_id = jsonObject.getString("artist_id");
            if( artist_id.equals(typeId)){
              countMusicSize++;
            }
          }
        } catch (JSONException e) {
          e.printStackTrace();
        }
      } else  if(musicType.equals("album")){
        countMusicSize = 0;
        try {
          for (int i = 0; i < allMusic.length(); i++) {
            JSONObject jsonObject = allMusic.getJSONObject(i);
            String artist_id = jsonObject.getString("album_id");
            if( artist_id.equals(typeId)){
              countMusicSize++;
            }
          }
        } catch (JSONException e) {
          e.printStackTrace();
        }
      }

      if (selectedSegmentIndex == 0) { //顺序播放
        if (songIndex <= 0) {
          songIndex = countMusicSize - 1;
        } else {
          songIndex--;
        }
      }
      else  if (selectedSegmentIndex == 1){ //随机播放
        int max= countMusicSize - 1;
        Random random = new Random();
        songIndex = random.nextInt(max)%(max+1);
      }
      // 从歌手处播放
      int countTypes = 0;
      for(int i = 0; i <allMusic.length(); i++) {
        try {
          if(musicType.equals("art")) {
            if(typeId.equals(allMusic.getJSONObject(i).getString("artist_id"))) {
              if(countTypes == songIndex) {
                songId = allMusic.getJSONObject(i).getString("id");
                Log.e(null,allMusic.getJSONObject(i).getString("displayName"));
                break;
              }
              countTypes++;
            }
          } else if(musicType.equals("album")) {
            if(typeId.equals(allMusic.getJSONObject(i).getString("album_id"))) {
              if(countTypes == songIndex) {
                songId = allMusic.getJSONObject(i).getString("id");
                Log.e(null,allMusic.getJSONObject(i).getString("displayName"));
                break;
              }
              countTypes++;
            }
          } else if(musicType.equals("song")) {
            if(songIndex == i){
              songId = allMusic.getJSONObject(i).getString("id");
              break;
            }
          }
        }catch (JSONException e) {
          e.printStackTrace();
        }
      }

      playMusic(false);
    }
  }

  /**
   * 关闭播放器
   */
  public void closeMedia() {
    if (mMediaPlayer != null) {
      mMediaPlayer.stop();
      mMediaPlayer.release();
    }
  }

  /**
   * 添加file文件到MediaPlayer对象并且准备播放音频
   */
  private void iniMediaPlayerFile(String idex) {
    //获取文件路径
    try {
      //此处的两个方法需要捕获IO异常
      //设置音频文件到MediaPlayer对象中
      int song_index = 0;
      int count_type = 0;
      String songPath =  musicList.get(song_index);
      for(int i = 0; i < musicIds.size(); i++){
        if( musicIds.get(i).equals(idex)){
          song_index = i;
          if(musicType.equals("song")) {
            songIndex = i;
            songPath =  musicList.get(song_index);
          }
        }
      }
      // 从歌手和专辑列表
      for(int i =0; i < allMusic.length();i++){
        try {
          String song_id = allMusic.getJSONObject(i).getString("id");
          if(musicType.equals("art")){
            String artist_id = allMusic.getJSONObject(i).getString("artist_id");
            if(artist_id.equals(typeId)){
              if(song_id.equals(idex)){
                songIndex = count_type;
                songPath =  musicList.get(song_index);
                break;
              }
              count_type++;
            }
          } else if(musicType.equals("album")){
            String album_id = allMusic.getJSONObject(i).getString("album_id");
            if(album_id.equals(typeId)){
              if(song_id.equals(idex)){
                songIndex = count_type;
                songPath =  musicList.get(song_index);
                break;
              }
              count_type++;
            }
          }
        } catch(JSONException e) {
          e.printStackTrace();
        }
      }
      Log.d(LOG_TAG , "播放路径");
      Log.e(null,songPath);
      mMediaPlayer.setDataSource(songPath);
      //让MediaPlayer对象准备
      mMediaPlayer.prepare();
    } catch (IOException e) {
      Log.d(LOG_TAG , "设置资源，准备阶段出错");
      e.printStackTrace();
    }
  }






}
