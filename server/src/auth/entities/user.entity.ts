import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { Subscription } from '../../subscription/entities/subscription.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, nullable: true })
  phone: string;

  @Column({ unique: true, nullable: true })
  email: string;

  @Column()
  passwordHash: string;

  @Column({ default: '用户' })
  nickname: string;

  @Column({ nullable: true })
  avatarUrl: string;

  @Column({ default: 'active' })
  status: string;

  @Column({ default: 'user' })
  role: string;

  @OneToMany(() => Subscription, sub => sub.user)
  subscriptions: Subscription[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
