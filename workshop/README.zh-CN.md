# Steam 创意工坊发布包

本目录已经准备好首个 Workshop 项目的上传材料。

## 已准备

- `content/main/wounded_officer_treatment_assignments.pack`：简体中文主 Pack
- `preview/wounded-officer-treatment-preview.png`：主 MOD 预览图（含中英功能说明）
- `preview/wounded-officer-treatment-preview-en.png`：英语语言包预览图
- `preview/wounded-officer-treatment-preview-ja.png`：日语语言包预览图
- `preview/wounded-officer-treatment-preview-ko.png`：韩语语言包预览图
- `vdf/workshopitem.main.vdf.template`：SteamCMD 上传配置模板
- `PUBLISH.zh-CN.md`：发布页文案、标签和发布前检查清单

VDF 语法、路径转义和描述排版规则见 [`docs/STEAM_WORKSHOP_VDF.md`](../docs/STEAM_WORKSHOP_VDF.md)。本项目的 Workshop 描述使用单行 VDF + Steam BBCode，不使用 `\n` 或 `\\n` 换行。

英语、日语、韩语语言包没有放进主项目的 content 目录，因为它们会覆盖同一组本地化 key。建议先发布简体中文主项目，确认稳定后再分别发布语言包，或在主项目说明中注明语言包下载方式。

## 上传

1. 将 `vdf/workshopitem.main.vdf.template` 复制为 `vdf/workshopitem.main.vdf`。
2. 把其中的 `__ABSOLUTE_WORKSHOP_DIR__` 替换为本仓库 `workshop` 目录的 Windows 绝对路径，并使用双反斜杠。
3. 登录 SteamCMD 后执行：

```text
workshop_build_item C:\\path\\to\\this\\repo\\workshop\\vdf\\workshopitem.main.vdf
```

首次上传保持 `publishedfileid` 为 `0`；SteamCMD 成功创建项目后会回写 ID。以后更新同一个 VDF 即可更新原项目。
