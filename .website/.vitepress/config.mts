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
  sitemap: {
    hostname: 'https://serinus.app'
  },
  lastUpdated: true,
  appearance: 'force-dark',
  themeConfig: {
    footer: {
      copyright: 'Copyright © 2024 Francesco Vallone',
      message: 'Built with 💙 and Dart 🎯 | One of the 🐤 of <a href="https://github.com/avesbox">Avesbox</a>'
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
        text: 'Blog',
        link: '/blog/'
      },
      {
        text: 'Next Version',
        link: '/next/in_a_nutshell'
      },
      {
        text: 'Pub.dev',
        link: 'https://pub.dev/packages/serinus'
      },
    ],
    sidebar: {
      '/next/': [
        {
          items: [
            {
              text: 'Getting Started',
              items: [
                { text: 'In a nutshell', link: '/in_a_nutshell' },
                { text: 'Quick Start', link: '/quick_start' },
                { text: 'What\'s next?', link: '/whats_next' }
              ],
              base: '/next/'
            },
            {
              text: 'Foundations',
              base: '/next/foundations/',
              collapsed: true,
              items: [
                { text: 'Paths', link: 'paths' },
                { text: 'Handler', link: 'handler' },
                { text: 'RequestContext', link: 'request_context' },
                { text: 'Body', link: 'body' },
                { text: 'Dependency Injection', link: 'dependency_injection' },
                { text: 'Request Lifecycle', link: 'request_lifecycle' },
              ]
            },
            {
              text: 'Core Concepts',
              base: '/next/core/',
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
                { text: 'Tracer', link: 'tracer' },
              ]
            },
            {
              text: 'Validation',
              base: '/next/validation/',
              collapsed: true,
              items: [
                { text: 'Schema', link: 'schema' },
              ]
            },
            {
              text: 'Techniques',
              base: '/next/techniques/',
              collapsed: true,
              items: [
                { text: 'Logging', link: 'logging' },
                { text: 'Request Events', link: 'request_events' },
                { text: 'Model Provider', link: 'model_provider' },
                { text: 'Model View Controller', link: 'mvc' },
                { text: 'Versioning', link: 'versioning' },
                { text: 'Global Prefix', link: 'global_prefix' },
                { text: 'Shelf Interoperability', link: 'shelf_interop' },
                { text: 'Configuration', link: 'configuration' },
                { 
                  text: 'CLI', 
                  base: '/techniques/cli/',
                  collapsed: true,
                  items: [
                    { text: 'Introduction', link: '/' },
                    { text: 'Create', link: 'create' },
                    { text: 'Generate', link: 'generate' },
                    { text: 'Run', link: 'run' },
                    { text: 'Deploy', link: 'deploy' },
                  ]
                },
              ]
            },
            {
              text: 'Built-in Hooks',
              base: '/next/hooks/',
              collapsed: true,
              items: [
                { text: 'Body Size Limit', link: 'body_size_limit' },
                { text: 'Secure Session', link: 'secure_session' },
              ]
            },
            {
              text: 'Plugins',
              base: '/next/plugins/',
              collapsed: true,
              items: [
                { text: 'Configuration', link: 'configuration' },
                { text: 'Serve Static Files', link: 'serve_static' },
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
                { text: 'Frontier', link: 'frontier' },
                { text: 'Health Check [WIP]' },
                { text: 'Cron [WIP]' },
                { text: 'Socket.IO [WIP]', link: 'socketio' },
              ],
              link: '/'
            },
            {
              text: 'Deployment',
              base: '/next/deployment/',
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
      '/': [
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
                { text: 'Body', link: 'body' },
                { text: 'Dependency Injection', link: 'dependency_injection' },
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
                { text: 'Tracer', link: 'tracer' },
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
                { text: 'Logging', link: 'logging' },
                { text: 'Request Events', link: 'request_events' },
                { text: 'Model Provider', link: 'model_provider' },
                { text: 'Model View Controller', link: 'mvc' },
                { text: 'Versioning', link: 'versioning' },
                { text: 'Global Prefix', link: 'global_prefix' },
                { text: 'Shelf Interoperability', link: 'shelf_interop' },
                { text: 'Configuration', link: 'configuration' },
                { 
                  text: 'CLI', 
                  base: '/techniques/cli/',
                  collapsed: true,
                  items: [
                    { text: 'Introduction', link: '/' },
                    { text: 'Create', link: 'create' },
                    { text: 'Generate', link: 'generate' },
                    { text: 'Run', link: 'run' },
                    { text: 'Deploy', link: 'deploy' },
                  ]
                },
              ]
            },
            {
              text: 'Built-in Hooks',
              base: '/hooks/',
              collapsed: true,
              items: [
                { text: 'Body Size Limit', link: 'body_size_limit' },
                { text: 'Secure Session', link: 'secure_session' },
              ]
            },
            {
              text: 'Plugins',
              base: '/plugins/',
              collapsed: true,
              items: [
                { text: 'Configuration', link: 'configuration' },
                { text: 'Serve Static Files', link: 'serve_static' },
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
                { text: 'Frontier', link: 'frontier' },
                { text: 'Health Check [WIP]' },
                { text: 'Cron [WIP]' },
                { text: 'Socket.IO [WIP]', link: 'socketio' },
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
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/francescovallone/serinus' },
      { icon: 'twitter', link: 'https://twitter.com/avesboxx'},
      { icon: 'discord', link: 'https://discord.gg/zydgnJ3ksJ' }
    ],
  },
})