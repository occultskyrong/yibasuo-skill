---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.ts"
  - "**/*.js"
  - "**/package.json"
---

# 前端安全规范

> 通用安全规范见 [common/security.md](../common/security.md)（OWASP Top 10、输入校验、注入防护、密钥管理）。前端特有安全要点集中于此文件；CDN/静态站点安全见 [static-website-checklist.md](./static-website-checklist.md)；代码级安全规则（.then() 链、回调嵌套）见 [eslint-checklist.md](./eslint-checklist.md)。

## XSS 防护

- **React/Vue 默认转义**：JSX 和 Vue 模板自动转义表达式输出，但需警惕 `dangerouslySetInnerHTML`（React）/ `v-html`（Vue）等显式绕过
- **富文本**：用 DOMPurify 白名单过滤，禁止直接渲染用户输入的 HTML
- **URL 参数**：`href={userInput}` 需校验 `javascript:` / `data:` 协议，防止 XSS via href

## Token 存储与 CSRF

- **JWT 存储位置**：`localStorage` 方便但受 XSS 影响；`httpOnly` cookie 受 CSRF 影响。按威胁模型选择
- **与 CSRF 的关系**：
  - 若 token 存 `httpOnly` cookie → 必须启用 CSRF 防护（见 [common/security.md](../common/security.md)）
  - 若 token 存 `localStorage` + `Authorization: Bearer` 头 → 无需 CSRF（浏览器不会自动附加）
- **logout 清理**：禁用用户/密码修改/密钥轮换时立即清 token

## Content-Security-Policy (CSP)

- 生产环境配置 CSP 响应头，限制脚本/样式/图片来源
- 禁止 `unsafe-inline` + `unsafe-eval`（除非显式评估后豁免）
- 静态站点 CSP 见 [static-website-checklist.md](./static-website-checklist.md)

## 依赖安全

- 定期 `npm audit` / `yarn audit` / `pnpm audit`
- CI 集成 CVE 扫描，高危漏洞阻断合并
- 锁定版本：`package-lock.json` / `pnpm-lock.yaml` 必须提交

## 审查清单

- [ ] 无 `dangerouslySetInnerHTML` / `v-html` 渲染未过滤内容
- [ ] URL 参数已校验协议（禁 `javascript:` / `data:`）
- [ ] Token 存储方式已评估 XSS/CSRF 权衡
- [ ] 生产配置 CSP 响应头
- [ ] 依赖审计通过，lockfile 已提交
