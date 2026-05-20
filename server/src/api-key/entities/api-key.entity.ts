import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('api_keys')
export class ApiKey {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  provider: string;

  @Column()
  apiKeyEncrypted: string;

  @Column()
  model: string;

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: 60 })
  rateLimitPerMin: number;

  @CreateDateColumn()
  createdAt: Date;
}
