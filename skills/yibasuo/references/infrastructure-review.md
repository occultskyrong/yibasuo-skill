# 基础设施配置审查

阶段 4 第 4 步，由主会话执行（agent 不负责）。

## 检查清单

- 扫描 `src/config/` 或 `src/main/resources/` 目录，识别同概念重复配置文件
- NestJS 项目：检查 `nest-cli.json` 的 `assets` 是否覆盖 `src/config/` 下所有 JSON 文件
- 检查 `.env.example` 变量与代码中 `process.env.*` 引用是否一一对应
- 检查是否存在硬编码的 API Key/Token/Password
- Java 项目：对比 `pom.xml` 依赖与 infra 模板（`references/java-templates.md`），多出来的每个依赖必须有明确的业务理由。禁止无理由引入额外依赖、禁止同时引入功能重叠的依赖（如多个 JSON 库/HTTP 客户端）
