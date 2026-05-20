'use client';

import { useState, useEffect } from 'react';
import { Card, CardBody, Button, Input, Table, TableHeader, TableColumn, TableBody, TableRow, TableCell, Chip, Modal, ModalHeader, ModalBody, ModalFooter, Select, SelectItem, Alert } from '@nextui-org/react';
import { Plus, Search, Edit, Trash2, Key, Eye, Copy, Check } from 'lucide-react';
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
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">API Key 管理</h1>
            <p className="text-gray-500 mt-1">管理第三方服务的 API Key</p>
          </div>
          <Button color="primary" className="flex items-center gap-2" onClick={() => setShowAddModal(true)}>
            <Plus className="w-4 h-4" />
            添加 Key
          </Button>
        </div>

        <Card className="bg-white border border-gray-200">
          <CardBody className="p-4">
            <div className="flex items-center gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input
                  placeholder="搜索提供商或模型..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
          </CardBody>
        </Card>

        <Card className="bg-white border border-gray-200">
          <CardBody className="p-0">
            <Table>
              <TableHeader>
                <TableColumn>提供商</TableColumn>
                <TableColumn>模型</TableColumn>
                <TableColumn>速率限制</TableColumn>
                <TableColumn>状态</TableColumn>
                <TableColumn>创建时间</TableColumn>
                <TableColumn>操作</TableColumn>
              </TableHeader>
              <TableBody>
                {filteredKeys.map((key) => (
                  <TableRow key={key.id}>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-lg bg-gradient-to-r from-indigo-500 to-purple-500 flex items-center justify-center">
                          <Key className="w-4 h-4 text-white" />
                        </div>
                        <span className="font-medium">{key.provider}</span>
                      </div>
                    </TableCell>
                    <TableCell>{key.model}</TableCell>
                    <TableCell>{key.rateLimitPerMin}/分钟</TableCell>
                    <TableCell>
                      <Chip color={key.isActive ? 'success' : 'danger'} size="sm">
                        {key.isActive ? '活跃' : '停用'}
                      </Chip>
                    </TableCell>
                    <TableCell>{key.createdAt}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Button size="sm" variant="light" color="primary" onClick={() => handleView(key)}>
                          <Eye className="w-4 h-4" />
                        </Button>
                        <Button size="sm" variant="light" color="warning">
                          <Edit className="w-4 h-4" />
                        </Button>
                        <Button size="sm" variant="light" color="danger" onClick={() => handleDeleteKey(key.id)}>
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

        <Modal isOpen={showAddModal} onClose={() => setShowAddModal(false)}>
          <ModalHeader>添加新 API Key</ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <Select label="提供商" value={newKey.provider} onChange={(e) => setNewKey({ ...newKey, provider: e.target.value })}>
                <SelectItem key="qwen" value="qwen">阿里云通义千问</SelectItem>
              </Select>
              <Input label="模型名称" placeholder="如: qwen-max" value={newKey.model} onChange={(e) => setNewKey({ ...newKey, model: e.target.value })} />
              <Input label="API Key" type="password" placeholder="输入 API Key" value={newKey.apiKey} onChange={(e) => setNewKey({ ...newKey, apiKey: e.target.value })} />
              <Input label="每分钟速率限制" type="number" value={String(newKey.rateLimitPerMin)} onChange={(e) => setNewKey({ ...newKey, rateLimitPerMin: parseInt(e.target.value) || 60 })} />
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowAddModal(false)}>取消</Button>
            <Button color="primary" onClick={handleAddKey}>创建</Button>
          </ModalFooter>
        </Modal>

        <Modal isOpen={showViewModal} onClose={() => setShowViewModal(false)}>
          <ModalHeader>API Key 详情</ModalHeader>
          <ModalBody>
            {selectedKey && (
              <div className="space-y-4">
                <Alert color="warning" className="flex items-center gap-2">
                  <Key className="w-5 h-5" />
                  <span>API Key 已加密存储，无法查看原始值</span>
                </Alert>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-500">提供商</p>
                    <p className="font-medium">{selectedKey.provider}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">模型</p>
                    <p className="font-medium">{selectedKey.model}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">速率限制</p>
                    <p className="font-medium">{selectedKey.rateLimitPerMin}/分钟</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">状态</p>
                    <Chip color={selectedKey.isActive ? 'success' : 'danger'}>{selectedKey.isActive ? '活跃' : '停用'}</Chip>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">创建时间</p>
                    <p className="font-medium">{selectedKey.createdAt}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Key ID</p>
                    <div className="flex items-center gap-2">
                      <p className="font-mono text-sm">{selectedKey.id}</p>
                      <Button size="sm" variant="light" onClick={() => handleCopy(selectedKey.id)}>
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
            <Button variant="light" onClick={() => setShowViewModal(false)}>关闭</Button>
          </ModalFooter>
        </Modal>
      </div>
    </Layout>
  );
}
