import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: false,
    environment: 'node',
    include: ['src/**/*.rules.test.ts', 'test/**/*.rules.test.ts'],
    testTimeout: 30_000,
    hookTimeout: 30_000,
    // Rules tests pin tới 1 emulator instance (firestore port 9999 + storage
    // 9199). fileParallelism:false → chạy TUẦN TỰ từng file (tránh nhiều
    // worker tranh cùng emulator + clearFirestore race). pool:forks (KHÔNG
    // singleFork) → mỗi file 1 child process riêng, RAM giải phóng sau mỗi
    // file → tránh OOM tích luỹ khi load @firebase/rules-unit-testing nhiều lần.
    pool: 'forks',
    fileParallelism: false,
  },
});
