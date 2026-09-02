# 伤员疗养差事

[English](README.md)

## Steam 创意工坊

| 项目 | Workshop 链接 |
| --- | --- |
| 主 MOD | [伤员疗养差事](https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386) |
| 英语语言包 | [English Translation](https://steamcommunity.com/sharedfiles/filedetails/?id=3793327818) |
| 日语语言包 | [日本語翻訳](https://steamcommunity.com/sharedfiles/filedetails/?id=3793327897) |
| 韩语语言包 | [한국어 번역](https://steamcommunity.com/sharedfiles/filedetails/?id=3793328007) |

三个语言包都依赖主 MOD。请先订阅主 MOD，再启用其中一个语言包。

这是一个适用于 **《全面战争：三国》1.7.x** 的战役 MOD。永久伤残武将可以通过两项人物差事或华佗来访随机事件接受治疗。

本 MOD 对派系文化保持中立。华佗事件不要求华佗本人已加入派系，也不依赖幕府会议或黄巾议会机制。主 Pack 默认使用简体中文，英语、日语、韩语分别提供独立语言包。

## 华佗来访随机事件

当永久伤残人物所在的军队**驻扎在城镇中且本回合正在补员**时，每回合有10%概率遇到游历至此的华佗。事件会从当前城镇内符合条件的人物中随机选择一人。可以支付2000金立即治疗，或婉拒而不产生花费。

若原版唯一随从“华佗”尚未被任何派系持有，可支付1000金招揽华佗；若原版唯一附件《青囊书》尚未被持有，也可以将华佗下狱并查取医书，代价是当前派系所有人物满意度降低10点、持续5回合。这两个彩蛋选项都不会同时治疗伤员。

华佗或《青囊书》已在其他派系时，华佗仍可能游历至此并提供治疗，只隐藏对应的唯一物品选项。付费选项也会按当前库存显示：不足2000金时不显示治疗，不足1000金时不显示招揽；若没有任何可执行选项则不触发事件。当前派系一旦成功招揽或查取医书，今后的同类随机事件会改为没有彩蛋选项的“名医来访”。事件触发后有8回合冷却；概率、费用和冷却均可在 `pack_root/script/campaign/mod/a_wota_config.lua` 中调整。

## 差事规则

| 差事 | 费用 | 时间 | 结果 |
| --- | ---: | ---: | --- |
| 疗伤修养（本地） | 免费 | 4回合 | 将配置中的永久重伤替换为“伤疤” |
| 寻访名医 | 4000金 | 1回合 | 将配置中的永久重伤替换为“伤疤” |

差事由伤员本人执行。本地修养免费；选择外国名医治疗需将人物派往外国差事，并支付4000金。疗程完成前召回人物会取消治疗，名医费用不予退还。两项差事的召回都不再产生额外回合开销。

默认情况下，一次完成的疗程会移除该人物身上所有已配置的严重伤残，并添加：

```text
3k_main_ceo_trait_physical_scarred
```

默认支持的原版伤残 CEO：

```text
3k_main_ceo_trait_physical_maimed_arm
3k_main_ceo_trait_physical_maimed_leg
3k_main_ceo_trait_physical_one-eyed
3k_main_ceo_trait_physical_blind
```

## 安装

1. 下载 [`dist/wounded_officer_treatment_assignments.pack`](dist/wounded_officer_treatment_assignments.pack)。
2. 将文件复制到游戏的 `data` 目录。
3. 在《全面战争》启动器中启用。
4. 建议排在 MTU、TUP、WDG2 之后。
5. 首次测试前备份存档。

## 语言包

主 Pack 默认内置**简体中文**。使用其他语言时，在主 MOD 后面启用一个对应语言包：

| 语言 | Pack |
| --- | --- |
| 简体中文 | 已包含在 `wounded_officer_treatment_assignments.pack` 中 |
| 英语 | [`wota_translation_en.pack`](dist/localization/wota_translation_en.pack) |
| 日语 | [`wota_translation_ja.pack`](dist/localization/wota_translation_ja.pack) |
| 韩语 | [`wota_translation_ko.pack`](dist/localization/wota_translation_ko.pack) |

加载顺序示例：

```text
wounded_officer_treatment_assignments.pack
wota_translation_ja.pack
```

不要同时启用多个翻译包，因为它们会有意覆盖同一组本地化 key。

## 兼容性

所有自定义记录均使用 `wota_` 前缀，不覆盖原版、MTU、TUP 或 WDG2 的数据库行。人物包沿用原版伤残 CEO 时可以直接使用。

若大型 MOD 创建了自己的伤残 CEO，需要在以下两个位置同时添加 key：

- `pack_root/script/campaign/mod/a_wota_config.lua`
- `rpfm_import/character_assignment_constraint_set_required_ceos_tables__wota_wounds.tsv`

Lua 配置负责允许治疗；DB 条目负责让对应伤员看到差事。

当前 Pack 包含主战役和已配置 DLC 的 campaign group 条目，详见 [`docs/COMPATIBILITY_CONFIG.tsv`](docs/COMPATIBILITY_CONFIG.tsv)。在 Windows 实机测试时，应使用本机 `database.pack` 核对这些引用。

## 项目结构

```text
dist/                  已编译的 Mod 类型 PFH5 Pack
dist/localization/     可选的英语、日语、韩语 Loc Pack
localization/          翻译源 TSV
pack_root/             战役 Lua 脚本
rpfm_import/           可导入 RPFM 的 DB 与 Loc TSV
tests/                 本机 Lua 逻辑测试
docs/                  技术与兼容说明
workshop/              Workshop 预览图、上传内容、VDF 模板和发布说明
```

## 当前测试状态

已通过离线检查：

- Lua 语法检查
- 4回合疗程计时
- 1回合疗程计时
- 提前召回取消治疗
- 华佗/名医事件的城镇补员筛选、动态唯一物品选项、费用和冷却
- 招揽与查抄终局状态、全地图唯一CEO复核及5回合满意度惩罚
- TSV 结构检查
- RPFM 二进制编译
- DB 与 Loc 二进制反向导出
- 英语、日语、韩语 Loc Pack 二进制反向导出

尚未完成 Windows 游戏内 UI 与数据库依赖测试。

运行本机逻辑测试：

```bash
lua tests/test_treatment.lua pack_root/script/campaign/mod
```

## 使用 RPFM 构建

为 Three Kingdoms 新建 Mod 类型 Pack，导入 `pack_root/script`，再批量导入 `rpfm_import` 中的 TSV。TSV 已包含 RPFM metadata 行与正确的 Pack 内部路径。使用 Node.js 20 和 RPFM 服务端自动构建时运行 `node --experimental-websocket tools/build-rpfm.mjs`。

疗程记录方式详见 [`docs/TECHNICAL_NOTES.md`](docs/TECHNICAL_NOTES.md)。

## 许可证

本项目使用 [MIT License](LICENSE)。
