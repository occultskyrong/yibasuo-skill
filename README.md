# 一把梭 (yibasuo) — Claude Code 全流程开发 Skill

> 需求 → 规划 → 架构 → TDD → 审查 → 提交，一条龙。

## 安装

### 方式一：一行命令

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USER/yibasuo-skill/main/install.sh | bash
```

### 方式二：Claude 帮你装

在 Claude Code 里说：

> 从 https://github.com/YOUR_USER/yibasuo-skill.git clone 到 /tmp，执行 install.sh，完成后删掉临时目录

### 方式三：手动

```bash
git clone https://github.com/YOUR_USER/yibasuo-skill.git /tmp/yibasuo-skill
cd /tmp/yibasuo-skill
./install.sh
rm -rf /tmp/yibasuo-skill
```

重启 Claude Code 后说 **"一把梭"** 即可触发。

## 更新

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USER/yibasuo-skill/main/install.sh | bash -s -- --force
```

查看已安装版本：`cat ~/.claude/skills/yibasuo/.installed-version`

## 运行模式

**默认自动**：阶段 0-4 自动执行，仅提交前确认。

| 模式 | 触发词 | 阶段 0 | 阶段 1-4 | 阶段 5 |
|------|--------|--------|---------|--------|
| 自动（默认） | `一把梭` `全流程` `梭哈` | 确认 | 连续 | 确认 |
| 交互（显式） | `一步步梭` `交互梭` `确认梭` | 确认 | 每阶段确认 | 确认 |

中途说"停一下"切交互，说"继续梭"回自动。

## 流程

```
0.需求确认 → 1.规划 → 2.架构 → 3.TDD → 4.审查 → 5.提交（格式→构建→commit）
```

| 技术栈 | 规范 + 工具链 |
|--------|------------|
| Java / Spring Boot | 阿里巴巴 p3c + JUnit5 + AssertJ + Mockito |
| Node.js / NestJS | Vitest/Jest + supertest + pino |
| Vue / React | Composition API / Hooks + Playwright + Prettier |

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 / 重构 | 完整 6 阶段 |
| Bug 修复 | 跳过 1-2，直接 TDD + 审查 + 提交 |
| 单文件小改 | 不建议用 |

## 依赖

**Agent**（Claude Code 内置）：planner / architect / tdd-guide / java-reviewer / typescript-reviewer / security-reviewer

**Rules**（随 install.sh 自动安装）：`common` / `java` / `typescript` / `web`
