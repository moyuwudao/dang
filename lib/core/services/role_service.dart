import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_role.dart';

class RoleService {
  static const String _customRolesKey = 'custom_ai_roles';
  static const String _selectedRoleKey = 'selected_ai_role';

  // Get all roles (built-in + custom)
  static Future<List<AiRole>> getAllRoles() async {
    final customRoles = await getCustomRoles();
    return [...AiRole.builtInRoles, ...customRoles];
  }

  // Get only custom roles
  static Future<List<AiRole>> getCustomRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_customRolesKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => AiRole.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Add custom role
  static Future<void> addCustomRole(AiRole role) async {
    final roles = await getCustomRoles();
    roles.add(role);
    await _saveCustomRoles(roles);
  }

  // Update custom role
  static Future<void> updateCustomRole(AiRole updatedRole) async {
    final roles = await getCustomRoles();
    final index = roles.indexWhere((r) => r.id == updatedRole.id);
    if (index >= 0) {
      roles[index] = updatedRole;
      await _saveCustomRoles(roles);
    }
  }

  // Delete custom role
  static Future<void> deleteCustomRole(String roleId) async {
    final roles = await getCustomRoles();
    roles.removeWhere((r) => r.id == roleId);
    await _saveCustomRoles(roles);
  }

  // Save custom roles
  static Future<void> _saveCustomRoles(List<AiRole> roles) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = roles.map((r) => r.toJson()).toList();
    await prefs.setString(_customRolesKey, jsonEncode(jsonList));
  }

  // Get selected role ID
  static Future<String?> getSelectedRoleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedRoleKey);
  }

  // Set selected role ID
  static Future<void> setSelectedRoleId(String roleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedRoleKey, roleId);
  }

  // Get role by ID
  static Future<AiRole?> getRoleById(String roleId) async {
    final allRoles = await getAllRoles();
    try {
      return allRoles.firstWhere((r) => r.id == roleId);
    } catch (e) {
      return null;
    }
  }

  // Get default role (first built-in)
  static AiRole getDefaultRole() {
    return AiRole.builtInRoles.first;
  }
}
