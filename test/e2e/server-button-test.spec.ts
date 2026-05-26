import { test, expect } from '@playwright/test';

const BASE_URL = 'http://101.133.238.249';

test.describe('服务器端按钮响应测试', () => {
  test('登录页面加载正常', async ({ page }) => {
    await page.goto(`${BASE_URL}/login`);
    
    await expect(page.locator('h1')).toContainText('畅记云管理后台');
    await expect(page.locator('input[placeholder*="手机号"]')).toBeVisible();
    await expect(page.locator('input[placeholder*="密码"]')).toBeVisible();
    await expect(page.locator('button:has-text("登录")')).toBeVisible();
  });

  test('登录功能正常', async ({ page }) => {
    await page.goto(`${BASE_URL}/login`);
    
    await page.fill('input[placeholder*="手机号"]', '13800138001');
    await page.fill('input[placeholder*="密码"]', 'ChangJi@2026#Admin!');
    
    await page.click('button:has-text("登录")');
    
    await page.waitForURL(`${BASE_URL}/dashboard`, { timeout: 5000 });
    
    await expect(page.locator('h1')).toContainText('仪表板');
  });

  test('Dashboard 刷新按钮响应', async ({ page }) => {
    await page.goto(`${BASE_URL}/login`);
    await page.fill('input[placeholder*="手机号"]', '13800138001');
    await page.fill('input[placeholder*="密码"]', 'ChangJi@2026#Admin!');
    await page.click('button:has-text("登录")');
    await page.waitForURL(`${BASE_URL}/dashboard`);

    const refreshButton = page.locator('button:has-text("刷新")');
    await expect(refreshButton).toBeVisible();
    
    await refreshButton.click();
    
    await page.waitForTimeout(2000);
    
    await expect(page.locator('h1')).toContainText('仪表板');
  });

  test('侧边栏导航按钮响应', async ({ page }) => {
    await page.goto(`${BASE_URL}/login`);
    await page.fill('input[placeholder*="手机号"]', '13800138001');
    await page.fill('input[placeholder*="密码"]', 'ChangJi@2026#Admin!');
    await page.click('button:has-text("登录")');
    await page.waitForURL(`${BASE_URL}/dashboard`);

    await page.click('a:has-text("用户管理")');
    await page.waitForURL(`${BASE_URL}/users`);
    await expect(page.locator('h1')).toContainText('用户管理');

    await page.click('a:has-text("API Keys")');
    await page.waitForURL(`${BASE_URL}/api-keys`);
    await expect(page.locator('h1')).toContainText('API Keys');

    await page.click('a:has-text("服务器监控")');
    await page.waitForURL(`${BASE_URL}/server-monitor`);
    await expect(page.locator('h1')).toContainText('服务器监控');
  });

  test('用户管理页面按钮响应', async ({ page }) => {
    await page.goto(`${BASE_URL}/login`);
    await page.fill('input[placeholder*="手机号"]', '13800138001');
    await page.fill('input[placeholder*="密码"]', 'ChangJi@2026#Admin!');
    await page.click('button:has-text("登录")');
    await page.waitForURL(`${BASE_URL}/dashboard`);

    await page.click('a:has-text("用户管理")');
    await page.waitForURL(`${BASE_URL}/users`);

    const addButton = page.locator('button:has-text("添加用户")');
    await expect(addButton).toBeVisible();
    await addButton.click();

    await page.waitForSelector('input[placeholder*="手机号"]');
    
    await page.click('button:has-text("取消")');
  });

  test('检查页面是否有 JavaScript 错误', async ({ page }) => {
    const errors: string[] = [];
    
    page.on('pageerror', (error) => {
      errors.push(`页面错误: ${error.message}`);
    });

    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        errors.push(`控制台错误: ${msg.text()}`);
      }
    });

    await page.goto(`${BASE_URL}/login`);
    await page.fill('input[placeholder*="手机号"]', '13800138001');
    await page.fill('input[placeholder*="密码"]', 'ChangJi@2026#Admin!');
    await page.click('button:has-text("登录")');
    await page.waitForURL(`${BASE_URL}/dashboard`);

    await page.waitForTimeout(3000);

    if (errors.length > 0) {
      console.log('发现错误:');
      errors.forEach((error, index) => {
        console.log(`${index + 1}. ${error}`);
      });
    } else {
      console.log('✅ 页面无 JavaScript 错误');
    }

    expect(errors.length).toBe(0);
  });
});
