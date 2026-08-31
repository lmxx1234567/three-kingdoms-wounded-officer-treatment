# GitHub 提交与发布建议

## 建议提交

- `pack_root/`、`rpfm_import/`、`localization/`：源码和可复现的导入数据
- `tests/`、`docs/`、`LICENSE`：测试、技术说明和许可证
- `dist/`：当前已经编译好的 Pack；这些文件很小，普通 Git 足够
- `workshop/preview/*.jpg`：实际使用的 Workshop 预览图（每张小于 1 MB）
- `workshop/vdf/*.vdf.template`：不含本机路径的上传模板
- `workshop/README.zh-CN.md`、`workshop/PUBLISH.zh-CN.md`：发布和维护说明

## 不建议提交

- `workshop/vdf/*.vdf`：包含本机绝对路径和已发布项目 ID，适合只保留在发布机
- `workshop/preview/*-base.png` 和 PNG 中间图：体积较大，且不是 Steam 实际上传文件
- `workshop/content/`：它只是 `dist/` 的上传镜像；如需要保留，维护时应确保不与 `dist/` 版本漂移

## 是否需要 Git LFS

目前不需要。最大的 Pack 约 11 KB，Workshop JPG 约 350–400 KB，均远低于普通 Git 管理的合理范围。只有未来加入几十 MB 以上的音频、视频、模型或大型二进制资源时，才建议使用 Git LFS，或将发行包放进 GitHub Releases，而不是反复写入 Git 历史。
