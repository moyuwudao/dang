'use client';

import { useState, useEffect } from 'react';
import { Card, CardBody, Button, Input, Table, TableHeader, TableColumn, TableBody, TableRow, TableCell, Chip, Modal, ModalHeader, ModalBody, ModalFooter, Select, SelectItem, Alert } from '@nextui-org/react';
import { Plus, Search, Edit, Trash2, Key, Eye, Copy, Check, Shield, Sparkles } from 'lucide-react';
import Layout from '@/components/Layout';
import { apiKeyAPI } from '@/services/api';
import type { ApiKey } from '@/types';

const mockApiKeys: ApiKey[] = [
  { id: '1', provider: 'qwen', model: 'qwen-max', isActive: true, rateLimitPerMin: 60, createdAt: '2026-05-15' },
  { id: '2', provider: 'qwen', model: 'qwen-plus', isActive: true, rateLimitPerMin: 30, createdAt: '2026-05-16' },
  { id: '3', provider: 'qwen', model: 'qwen-turbo', isActive: false, rateLimitPerMin: 100, createdAt: '2026-05-17' },
];

export default function ApiKeysPage() {
  const [apiKeys, setApiKeys] = useState<ApiKey[]>(mockApiKeys);
  const [searchTerm, setSearchTerm] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);
  const [showViewModal, setShowViewModal] = useState(false);
  const [selectedKey, setSelectedKey] = useState<ApiKey | null>(null);
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [newKey, setNewKey] = useState({
    provider: 'qwen',
    model: '',
    apiKey: '',
    rateLimitPerMin: 60,
    isActive: true,
  });

  useEffect(() => {
    const fetchKeys = async () => {
      try {
        const data = await apiKeyAPI.getApiKeys();
        setApiKeys(data);
      } catch (err) {
        console.error('Failed to fetch API keys:', err);
      }
    };
    fetchKeys();
  }, []);

  const filteredKeys = apiKeys.filter(key =>
    key.provider.includes(searchTerm) || key.model.includes(searchTerm)
  );

  const handleAddKey = async () => {
    try {
      await apiKeyAPI.createApiKey(newKey);
      setApiKeys([...apiKeys, { ...newKey, id: `key_${Date.now()}`, createdAt: new Date().toISOString().split('T')[0] }]);
      setShowAddModal(false);
      setNewKey({ provider: 'qwen', model: '', apiKey: '', rateLimitPerMin: 60, isActive: true });
    } catch (err) {
      console.error('Failed to create API key:', err);
    }
  };

  const handleDeleteKey = async (id: string) => {
    try {
      await apiKeyAPI.deleteApiKey(id);
      setApiKeys(apiKeys.filter(k => k.id !== id));
    } catch (err) {
      console.error('Failed to delete API key:', err);
    }
  };

  const handleCopy = (id: string) => {
    if (typeof navigator !== 'undefined') {
      navigator.clipboard.writeText(id);
      setCopiedId(id);
      setTimeout(() => setCopiedId(null), 2000);
    }
  };

  const handleView = (key: ApiKey) => {
    setSelectedKey(key);
    setShowViewModal(true);
  };

  return (
    <Layout currentPage="api-keys">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-semibold text-gray-900">API Key 管理</h1>
            <p className="text-gray-500 mt-1 flex items-center gap-2">
              <Shield className="w-4 h-4" />
              安全地管理第三方服务的 API Key
            </p>
          </div>
          <Button color="primary" className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white" onClick={() => setShowAddModal(true)}>
            <Plus className="w-4 h-4" />
            添加 Key
          </Button>
        </div>

        {/* Search Card */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-4">
            <div className="flex items-center gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input
                  placeholder="搜索提供商或模型..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-12"
                  classNames={{
                    inputWrapper: 'bg-gray-50 border border-gray-200 rounded-xl',
                  }}
                />
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Table Card */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-0">
            <Table>
              <TableHeader>
                <TableColumn className="bg-gray-50/80">提供商</TableColumn>
                <TableColumn className="bg-gray-50/80">模型</TableColumn>
                <TableColumn className="bg-gray-50/80">速率限制</TableColumn>
                <TableColumn className="bg-gray-50/80">状态</TableColumn>
                <TableColumn className="bg-gray-50/80">创建时间</TableColumn>
                <TableColumn className="bg-gray-50/80">操作</TableColumn>
              </TableHeader>
              <TableBody>
                {filteredKeys.map((key) => (
                  <TableRow key={key.id} className="hover:bg-gray-50 transition-colors">
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                          <Key className="w-5 h-5 text-blue-600" />
                        </div>
                        <span className="font-semibold text-gray-800 capitalize">{key.provider}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <span className="font-medium text-gray-700">{key.model}</span>
                    </TableCell>
                    <TableCell>
                      <span className="text-gray-600">{key.rateLimitPerMin}/分钟</span>
                    </TableCell>
                    <TableCell>
                      <Chip color={key.isActive ? 'success' : 'danger'} size="sm" className={key.isActive ? 'bg-green-100 text-green-700 border border-green-200' : 'bg-red-100 text-red-700 border border-red-200'}>
                        {key.isActive ? '活跃' : '停用'}
                      </Chip>
                    </TableCell>
                    <TableCell>
                      <span className="text-gray-500">{key.createdAt}</span>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <Button size="sm" variant="light" color="primary" onClick={() => handleView(key)} className="hover:bg-gray-50">
                          <Eye className="w-4 h-4" />
                        </Button>
                        <Button size="sm" variant="light" color="warning" className="hover:bg-yellow-50">
                          <Edit className="w-4 h-4" />
                        </Button>
                        <Button size="sm" variant="light" color="danger" onClick={() => handleDeleteKey(key.id)} className="hover:bg-red-50">
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardBody>
        </Card>

        {/* Add Modal */}
        <Modal isOpen={showAddModal} onClose={() => setShowAddModal(false)} classNames={{
          base: 'rounded-xl',
        }}>
          <ModalHeader className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
              <Plus className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-lg font-bold text-gray-800">添加新 API Key</p>
              <p className="text-sm text-gray-500">配置第三方服务访问</p>
            </div>
          </ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <Select label="提供商" value={newKey.provider} onChange={(e) => setNewKey({ ...newKey, provider: e.target.value })} classNames={{ trigger: 'rounded-xl' }}>
                <SelectItem key="qwen" value="qwen">阿里云通义千问</SelectItem>
              </Select>
              <Input label="模型名称" placeholder="如: qwen-max" value={newKey.model} onChange={(e) => setNewKey({ ...newKey, model: e.target.value })} classNames={{ inputWrapper: 'rounded-xl' }} />
              <Input label="API Key" type="password" placeholder="输入 API Key" value={newKey.apiKey} onChange={(e) => setNewKey({ ...newKey, apiKey: e.target.value })} classNames={{ inputWrapper: 'rounded-xl' }} />
              <Input label="每分钟速率限制" type="number" value={String(newKey.rateLimitPerMin)} onChange={(e) => setNewKey({ ...newKey, rateLimitPerMin: parseInt(e.target.value) || 60 })} classNames={{ inputWrapper: 'rounded-xl' }} />
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowAddModal(false)} className="hover:bg-gray-100 rounded-xl">取消</Button>
            <Button color="primary" className="bg-blue-600 hover:bg-blue-700 rounded-xl" onClick={handleAddKey}>创建</Button>
          </ModalFooter>
        </Modal>

        {/* View Modal */}
        <Modal isOpen={showViewModal} onClose={() => setShowViewModal(false)} classNames={{
          base: 'rounded-xl',
        }}>
          <ModalHeader className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
              <Sparkles className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-lg font-bold text-gray-800">API Key 详情</p>
              <p className="text-sm text-gray-500">查看 Key 详细信息</p>
            </div>
          </ModalHeader>
          <ModalBody>
            {selectedKey && (
              <div className="space-y-5">
                <Alert color="warning" className="flex items-center gap-2 bg-yellow-50/80 border border-yellow-200/50 rounded-xl">
                  <Shield className="w-5 h-5" />
                  <span>API Key 已加密存储，无法查看原始值</span>
                </Alert>
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">提供商</p>
                    <p className="font-semibold text-gray-800 capitalize">{selectedKey.provider}</p>
                  </div>
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">模型</p>
                    <p className="font-semibold text-gray-800">{selectedKey.model}</p>
                  </div>
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">速率限制</p>
                    <p className="font-semibold text-gray-800">{selectedKey.rateLimitPerMin}/分钟</p>
                  </div>
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">状态</p>
                    <Chip color={selectedKey.isActive ? 'success' : 'danger'} size="sm" className={selectedKey.isActive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}>
                      {selectedKey.isActive ? '活跃' : '停用'}
                    </Chip>
                  </div>
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">创建时间</p>
                    <p className="font-semibold text-gray-800">{selectedKey.createdAt}</p>
                  </div>
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">Key ID</p>
                    <div className="flex items-center gap-2">
                      <p className="font-mono text-sm bg-gray-200/50 px-2 py-1 rounded">{selectedKey.id}</p>
                      <Button size="sm" variant="light" onClick={() => handleCopy(selectedKey.id)} className="hover:bg-gray-100">
                        {copiedId === selectedKey.id ? (
                          <Check className="w-4 h-4 text-green-500" />
                        ) : (
                          <Copy className="w-4 h-4" />
                        )}
                      </Button>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowViewModal(false)} className="hover:bg-gray-100 rounded-xl">关闭</Button>
          </ModalFooter>
        </Modal>
      </div>
    </Layout>
  );
}
