import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany, OneToOne, JoinColumn } from 'typeorm';
import { Subscription } from '../../subscription/entities/subscription.entity';
import { UserBalance } from '../../subscription/entities/user-balance.entity';

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

  @OneToOne(() => UserBalance, balance => balance.user)
  @JoinColumn({ name: 'id', referencedColumnName: 'userId' })
  balance: UserBalance;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
