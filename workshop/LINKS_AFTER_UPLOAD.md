# 发布后替换链接

上传完成后，把四个 Workshop 页面 ID 填入以下占位符，再重新上传对应 VDF：

```text
__MAIN_ID__    = 3793327386
__LANG_EN_ID__ = 3793327818
__LANG_JA_ID__ = 3793327897
__LANG_KO_ID__ = 3793328007

页面链接：

- 主 MOD：https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386
- English：https://steamcommunity.com/sharedfiles/filedetails/?id=3793327818
- 日本語：https://steamcommunity.com/sharedfiles/filedetails/?id=3793327897
- 한국어：https://steamcommunity.com/sharedfiles/filedetails/?id=3793328007
```

主 MOD 的描述会展示三个语言包链接；每个语言包的描述会展示主 MOD 链接。SteamCMD 首次成功上传后会把 `publishedfileid` 写回对应 VDF。
