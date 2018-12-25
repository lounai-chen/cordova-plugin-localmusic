### 前言  
这是一个可以获取手机本地音乐文件的cordova插件，可以后台播放，上一曲、下一曲
### 参考
https://github.com/dongqishu/cordova-plugin-localmusic
https://github.com/jasminpethani/cordova-plugin-musicplayer   


### 作用  
扫描本地的音乐文件，有三个方法，分别是：1. 获取所有音乐列表。 2.获取专辑列表。 3.获取歌手列表。

### 支持环境  
IOS   
Android

### 使用示例  

```
//获取所有音乐列表
function getMusicList(){
    LocalMusic.getMusicList(function(s){  
        alert(JSON.stringify(s));
     },function(r){}, null);
}
```

### 注意事项
安卓版本需要与插件cordova-plugin-android-permissions配合使用
