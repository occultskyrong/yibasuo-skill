# Changelog

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
