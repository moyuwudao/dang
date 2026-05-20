'use client';

import { useState } from 'react';
import { Card, CardBody, Button, Input, Table, TableHeader, TableColumn, TableBody, TableRow, TableCell, Chip, Modal, ModalHeader, ModalBody, ModalFooter, Pagination } from '@nextui-org/react';
import { Plus, Search, Edit, Trash2, Eye, UserPlus, Users } from 'lucide-react';
import Layout from '@/components/Layout';
import type { User as UserType } from '@/types';

const mockUsers: UserType[] = [
  { id: '1', phone: '13800138000', createdAt: '2026-05-15 10:30' },
  { id: '2', phone: '13800138001', createdAt: '2026-05-16 14:20' },
  { id: '3', phone: '13800138002', createdAt: '2026-05-17 09:15' },
  { id: '4', phone: '13800138003', createdAt: '2026-05-18 16:45' },
  { id: '5', phone: '13800138004', createdAt: '2026-05-19 11:00' },
  { id: '6', phone: '13800138005', createdAt: '2026-05-19 15:30' },
  { id: '7', phone: '13800138006', createdAt: '2026-05-20 08:45' },
];

export default function UsersPage() {
  const [users, setUsers] = useState<UserType[]>(mockUsers);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState<UserType | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [page, setPage] = useState(1);
  const rowsPerPage = 5;

  const filteredUsers = users.filter(user =>
    user.phone.includes(searchTerm) || user.id.includes(searchTerm)
  );

  const paginatedUsers = filteredUsers.slice((page - 1) * rowsPerPage, page * rowsPerPage);
  const totalPages = Math.ceil(filteredUsers.length / rowsPerPage);

  const handleDelete = (id: string) => {
    setUsers(users.filter(u => u.id !== id));
  };

  const handleView = (user: UserType) => {
    setSelectedUser(user);
    setShowModal(true);
  };

  return (
    <Layout currentPage="users">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">用户管理</h1>
            <p className="text-gray-500 mt-1 flex items-center gap-2">
              <Users className="w-4 h-4" />
              共 {filteredUsers.length} 位用户
            </p>
          </div>
          <Button color="primary" className="flex items-center gap-2 bg-gradient-to-r from-indigo-500 to-purple-500 shadow-lg shadow-indigo-500/30">
            <UserPlus className="w-4 h-4" />
            添加用户
          </Button>
        </div>

        {/* Search Card */}
        <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
          <CardBody className="p-4">
            <div className="flex items-center gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input
                  placeholder="搜索用户手机号..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-12"
                  classNames={{
                    inputWrapper: 'bg-gray-50/80 border border-gray-200/50 rounded-xl',
                  }}
                />
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Table Card */}
        <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
          <CardBody className="p-0">
            <Table>
              <TableHeader>
                <TableColumn className="bg-gray-50/80">用户ID</TableColumn>
                <TableColumn className="bg-gray-50/80">手机号</TableColumn>
                <TableColumn className="bg-gray-50/80">注册时间</TableColumn>
                <TableColumn className="bg-gray-50/80">状态</TableColumn>
                <TableColumn className="bg-gray-50/80">操作</TableColumn>
              </TableHeader>
              <TableBody>
                {paginatedUsers.map((user) => (
                  <TableRow key={user.id} className="hover:bg-indigo-50/30 transition-colors">
                    <TableCell>
                      <span className="font-mono text-sm text-gray-600 bg-gray-100 px-2 py-1 rounded">{user.id.slice(0, 8)}...</span>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center shadow-md">
                          <span className="text-white font-semibold">U</span>
                        </div>
                        <span className="font-medium text-gray-800">{user.phone}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <span className="text-gray-600">{user.createdAt}</span>
                    </TableCell>
                    <TableCell>
                      <Chip color="success" size="sm" className="bg-green-100 text-green-700 border border-green-200">
                        活跃
                      </Chip>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <Button
                          size="sm"
                          variant="light"
                          color="primary"
                          onClick={() => handleView(user)}
                          className="hover:bg-indigo-50"
                        >
                          <Eye className="w-4 h-4" />
                        </Button>
                        <Button size="sm" variant="light" color="warning" className="hover:bg-yellow-50">
                          <Edit className="w-4 h-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="light"
                          color="danger"
                          onClick={() => handleDelete(user.id)}
                          className="hover:bg-red-50"
                        >
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
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
                    item: 'bg-gray-100/50 hover:bg-indigo-50',
                    cursor: 'bg-gradient-to-r from-indigo-500 to-purple-500 shadow-lg',
                  }}
                />
              </div>
            )}
          </CardBody>
        </Card>

        {/* User Detail Modal */}
        <Modal isOpen={showModal} onClose={() => setShowModal(false)} classNames={{
          base: 'rounded-2xl',
          header: 'border-b border-gray-100',
          footer: 'border-t border-gray-100',
        }}>
          <ModalHeader className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center">
              <span className="text-white text-lg font-bold">U</span>
            </div>
            <div>
              <p className="text-lg font-bold text-gray-800">用户详情</p>
              <p className="text-sm text-gray-500">查看用户详细信息</p>
            </div>
          </ModalHeader>
          <ModalBody>
            {selectedUser && (
              <div className="space-y-6">
                <div className="flex items-center gap-4 p-4 bg-gradient-to-r from-indigo-50/50 to-purple-50/50 rounded-xl">
                  <div className="w-16 h-16 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center shadow-lg">
                    <span className="text-white text-2xl font-bold">U</span>
                  </div>
                  <div>
                    <p className="text-xl font-bold text-gray-800">{selectedUser.phone}</p>
                    <p className="text-gray-500 font-mono text-sm">ID: {selectedUser.id}</p>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">注册时间</p>
                    <p className="font-semibold text-gray-800">{selectedUser.createdAt}</p>
                  </div>
                  <div className="p-4 bg-gray-50/80 rounded-xl">
                    <p className="text-sm text-gray-500 mb-1">状态</p>
                    <Chip color="success" size="sm" className="bg-green-100 text-green-700">活跃</Chip>
                  </div>
                </div>
              </div>
            )}
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowModal(false)} className="hover:bg-gray-100">
              关闭
            </Button>
            <Button color="primary" className="bg-gradient-to-r from-indigo-500 to-purple-500">
              编辑用户
            </Button>
          </ModalFooter>
        </Modal>
      </div>
    </Layout>
  );
}
