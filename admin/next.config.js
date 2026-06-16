/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'export',
  trailingSlash: true,
  images: {
    unoptimized: true,
  },
  env: {
    // 使用相对路径，自动跟随当前域名和协议（避免 HTTPS 页面请求 HTTP API 的混合内容问题）
    NEXT_PUBLIC_API_URL: '/api/v1',
  },
}

module.exports = nextConfig
