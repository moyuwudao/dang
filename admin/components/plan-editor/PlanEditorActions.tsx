'use client';

import { Button } from '@nextui-org/react';
import { Save, ArrowLeft, Info } from 'lucide-react';

interface Props {
  saving: boolean;
  isEdit: boolean;
  onCancel: () => void;
  onSave: () => void;
  hasChanges?: boolean;
}

/**
 * 套餐编辑底部操作栏
 * 始终在页面底部 sticky 显示，方便长页面随时保存
 */
export default function PlanEditorActions({ saving, isEdit, onCancel, onSave }: Props) {
  return (
    <div className="sticky bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-sm border-t border-gray-200 shadow-lg -mx-4 px-6 py-3 mt-6">
      <div className="flex items-center justify-between gap-3 max-w-screen-2xl mx-auto">
        <div className="text-xs text-gray-500 flex items-center gap-1">
          <Info className="w-3 h-3" />
          <span>修改后请点击「保存」按钮持久化到服务器</span>
        </div>
        <div className="flex gap-2">
          <Button
            variant="light"
            startContent={<ArrowLeft className="w-4 h-4" />}
            onClick={onCancel}
            size="sm"
            isDisabled={saving}
          >
            取消
          </Button>
          <Button
            color="primary"
            startContent={!saving && <Save className="w-4 h-4" />}
            onClick={onSave}
            isLoading={saving}
            size="sm"
          >
            {saving ? '保存中...' : isEdit ? '保存修改' : '创建套餐'}
          </Button>
        </div>
      </div>
    </div>
  );
}
