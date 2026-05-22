# Changelog

## [2.8.6] - 2026-05-23

### Changed
- 需求澄清从"一次一个问题"改为"一次一个主题"，跨模块复杂需求允许多问
- 前端项目差异从语言适配中独立为 `##` 节

### Refactored
- 基础设施配置审查详情移至 `references/infrastructure-review.md`

## [2.8.5] - 2026-05-23

### Refactored
- 迁移规范从 Java 专属移至 `rules/common/patterns.md`，Java/TypeScript 各留引用

## [2.8.4] - 2026-05-22

### Added
- 数据库迁移规范：6步流程（编写→验证→提交→CI幂等→部署→记录）+ 幂等 + 回滚 + 大表策略 + 反模式

### Fixed
- 删除复活的 `trace-id.md` 僵尸文件

## [2.8.3] - 2026-05-22

### Refactored
- CodeGraph 集成详情抽出到 `references/codegraph.md`
- 示例恢复为表格格式

### Removed
- 清理僵尸文件（trace-id.md, meta.md）

## [2.8.2] - 2026-05-24

### Added
- `docs/index.html` — UI/UX Pro Max 生成的产品说明页

### Changed
- README 增加 Token 消耗警告（新功能 3.5x / Bug 修复 3x）
- README 移除"Claude 帮你装"链接行

## [2.8.1] - 2026-05-24

### Changed
- 生成说明文档改用 `ui-ux-pro-max` skill（替代 frontend-design）

## [2.8.0] - 2026-05-24

### Changed
- README 101→67 行重构：面向用户
- CLAUDE 150→90 行重构：面向开发者+AI
- 消除两文档重复：运行模式/方法论栈/6阶段详细表/提交前验证清单

## [2.7.7] - 2026-05-24

### Added
- 行为红线第5条：破坏性变更需确认+日志(.yibasuo-deletions.log)
- 行为红线第6条：前端校验不替代后端
- 前端项目差异：静态网站/管理后台分流
- git-workflow 独立技能

### Changed
- feat!: ApiResponse 合并 traceId+requestId
- SKILL.md 222→131 行重构
- 统一时间传输格式：yyyy-MM-dd HH:mm:ss.SSS
- 命名规范嵌入 rules

### Fixed
- 前端审查补全
- 全仓库脱敏

## [1.3.0] - 2026-05-12
### Changed
- 大幅精简 SKILL.md (193→50行)，遵循渐进式披露

## [1.2.0] - 2026-05-12
### Added
- 自动模式：触发词 `自动梭`、`全自动`、`一路梭到底`

## [1.1.0] - 2026-05-12
### Added
- `rules/web/static-website-checklist.md` 前端静态网站检查清单

## [1.0.1] - 2026-05-11
### Changed
- README 增加"一句话让 Claude 装"安装方式

## [1.0.0] - 2026-05-11
### Added
- 初始版本：一把梭 (yibasuo) 全流程开发技能
