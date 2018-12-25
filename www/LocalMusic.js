var exec = require('cordova/exec');

function LocalMusic() {}

LocalMusic.prototype.getMusicList = function(
  successCallback,
  errorCallback,
  json
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'getMusicList', [json]);
};

LocalMusic.prototype.playOrPause = function(
  successCallback,
  errorCallback,
  index,
  isPlaying
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'playOrPause', [index,isPlaying]);
};

LocalMusic.prototype.nextSong = function(
  successCallback,
  errorCallback,
  json
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'nextSong', [json]);
};

LocalMusic.prototype.prevSong = function(
  successCallback,
  errorCallback,
  json
) {
  exec(successCallback, errorCallback, 'LocalMusic', 'prevSong', [json]);
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
