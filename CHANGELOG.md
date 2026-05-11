# Changelog

## [1.2.0] - 2026-05-12

### Added

- **自动模式**：阶段 0-4 不暂停，一路走到底，仅提交前确认
  - 触发词：`自动梭`、`全自动`、`一路梭到底`、`不问我`
  - 模式切换：中途可说"自动走完剩下的"或"停一下"
- CRITICAL/HIGH 审查问题在自动模式中也拦截

## [1.1.0] - 2026-05-12

### Added

- `rules/web/static-website-checklist.md` — 前端静态网站检查清单
  - 安全（target=_blank, https）
  - CDN 国内化（Google Fonts, cdnjs, jsdelivr 替代方案）
  - 备案信息（ICP + 公安备案图标）
  - SEO & 多语言（hreflang, canonical, OG/Twitter 标签）
  - 模板残留、冗余文件检查
  - 域名 & 品牌一致性

### Changed

- SKILL.md requires 增加 `rules/web/`
- README 增加 web rules 说明

## [1.0.1] - 2026-05-11

### Changed

- README 增加"一句话让 Claude 装"安装方式
- 修正远端地址为 git.mypacelab.com

## [1.0.0] - 2026-05-11

### Added

- 初始版本：一把梭 (yibasuo) 全流程开发技能
- 6 阶段工作流：需求确认 → 规划 → 架构 → TDD 实现 → 审查 → 提交
- rules/common/ 通用编码规范（11 份）
- rules/java/ Java/Spring Boot 规范（6 份，含 logging.md）
- rules/typescript/ TypeScript/NestJS 规范（6 份，含 logging.md）
- install.sh 一键安装脚本（支持 --force 覆盖）
- 阶段门禁机制：每阶段暂停等待用户确认
- 内置 Agent 编排：planner / architect / tdd-guide / code-reviewer / security-reviewer
