import json
import os

pub_cache = "/home/mayn/.pub-cache/hosted/pub.flutter-io.cn"

# 手动列出已知的插件
plugins = []
plugin_names = [
    "add_2_calendar", "audio_session", "audioplayers", "audioplayers_android",
    "audioplayers_darwin", "audioplayers_linux", "audioplayers_web",
    "audioplayers_windows", "battery_plus", "connectivity_plus",
    "device_info_plus", "file_picker", "flutter_plugin_android_lifecycle",
    "geolocator", "geolocator_android", "geolocator_apple",
    "geolocator_web", "geolocator_windows", "image_cropper",
    "image_picker", "image_picker_android", "image_picker_for_web",
    "image_picker_ios", "image_picker_linux", "image_picker_macos",
    "image_picker_windows", "just_audio", "just_audio_platform_interface",
    "just_audio_web", "local_auth", "local_auth_android",
    "local_auth_darwin", "local_auth_windows", "network_info_plus",
    "package_info_plus", "path_provider", "path_provider_android",
    "path_provider_foundation", "path_provider_linux", "path_provider_windows",
    "permission_handler", "permission_handler_android",
    "permission_handler_apple", "permission_handler_html",
    "permission_handler_windows", "record", "record_android",
    "record_darwin", "record_linux", "record_web", "record_windows",
    "share_plus", "shared_preferences", "shared_preferences_android",
    "shared_preferences_foundation", "shared_preferences_linux",
    "shared_preferences_web", "shared_preferences_windows", "sqflite",
    "sqflite_common", "url_launcher", "url_launcher_android",
    "url_launcher_ios", "url_launcher_linux", "url_launcher_macos",
    "url_launcher_web", "url_launcher_windows", "webview_flutter",
    "webview_flutter_android", "webview_flutter_wkwebview"
]

for name in plugin_names:
    # 查找版本目录
    dirs = [d for d in os.listdir(pub_cache) if d.startswith(name + "-")]
    if dirs:
        version_dir = sorted(dirs)[-1]  # 取最新版本
        plugin_dir = os.path.join(pub_cache, version_dir)
        android_dir = os.path.join(plugin_dir, "android")
        if os.path.exists(android_dir):
            plugins.append({
                "name": name,
                "path": plugin_dir,
                "dependencies": [],
                "native_build": True,
                "dev_dependency": False
            })

# 构建 flutter-plugins-dependencies 结构
data = {
    "info": "This is a generated file; do not edit or check into version control.",
    "plugins": {
        "android": plugins
    },
    "dependencyGraph": []
}

# 写入文件
with open("/home/mayn/dang/.flutter-plugins-dependencies", "w") as f:
    json.dump(data, f, indent=2)

print(f"Generated .flutter-plugins-dependencies with {len(plugins)} plugins")
for p in plugins[:5]:
    print(f"  - {p['name']}: {p['path']}")
