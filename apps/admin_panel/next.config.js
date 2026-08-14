/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Allow monorepo packages
  transpilePackages: [],
  experimental: {
    serverActions: { bodySizeLimit: '5mb' }
  },
  // Vercel-friendly output
  output: 'standalone'
};

module.exports = nextConfig;
