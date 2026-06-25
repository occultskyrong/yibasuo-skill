# 并发编程规范

> 语言无关的并发原则。Java 特定实现（线程池/CompletableFuture/ThreadLocal/锁/并发集合/virtual thread）见 `rules/java/concurrency.md`，TypeScript/Node.js 并发（Promise 并发控制、EventLoop 防阻塞、Worker Threads）见 `rules/typescript/patterns.md`。

## 核心原则

### 线程安全

- **共享可变状态必须同步** — 多线程访问的可变状态，必须用锁、CAS 或不可变对象保护
- **优先不可变** — 不可变对象天然线程安全，避免同步开销（见 [coding-style.md](./coding-style.md) 不可变性）
- **最小化共享** — 能不共享就不共享，用线程局部存储或方法参数传递

### 锁

- **锁粒度最小化** — 锁范围只包含需要互斥的代码，不锁整个方法
- **锁顺序一致** — 多把锁时，所有线程按相同顺序获取，防止死锁
- **优先高级同步原语** — 语言提供的并发原语（Java `ReentrantLock`、JS `Atomics`）优于自旋或自实现锁
- **锁释放必须在 `finally`** — 异常时也要释放，防止死锁

### 超时

- **所有等待必须设超时** — 锁等待、Future 获取、条件变量 await，禁止无限期阻塞
- **外部调用必须设超时** — 网络/DB/下游 API 调用，防止线程被永久挂起

### 原子操作

- **复合操作必须原子** — "检查-然后-操作"（check-then-act）模式有竞态，必须用原子操作（`putIfAbsent`/`computeIfAbsent`/CAS）
- **禁止先读后写的检查-操作模式** — `if (!contains) put` 在并发下会漏判

## 异步与并发

- **异步链必须有异常处理** — Promise/CompletableFuture 链必须捕获异常，禁止裸 `get()`/裸 `.then()` 无 `.catch()`
- **异步链必须设超时** — 防止无限等待（Java `orTimeout()`、JS `Promise.race(timeout)`）
- **异步链中禁止阻塞** — 不在异步链里调用阻塞方法卡住调用线程

## 常见陷阱

| 陷阱 | 后果 | 对策 |
| ---- | ---- | ---- |
| 检查-then-操作竞态 | 双重写入、覆盖 | 用原子操作 |
| 锁未在 finally 释放 | 异常时死锁 | try-finally 包裹 |
| 无超时的等待 | 线程永久阻塞 | 所有 await 设超时 |
| 锁顺序不一致 | 死锁 | 全局统一锁顺序 |
| 共享可变状态无同步 | 数据竞争、脏读 | 同步或改不可变 |
| 线程池无界队列/线程 | OOM | 显式限定容量 |

## 审查清单

- [ ] 共享可变状态已同步或改为不可变
- [ ] 锁粒度最小，锁释放在 `finally`
- [ ] 多锁顺序全局一致
- [ ] 所有等待和外部调用设超时
- [ ] 复合操作用原子原语，无 check-then-act
- [ ] 异步链有异常处理和超时
