---
name: git-workflow
description: "Git 提交操作规范 — 强制执行分支命名、Conventional Commits、提交前验证、SemVer 标签创建、受保护分支保护。所有项目执行 git commit/push 时必须使用。触发词：提交、commit、push、推送、创建分支、切分支、merge、合并、tag。"
metadata:
  version: "1.0.1"
---

# Git 操作规范

> 分支命名 → 提交前验证 → Conventional Commit → SemVer Tag → Push

## 铁律

1. **禁止直接在 staging/master/production 分支提交** — 所有改动走 feature 分支
2. **提交前验证必须通过** — 格式化 + 构建 + 测试，任何一项失败不得提交
3. **标签不可变** — 标签推送后永不 `tag -d` 重打

## 一、分支命名

格式：`<type>/YYMMDD_short-desc`

| 元素 | 规则 | 示例 |
|------|------|------|
| type | feat/fix/hotfix/refactor/docs/chore | `feat` |
| YYMMDD | 6 位日期 | `260513` |
| desc | kebab-case，小写英文+连字符，≤20 字符 | `add-login-page` |

示例：`feat/260513_add-user-profile`、`fix/260513_null-pointer`、`hotfix/260513_payment-failure`

创建分支：
```bash
git status --short
git fetch origin
git switch <base-branch>         # production 或 staging 或 master
git merge --ff-only origin/<base-branch>
git switch -c feat/YYMMDD_desc
```

工作区不干净、远端不存在或无法 fast-forward 时暂停，不得自动 rebase、stash 或强制覆盖。

## 二、受保护分支

禁止在以下分支直接 commit：
- `production` / `prod` — 生产环境
- `staging` — 测试环境
- `master` — 主分支

所有改动必须通过 feature 分支 → PR/Merge Request 合并。

## 三、提交前验证

按技术栈执行，任何一项失败不得提交：

**Java 项目：**
```bash
mvn pmd:check          # 1. 格式检查（p3c），失败则修复后重跑
mvn test                # 2. 测试，失败则修复后重跑
mvn package -DskipTests # 3. 编译验证
```

**Node.js / 前端项目：**
```bash
<pkg> prettier --write "src/**/*.{ts,tsx,js,jsx,css,scss}"  # 1. 格式化
<pkg> eslint --fix "src/**/*.{ts,tsx,js,jsx}"               # 2. Lint
<pkg> build                                                  # 3. 构建，缺 build script 警告并暂停
<pkg> test                                                   # 4. 测试
```

`<pkg>` 根据锁文件自动检测：`pnpm-lock.yaml` → pnpm > `yarn.lock` → yarn > `package-lock.json` → npm

## 四、Conventional Commits

格式：`<type>[!]: <description>`

| 变更类型 | type | 示例 |
|---------|------|------|
| 破坏性变更 | `feat!:` `fix!:` | `feat!: 重构ApiResponse` |
| 新功能 | `feat:` | `feat: 增加用户导出功能` |
| Bug 修复 | `fix:` | `fix: 修复登录超时无提示` |
| 文档 | `docs:` | `docs: 更新README` |
| 重构 | `refactor:` | `refactor: 提取公共校验` |
| 杂项 | `chore:` | `chore: 更新依赖` |
| 测试 | `test:` | `test: 补充边界用例` |
| CI | `ci:` | `ci: 更新部署脚本` |
| 性能 | `perf:` | `perf: 优化查询性能` |

破坏性变更在标题加 `!`，或在 body 写 `BREAKING CHANGE:`

```bash
git add <files>                           # 精确提交，禁止 git add -A / git add .
git commit -m "feat: 增加用户导出功能"     # Conventional Commits
```

## 五、SemVer Tag

| commit type | 版本升级 |
|------------|:--:|
| `feat!:` `fix!:` | **MAJOR** `1.0.0→2.0.0` |
| `feat:` | **MINOR** `1.0.0→1.1.0` |
| `fix:` | **PATCH** `1.0.0→1.0.1` |
| `docs:` `chore:` `refactor:` `test:` `ci:` `perf:` | 不创建 tag |

```bash
# 检测当前最新 tag
git tag --sort=-v:refname | head -1

# 根据 commit type 确定版本级别
# 用户确认后创建注释标签
git tag -a vX.Y.Z -m "vX.Y.Z — 简短描述"
```

**标签不可变**：已推送的 tag 永不 `tag -d` 重打，发现错误发新版本。

## 六、Push 流程

```bash
git push origin <branch>           # 仅推送已确认的目标分支
git push origin vX.Y.Z             # 仅在用户另行确认标签后推送当前标签
```

- 首次推送 `git push -u origin <branch>`
- 分支与标签是两个独立外部写入动作，分别展示目标并确认；禁止 `push --all` 和无范围的 `push --tags`
- 若需要 PR，创建 Pull Request / Merge Request
- 分支完成后，询问合并策略（merge/变基/压缩）

## 七、异常处理

| 场景 | 处理 |
|------|------|
| 分支名冲突 | 追加 `-2` / `-3` 后缀 |
| 格式化失败 | 展示错误，修复后重跑 |
| 构建失败 | 暂停，等用户修复 |
| 测试失败 | 暂停，等用户修复 |
| tag 已存在 | 永远不重打，提示当前版本号并询问是否发新版本 |
| 非 git 仓库 | 警告并暂停 |

## 八、反模式

- **不要 `git add -A` / `git add .`** — 精确添加，防止误提交敏感文件
- **不要 `--no-verify`** — 跳过验证等于跳过安全检查
- **不要在保护分支直接提交** — 必须走 feature 分支
- **不要重打已推送的 tag** — 发新版本
- **不要自动 rebase/stash/force push** — 工作区或历史不满足前置条件时暂停
- **不要提交 `.env` / `credentials.*`** — 遵循项目 .gitignore
