'use client';

import { useState } from 'react';
import { Card, CardBody, Button, Input, Table, TableHeader, TableColumn, TableBody, TableRow, TableCell, Chip, Modal, ModalHeader, ModalBody, ModalFooter } from '@nextui-org/react';
import { Plus, Search, Edit, Trash2, Eye } from 'lucide-react';
import Layout from '@/components/Layout';
import type { User as UserType } from '@/types';

const mockUsers: UserType[] = [
  { id: '1', phone: '13800138000', createdAt: '2026-05-15 10:30' },
  { id: '2', phone: '13800138001', createdAt: '2026-05-16 14:20' },
  { id: '3', phone: '13800138002', createdAt: '2026-05-17 09:15' },
  { id: '4', phone: '13800138003', createdAt: '2026-05-18 16:45' },
  { id: '5', phone: '13800138004', createdAt: '2026-05-19 11:00' },
];

export default function UsersPage() {
  const [users, setUsers] = useState<UserType[]>(mockUsers);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState<UserType | null>(null);
  const [showModal, setShowModal] = useState(false);

  const filteredUsers = users.filter(user => 
    user.phone.includes(searchTerm) || user.id.includes(searchTerm)
  );

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
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">用户管理</h1>
            <p className="text-gray-500 mt-1">管理平台用户账户</p>
          </div>
          <Button color="primary" className="flex items-center gap-2">
            <Plus className="w-4 h-4" />
            添加用户
          </Button>
        </div>

        <Card className="bg-white border border-gray-200">
          <CardBody className="p-4">
            <div className="flex items-center gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input
                  placeholder="搜索用户手机号..."
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
                <TableColumn>用户ID</TableColumn>
                <TableColumn>手机号</TableColumn>
                <TableColumn>注册时间</TableColumn>
                <TableColumn>状态</TableColumn>
                <TableColumn>操作</TableColumn>
              </TableHeader>
              <TableBody>
                {filteredUsers.map((user) => (
                  <TableRow key={user.id}>
                    <TableCell>{user.id.slice(0, 8)}...</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-full bg-gradient-to-r from-indigo-500 to-purple-500 flex items-center justify-center">
                          <span className="text-white text-xs">U</span>
                        </div>
                        {user.phone}
                      </div>
                    </TableCell>
                    <TableCell>{user.createdAt}</TableCell>
                    <TableCell>
                      <Chip color="success" size="sm">活跃</Chip>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Button
                          size="sm"
                          variant="light"
                          color="primary"
                          onClick={() => handleView(user)}
                        >
                          <Eye className="w-4 h-4" />
                        </Button>
                        <Button size="sm" variant="light" color="warning">
                          <Edit className="w-4 h-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="light"
                          color="danger"
                          onClick={() => handleDelete(user.id)}
                        >
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

        <Modal isOpen={showModal} onClose={() => setShowModal(false)}>
          <ModalHeader>用户详情</ModalHeader>
          <ModalBody>
            {selectedUser && (
              <div className="space-y-4">
                <div className="flex items-center gap-4">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-r from-indigo-500 to-purple-500 flex items-center justify-center">
                    <span className="text-white text-xl">U</span>
                  </div>
                  <div>
                    <p className="text-xl font-bold">{selectedUser.phone}</p>
                    <p className="text-gray-500">用户ID: {selectedUser.id}</p>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-500">注册时间</p>
                    <p className="font-medium">{selectedUser.createdAt}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">状态</p>
                    <Chip color="success">活跃</Chip>
                  </div>
                </div>
              </div>
            )}
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowModal(false)}>关闭</Button>
            <Button color="primary">编辑用户</Button>
          </ModalFooter>
        </Modal>
      </div>
    </Layout>
  );
}
