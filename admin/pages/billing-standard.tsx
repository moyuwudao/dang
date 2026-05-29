import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import { adminAPI } from '../services/api';
import {
  Card,
  CardBody,
  Button,
  Input,
  Table,
  TableHeader,
  TableColumn,
  TableBody,
  TableRow,
  TableCell,
  Modal,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalFooter,
  useDisclosure,
  Chip,
} from '@nextui-org/react';
import { Save, Plus, Trash2, AlertCircle, Settings, Calculator } from 'lucide-react';

interface BillingStandard {
  id: string;
  featureType: string;
  featureLabel: string;
  unit: string;
  unitLabel: string;
  tokenRatio: number;
  standardPricePerUnit: number;
  actualCostPerUnit: number;
  currency: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// 功能类型配置
const FEATURE_TYPES = [
  { key: 'text_analysis', label: '文本分析', unit: 'tokens', unitLabel: '1K tokens', tokenRatio: 1, defaultPrice: 0.005, defaultCost: 0.0028 },
  { key: 'transcription', label: '语音转文本', unit: 'minutes', unitLabel: '分钟', tokenRatio: 1500, defaultPrice: 0.01, defaultCost: 0.000675 },
  { key: 'realtime_transcription', label: '实时语音转写', unit: 'minutes', unitLabel: '分钟', tokenRatio: 1500, defaultPrice: 0.01, defaultCost: 0.000675 },
  { key: 'image_recognition', label: '图像识别', unit: 'images', unitLabel: '张', tokenRatio: 1000, defaultPrice: 0.005, defaultCost: 0.00045 },
  { key: 'ocr', label: 'OCR识别', unit: 'images', unitLabel: '张', tokenRatio: 800, defaultPrice: 0.004, defaultCost: 0.00036 },
];

const BILLING_COLORS: Record<string, string> = {
  text_analysis: 'bg-blue-100 text-blue-700',
  transcription: 'bg-green-100 text-green-700',
  realtime_transcription: 'bg-teal-100 text-teal-700',
  image_recognition: 'bg-purple-100 text-purple-700',
  ocr: 'bg-orange-100 text-orange-700',
};

export default function BillingStandardPage() {
  const [standards, setStandards] = useState<BillingStandard[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [editingStandard, setEditingStandard] = useState<Partial<BillingStandard>>({});
  const [isEditing, setIsEditing] = useState(false);

  useEffect(() => {
    fetchStandards();
  }, []);

  const fetchStandards = async () => {
    setLoading(true);
    try {
      const data = await adminAPI.getBillingStandards();
      setStandards(data || []);
    } catch (err: any) {
      setError(err.response?.data?.message || '获取计费标准失败');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!editingStandard.featureType || !editingStandard.standardPricePerUnit) {
      setError('请填写完整信息');
      return;
    }

    try {
      const featureConfig = FEATURE_TYPES.find(f => f.key === editingStandard.featureType) || FEATURE_TYPES[0];
      const data = {
        featureType: editingStandard.featureType,
        featureLabel: featureConfig.label,
        unit: featureConfig.unit,
        unitLabel: featureConfig.unitLabel,
        tokenRatio: featureConfig.tokenRatio,
        standardPricePerUnit: editingStandard.standardPricePerUnit,
        actualCostPerUnit: editingStandard.actualCostPerUnit || featureConfig.defaultCost,
        currency: editingStandard.currency || 'CNY',
        isActive: editingStandard.isActive !== false,
      };

      if (isEditing && editingStandard.id) {
        await adminAPI.updateBillingStandard(editingStandard.id, data);
      } else {
        await adminAPI.createBillingStandard(data);
      }

      onClose();
      fetchStandards();
      setEditingStandard({});
      setIsEditing(false);
      setError(null);
    } catch (err: any) {
      setError(err.response?.data?.message || '保存失败');
    }
  };

  const openAdd = () => {
    setEditingStandard({
      featureType: 'text_analysis',
      standardPricePerUnit: 0.005,
      actualCostPerUnit: 0.0028,
      currency: 'CNY',
      isActive: true,
    });
    setIsEditing(false);
    setError(null);
    onOpen();
  };

  const openEdit = (standard: BillingStandard) => {
    setEditingStandard({ ...standard });
    setIsEditing(true);
    setError(null);
    onOpen();
  };

  const handleDelete = async (id: string) => {
    if (!confirm('确定要删除该计费标准吗？')) return;
    try {
      await adminAPI.deleteBillingStandard(id);
      fetchStandards();
    } catch (err: any) {
      setError(err.response?.data?.message || '删除失败');
    }
  };

  // 计算等效Token价格
  const getTokenPrice = (standard: BillingStandard) => {
    if (!standard.tokenRatio) return '-';
    return `¥${(standard.standardPricePerUnit * 1000 / standard.tokenRatio).toFixed(4)}`;
  };

  // 计算利润率
  const getProfitMargin = (standard: BillingStandard) => {
    if (!standard.actualCostPerUnit || standard.actualCostPerUnit === 0) return '-';
    const margin = ((standard.standardPricePerUnit - standard.actualCostPerUnit) / standard.standardPricePerUnit * 100).toFixed(1);
    return `${margin}%`;
  };

  return (
    <Layout currentPage="billing-standard">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">计费标准配置</h1>
            <p className="text-gray-500 mt-1">配置各功能类型的标准单价（用户按量付费价格）和实际成本</p>
          </div>
          <Button
            color="primary"
            className="bg-blue-600 hover:bg-blue-700"
            onClick={openAdd}
            startContent={<Plus className="w-4 h-4" />}
          >
            添加计费标准
          </Button>
        </div>

        {error && (
          <div className="p-4 bg-red-50 border border-red-200 rounded-xl flex items-center gap-2 text-red-700">
            <AlertCircle className="w-5 h-5" />
            <span>{error}</span>
          </div>
        )}

        {/* 计费标准说明 */}
        <Card className="shadow-sm bg-blue-50">
          <CardBody>
            <h3 className="text-lg font-bold text-blue-800 mb-3 flex items-center gap-2">
              <Calculator className="w-5 h-5" />
              计费标准说明
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-blue-700">
              <div>
                <p className="font-medium mb-1">标准单价</p>
                <p className="text-xs text-blue-500">用户按量付费时的价格</p>
              </div>
              <div>
                <p className="font-medium mb-1">实际成本</p>
                <p className="text-xs text-blue-500">支付给模型厂商的费用</p>
              </div>
              <div>
                <p className="font-medium mb-1">Token转换</p>
                <p className="text-xs text-blue-500">统一转换为Token计费</p>
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Standards Table */}
        <Card className="shadow-sm">
          <CardBody>
            <Table aria-label="计费标准列表">
              <TableHeader>
                <TableColumn>功能类型</TableColumn>
                <TableColumn>计费单位</TableColumn>
                <TableColumn>Token转换比例</TableColumn>
                <TableColumn>标准单价（用户价）</TableColumn>
                <TableColumn>实际成本</TableColumn>
                <TableColumn>等效Token价格</TableColumn>
                <TableColumn>利润率</TableColumn>
                <TableColumn>状态</TableColumn>
                <TableColumn>操作</TableColumn>
              </TableHeader>
              <TableBody>
                {standards.map((standard) => (
                  <TableRow key={standard.id}>
                    <TableCell>
                      <Chip
                        size="sm"
                        className={BILLING_COLORS[standard.featureType] || 'bg-gray-100 text-gray-700'}
                      >
                        {standard.featureLabel}
                      </Chip>
                    </TableCell>
                    <TableCell>{standard.unitLabel}</TableCell>
                    <TableCell>
                      <span className="font-mono text-sm">
                        1{standard.unitLabel} = {standard.tokenRatio} tokens
                      </span>
                    </TableCell>
                    <TableCell>
                      <span className="font-mono text-sm text-blue-600 font-medium">
                        ¥{standard.standardPricePerUnit.toFixed(4)}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span className="font-mono text-sm text-gray-500">
                        ¥{standard.actualCostPerUnit?.toFixed(4) || '-'}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span className="font-mono text-sm text-green-600">
                        {getTokenPrice(standard)}/1K tokens
                      </span>
                    </TableCell>
                    <TableCell>
                      <Chip
                        size="sm"
                        className={
                          parseFloat(getProfitMargin(standard)) > 40
                            ? 'bg-green-100 text-green-700'
                            : parseFloat(getProfitMargin(standard)) > 20
                            ? 'bg-yellow-100 text-yellow-700'
                            : 'bg-red-100 text-red-700'
                        }
                      >
                        {getProfitMargin(standard)}
                      </Chip>
                    </TableCell>
                    <TableCell>
                      <Chip
                        size="sm"
                        className={standard.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}
                      >
                        {standard.isActive ? '启用' : '停用'}
                      </Chip>
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-2">
                        <Button
                          size="sm"
                          variant="light"
                          color="primary"
                          onClick={() => openEdit(standard)}
                        >
                          编辑
                        </Button>
                        <Button
                          size="sm"
                          variant="light"
                          color="danger"
                          isIconOnly
                          aria-label="删除"
                          onClick={() => handleDelete(standard.id)}
                        >
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {standards.length === 0 && !loading && (
              <div className="text-center py-12 text-gray-500">
                <Settings className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                <p>暂无计费标准配置</p>
                <p className="text-sm mt-1">点击右上角添加计费标准</p>
              </div>
            )}
          </CardBody>
        </Card>

        {/* 默认配置参考 */}
        <Card className="shadow-sm">
          <CardBody>
            <h3 className="text-lg font-bold text-gray-800 mb-4">默认配置参考</h3>
            <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
              {FEATURE_TYPES.map((feature) => (
                <div key={feature.key} className="p-3 bg-gray-50 rounded-xl">
                  <p className="font-medium text-gray-800 text-sm">{feature.label}</p>
                  <p className="text-xs text-gray-500">{feature.unitLabel}</p>
                  <div className="mt-2 space-y-1">
                    <p className="text-xs text-gray-600">
                      标准价: <span className="font-mono font-medium">¥{feature.defaultPrice.toFixed(4)}</span>
                    </p>
                    <p className="text-xs text-gray-600">
                      成本: <span className="font-mono font-medium">¥{feature.defaultCost.toFixed(4)}</span>
                    </p>
                    <p className="text-xs text-blue-600">
                      Token: 1{feature.unitLabel} = {feature.tokenRatio} tokens
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Add/Edit Modal */}
      <Modal isOpen={isOpen} onClose={onClose} classNames={{ base: 'rounded-xl' }} size="lg">
        <ModalContent>
          <ModalHeader>{isEditing ? '编辑计费标准' : '添加计费标准'}</ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  功能类型 <span className="text-red-500">*</span>
                </label>
                <select
                  value={editingStandard.featureType || 'text_analysis'}
                  onChange={(e) => {
                    const featureType = e.target.value;
                    const featureConfig = FEATURE_TYPES.find(f => f.key === featureType);
                    setEditingStandard({
                      ...editingStandard,
                      featureType,
                      standardPricePerUnit: featureConfig?.defaultPrice || 0,
                      actualCostPerUnit: featureConfig?.defaultCost || 0,
                    });
                  }}
                  className="w-full px-3 py-2.5 rounded-xl border border-gray-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  {FEATURE_TYPES.map((feature) => (
                    <option key={feature.key} value={feature.key}>{feature.label}</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <Input
                  label="标准单价（用户按量付费价格）"
                  type="number"
                  step="0.0001"
                  placeholder="0.005"
                  value={String(editingStandard.standardPricePerUnit || 0)}
                  onChange={(e) => setEditingStandard({ ...editingStandard, standardPricePerUnit: parseFloat(e.target.value) })}
                  classNames={{ inputWrapper: 'rounded-xl' }}
                  isRequired
                  startContent={<span className="text-gray-400 text-sm">¥</span>}
                />
                <Input
                  label="实际成本（支付给厂商）"
                  type="number"
                  step="0.0001"
                  placeholder="0.0028"
                  value={String(editingStandard.actualCostPerUnit || 0)}
                  onChange={(e) => setEditingStandard({ ...editingStandard, actualCostPerUnit: parseFloat(e.target.value) })}
                  classNames={{ inputWrapper: 'rounded-xl' }}
                  startContent={<span className="text-gray-400 text-sm">¥</span>}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">货币</label>
                  <select
                    value={editingStandard.currency || 'CNY'}
                    onChange={(e) => setEditingStandard({ ...editingStandard, currency: e.target.value })}
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="CNY">CNY (人民币)</option>
                    <option value="USD">USD (美元)</option>
                  </select>
                </div>
                <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <input
                    type="checkbox"
                    id="isActive"
                    checked={editingStandard.isActive !== false}
                    onChange={(e) => setEditingStandard({ ...editingStandard, isActive: e.target.checked })}
                    className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <label htmlFor="isActive" className="text-sm text-gray-700">
                    启用该计费标准
                  </label>
                </div>
              </div>

              {/* 预览 */}
              {editingStandard.standardPricePerUnit && editingStandard.actualCostPerUnit && (
                <div className="p-3 bg-green-50 rounded-xl">
                  <p className="text-sm text-green-700 font-medium">利润预览</p>
                  <div className="mt-2 grid grid-cols-3 gap-4 text-xs text-green-600">
                    <div>
                      <p>标准单价</p>
                      <p className="font-mono font-medium">¥{editingStandard.standardPricePerUnit.toFixed(4)}</p>
                    </div>
                    <div>
                      <p>实际成本</p>
                      <p className="font-mono font-medium">¥{editingStandard.actualCostPerUnit.toFixed(4)}</p>
                    </div>
                    <div>
                      <p>利润率</p>
                      <p className="font-mono font-medium">
                        {((editingStandard.standardPricePerUnit - editingStandard.actualCostPerUnit) / editingStandard.standardPricePerUnit * 100).toFixed(1)}%
                      </p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={onClose}>
              取消
            </Button>
            <Button
              color="primary"
              className="bg-blue-600"
              onClick={handleSave}
              startContent={<Save className="w-4 h-4" />}
            >
              {isEditing ? '保存修改' : '添加配置'}
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </Layout>
  );
}
