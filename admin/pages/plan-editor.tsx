import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { Button, Card, Form, Input, InputNumber, Switch, Select, message, Space, Divider, Typography, Row, Col } from 'antd';
import { ArrowLeftOutlined, SaveOutlined } from '@ant-design/icons';
import Layout from '../components/Layout';
import { api } from '../services/api';

const { Title, Text } = Typography;
const { Option } = Select;

interface FeatureQuota {
  featureType: string;
  quotaValue: number;
  quotaUnit: string;
  multiplier?: number;
}

interface DefaultConfig {
  functionType: string;
  modelPattern: string;
  isActive?: boolean;
}

interface PlanFormData {
  id?: string;
  name: string;
  description?: string;
  priceCents: number;
  durationDays: number;
  quotaValue: number;
  quotaUnit: string;
  isActive?: boolean;
  sortOrder?: number;
  featureQuotas?: FeatureQuota[];
  defaultConfigs?: DefaultConfig[];
}

const FEATURE_TYPES = [
  { label: 'AI对话', value: 'ai_chat', unit: 'tokens' },
  { label: '语音转写', value: 'transcription', unit: 'minutes' },
  { label: '实时转写', value: 'realtime_transcription', unit: 'minutes' },
  { label: '文本分析', value: 'text_analysis', unit: 'thousand_chars' },
  { label: '图像识别', value: 'image_recognition', unit: 'images' },
  { label: 'OCR识别', value: 'ocr', unit: 'images' },
  { label: '语音合成', value: 'tts', unit: 'thousand_chars' },
];

const FUNCTION_TYPES = [
  { label: 'AI对话', value: 'ai_chat' },
  { label: '语音转写', value: 'transcription' },
  { label: '实时转写', value: 'realtime_transcription' },
  { label: '文本分析', value: 'text_analysis' },
  { label: '图像识别', value: 'image_recognition' },
  { label: 'OCR识别', value: 'ocr' },
  { label: '语音合成', value: 'tts' },
];

const COMMON_MODELS = [
  'gpt-4o', 'gpt-4', 'gpt-3.5-turbo',
  'claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku',
  'qwen-turbo', 'qwen-plus', 'qwen-max',
  'deepseek-chat',
  'whisper-1',
];

export default function PlanEditor() {
  const router = useRouter();
  const [form] = Form.useForm<PlanFormData>();
  const [loading, setLoading] = useState(false);
  const [planId, setPlanId] = useState<string | null>(null);
  const [featureQuotas, setFeatureQuotas] = useState<FeatureQuota[]>([]);
  const [defaultConfigs, setDefaultConfigs] = useState<DefaultConfig[]>([]);

  const isEdit = router.query.id && router.query.id !== 'new';

  useEffect(() => {
    if (isEdit) {
      const id = router.query.id as string;
      setPlanId(id);
      loadPlan(id);
    }
  }, [router.query.id]);

  async function loadPlan(id: string) {
    try {
      setLoading(true);
      const plan = await api.getPlan(id);
      
      form.setFieldsValue({
        id: plan.id,
        name: plan.name,
        description: plan.description,
        priceCents: plan.priceCents / 100,
        durationDays: plan.durationDays,
        quotaValue: plan.quotaValue,
        quotaUnit: plan.quotaUnit,
        isActive: plan.isActive,
        sortOrder: plan.sortOrder || 0,
      });

      if (plan.featureQuotas) {
        setFeatureQuotas(plan.featureQuotas);
      }

      const configs = await api.getPlanDefaultConfigs(id);
      setDefaultConfigs(configs);
    } catch (error) {
      console.error('Failed to load plan:', error);
      message.error('加载套餐失败');
    } finally {
      setLoading(false);
    }
  }

  function addFeatureQuota() {
    setFeatureQuotas([
      ...featureQuotas,
      { featureType: 'ai_chat', quotaValue: 0, quotaUnit: 'tokens', multiplier: 1.0 },
    ]);
  }

  function removeFeatureQuota(index: number) {
    setFeatureQuotas(featureQuotas.filter((_, i) => i !== index));
  }

  function updateFeatureQuota(index: number, field: keyof FeatureQuota, value: any) {
    const newQuotas = [...featureQuotas];
    newQuotas[index] = { ...newQuotas[index], [field]: value };
    setFeatureQuotas(newQuotas);
  }

  function addDefaultConfig() {
    setDefaultConfigs([
      ...defaultConfigs,
      { functionType: 'ai_chat', modelPattern: '', isActive: true },
    ]);
  }

  function removeDefaultConfig(index: number) {
    setDefaultConfigs(defaultConfigs.filter((_, i) => i !== index));
  }

  function updateDefaultConfig(index: number, field: keyof DefaultConfig, value: any) {
    const newConfigs = [...defaultConfigs];
    newConfigs[index] = { ...newConfigs[index], [field]: value };
    setDefaultConfigs(newConfigs);
  }

  async function handleSave(values: PlanFormData) {
    try {
      setLoading(true);
      
      const data = {
        ...values,
        priceCents: Math.round((values.priceCents || 0) * 100),
        featureQuotas,
      };

      if (isEdit) {
        await api.updatePlan(planId!, data);
        for (const config of defaultConfigs) {
          await api.setPlanDefaultConfig(planId!, config);
        }
        message.success('套餐更新成功');
      } else {
        const newPlan = await api.createPlan(data);
        for (const config of defaultConfigs) {
          await api.setPlanDefaultConfig(newPlan.id, config);
        }
        message.success('套餐创建成功');
      }

      router.push('/subscriptions');
    } catch (error) {
      console.error('Failed to save plan:', error);
      message.error('保存套餐失败');
    } finally {
      setLoading(false);
    }
  }

  return (
    <Layout currentPage="subscriptions">
      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <Button
            icon={<ArrowLeftOutlined />}
            onClick={() => router.push('/subscriptions')}
          >
            返回
          </Button>
          <div>
            <Title level={2} className="m-0">{isEdit ? '编辑套餐' : '创建套餐'}</Title>
            <Text type="secondary">{isEdit ? '修改套餐配置信息' : '创建新的套餐'}</Text>
          </div>
        </div>

        <Card>
          <Form
            form={form}
            layout="vertical"
            onFinish={handleSave}
            initialValues={{
              isActive: true,
              sortOrder: 0,
              durationDays: 30,
              quotaUnit: 'minutes',
            }}
          >
            <Row gutter={24}>
              <Col xs={24} md={12}>
                <Form.Item
                  name="name"
                  label="套餐名称"
                  rules={[{ required: true, message: '请输入套餐名称' }]}
                >
                  <Input placeholder="如：基础版、专业版" />
                </Form.Item>
              </Col>
              <Col xs={24} md={12}>
                <Form.Item
                  name="priceCents"
                  label="价格（元）"
                  rules={[{ required: true, message: '请输入价格' }]}
                >
                  <InputNumber
                    min={0}
                    precision={2}
                    style={{ width: '100%' }}
                    placeholder="套餐价格"
                  />
                </Form.Item>
              </Col>
            </Row>

            <Form.Item name="description" label="套餐描述">
              <Input.TextArea rows={3} placeholder="描述套餐包含的内容" />
            </Form.Item>

            <Row gutter={24}>
              <Col xs={24} md={8}>
                <Form.Item
                  name="durationDays"
                  label="有效期（天）"
                  rules={[{ required: true, message: '请输入有效期' }]}
                >
                  <InputNumber min={1} style={{ width: '100%' }} placeholder="30" />
                </Form.Item>
              </Col>
              <Col xs={24} md={8}>
                <Form.Item
                  name="quotaValue"
                  label="基础配额"
                  rules={[{ required: true, message: '请输入配额' }]}
                >
                  <InputNumber min={0} style={{ width: '100%' }} placeholder="配额数值" />
                </Form.Item>
              </Col>
              <Col xs={24} md={8}>
                <Form.Item
                  name="quotaUnit"
                  label="配额单位"
                  rules={[{ required: true, message: '请选择单位' }]}
                >
                  <Select placeholder="选择单位">
                    <Option value="minutes">分钟</Option>
                    <Option value="tokens">Tokens</Option>
                    <Option value="thousand_chars">千字符</Option>
                    <Option value="images">张</Option>
                  </Select>
                </Form.Item>
              </Col>
            </Row>

            <Row gutter={24}>
              <Col xs={24} md={12}>
                <Form.Item
                  name="sortOrder"
                  label="排序值"
                  help="数值越小越靠前"
                >
                  <InputNumber min={0} style={{ width: '100%' }} placeholder="0" />
                </Form.Item>
              </Col>
              <Col xs={24} md={12}>
                <Form.Item
                  name="isActive"
                  label="启用状态"
                  valuePropName="checked"
                >
                  <Switch />
                </Form.Item>
              </Col>
            </Row>

            <Divider />

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Title level={4} className="m-0">功能配额</Title>
                <Button type="dashed" onClick={addFeatureQuota}>+ 添加功能配额</Button>
              </div>

              {featureQuotas.map((quota, index) => (
                <Card key={index} size="small">
                  <Row gutter={16} align="middle">
                    <Col xs={24} sm={5}>
                      <Select
                        value={quota.featureType}
                        onChange={(value) => {
                          updateFeatureQuota(index, 'featureType', value);
                          const type = FEATURE_TYPES.find(t => t.value === value);
                          if (type) {
                            updateFeatureQuota(index, 'quotaUnit', type.unit);
                          }
                        }}
                        style={{ width: '100%' }}
                        placeholder="选择功能"
                      >
                        {FEATURE_TYPES.map(type => (
                          <Option key={type.value} value={type.value}>{type.label}</Option>
                        ))}
                      </Select>
                    </Col>
                    <Col xs={24} sm={5}>
                      <InputNumber
                        value={quota.quotaValue}
                        onChange={(value) => updateFeatureQuota(index, 'quotaValue', value)}
                        min={0}
                        style={{ width: '100%' }}
                        placeholder="配额值"
                      />
                    </Col>
                    <Col xs={24} sm={5}>
                      <Select
                        value={quota.quotaUnit}
                        onChange={(value) => updateFeatureQuota(index, 'quotaUnit', value)}
                        style={{ width: '100%' }}
                        placeholder="单位"
                      >
                        <Option value="minutes">分钟</Option>
                        <Option value="tokens">Tokens</Option>
                        <Option value="thousand_chars">千字符</Option>
                        <Option value="images">张</Option>
                      </Select>
                    </Col>
                    <Col xs={24} sm={5}>
                      <InputNumber
                        value={quota.multiplier}
                        onChange={(value) => updateFeatureQuota(index, 'multiplier', value)}
                        min={0.1}
                        max={10}
                        step={0.1}
                        style={{ width: '100%' }}
                        placeholder="系数"
                      />
                    </Col>
                    <Col xs={24} sm={4} className="text-right">
                      <Button danger onClick={() => removeFeatureQuota(index)}>删除</Button>
                    </Col>
                  </Row>
                </Card>
              ))}
            </div>

            <Divider />

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Title level={4} className="m-0">场景默认模型</Title>
                <Button type="dashed" onClick={addDefaultConfig}>+ 添加场景配置</Button>
              </div>

              {defaultConfigs.map((config, index) => (
                <Card key={index} size="small">
                  <Row gutter={16} align="middle">
                    <Col xs={24} sm={7}>
                      <Select
                        value={config.functionType}
                        onChange={(value) => updateDefaultConfig(index, 'functionType', value)}
                        style={{ width: '100%' }}
                        placeholder="选择场景"
                      >
                        {FUNCTION_TYPES.map(type => (
                          <Option key={type.value} value={type.value}>{type.label}</Option>
                        ))}
                      </Select>
                    </Col>
                    <Col xs={24} sm={12}>
                      <Select
                        value={config.modelPattern}
                        onChange={(value) => updateDefaultConfig(index, 'modelPattern', value)}
                        style={{ width: '100%' }}
                        placeholder="选择模型"
                        showSearch
                        allowClear
                      >
                        {COMMON_MODELS.map(model => (
                          <Option key={model} value={model}>{model}</Option>
                        ))}
                      </Select>
                    </Col>
                    <Col xs={24} sm={3}>
                      <Switch
                        checked={config.isActive}
                        onChange={(checked) => updateDefaultConfig(index, 'isActive', checked)}
                      />
                    </Col>
                    <Col xs={24} sm={2} className="text-right">
                      <Button danger onClick={() => removeDefaultConfig(index)}>删除</Button>
                    </Col>
                  </Row>
                </Card>
              ))}
            </div>

            <Divider />

            <div className="flex justify-end">
              <Space>
                <Button onClick={() => router.push('/subscriptions')}>取消</Button>
                <Button type="primary" icon={<SaveOutlined />} htmlType="submit" loading={loading}>
                  {isEdit ? '保存修改' : '创建套餐'}
                </Button>
              </Space>
            </div>
          </Form>
        </Card>
      </div>
    </Layout>
  );
}
