package org.apache.cordova.localMusic;

import android.content.ContentResolver;
import android.database.Cursor;
import android.net.Uri;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * This class echoes a string called from JavaScript.
 */
public class LocalMusic extends CordovaPlugin {

  public static final String TAG = "LOCALMUSIC";
  public static Uri ALL_SONGS_URI = android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
  public static Uri ALBUMS_URI = android.provider.MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI;
  public static Uri ARTISTS_URI = android.provider.MediaStore.Audio.Artists.EXTERNAL_CONTENT_URI;

  public boolean execute(String action, JSONArray args,CallbackContext callbackContext) throws JSONException {
    if("getMusicList".equals(action)) {
      JSONArray allMusic = this.getJsonListOfSongs();
      callbackContext.success(allMusic);
    } else if("getAlbums".equals(action)){
      JSONArray allAlbums = this.getJsonListOfAlbums();
      callbackContext.success(allAlbums);
    } else if("getArtists".equals(action)){
      JSONArray allAlbums = this.getJsonListOfArtists();
      callbackContext.success(allAlbums);
    } else {
      return false;
    }
    return true;
  }

  public JSONArray getJsonListOfSongs(){
    ContentResolver contentResolver = this.cordova.getActivity().getContentResolver();
    Cursor cursor = contentResolver.query(ALL_SONGS_URI, null, (android.provider.MediaStore.Audio.Media.IS_MUSIC+" = ?"), new String[]{"1"}, null);
    JSONArray allMusic = new JSONArray();
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
        } catch (JSONException e) {
          e.printStackTrace();
        }
      } while (cursor.moveToNext());
    }
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

}
