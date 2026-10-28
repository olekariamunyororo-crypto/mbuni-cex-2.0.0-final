import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

// Query logging prints every statement (including bound params such as emails)
// and slows hot paths. It is opt-in: PRISMA_LOG_QUERIES=1
const log: ('query' | 'warn' | 'error')[] =
  process.env.PRISMA_LOG_QUERIES === '1'
    ? ['query', 'warn', 'error']
    : process.env.NODE_ENV === 'production'
      ? ['error']
      : ['warn', 'error']

export const db = globalForPrisma.prisma ?? new PrismaClient({ log })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db
