# NestJS Messaging Patterns

Messaging patterns for NestJS 11.x covering BullMQ, RabbitMQ, and Kafka.

## Platform Selection Guide

| Aspect | BullMQ (Redis) | RabbitMQ (AMQP) | Kafka (Streaming) |
|--------|----------------|-----------------|-------------------|
| **Best For** | Background jobs, delayed tasks | Reliable messaging, RPC, complex routing | High-throughput streaming, analytics |
| **NestJS Integration** | Excellent (`@nestjs/bullmq`) | Good (`@golevelup/nestjs-rabbitmq`) | Solid (`kafkajs`) |
| **Throughput** | ~10k-100k jobs/sec | High (needs tuning) | Millions/sec |
| **Complexity** | Low | Medium | High |
| **Use When** | You already have Redis, need job scheduling | Cross-language services, guaranteed delivery | Event sourcing, 1M+ events/day |

## BullMQ — Background Job Processing

### Queue Module

```typescript
/**
 * BullMQ Queue Module
 *
 * Enterprise-grade background job processing with:
 * - Redis-backed persistent queues
 * - Job retries with exponential backoff
 * - Job prioritization and scheduling
 * - Bull Board dashboard for monitoring
 * - Dead letter queue for failed jobs
 */

import { Module, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { BullModule } from '@nestjs/bullmq';
import { BullBoardModule } from '@bull-board/nestjs';
import { BullMQAdapter } from '@bull-board/api/bullMQAdapter';
import { ExpressAdapter } from '@bull-board/express';

import { QueueConfigurationService } from './configs/queue-configuration.service';
import { QueueOrchestratorService } from './services/queue-orchestrator.service';

// Queue names as constants
export const QUEUE_NAMES = {
  EMAIL: 'email',
  NOTIFICATIONS: 'notifications',
  REPORTS: 'reports',
  DATA_SYNC: 'data-sync',
  WEBHOOKS: 'webhooks',
} as const;

@Module({
  imports: [
    // Register BullMQ with Redis connection
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        connection: {
          host: configService.getOrThrow<string>('cache.redis.host'),
          port: configService.getOrThrow<number>('cache.redis.port'),
          password: configService.get<string>('cache.redis.password'),
          db: configService.get<number>('cache.redis.queueDb') ?? 1,
        },
        defaultJobOptions: {
          attempts: 3,
          backoff: {
            type: 'exponential',
            delay: 1000,
          },
          removeOnComplete: {
            age: 3600, // Keep completed jobs for 1 hour
            count: 1000, // Keep last 1000 completed jobs
          },
          removeOnFail: {
            age: 86400 * 7, // Keep failed jobs for 7 days
          },
        },
      }),
    }),

    // Register individual queues
    BullModule.registerQueue(
      { name: QUEUE_NAMES.EMAIL },
      { name: QUEUE_NAMES.NOTIFICATIONS },
      { name: QUEUE_NAMES.REPORTS },
      { name: QUEUE_NAMES.DATA_SYNC },
      { name: QUEUE_NAMES.WEBHOOKS },
    ),

    // Bull Board dashboard (optional, disable in production if needed)
    BullBoardModule.forRoot({
      route: '/admin/queues',
      adapter: ExpressAdapter,
    }),
    BullBoardModule.forFeature(
      { name: QUEUE_NAMES.EMAIL, adapter: BullMQAdapter },
      { name: QUEUE_NAMES.NOTIFICATIONS, adapter: BullMQAdapter },
      { name: QUEUE_NAMES.REPORTS, adapter: BullMQAdapter },
      { name: QUEUE_NAMES.DATA_SYNC, adapter: BullMQAdapter },
      { name: QUEUE_NAMES.WEBHOOKS, adapter: BullMQAdapter },
    ),
  ],
  providers: [
    QueueConfigurationService,
    QueueOrchestratorService,
  ],
  exports: [
    BullModule,
    QueueOrchestratorService,
  ],
})
export class QueuesModule implements OnModuleInit {
  private readonly logger = new Logger(QueuesModule.name);

  onModuleInit(): void {
    this.logger.log('BullMQ Queues Module initialized');
    this.logger.log(`Registered queues: ${Object.values(QUEUE_NAMES).join(', ')}`);
    this.logger.log('Bull Board dashboard available at /admin/queues');
  }
}
```

### Queue Orchestrator Service

```typescript
/**
 * Queue Orchestrator Service
 *
 * Single entry point for all queue operations.
 * Provides a unified API for adding jobs across all queues.
 */

import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue, Job, JobsOptions } from 'bullmq';

import { QUEUE_NAMES } from '../queues.module';
import { getCorrelationId } from '../../../common/context/request-context.service';

export interface JobData {
  [key: string]: unknown;
}

export interface QueueJobOptions extends JobsOptions {
  correlationId?: string;
}

@Injectable()
export class QueueOrchestratorService {
  private readonly logger = new Logger(QueueOrchestratorService.name);

  constructor(
    @InjectQueue(QUEUE_NAMES.EMAIL) private readonly emailQueue: Queue,
    @InjectQueue(QUEUE_NAMES.NOTIFICATIONS) private readonly notificationsQueue: Queue,
    @InjectQueue(QUEUE_NAMES.REPORTS) private readonly reportsQueue: Queue,
    @InjectQueue(QUEUE_NAMES.DATA_SYNC) private readonly dataSyncQueue: Queue,
    @InjectQueue(QUEUE_NAMES.WEBHOOKS) private readonly webhooksQueue: Queue,
  ) {}

  /**
   * Add an email job to the queue
   */
  async addEmailJob(
    jobName: string,
    data: JobData,
    options?: QueueJobOptions
  ): Promise<Job> {
    return this.addJob(this.emailQueue, jobName, data, options);
  }

  /**
   * Add a notification job to the queue
   */
  async addNotificationJob(
    jobName: string,
    data: JobData,
    options?: QueueJobOptions
  ): Promise<Job> {
    return this.addJob(this.notificationsQueue, jobName, data, options);
  }

  /**
   * Add a report generation job to the queue
   */
  async addReportJob(
    jobName: string,
    data: JobData,
    options?: QueueJobOptions
  ): Promise<Job> {
    // Reports typically need more time
    return this.addJob(this.reportsQueue, jobName, data, {
      ...options,
      attempts: 2,
      backoff: { type: 'fixed', delay: 5000 },
    });
  }

  /**
   * Add a data sync job to the queue
   */
  async addDataSyncJob(
    jobName: string,
    data: JobData,
    options?: QueueJobOptions
  ): Promise<Job> {
    return this.addJob(this.dataSyncQueue, jobName, data, options);
  }

  /**
   * Add a webhook delivery job to the queue
   */
  async addWebhookJob(
    jobName: string,
    data: JobData,
    options?: QueueJobOptions
  ): Promise<Job> {
    // Webhooks need quick retries
    return this.addJob(this.webhooksQueue, jobName, data, {
      ...options,
      attempts: 5,
      backoff: { type: 'exponential', delay: 500 },
    });
  }

  /**
   * Schedule a recurring job
   */
  async addRecurringJob(
    queueName: keyof typeof QUEUE_NAMES,
    jobName: string,
    data: JobData,
    cron: string
  ): Promise<Job> {
    const queue = this.getQueue(queueName);
    return this.addJob(queue, jobName, data, {
      repeat: { pattern: cron },
    });
  }

  /**
   * Schedule a delayed job
   */
  async addDelayedJob(
    queueName: keyof typeof QUEUE_NAMES,
    jobName: string,
    data: JobData,
    delayMs: number
  ): Promise<Job> {
    const queue = this.getQueue(queueName);
    return this.addJob(queue, jobName, data, { delay: delayMs });
  }

  /**
   * Get queue metrics
   */
  async getQueueMetrics(): Promise<Record<string, unknown>> {
    const queues = [
      this.emailQueue,
      this.notificationsQueue,
      this.reportsQueue,
      this.dataSyncQueue,
      this.webhooksQueue,
    ];

    const metrics: Record<string, unknown> = {};

    for (const queue of queues) {
      const [waiting, active, completed, failed, delayed] = await Promise.all([
        queue.getWaitingCount(),
        queue.getActiveCount(),
        queue.getCompletedCount(),
        queue.getFailedCount(),
        queue.getDelayedCount(),
      ]);

      metrics[queue.name] = {
        waiting,
        active,
        completed,
        failed,
        delayed,
        total: waiting + active + delayed,
      };
    }

    return metrics;
  }

  private getQueue(queueName: keyof typeof QUEUE_NAMES): Queue {
    const queueMap: Record<string, Queue> = {
      EMAIL: this.emailQueue,
      NOTIFICATIONS: this.notificationsQueue,
      REPORTS: this.reportsQueue,
      DATA_SYNC: this.dataSyncQueue,
      WEBHOOKS: this.webhooksQueue,
    };
    return queueMap[queueName];
  }

  private async addJob(
    queue: Queue,
    jobName: string,
    data: JobData,
    options?: QueueJobOptions
  ): Promise<Job> {
    // Inject correlation ID for tracing
    const correlationId = options?.correlationId ?? getCorrelationId() ?? 'unknown';

    const enrichedData = {
      ...data,
      _meta: {
        correlationId,
        enqueuedAt: new Date().toISOString(),
      },
    };

    const job = await queue.add(jobName, enrichedData, options);

    this.logger.debug(
      `Job added: ${queue.name}/${jobName} (${job.id}) - correlationId: ${correlationId}`
    );

    return job;
  }
}
```

### Base Job Processor

```typescript
/**
 * Base Job Processor
 *
 * Abstract base class for all job processors with:
 * - Automatic logging with correlation ID
 * - Error handling and reporting
 * - Metrics collection
 * - Request context propagation
 */

import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { runWithContext, RequestContext } from '../../../common/context/request-context.service';

export interface JobMeta {
  correlationId: string;
  enqueuedAt: string;
}

export abstract class BaseProcessor {
  protected abstract readonly logger: Logger;

  /**
   * Process a job with automatic context propagation and error handling
   */
  protected async processWithContext<T, R>(
    job: Job<T & { _meta?: JobMeta }>,
    handler: (data: T) => Promise<R>
  ): Promise<R> {
    const meta = job.data._meta;
    const correlationId = meta?.correlationId ?? job.id ?? 'unknown';

    const context: RequestContext = {
      correlationId,
      startTime: Date.now(),
      metadata: {
        jobId: job.id,
        jobName: job.name,
        queueName: job.queueName,
        attemptsMade: job.attemptsMade,
      },
    };

    return runWithContext(context, async () => {
      this.logger.log(`Processing job: ${job.name} (${job.id})`);

      try {
        // Remove _meta from data before passing to handler
        const { _meta, ...cleanData } = job.data;
        const result = await handler(cleanData as T);

        const duration = Date.now() - context.startTime;
        this.logger.log(`Job completed: ${job.name} (${job.id}) in ${duration}ms`);

        return result;
      } catch (error) {
        const duration = Date.now() - context.startTime;
        this.logger.error(
          `Job failed: ${job.name} (${job.id}) after ${duration}ms - Attempt ${job.attemptsMade}`,
          error instanceof Error ? error.stack : error
        );
        throw error;
      }
    });
  }

  /**
   * Handle job failure (called when all retries exhausted)
   */
  protected async onFailed(job: Job, error: Error): Promise<void> {
    this.logger.error(
      `Job permanently failed: ${job.name} (${job.id}) after ${job.attemptsMade} attempts`,
      error.stack
    );

    // TODO: Send to dead letter queue or alerting system
  }

  /**
   * Handle job completion
   */
  protected async onCompleted(job: Job, result: unknown): Promise<void> {
    this.logger.debug(`Job completed callback: ${job.name} (${job.id})`);
  }
}
```

## RabbitMQ — Reliable Messaging

### Module Configuration

```typescript
/**
 * RabbitMQ Messaging Module
 *
 * Use this module when you need:
 * - Guaranteed message delivery with ACKs
 * - Complex routing patterns (fanout, topic, headers)
 * - Cross-language microservices communication
 * - RPC-style request/response patterns
 * - Mission-critical messaging with DLQs
 */

import { Module, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RabbitMQModule as GolevelupRabbitMQ } from '@golevelup/nestjs-rabbitmq';

// Exchange names for different routing patterns
export const EXCHANGES = {
  DIRECT: 'app.direct',
  TOPIC: 'app.topic',
  FANOUT: 'app.fanout',
  DEAD_LETTER: 'app.dlx',
} as const;

// Queue names
export const QUEUES = {
  EMAIL: 'email.queue',
  NOTIFICATIONS: 'notifications.queue',
  WEBHOOKS: 'webhooks.queue',
  DEAD_LETTER: 'dead-letter.queue',
} as const;

// Routing keys for topic exchange
export const ROUTING_KEYS = {
  EMAIL_SEND: 'email.send',
  EMAIL_BULK: 'email.bulk',
  NOTIFICATION_PUSH: 'notification.push',
  NOTIFICATION_SMS: 'notification.sms',
  WEBHOOK_OUTGOING: 'webhook.outgoing',
} as const;

@Module({
  imports: [
    GolevelupRabbitMQ.forRootAsync(GolevelupRabbitMQ, {
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        uri: config.getOrThrow<string>('RABBITMQ_URI'),
        connectionInitOptions: {
          wait: true,
          timeout: 30000,
        },
        connectionManagerOptions: {
          heartbeatIntervalInSeconds: 30,
          reconnectTimeInSeconds: 5,
        },
        exchanges: [
          { name: EXCHANGES.DIRECT, type: 'direct', options: { durable: true } },
          { name: EXCHANGES.TOPIC, type: 'topic', options: { durable: true } },
          { name: EXCHANGES.FANOUT, type: 'fanout', options: { durable: true } },
          { name: EXCHANGES.DEAD_LETTER, type: 'direct', options: { durable: true } },
        ],
        queues: [
          {
            name: QUEUES.EMAIL,
            options: {
              durable: true,
              arguments: {
                'x-dead-letter-exchange': EXCHANGES.DEAD_LETTER,
                'x-dead-letter-routing-key': QUEUES.DEAD_LETTER,
              },
            },
          },
          {
            name: QUEUES.NOTIFICATIONS,
            options: {
              durable: true,
              arguments: {
                'x-dead-letter-exchange': EXCHANGES.DEAD_LETTER,
                'x-dead-letter-routing-key': QUEUES.DEAD_LETTER,
              },
            },
          },
          {
            name: QUEUES.WEBHOOKS,
            options: {
              durable: true,
              arguments: {
                'x-dead-letter-exchange': EXCHANGES.DEAD_LETTER,
                'x-dead-letter-routing-key': QUEUES.DEAD_LETTER,
              },
            },
          },
          {
            name: QUEUES.DEAD_LETTER,
            options: { durable: true },
          },
        ],
        enableControllerDiscovery: true,
        prefetchCount: 10,
      }),
    }),
  ],
  exports: [GolevelupRabbitMQ],
})
export class RabbitMQModule implements OnModuleInit {
  private readonly logger = new Logger(RabbitMQModule.name);

  onModuleInit(): void {
    this.logger.log('RabbitMQ Module initialized');
    this.logger.log(`Exchanges: ${Object.values(EXCHANGES).join(', ')}`);
    this.logger.log(`Queues: ${Object.values(QUEUES).join(', ')}`);
  }
}
```

### Publisher Service

```typescript
/**
 * RabbitMQ Publisher Service
 *
 * Single orchestrator for publishing messages to RabbitMQ.
 * Supports direct, topic, and fanout exchange patterns.
 */

import { Injectable, Logger } from '@nestjs/common';
import { AmqpConnection } from '@golevelup/nestjs-rabbitmq';
import { EXCHANGES, ROUTING_KEYS } from '../rabbitmq.module';
import { getCorrelationId } from '../../../../common/context/request-context.service';

export interface PublishOptions {
  correlationId?: string;
  replyTo?: string;
  expiration?: string;
  priority?: number;
  persistent?: boolean;
  headers?: Record<string, string>;
}

@Injectable()
export class RabbitMQPublisherService {
  private readonly logger = new Logger(RabbitMQPublisherService.name);

  constructor(private readonly amqpConnection: AmqpConnection) {}

  /**
   * Publish to direct exchange (point-to-point)
   */
  async publishDirect<T>(
    routingKey: string,
    message: T,
    options?: PublishOptions
  ): Promise<void> {
    await this.publish(EXCHANGES.DIRECT, routingKey, message, options);
  }

  /**
   * Publish to topic exchange (pattern-based routing)
   */
  async publishTopic<T>(
    routingKey: string,
    message: T,
    options?: PublishOptions
  ): Promise<void> {
    await this.publish(EXCHANGES.TOPIC, routingKey, message, options);
  }

  /**
   * Publish to fanout exchange (broadcast to all)
   */
  async broadcast<T>(message: T, options?: PublishOptions): Promise<void> {
    await this.publish(EXCHANGES.FANOUT, '', message, options);
  }

  /**
   * RPC-style request/response
   */
  async request<TRequest, TResponse>(
    routingKey: string,
    message: TRequest,
    timeout = 30000
  ): Promise<TResponse> {
    const correlationId = getCorrelationId() ?? crypto.randomUUID();

    this.logger.debug(`RPC request: ${routingKey} - correlationId: ${correlationId}`);

    const response = await this.amqpConnection.request<TResponse>({
      exchange: EXCHANGES.DIRECT,
      routingKey,
      payload: message,
      timeout,
      correlationId,
    });

    return response;
  }

  /**
   * Send email (convenience method)
   */
  async sendEmail(payload: {
    to: string | string[];
    subject: string;
    template: string;
    data: Record<string, unknown>;
  }): Promise<void> {
    await this.publishTopic(ROUTING_KEYS.EMAIL_SEND, payload);
  }

  /**
   * Send notification (convenience method)
   */
  async sendNotification(payload: {
    userId: string;
    type: 'push' | 'sms' | 'in-app';
    title: string;
    body: string;
    data?: Record<string, unknown>;
  }): Promise<void> {
    const routingKey = payload.type === 'push'
      ? ROUTING_KEYS.NOTIFICATION_PUSH
      : ROUTING_KEYS.NOTIFICATION_SMS;
    await this.publishTopic(routingKey, payload);
  }

  /**
   * Dispatch webhook (convenience method)
   */
  async dispatchWebhook(payload: {
    url: string;
    event: string;
    data: Record<string, unknown>;
    headers?: Record<string, string>;
  }): Promise<void> {
    await this.publishTopic(ROUTING_KEYS.WEBHOOK_OUTGOING, payload, {
      persistent: true,
      priority: 5,
    });
  }

  private async publish<T>(
    exchange: string,
    routingKey: string,
    message: T,
    options?: PublishOptions
  ): Promise<void> {
    const correlationId = options?.correlationId ?? getCorrelationId() ?? 'unknown';

    const enrichedMessage = {
      ...message,
      _meta: {
        correlationId,
        publishedAt: new Date().toISOString(),
        exchange,
        routingKey,
      },
    };

    await this.amqpConnection.publish(exchange, routingKey, enrichedMessage, {
      correlationId,
      persistent: options?.persistent ?? true,
      priority: options?.priority,
      expiration: options?.expiration,
      headers: options?.headers,
    });

    this.logger.debug(
      `Message published: ${exchange}/${routingKey} - correlationId: ${correlationId}`
    );
  }
}
```

### Consumer Handler

```typescript
/**
 * Email Consumer Handler
 *
 * Example of a RabbitMQ message consumer with:
 * - Automatic ACK/NACK handling
 * - Dead letter queue on failure
 * - Correlation ID propagation
 */

import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe, Nack } from '@golevelup/nestjs-rabbitmq';
import { EXCHANGES, QUEUES, ROUTING_KEYS } from '../rabbitmq.module';
import { runWithContext, RequestContext } from '../../../../common/context/request-context.service';

interface EmailMessage {
  to: string | string[];
  subject: string;
  template: string;
  data: Record<string, unknown>;
  _meta?: {
    correlationId: string;
    publishedAt: string;
  };
}

@Injectable()
export class EmailHandler {
  private readonly logger = new Logger(EmailHandler.name);

  @RabbitSubscribe({
    exchange: EXCHANGES.TOPIC,
    routingKey: ROUTING_KEYS.EMAIL_SEND,
    queue: QUEUES.EMAIL,
    queueOptions: {
      durable: true,
    },
  })
  async handleEmailSend(message: EmailMessage): Promise<void | Nack> {
    const correlationId = message._meta?.correlationId ?? 'unknown';

    const context: RequestContext = {
      correlationId,
      startTime: Date.now(),
      metadata: {
        handler: 'EmailHandler.handleEmailSend',
        queue: QUEUES.EMAIL,
      },
    };

    return runWithContext(context, async () => {
      this.logger.log(`Processing email: ${message.subject} to ${message.to}`);

      try {
        // TODO: Implement actual email sending logic
        // await this.emailService.send(message);

        const duration = Date.now() - context.startTime;
        this.logger.log(`Email sent successfully in ${duration}ms`);

        // Return void to ACK the message
        return;
      } catch (error) {
        this.logger.error(
          `Failed to send email: ${message.subject}`,
          error instanceof Error ? error.stack : error
        );

        // NACK and requeue (will go to DLQ after max retries)
        return new Nack(false); // false = don't requeue, send to DLQ
      }
    });
  }

  @RabbitSubscribe({
    exchange: EXCHANGES.TOPIC,
    routingKey: ROUTING_KEYS.EMAIL_BULK,
    queue: QUEUES.EMAIL,
  })
  async handleBulkEmail(message: EmailMessage): Promise<void | Nack> {
    // Similar pattern for bulk email processing
    this.logger.log(`Processing bulk email: ${message.subject}`);
    return;
  }
}
```

## Kafka — Event Streaming

### Module Configuration

```typescript
/**
 * Kafka Streaming Module
 *
 * Use this module when you need:
 * - High-throughput event streaming (1M+ events/day)
 * - Event sourcing with replay capability
 * - Real-time analytics and data pipelines
 * - Log aggregation across services
 * - Exactly-once delivery semantics
 */

import { Module, Logger, OnModuleInit, OnModuleDestroy, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Kafka, Consumer, Producer, Admin, logLevel } from 'kafkajs';

// Topic names
export const TOPICS = {
  USER_EVENTS: 'user-events',
  ORDER_EVENTS: 'order-events',
  ANALYTICS_EVENTS: 'analytics-events',
  AUDIT_LOG: 'audit-log',
  DEAD_LETTER: 'dead-letter',
} as const;

// Consumer group IDs
export const CONSUMER_GROUPS = {
  USER_SERVICE: 'user-service-group',
  ORDER_SERVICE: 'order-service-group',
  ANALYTICS_SERVICE: 'analytics-service-group',
} as const;

@Module({
  providers: [
    {
      provide: 'KAFKA_CLIENT',
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        return new Kafka({
          clientId: config.get<string>('KAFKA_CLIENT_ID', 'nestjs-app'),
          brokers: config.getOrThrow<string>('KAFKA_BROKERS').split(','),
          ssl: config.get<boolean>('KAFKA_SSL', false),
          sasl: config.get<string>('KAFKA_SASL_USERNAME')
            ? {
                mechanism: 'plain',
                username: config.getOrThrow<string>('KAFKA_SASL_USERNAME'),
                password: config.getOrThrow<string>('KAFKA_SASL_PASSWORD'),
              }
            : undefined,
          logLevel: logLevel.INFO,
          retry: {
            initialRetryTime: 100,
            retries: 8,
          },
        });
      },
    },
    {
      provide: 'KAFKA_PRODUCER',
      inject: ['KAFKA_CLIENT'],
      useFactory: async (kafka: Kafka) => {
        const producer = kafka.producer({
          allowAutoTopicCreation: false,
          idempotent: true, // Exactly-once semantics
          maxInFlightRequests: 5,
        });
        await producer.connect();
        return producer;
      },
    },
    {
      provide: 'KAFKA_ADMIN',
      inject: ['KAFKA_CLIENT'],
      useFactory: async (kafka: Kafka) => {
        const admin = kafka.admin();
        await admin.connect();
        return admin;
      },
    },
  ],
  exports: ['KAFKA_CLIENT', 'KAFKA_PRODUCER', 'KAFKA_ADMIN'],
})
export class KafkaModule implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(KafkaModule.name);

  constructor(
    @Inject('KAFKA_ADMIN') private readonly admin: Admin,
  ) {}

  async onModuleInit(): Promise<void> {
    this.logger.log('Kafka Module initializing...');
    await this.ensureTopicsExist();
    this.logger.log('Kafka Module initialized');
  }

  async onModuleDestroy(): Promise<void> {
    await this.admin.disconnect();
    this.logger.log('Kafka Admin disconnected');
  }

  private async ensureTopicsExist(): Promise<void> {
    const existingTopics = await this.admin.listTopics();

    const topicsToCreate = Object.values(TOPICS)
      .filter((topic) => !existingTopics.includes(topic))
      .map((topic) => ({
        topic,
        numPartitions: topic === TOPICS.ANALYTICS_EVENTS ? 12 : 6, // More partitions for high-volume
        replicationFactor: 3,
        configEntries: [
          { name: 'retention.ms', value: '604800000' }, // 7 days
          { name: 'cleanup.policy', value: topic === TOPICS.AUDIT_LOG ? 'compact' : 'delete' },
        ],
      }));

    if (topicsToCreate.length > 0) {
      await this.admin.createTopics({ topics: topicsToCreate });
      this.logger.log(`Created topics: ${topicsToCreate.map((t) => t.topic).join(', ')}`);
    }
  }
}
```

### Producer Service

```typescript
/**
 * Kafka Producer Service
 *
 * Single orchestrator for publishing events to Kafka topics.
 * Supports batching, partitioning, and exactly-once semantics.
 */

import { Injectable, Inject, Logger, OnModuleDestroy } from '@nestjs/common';
import { Producer, CompressionTypes, Message } from 'kafkajs';
import { TOPICS } from '../kafka.module';
import { getCorrelationId, getRequestContext } from '../../../../common/context/request-context.service';

export interface KafkaEvent<T = unknown> {
  key?: string;
  value: T;
  headers?: Record<string, string>;
  partition?: number;
  timestamp?: string;
}

export interface PublishOptions {
  partition?: number;
  key?: string;
  headers?: Record<string, string>;
  compression?: CompressionTypes;
}

@Injectable()
export class KafkaProducerService implements OnModuleDestroy {
  private readonly logger = new Logger(KafkaProducerService.name);

  constructor(@Inject('KAFKA_PRODUCER') private readonly producer: Producer) {}

  async onModuleDestroy(): Promise<void> {
    await this.producer.disconnect();
    this.logger.log('Kafka Producer disconnected');
  }

  /**
   * Publish a single event to a topic
   */
  async publish<T>(
    topic: string,
    event: T,
    options?: PublishOptions
  ): Promise<void> {
    const correlationId = getCorrelationId() ?? crypto.randomUUID();
    const context = getRequestContext();

    const message: Message = {
      key: options?.key ?? null,
      value: JSON.stringify({
        ...event,
        _meta: {
          correlationId,
          publishedAt: new Date().toISOString(),
          userId: context?.userId,
          tenantId: context?.tenantId,
        },
      }),
      headers: {
        'correlation-id': correlationId,
        'content-type': 'application/json',
        ...options?.headers,
      },
      partition: options?.partition,
      timestamp: Date.now().toString(),
    };

    await this.producer.send({
      topic,
      messages: [message],
      compression: options?.compression ?? CompressionTypes.GZIP,
    });

    this.logger.debug(`Event published: ${topic} - correlationId: ${correlationId}`);
  }

  /**
   * Publish multiple events in a batch (high throughput)
   */
  async publishBatch<T>(
    topic: string,
    events: KafkaEvent<T>[]
  ): Promise<void> {
    const correlationId = getCorrelationId() ?? crypto.randomUUID();

    const messages: Message[] = events.map((event, index) => ({
      key: event.key ?? null,
      value: JSON.stringify({
        ...event.value,
        _meta: {
          correlationId,
          batchIndex: index,
          publishedAt: new Date().toISOString(),
        },
      }),
      headers: {
        'correlation-id': correlationId,
        'batch-size': events.length.toString(),
        ...event.headers,
      },
      partition: event.partition,
      timestamp: event.timestamp ?? Date.now().toString(),
    }));

    await this.producer.send({
      topic,
      messages,
      compression: CompressionTypes.GZIP,
    });

    this.logger.debug(`Batch published: ${topic} (${events.length} events) - correlationId: ${correlationId}`);
  }

  /**
   * Publish user event (convenience method)
   */
  async publishUserEvent(event: {
    userId: string;
    eventType: string;
    data: Record<string, unknown>;
  }): Promise<void> {
    await this.publish(TOPICS.USER_EVENTS, event, {
      key: event.userId, // Partition by user ID for ordering
    });
  }

  /**
   * Publish order event (convenience method)
   */
  async publishOrderEvent(event: {
    orderId: string;
    eventType: string;
    data: Record<string, unknown>;
  }): Promise<void> {
    await this.publish(TOPICS.ORDER_EVENTS, event, {
      key: event.orderId,
    });
  }

  /**
   * Publish analytics event (convenience method)
   */
  async publishAnalyticsEvent(event: {
    eventName: string;
    properties: Record<string, unknown>;
    userId?: string;
    sessionId?: string;
  }): Promise<void> {
    await this.publish(TOPICS.ANALYTICS_EVENTS, event);
  }

  /**
   * Publish audit log entry (convenience method)
   */
  async publishAuditLog(entry: {
    action: string;
    resourceType: string;
    resourceId: string;
    userId: string;
    changes?: Record<string, { old: unknown; new: unknown }>;
  }): Promise<void> {
    await this.publish(TOPICS.AUDIT_LOG, entry, {
      key: `${entry.resourceType}:${entry.resourceId}`, // Compaction key
    });
  }
}
```

### Consumer Service

```typescript
/**
 * Kafka Consumer Service
 *
 * Base consumer with automatic offset management,
 * error handling, and dead letter queue support.
 */

import { Injectable, Inject, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { Kafka, Consumer, EachMessagePayload } from 'kafkajs';
import { TOPICS, CONSUMER_GROUPS } from '../kafka.module';
import { KafkaProducerService } from './kafka-producer.service';
import { runWithContext, RequestContext } from '../../../../common/context/request-context.service';

export interface MessageHandler<T = unknown> {
  (payload: T, metadata: MessageMetadata): Promise<void>;
}

export interface MessageMetadata {
  topic: string;
  partition: number;
  offset: string;
  timestamp: string;
  correlationId: string;
}

@Injectable()
export class KafkaConsumerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(KafkaConsumerService.name);
  private consumer: Consumer;
  private handlers = new Map<string, MessageHandler>();

  constructor(
    @Inject('KAFKA_CLIENT') private readonly kafka: Kafka,
    private readonly producer: KafkaProducerService,
  ) {}

  async onModuleInit(): Promise<void> {
    this.consumer = this.kafka.consumer({
      groupId: CONSUMER_GROUPS.USER_SERVICE,
      sessionTimeout: 30000,
      heartbeatInterval: 3000,
      maxBytesPerPartition: 1048576, // 1MB
      retry: {
        retries: 5,
      },
    });

    await this.consumer.connect();
    this.logger.log('Kafka Consumer connected');
  }

  async onModuleDestroy(): Promise<void> {
    await this.consumer.disconnect();
    this.logger.log('Kafka Consumer disconnected');
  }

  /**
   * Subscribe to a topic with a handler
   */
  async subscribe<T>(
    topic: string,
    handler: MessageHandler<T>,
    options?: { fromBeginning?: boolean }
  ): Promise<void> {
    this.handlers.set(topic, handler as MessageHandler);

    await this.consumer.subscribe({
      topic,
      fromBeginning: options?.fromBeginning ?? false,
    });

    this.logger.log(`Subscribed to topic: ${topic}`);
  }

  /**
   * Start consuming messages
   */
  async startConsuming(): Promise<void> {
    await this.consumer.run({
      eachMessage: async (payload: EachMessagePayload) => {
        await this.handleMessage(payload);
      },
    });
  }

  private async handleMessage(payload: EachMessagePayload): Promise<void> {
    const { topic, partition, message } = payload;
    const handler = this.handlers.get(topic);

    if (!handler) {
      this.logger.warn(`No handler registered for topic: ${topic}`);
      return;
    }

    const correlationId =
      message.headers?.['correlation-id']?.toString() ?? 'unknown';

    const context: RequestContext = {
      correlationId,
      startTime: Date.now(),
      metadata: {
        topic,
        partition,
        offset: message.offset,
      },
    };

    await runWithContext(context, async () => {
      try {
        const value = JSON.parse(message.value?.toString() ?? '{}');

        const metadata: MessageMetadata = {
          topic,
          partition,
          offset: message.offset,
          timestamp: message.timestamp,
          correlationId,
        };

        this.logger.debug(`Processing message: ${topic}[${partition}]@${message.offset}`);

        await handler(value, metadata);

        const duration = Date.now() - context.startTime;
        this.logger.debug(`Message processed in ${duration}ms`);
      } catch (error) {
        this.logger.error(
          `Failed to process message: ${topic}[${partition}]@${message.offset}`,
          error instanceof Error ? error.stack : error
        );

        // Send to dead letter topic
        await this.sendToDeadLetter(topic, message, error);
      }
    });
  }

  private async sendToDeadLetter(
    originalTopic: string,
    message: any,
    error: unknown
  ): Promise<void> {
    try {
      await this.producer.publish(TOPICS.DEAD_LETTER, {
        originalTopic,
        originalMessage: message.value?.toString(),
        error: error instanceof Error ? error.message : String(error),
        failedAt: new Date().toISOString(),
      });

      this.logger.warn(`Message sent to dead letter queue from ${originalTopic}`);
    } catch (dlqError) {
      this.logger.error('Failed to send to dead letter queue', dlqError);
    }
  }
}
```
