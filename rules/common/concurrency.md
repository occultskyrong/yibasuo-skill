# 并发编程规范

> 基于《阿里巴巴 Java 开发手册》p3c 第五章"并发编程"。语言特定实现见 `rules/java/` 和 `rules/typescript/`。

## 线程池

- **禁止使用 `Executors` 创建线程池** — `newFixedThreadPool` / `newCachedThreadPool` 可能导致 OOM（队列无界或线程数无界）。必须用 `ThreadPoolExecutor` 显式指定核心线程数、最大线程数、队列容量
- **线程池必须命名** — `ThreadFactory` 设置 `setNamePrefix`，便于排查线程泄漏和死锁
- **线程池大小公式**：
  - CPU 密集型：`N_cpu + 1`
  - IO 密集型：`N_cpu * 2 * (1 + W/C)`（W=等待时间，C=计算时间）
  - 不硬编码，通过配置注入

## CompletableFuture

- **必须设置超时** — `orTimeout()` 或 `completeOnTimeout()`，防止无限等待
- **异常处理** — 必须用 `exceptionally()` / `handle()` 处理异常，禁止裸 `get()`
- **禁止阻塞** — 在异步链中禁止 `.get()` / `.join()` 阻塞调用线程

```java
// GOOD
CompletableFuture.supplyAsync(() -> fetchOrder(id), executor)
    .orTimeout(5, TimeUnit.SECONDS)
    .exceptionally(ex -> Order.empty());

// BAD — 无超时，无异常处理
orderFuture.get();
```

## ThreadLocal

- **必须在 `finally` 中 `remove`** — 防止线程复用时数据泄露（尤其线程池场景）
- **Virtual Thread 下注意** — 每个 Virtual Thread 都会创建 ThreadLocal 副本，大量 VT + 大 ThreadLocal = 内存爆炸

```java
private static final ThreadLocal<User> CURRENT_USER = new ThreadLocal<>();

try {
    CURRENT_USER.set(user);
    doSomething();
} finally {
    CURRENT_USER.remove(); // 必须
}
```

## 锁

- **优先使用 `ReentrantLock`** — 而非 `synchronized`。`ReentrantLock` 支持超时（`tryLock`）、公平锁、条件变量
- **Virtual Thread 下禁止 `synchronized`** — `synchronized` 会导致 Virtual Thread pinning 到平台线程，改用 `ReentrantLock`
- **锁粒度最小化** — 锁范围只包含需要互斥的代码，不锁整个方法
- **锁顺序一致** — 多把锁时，所有线程按相同顺序获取，防止死锁

## 并发集合

- **高并发 Map 用 `ConcurrentHashMap`** — 禁止 `HashMap` 做并发缓存
- **`ConcurrentHashMap` 的 key/value 禁止为 null** — 与 `HashMap` 不同，`put(null, ...)` 会 NPE
- **原子操作用 `putIfAbsent` / `computeIfAbsent`** — 禁止先 `get` 再 `put` 的检查-then-操作模式

```java
// GOOD
map.computeIfAbsent(key, k -> loadValue(k));

// BAD — 竞态条件
if (!map.containsKey(key)) {
    map.put(key, loadValue(key));
}
```

## volatile

- **适用场景**：状态标志位（`volatile boolean running`）、双重检查锁定（DCL）
- **不适用场景**：计数器（用 `AtomicInteger`）、复合操作（用 `synchronized` 或 `Lock`）
- **Virtual Thread 下无特殊影响** — volatile 语义在 VT 和平台线程上一致

## CountDownLatch / CyclicBarrier

- **CountDownLatch**：一次性等待，计数到 0 后不可重置。用于"等 N 个任务全部完成"
- **CyclicBarrier**：可重置，所有线程互相等待。用于"等 N 个线程同时到达某个点"
- **必须设置超时** — `await(timeout, unit)` 防止某个线程失败导致永久等待

## 通用规则

- **禁止 `Thread.stop()`** — 已废弃，会导致数据不一致
- **禁止 `Thread.sleep()` 在锁内** — 持有锁时 sleep 会延长锁持有时间
- **中断处理** — 捕获 `InterruptedException` 后必须恢复中断状态 `Thread.currentThread().interrupt()`
