# 伤员疗养差事

[English](README.md)

这是一个适用于 **《全面战争：三国》1.7.x** 的战役 MOD。永久伤残武将可以通过两项人物差事接受治疗。

本 MOD 对派系文化保持中立，不依赖华佗、幕府会议或黄巾议会机制。

## 差事规则

| 差事 | 费用 | 时间 | 结果 |
| --- | ---: | ---: | --- |
| 疗伤修养 | 800金 | 4回合 | 将配置中的永久重伤替换为“伤疤” |
| 寻访名医 | 4000金 | 1回合 | 将配置中的永久重伤替换为“伤疤” |

差事由伤员本人执行。疗程完成前召回人物会取消治疗，开始差事时支付的费用不予退还。

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
pack_root/             战役 Lua 脚本
rpfm_import/           可导入 RPFM 的 DB 与 Loc TSV
tests/                 本机 Lua 逻辑测试
docs/                  技术与兼容说明
```

## 当前测试状态

已通过离线检查：

- Lua 语法检查
- 4回合疗程计时
- 1回合疗程计时
- 提前召回取消治疗
- TSV 结构检查
- RPFM 二进制编译
- DB 与 Loc 二进制反向导出

尚未完成 Windows 游戏内 UI 与数据库依赖测试。

运行本机逻辑测试：

```bash
lua tests/test_treatment.lua pack_root/script/campaign/mod
```

## 使用 RPFM 构建

为 Three Kingdoms 新建 Mod 类型 Pack，导入 `pack_root/script`，再批量导入 `rpfm_import` 中的 TSV。TSV 已包含 RPFM metadata 行与正确的 Pack 内部路径。

疗程记录方式详见 [`docs/TECHNICAL_NOTES.md`](docs/TECHNICAL_NOTES.md)。

## 许可证

本项目使用 [MIT License](LICENSE)。

