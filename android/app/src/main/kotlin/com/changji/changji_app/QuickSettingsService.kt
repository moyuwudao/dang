package com.changji.changji_app

import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class QuickSettingsService : TileService() {

    override fun onClick() {
        super.onClick()
        
        // 启动录音界面
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "com.changji.changji_app.RECORD"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        // 解锁设备（如果需要）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(intent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    override fun onStartListening() {
        super.onStartListening()
        updateTile()
    }

    private fun updateTile() {
        val tile = qsTile
        tile?.apply {
            state = Tile.STATE_ACTIVE
            label = "畅记录音"
            contentDescription = "点击开始录音"
            updateTile()
        }
    }
}
