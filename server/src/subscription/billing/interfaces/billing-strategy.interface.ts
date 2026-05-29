export interface ConsumeResult {
  success: boolean;
  consumed: number;
  remaining: number;
  costCents?: number;
  message?: string;
}

export interface BillingStrategy {
  canUse(userId: string, featureType: string, amount: number): Promise<boolean>;
  consume(userId: string, featureType: string, amount: number, metadata?: any): Promise<ConsumeResult>;
  getRemaining(userId: string, featureType: string): Promise<number>;
}
