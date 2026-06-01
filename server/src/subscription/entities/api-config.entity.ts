import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('api_configs')
export class ApiConfig {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  provider: string;

  @Column({ name: 'model_pattern' })
  modelPattern: string;

  @Column({ name: 'model_name', nullable: true })
  modelName: string;

  @Column({ name: 'base_coefficient', type: 'decimal', precision: 10, scale: 4, default: 1.0 })
  baseCoefficient: number;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
