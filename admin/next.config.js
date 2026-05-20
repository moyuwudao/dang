/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'export',
  images: {
    unoptimized: true,
  },
  env: {
    API_URL: process.env.API_URL || 'http://101.133.238.249/api/v1',
  },
}

module.exports = nextConfig
