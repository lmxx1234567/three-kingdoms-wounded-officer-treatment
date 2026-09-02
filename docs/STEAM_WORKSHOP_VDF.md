# Steam Workshop VDF 规则

本项目通过 SteamCMD 的 `workshop_build_item` 发布 Steam Workshop 项目。VDF 是 Valve KeyValues 文本格式；其中 `description` 的内容还会经过 Steam Workshop 的 BBCode 解析。

## 基本结构

```vdf
"workshopitem"
{
    "appid"           "779340"
    "publishedfileid" "3793327386"
    "contentfolder"   "C:\\Mods\\WoundedOfficerTreatment"
    "previewfile"     "C:\\Mods\\WoundedOfficerTreatment\\preview.jpg"
    "visibility"      "0"
    "title"           "标题"
    "description"     "描述"
    "changenote"      "更新说明"
    "tags"            "mod;campaign;ui"
}
```

- 新建项目时，`publishedfileid` 使用 `0`；更新项目时使用原有 Workshop ID。
- `contentfolder` 是实际上传目录，`previewfile` 是单独的预览图文件。
- Windows 路径中的反斜杠需要写成双反斜杠，例如 `C:\\Mods\\MyMod`。
- 字符串用双引号包围；描述中尽量避免使用英文双引号，以免破坏 KeyValues 解析。
- `description` 应保持为一个完整的单行字符串，不要直接写成跨行的引号字符串。

## 描述排版

Steam Workshop 描述不应依赖 `\n` 或 `\\n` 换行。不同的解析环节可能把它显示成字面量 `\\n`，因此本项目统一使用单行 VDF，并用 Steam BBCode 排版：

```text
[h1]主标题[/h1][h2]章节标题[/h2]正文
[h3]小标题[/h3]正文
[list][*]项目一[*]项目二[/list]
[b]粗体[/b]
[url=https://example.com]链接文字[/url]
```

常用标签包括：

- `[h1]...[/h1]`、`[h2]...[/h2]`、`[h3]...[/h3]`：标题层级
- `[b]...[/b]`：粗体
- `[list][*]...[/list]`：项目列表
- `[url=地址]文字[/url]`：链接

标题和列表标签本身负责视觉分隔；不要在 VDF 描述中插入实际换行，也不要把 `\n` 当作可靠的 Workshop 换行语法。

## 发布前检查

```sh
rg -n '\\\\n|\\n' workshop/vdf
```

上面的检查应无输出。发布前还应确认：

1. `publishedfileid` 与目标 Workshop 条目一致。
2. `contentfolder` 中的 Pack 是当前构建产物。
3. 主 Pack 与上传镜像的 SHA-256 校验和一致。
4. SteamCMD 输出 `Committing update...Success.`。
5. 发布后从 Workshop 页面检查描述，确认没有显示 `\\n`。

## 参考

- [Steam Workshop Implementation Guide](https://partner.steamgames.com/doc/features/workshop/implementation)
- [ValveResourceFormat/ValveKeyValue](https://github.com/ValveResourceFormat/ValveKeyValue)
