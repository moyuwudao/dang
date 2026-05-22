'use client';

import { useState, useEffect, useCallback } from 'react';
import { Card, CardBody, Button, Input, Table, TableHeader, TableColumn, TableBody, TableRow, TableCell, Chip, Modal, ModalHeader, ModalBody, ModalFooter, Pagination, Spinner, Select, SelectItem } from '@nextui-org/react';
import { Search, Edit, Trash2, Eye, UserPlus, Users, AlertCircle, RefreshCw } from 'lucide-react';
import Layout from '@/components/Layout';
import { adminAPI } from '@/services/api';
import type { User } from '@/types';

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [userToDelete, setUserToDelete] = useState<string | null>(null);
  const [editForm, setEditForm] = useState({ status: '', role: '' });
  const [createForm, setCreateForm] = useState({
    phone: '',
    password: '',
    nickname: '',
    role: 'user',
    status: 'active',
  });
  const [createLoading, setCreateLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const rowsPerPage = 10;

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await adminAPI.getUsers(page, rowsPerPage, searchTerm || undefined);
      setUsers(data.items);
      setTotal(data.total);
      setTotalPages(data.totalPages);
    } catch (err: any) {
      setError(err.response?.data?.message || '获取用户列表失败，请重试');
    } finally {
      setLoading(false);
    }
  }, [page, searchTerm]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const handleSearch = () => {
    setPage(1);
    fetchUsers();
  };

  const handleDelete = async () => {
    if (!userToDelete) return;
    try {
      await adminAPI.deleteUser(userToDelete);
      setShowDeleteModal(false);
      setUserToDelete(null);
      fetchUsers();
    } catch (err: any) {
      setError(err.response?.data?.message || '删除用户失败');
    }
  };

  const handleUpdateUser = async () => {
    if (!selectedUser) return;
    try {
      await adminAPI.updateUser(selectedUser.id, {
        status: editForm.status,
        role: editForm.role,
      });
      setShowEditModal(false);
      setSelectedUser(null);
      fetchUsers();
    } catch (err: any) {
      setError(err.response?.data?.message || '更新用户失败');
    }
  };

  const openDetail = (user: User) => {
    setSelectedUser(user);
    setShowDetailModal(true);
  };

  const openEdit = (user: User) => {
    setSelectedUser(user);
    setEditForm({ status: user.status, role: user.role });
    setShowEditModal(true);
  };

  const openDelete = (id: string) => {
    setUserToDelete(id);
    setShowDeleteModal(true);
  };

  const handleCreateUser = async () => {
    if (!createForm.phone || !createForm.password) {
      setError('请填写手机号和密码');
      return;
    }
    
    setCreateLoading(true);
    try {
      await adminAPI.createUser(createForm);
      setShowCreateModal(false);
      setCreateForm({
        phone: '',
        password: '',
        nickname: '',
        role: 'user',
        status: 'active',
      });
      setError(null);
      fetchUsers();
    } catch (err: any) {
      setError(err.response?.data?.message || '创建用户失败');
    } finally {
      setCreateLoading(false);
    }
  };

  const getStatusConfig = (status: string) => {
    switch (status) {
      case 'active':
        return { label: '活跃', className: 'bg-green-50 text-green-700 border-green-200' };
      case 'banned':
        return { label: '停用', className: 'bg-red-50 text-red-700 border-red-200' };
      default:
        return { label: status, className: 'bg-gray-50 text-gray-700 border-gray-200' };
    }
  };

  const getRoleConfig = (role: string) => {
    switch (role) {
      case 'admin':
        return { label: '管理员', className: 'bg-purple-50 text-purple-700 border-purple-200' };
      case 'user':
        return { label: '普通用户', className: 'bg-blue-50 text-blue-700 border-blue-200' };
      default:
        return { label: role, className: 'bg-gray-50 text-gray-700 border-gray-200' };
    }
  };

  return (
    <Layout currentPage="users">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-semibold text-gray-900">用户管理</h1>
            <p className="text-gray-500 mt-1 flex items-center gap-2">
              <Users className="w-4 h-4" />
              共 {total} 位用户
            </p>
          </div>
          <Button 
            color="primary" 
            className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white"
            onClick={() => setShowCreateModal(true)}
          >
            <UserPlus className="w-4 h-4" />
            添加用户
          </Button>
        </div>

        {/* Search Card */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-4">
            <div className="flex items-center gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input
                  placeholder="搜索手机号或昵称..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                  className="pl-12"
                  size="sm"
                  classNames={{
                    inputWrapper: 'bg-gray-50 border border-gray-200 rounded-xl',
                  }}
                />
              </div>
              <Button
                color="primary"
                className="bg-blue-600 hover:bg-blue-700 text-white"
                onClick={handleSearch}
                isLoading={loading}
              >
                搜索
              </Button>
              <Button
                variant="light"
                className="hover:bg-gray-100"
                onClick={fetchUsers}
                isIconOnly
              >
                <RefreshCw className="w-4 h-4" />
              </Button>
            </div>
          </CardBody>
        </Card>

        {/* Error Alert */}
        {error && (
          <div className="flex items-center gap-3 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700">
            <AlertCircle className="w-5 h-5 flex-shrink-0" />
            <span className="flex-1">{error}</span>
            <Button size="sm" variant="light" color="danger" onClick={fetchUsers}>
              重试
            </Button>
          </div>
        )}

        {/* Table Card */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-0">
            {loading && users.length === 0 ? (
              <div className="flex items-center justify-center py-20">
                <Spinner size="lg" color="primary" />
              </div>
            ) : (
              <>
                <Table>
                  <TableHeader>
                    <TableColumn className="bg-gray-50/80">手机号</TableColumn>
                    <TableColumn className="bg-gray-50/80">昵称</TableColumn>
                    <TableColumn className="bg-gray-50/80">状态</TableColumn>
                    <TableColumn className="bg-gray-50/80">角色</TableColumn>
                    <TableColumn className="bg-gray-50/80">订阅数</TableColumn>
                    <TableColumn className="bg-gray-50/80">余额</TableColumn>
                    <TableColumn className="bg-gray-50/80">注册时间</TableColumn>
                    <TableColumn className="bg-gray-50/80">操作</TableColumn>
                  </TableHeader>
                  <TableBody>
                    {users.map((user) => {
                      const statusConfig = getStatusConfig(user.status);
                      const roleConfig = getRoleConfig(user.role);
                      return (
                        <TableRow key={user.id} className="hover:bg-gray-50 transition-colors">
                          <TableCell>
                            <div className="flex items-center gap-3">
                              <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                                <span className="text-blue-600 font-semibold">{user.phone.slice(-1)}</span>
                              </div>
                              <span className="font-medium text-gray-800">{user.phone}</span>
                            </div>
                          </TableCell>
                          <TableCell>
                            <span className="text-gray-700">{user.nickname || '-'}</span>
                          </TableCell>
                          <TableCell>
                            <span className={`px-2.5 py-1 text-xs rounded-full border ${statusConfig.className}`}>
                              {statusConfig.label}
                            </span>
                          </TableCell>
                          <TableCell>
                            <span className={`px-2.5 py-1 text-xs rounded-full border ${roleConfig.className}`}>
                              {roleConfig.label}
                            </span>
                          </TableCell>
                          <TableCell>
                            <span className="text-gray-700">{user.subscriptionCount ?? 0}</span>
                          </TableCell>
                          <TableCell>
                            <span className="text-gray-700 font-medium">¥{(user.balance ?? 0).toFixed(2)}</span>
                          </TableCell>
                          <TableCell>
                            <span className="text-gray-600 text-sm">{user.createdAt}</span>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-1">
                              <Button
                                size="sm"
                                variant="light"
                                color="primary"
                                onClick={() => openDetail(user)}
                                className="hover:bg-gray-50"
                                isIconOnly
                              >
                                <Eye className="w-4 h-4" />
                              </Button>
                              <Button
                                size="sm"
                                variant="light"
                                color="warning"
                                onClick={() => openEdit(user)}
                                className="hover:bg-yellow-50"
                                isIconOnly
                              >
                                <Edit className="w-4 h-4" />
                              </Button>
                              <Button
                                size="sm"
                                variant="light"
                                color="danger"
                                onClick={() => openDelete(user.id)}
                                className="hover:bg-red-50"
                                isIconOnly
                              >
                                <Trash2 className="w-4 h-4" />
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>

                {/* Pagination */}
                {totalPages > 1 && (
                  <div className="flex justify-center py-4 border-t border-gray-100">
                    <Pagination
                      total={totalPages}
                      page={page}
                      onChange={setPage}
                      showControls
                      color="primary"
                      classNames={{
                        wrapper: 'gap-2',
                        item: 'bg-gray-100 hover:bg-gray-50',
                        cursor: 'bg-blue-600',
                      }}
                    />
                  </div>
                )}
              </>
            )}
          </CardBody>
        </Card>

        {/* User Detail Modal */}
        <Modal isOpen={showDetailModal} onClose={() => setShowDetailModal(false)} classNames={{
          base: 'rounded-xl',
          header: 'border-b border-gray-100',
          footer: 'border-t border-gray-100',
        }}>
          <ModalHeader className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
              <span className="text-blue-600 text-lg font-bold">{selectedUser?.phone.slice(-1)}</span>
            </div>
            <div>
              <p className="text-lg font-bold text-gray-800">用户详情</p>
              <p className="text-sm text-gray-500">查看用户详细信息</p>
            </div>
          </ModalHeader>
          <ModalBody>
            {selectedUser && (
              <div className="space-y-6">
                <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-lg">
                  <div className="w-16 h-16 rounded-lg bg-blue-50 flex items-center justify-center">
                    <span className="text-blue-600 text-2xl font-bold">{selectedUser.phone.slice(-1)}</span>
                  </div>
                  <div>
                    <p className="text-xl font-bold text-gray-800">{selectedUser.phone}</p>
                    <p className="text-gray-500 font-mono text-sm">ID: {selectedUser.id}</p>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">昵称</p>
                    <p className="font-semibold text-gray-800">{selectedUser.nickname || '-'}</p>
                  </div>
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">状态</p>
                    <span className={`px-2.5 py-1 text-xs rounded-full border ${getStatusConfig(selectedUser.status).className}`}>
                      {getStatusConfig(selectedUser.status).label}
                    </span>
                  </div>
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">角色</p>
                    <span className={`px-2.5 py-1 text-xs rounded-full border ${getRoleConfig(selectedUser.role).className}`}>
                      {getRoleConfig(selectedUser.role).label}
                    </span>
                  </div>
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">订阅数</p>
                    <p className="font-semibold text-gray-800">{selectedUser.subscriptionCount ?? 0}</p>
                  </div>
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">余额</p>
                    <p className="font-semibold text-gray-800">¥{(selectedUser.balance ?? 0).toFixed(2)}</p>
                  </div>
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">注册时间</p>
                    <p className="font-semibold text-gray-800">{selectedUser.createdAt}</p>
                  </div>
                </div>
              </div>
            )}
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowDetailModal(false)} className="hover:bg-gray-100">
              关闭
            </Button>
            <Button color="primary" className="bg-blue-600 hover:bg-blue-700" onClick={() => {
              setShowDetailModal(false);
              if (selectedUser) openEdit(selectedUser);
            }}>
              编辑用户
            </Button>
          </ModalFooter>
        </Modal>

        {/* Edit User Modal */}
        <Modal isOpen={showEditModal} onClose={() => setShowEditModal(false)} classNames={{
          base: 'rounded-xl',
          header: 'border-b border-gray-100',
          footer: 'border-t border-gray-100',
        }}>
          <ModalHeader className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
              <Edit className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-lg font-bold text-gray-800">编辑用户</p>
              <p className="text-sm text-gray-500">{selectedUser?.phone}</p>
            </div>
          </ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <Select
                label="状态"
                selectedKeys={[editForm.status]}
                onChange={(e) => setEditForm({ ...editForm, status: e.target.value })}
                classNames={{ trigger: 'rounded-xl' }}
              >
                <SelectItem key="active" value="active">活跃</SelectItem>
                <SelectItem key="banned" value="banned">停用</SelectItem>
              </Select>
              <Select
                label="角色"
                selectedKeys={[editForm.role]}
                onChange={(e) => setEditForm({ ...editForm, role: e.target.value })}
                classNames={{ trigger: 'rounded-xl' }}
              >
                <SelectItem key="user" value="user">普通用户</SelectItem>
                <SelectItem key="admin" value="admin">管理员</SelectItem>
              </Select>
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowEditModal(false)} className="hover:bg-gray-100">
              取消
            </Button>
            <Button color="primary" className="bg-blue-600 hover:bg-blue-700" onClick={handleUpdateUser}>
              保存
            </Button>
          </ModalFooter>
        </Modal>

        {/* Create User Modal */}
        <Modal isOpen={showCreateModal} onClose={() => setShowCreateModal(false)} classNames={{
          base: 'rounded-xl',
          header: 'border-b border-gray-100',
          footer: 'border-t border-gray-100',
        }}>
          <ModalHeader className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
              <UserPlus className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-lg font-bold text-gray-800">添加用户</p>
              <p className="text-sm text-gray-500">创建新的用户账户</p>
            </div>
          </ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <Input
                label="手机号"
                placeholder="请输入手机号"
                value={createForm.phone}
                onChange={(e) => setCreateForm({ ...createForm, phone: e.target.value })}
                classNames={{ inputWrapper: 'rounded-xl' }}
                isRequired
              />
              <Input
                label="密码"
                type="password"
                placeholder="请设置密码"
                value={createForm.password}
                onChange={(e) => setCreateForm({ ...createForm, password: e.target.value })}
                classNames={{ inputWrapper: 'rounded-xl' }}
                isRequired
              />
              <Input
                label="昵称"
                placeholder="请输入昵称（可选）"
                value={createForm.nickname}
                onChange={(e) => setCreateForm({ ...createForm, nickname: e.target.value })}
                classNames={{ inputWrapper: 'rounded-xl' }}
              />
              <Select
                label="角色"
                selectedKeys={[createForm.role]}
                onChange={(e) => setCreateForm({ ...createForm, role: e.target.value })}
                classNames={{ trigger: 'rounded-xl' }}
              >
                <SelectItem key="user" value="user">普通用户</SelectItem>
                <SelectItem key="admin" value="admin">管理员</SelectItem>
              </Select>
              <Select
                label="状态"
                selectedKeys={[createForm.status]}
                onChange={(e) => setCreateForm({ ...createForm, status: e.target.value })}
                classNames={{ trigger: 'rounded-xl' }}
              >
                <SelectItem key="active" value="active">活跃</SelectItem>
                <SelectItem key="banned" value="banned">停用</SelectItem>
              </Select>
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowCreateModal(false)} className="hover:bg-gray-100">
              取消
            </Button>
            <Button 
              color="primary" 
              className="bg-blue-600 hover:bg-blue-700" 
              onClick={handleCreateUser}
              isLoading={createLoading}
            >
              创建
            </Button>
          </ModalFooter>
        </Modal>

        {/* Delete Confirm Modal */}
        <Modal isOpen={showDeleteModal} onClose={() => setShowDeleteModal(false)} classNames={{
          base: 'rounded-xl',
          header: 'border-b border-gray-100',
          footer: 'border-t border-gray-100',
        }}>
          <ModalHeader className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-red-50 flex items-center justify-center">
              <Trash2 className="w-5 h-5 text-red-600" />
            </div>
            <div>
              <p className="text-lg font-bold text-gray-800">确认删除</p>
              <p className="text-sm text-gray-500">此操作不可撤销</p>
            </div>
          </ModalHeader>
          <ModalBody>
            <p className="text-gray-600">确定要删除该用户吗？删除后该用户的所有数据将被清除。</p>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowDeleteModal(false)} className="hover:bg-gray-100">
              取消
            </Button>
            <Button color="danger" className="bg-red-600 hover:bg-red-700" onClick={handleDelete}>
              确认删除
            </Button>
          </ModalFooter>
        </Modal>
      </div>
    </Layout>
  );
}
