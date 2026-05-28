# 前端项目差异

> SKILL.md 阶段 0-5 通用流程中，前端项目在各阶段的差异化行为。

## 静态网站项目

公司官网、产品主页、落地页：

| 阶段 | 行为 |
|------|------|
| 2 架构 | 页面结构 + 资源清单 |
| 4 审查 | typescript-reviewer + `static-website-checklist` + **a11y/WCAG 无障碍检查** + 多设备响应式断点 |
| 5 提交 | prettier+eslint + 备案检查 + **Lighthouse 性能基线** |

## 管理后台项目

含登录/权限/CRUD/数据看板（如 pts-admin）：

| 阶段 | 行为 |
|------|------|
| 0 需求 | + **头脑风暴**：竞品参考（2-3 个同类后台截图+分析）、用户角色矩阵、核心操作路径白板 |
| 2 架构 | **组件树 + 路由权限设计 + Token 存储策略（httpOnly cookie vs localStorage）+ 组件库选型（Ant Design/Element Plus）+ 表单校验策略（Zod/Yup schema）+ API 对接清单** |
| 3 TDD | RED→GREEN→IMPROVE + **异步状态覆盖**（loading/skeleton/empty/error 每个数据组件必测） |
| 4 审查 | typescript-reviewer + `static-website-checklist` + 权限矩阵验证 + 响应式断点 + **富文本 XSS（DOMPurify）** + **文件上传校验（类型/大小/路径遍历）** + **CSP 响应头验证** |
| 5 提交 | prettier+eslint + 备案检查 + `lighthouse` 性能基线 |

管理后台阶段 0 产出物增加：竞品分析卡片（2-3 款、含截图 URL + UX 优缺点）、用户角色表（谁、能看什么、能干什么）、关键页面线框图描述。
