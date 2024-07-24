import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Serinus",
  titleTemplate: ':title - Serinus | Dart Backend Framework',
  description: "Serinus is a framework written in Dart for building efficient and scalable server-side applications.",
  head: [
    ['link', { rel: "icon", type: "image/png", sizes: "32x32", href: "/serinus-icon-32x32.png"}],
    ['link', { rel: "icon", type: "image/png", sizes: "16x16", href: "/serinus-icon-16x16.png"}],
  ],
  markdown: {
    image: {
      lazyLoading: true
    }
  },
  lastUpdated: true,
  appearance: 'force-dark',
  themeConfig: {
    footer: {
      copyright: 'Copyright © 2024 Francesco Vallone',
      message: 'Built with 💙 and Dart 🎯 | One of the 🐤 of <a href="https://github.com/serinus-nest">Serinus Nest</a>'
    },
    // https://vitepress.dev/reference/default-theme-config
    logo: '/serinus-logo.png',
    search: {
      provider: 'local'
    },
    nav: [
      {
        text: 'Guide',
        link: '/in_a_nutshell'
      },
      {
        text: 'Pub.dev',
        link: 'https://pub.dev/packages/serinus'
      },
    ],
    sidebar: [
      {
        items: [
          {
            text: 'Getting Started',
            items: [
              { text: 'In a nutshell', link: '/in_a_nutshell' },
              { text: 'Quick Start', link: '/quick_start' },
              { text: 'What\'s next?', link: '/whats_next' }
            ]
          },
          {
            text: 'Foundations',
            base: '/foundations/',
            collapsed: true,
            items: [
              { text: 'Paths', link: 'paths' },
              { text: 'Handler', link: 'handler' },
              { text: 'RequestContext', link: 'request_context' },
              { text: 'Dependency Inejction', link: 'dependency_injection' },
              { text: 'Request Lifecycle', link: 'request_lifecycle' },
            ]
          },
          {
            text: 'Core Concepts',
            base: '/core/',
            collapsed: true,
            items: [
              { text: 'Modules', link: 'modules' },
              { text: 'Controllers', link: 'controllers' },
              { text: 'Routes', link: 'routes' },
              { text: 'Providers', link: 'providers' },
              { text: 'Metadata', link: 'metadata' },
              { text: 'Middlewares', link: 'middlewares' },
              { text: 'WebSockets', link: 'websockets' },
              { text: 'Hooks', link: 'hooks' },
              { text: 'Exceptions', link: 'exceptions' },
              { text: 'Trace', link: 'trace' },
            ]
          },
          {
            base: '/validation/',
            text: 'Validation',
            collapsed: true,
            items: [
              { text: 'Schema', link: 'schema' },
            ]
          },
          {
            text: 'Techniques',
            base: '/techniques/',
            collapsed: true,
            items: [
              { text: 'Model View Controller', link: 'mvc' },
              { text: 'Versioning', link: 'versioning' },
              { text: 'Global Prefix', link: 'global_prefix' },
              { text: 'Body Size Limit', link: 'body_size_limit' },
              { text: 'Shelf Interoperability', link: 'shelf_interop' }
            ]
          },
          {
            text: 'Plugins',
            base: '/plugins/',
            collapsed: true,
            items: [
              { text: 'Configuration', link: 'configuration' },
              { text: 'Serve Static Files', link: 'serve_static' },
              { text: 'CORS', link: 'cors' },
              { text: 'Rate Limiter', link: 'rate_limiter' },
              { 
                text: 'Swagger', 
                collapsed: true,
                base: '/plugins/swagger/',
                items: [
                  { text: 'Introduction', link: '/' },
                  { text: 'Document', link: 'document' },
                  { text: 'Api Specification', link: 'api_spec' },
                  { text: 'Components', link: 'components' },
                ],
              },
              { text: 'Health Check [WIP]' },
              { text: 'Cron [WIP]' },
            ],
            link: '/'
          },
          {
            text: 'Deployment',
            base: '/deployment/',
            collapsed: true,
            items: [
              { text: 'Docker', link: 'docker' },
              { text: 'Globe', link: 'globe' },
              { text: 'VPS', link: 'vps' },
            ],
          }, 
        ]
      },
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/francescovallone/serinus' },
      { icon: 'twitter', link: 'https://twitter.com/serinus_nest'},
      { icon: 'discord', link: 'https://discord.gg/zydgnJ3ksJ' }
    ],
  },
})