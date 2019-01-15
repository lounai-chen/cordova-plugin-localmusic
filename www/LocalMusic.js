var exec = require('cordova/exec');

function LocalMusic() {}

LocalMusic.prototype.getMusicList = function(
  successCallback,
  errorCallback,
  json
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'getMusicList', [json]);
};
// 播放 、 暂停
LocalMusic.prototype.playOrPause = function(
  successCallback,
  errorCallback,
  id,
  isPlaying,
  musicType,
  typeId
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'playOrPause', [id,isPlaying,musicType,typeId]);
};
 //下一曲
LocalMusic.prototype.nextSong = function(
  successCallback,
  errorCallback,
  musicType,
  typeId
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'nextSong', [musicType,typeId]);
};
//上一曲
LocalMusic.prototype.prevSong = function(
  successCallback,
  errorCallback,
  musicType,
  typeId
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'prevSong', [musicType,typeId]);
};

//0顺序播放 1随机。2循环。
LocalMusic.prototype.setSelectedSegmentIndexs = function(
  successCallback,
  errorCallback,
  json
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'setSelectedSegmentIndexs', [json]);
};
// 快进 or 后退
LocalMusic.prototype.speedOrBack = function(
  successCallback,
  errorCallback,
  json
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'speedOrBack', [json]);
};
// 开启媒体按键监听 android
LocalMusic.prototype.start = function(
  successCallback,
  errorCallback,
  json
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'start', [json]);
};
LocalMusic.prototype.getAlbums = function(
  successCallback,
  errorCallback,
  json
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'getAlbums', [json]);
};

LocalMusic.prototype.getArtists = function(
  successCallback,
  errorCallback,
  json
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'getArtists', [json]);
};

module.exports = new LocalMusic();
