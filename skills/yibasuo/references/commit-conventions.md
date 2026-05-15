# 提交与版本标签规范

遵循 **SemVer v2.0** + **Conventional Commits**。

## Commit 类型

| 变更类型 | type | 示例 |
|---------|------|------|
| 破坏性变更 | `feat!:` `fix!:` | `feat!: 重构ApiResponse code类型` |
| 新功能 | `feat:` | `feat: 增加用户导出功能` |
| Bug 修复 | `fix:` | `fix: 修复登录超时无提示` |
| 文档/杂项 | `docs:` `chore:` | `docs: 更新README安装说明` |
| 重构/性能 | `refactor:` `perf:` | `refactor: 提取公共校验方法` |
| 测试/CI | `test:` `ci:` | `test: 补充边界条件用例` |

破坏性变更必须在标题加 `!`（如 `feat!:`），或在 body 写 `BREAKING CHANGE:`。

## SemVer Tag

| commit type | 版本升级 |
|------------|:--:|
| `feat!:` `fix!:` | **MAJOR** `1.0.0→2.0.0` |
| `feat:` | **MINOR** `1.0.0→1.1.0` |
| `fix:` | **PATCH** `1.0.0→1.0.1` |
| `docs:` `chore:` `refactor:` `test:` `ci:` `perf:` | 不创建 tag |

**标签铁律**：`git push --tags` 后永不 `tag -d` 重打，发现错误发新版本。

创建流程：
1. `git tag --sort=-v:refname | head -1` 检测当前最新 tag
2. 根据 commit type 确定 MAJOR/MINOR/PATCH
3. 询问用户确认后 `git tag -a vX.Y.Z -m "vX.Y.Z — <summary>"`
