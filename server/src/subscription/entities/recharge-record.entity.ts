import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from '../../auth/entities/user.entity';

@Entity('recharge_records')
export class RechargeRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column()
  amountCents: number;

  @Column({ default: 'recharge' })
  type: string; // recharge | refund

  @Column({ nullable: true })
  paymentMethod: string; // wechat | alipay

  @Column({ nullable: true })
  transactionId: string;

  @Column({ default: 'completed' })
  status: string; // pending | completed | failed | refunded

  @Column({ nullable: true })
  remark: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @CreateDateColumn()
  createdAt: Date;
}
