package org.apache.cordova.localMusic;

import android.Manifest;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.WindowInsets;

import com.duntuo.SmartVoiceAPP.MainActivity;
import com.duntuo.SmartVoiceAPP.R;

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

  final MediaPlayer mMediaPlayer = new MediaPlayer();
  private ArrayList<String> musicList;
  private String isPlaying;    // 1 正在播放
  private int songIndex=0;    // 标记当前歌曲的序号
  private int selectedSegmentIndex=0; //  0 顺序播放  1 随机  2 单曲循环
  JSONArray allMusic = new JSONArray();
  private MediaSessionCompat mMediaSession;
  private CallbackContext BleButtonCallbackContext = null;

  public boolean execute(String action, JSONArray args,CallbackContext callbackContext) throws JSONException {
    //判断权限够不够，不够就给
    if (ContextCompat.checkSelfPermission(cordova.getContext(), Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
      ActivityCompat.requestPermissions(cordova.getActivity(), new String[]{
              Manifest.permission.WRITE_EXTERNAL_STORAGE
      }, 1);
    }

    if("getMusicList".equals(action)) {
      JSONArray allMusic = this.getJsonListOfSongs();
      callbackContext.success(allMusic);
    } else if("getAlbums".equals(action)){
      JSONArray allAlbums = this.getJsonListOfAlbums();
      callbackContext.success(allAlbums);
    } else if("getArtists".equals(action)){
      JSONArray allAlbums = this.getJsonListOfArtists();
      callbackContext.success(allAlbums);
    }
    //   播放 、 暂停
    else if("playOrPause".equals(action)){
      songIndex =  Integer.parseInt(args.getString(0));
      isPlaying =  args.getString(1);
      Log.e(null,"第几首歌："+songIndex+" 播放暂停："+isPlaying);
      playMusic();
    }
    //上一曲
    else if("prevSong".equals(action)){
      preciousMusic();
    }
    //下一曲
    else if("nextSong".equals(action)){
      nextMusic();
    }
    // 0顺序播放 1随机。2循环。
    else if("setSelectedSegmentIndexs".equals(action)){
      selectedSegmentIndex = Integer.parseInt(args.getString(0));
    }
    // 快进 or 后退
    else if("speedOrBack".equals(action)){
       mMediaPlayer.seekTo(Integer.parseInt(args.getString(0)));
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

      do {
        JSONObject music = new JSONObject();
        try {
          music.put("id", cursor.getLong(idColumn));
          music.put("displayName", cursor.getString(titleColumn));
          music.put("album_id", cursor.getLong(albumIdColumn));
          music.put("albumName", cursor.getString(albumColumn));
          music.put("artist_id", cursor.getLong(artistIdColumn));
          music.put("artistName", cursor.getString(artistColumn));
          music.put("duration", cursor.getLong(durationColumn));
          music.put("data", cursor.getString(dataColumn));
          allMusic.put(music);
          musicList.add(cursor.getString(dataColumn));
          Log.e( null ,music.getString("displayName"));
          Log.e( null ,music.getString("data"));
        } catch (JSONException e) {
          e.printStackTrace();
        }
      } while (cursor.moveToNext());
    }
    // 释放资源
    cursor.close();
    return allMusic;
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
  public void playMusic() {
    Log.e(null,"开始播放-暂停音乐"+isPlaying);
    if (isPlaying.equals("1")) {
      //如果还没开始播放，就开始
      Log.e(null,"开始播放");
      mMediaPlayer.reset();
      iniMediaPlayerFile(songIndex);
      mMediaPlayer.start();
      isPlaying = "0";
    }
    // 暂停播放
    else {
      Log.e(null,"暂停");
      mMediaPlayer.pause();
      isPlaying = "1";
    }

    //播放完成事件
    mMediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
      @Override
      public void onCompletion(MediaPlayer mediaPlayer) {
       nextMusic();
      }
    });
  }


  /**
   * 下一首
   */
  public void nextMusic() {

    if (mMediaPlayer != null) {
      if (selectedSegmentIndex == 0) { //顺序播放
        if (songIndex >= musicList.size() - 1) {
          songIndex = 0;
        } else {
          songIndex++;
        }
      }
      else if (selectedSegmentIndex == 1) { //随机播放
        int max= musicList.size() - 1;
        Random random = new Random();
        songIndex = random.nextInt(max)%(max+1);
      }
      playMusic();
    }

  }

  /**
   * 上一首
   */
  public void preciousMusic() {

    if (mMediaPlayer != null){
      if (selectedSegmentIndex == 0) { //顺序播放
        if (songIndex <= 0) {
          songIndex =  musicList.size() - 1;
        } else {
          songIndex--;
        }
      }
      else  if (selectedSegmentIndex == 1){ //随机播放
        int max= musicList.size() - 1;
        Random random = new Random();
        songIndex = random.nextInt(max)%(max+1);
      }

      playMusic();
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
  private void iniMediaPlayerFile(int dex) {
    //获取文件路径
    try {
      //此处的两个方法需要捕获IO异常
      //设置音频文件到MediaPlayer对象中

      String songPath =  musicList.get(dex);
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
