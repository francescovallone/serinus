import { defineConfig } from 'vitepress'
import Tailwind from '@tailwindcss/vite'
import { serinusNocturneTheme, serinusParchmentTheme } from './theme/serinus-parchment'
import { serinusTypes } from './serinus-types'
import { canaryTransformer } from '@avesbox/canary'
import llmstxt from 'vitepress-plugin-llms'

// https://vitepress.dev/reference/site-config

const description = "Serinus is a framework written in Dart for building efficient and scalable server-side applications."
export default defineConfig({
  title: "Serinus",
  titleTemplate: ':title - Serinus | The Flutter modular Backend Framework',
  description,
  head: [
    ['link', { rel: "icon", type: "image/png", sizes: "32x32", href: "/serinus-icon-32x32.png"}],
    ['link', { rel: "icon", type: "image/png", sizes: "16x16", href: "/serinus-icon-16x16.png"}],
    [
        'meta',
        {
            name: 'viewport',
            content: 'width=device-width,initial-scale=1,user-scalable=no'
        }
    ],
    [
        'meta',
        {
            property: 'og:image',
            content: 'https://serinus.app/cover.jpg'
        }
    ],
    [
        'meta',
        {
            property: 'og:image:width',
            content: '1600'
        }
    ],
    [
        'meta',
        {
            property: 'og:image:height',
            content: '900'
        }
    ],
    [
        'meta',
        {
            property: 'twitter:card',
            content: 'summary_large_image'
        }
    ],
    [
        'meta',
        {
            property: 'twitter:image',
            content: 'https://serinus.app/cover.jpg'
        }
    ],
    [
        'meta',
        {
            property: 'og:title',
            content: 'Serinus'
        }
    ],
    [
        'meta',
        {
            property: 'og:description',
            content: description
        }
    ],
    [
        'meta',
        {
            property: 'keywords',
            content: 'serinus, dart serinus, serinus framework, serinus dart framework, serinus backend, serinus backend framework, dart backend framework, dart backend, flutter backend, flutter backend framework'
        }
    ],
  ],
  markdown: {
    image: {
      lazyLoading: true
    },
    theme: {
      light: {
        ...serinusParchmentTheme,
        type: "light"
      },
      dark: {
        ...serinusNocturneTheme,
        type: "dark"
      }
    },
    codeTransformers: [
      canaryTransformer({ customTypes: serinusTypes, explicitTrigger: true }),
    ],
  },
  sitemap: {
    hostname: 'https://serinus.app'
  },
  lastUpdated: true,
  appearance: {
    initialValue: undefined
  },
  ignoreDeadLinks: true,
  themeConfig: {
    // footer: {
    //   copyright: 'Copyright © 2025 Francesco Vallone',
    //   message: 'Built with 💙 and Dart 🎯 | One of the 🐤 of <a href="https://github.com/avesbox">Avesbox</a>',
    // },
    // https://vitepress.dev/reference/default-theme-config
    logo: '/serinus-logo.png',
    search: {
      provider: 'local',
      options: {
        translations: {
          button: {
            buttonText: 'Search docs...',
          }
        }
      }
    },
    siteTitle: false,
    nav: [
      {
        text: 'Documentation',
        link: '/introduction'
      },
      {
        text: 'v2.0',
        items: [
          { text: 'Breaking Changes', link: '/next/breaking-changes' },
          { text: 'Analysis', link: '/next/analysis/' }
        ]
      },
      {
        text: 'Blog',
        link: '/blog/'
      },
    ],
    sidebar: [
      {
        items: [
          {
            text: 'Introduction',
            link: '/introduction'
          },
          {
            text: 'Overview',
            base: '/',
            items: [
              { text: 'Quick Start', link: 'quick_start' },
              { text: 'Modules', link: 'modules' },
              { text: 'Controllers', link: 'controllers' },
              { text: 'Routes', link: 'routes' },
              { text: 'Providers', link: 'providers' },
              { text: 'Metadata', link: 'metadata' },
              { text: 'Middlewares', link: 'middlewares' },
              { text: 'Hooks', link: 'hooks' },
              { text: 'Pipes', link: 'pipes' },
              { text: 'Exception Filters', link: 'exception_filters' },
            ]
          },
          {
            text: 'Techniques',
            base: '/techniques/',
            collapsed: true,
            items: [
              { text: 'Configuration', link: 'configuration' },
              { text: 'Logging', link: 'logging' },
              { text: 'Model Provider', link: 'model_provider' },
              { text: 'Model View Controller', link: 'mvc' },
              { text: 'Task Scheduling', link: 'task_scheduling' },
              { text: 'File Upload', link: 'file_upload' },
              { text: 'Request Events', link: 'request_events' },
              { text: 'Versioning', link: 'versioning' },
              { text: 'Global Prefix', link: 'global_prefix' },
              { text: 'Session', link: 'session' },
              { text: 'Serve static files', link: 'serve_static' },
              { text: 'Server-Sent Events', link: 'sse'},
            ]
          },
          {
            text: 'Security',
            base: '/security/',
            collapsed: true,
            items: [
              { text: 'Rate Limiting', link: 'rate_limiting' },
              { text: 'Body Size', link: 'body_size' },
              { text: 'CORS', link: 'cors' },
            ]
          },
          {
            text: 'WebSockets',
            base: '/websockets/',
            collapsed: true,
            items: [
              { text: 'Gateways', link: 'gateways' },
              { text: 'Pipes', link: 'pipes' },
              { text: 'Exception Filters', link: 'exception_filters' },
              // { text: 'Adapters', link: 'adapters' },
              // { text: 'Client', link: 'client' },
            ]
          },
          {
            text: 'OpenAPI',
            base: '/openapi/',
            collapsed: true,
            items: [
              { text: 'Introduction', link: '/' },
              { text: 'Renderer', link: 'renderer' },
              { text: 'Advanced usage', link: 'advanced_usage' },
            ]
          },
          {
            text: 'Microservices',
            base: '/microservices/',
            collapsed: true,
            items: [
              { text: 'Introduction', link: '/' },
              { text: 'gRPC', link: 'grpc' },
            ]
          },
          {
            text: 'CLI',
            base: '/cli/',
            collapsed: true,
            items: [
              { text: 'Introduction', link: '/' },
              { text: 'Create', link: 'create' },
              { text: 'Generate', link: 'generate' },
              { text: 'Run', link: 'run' },
              { text: 'Deploy', link: 'deploy' },
            ]
          },
          {
            text: 'Comparisons',
            base: '/comparisons/',
            collapsed: true,
            items: [
              { text: 'Shelf', link: 'shelf' },
            ]
          },
          {
            text: 'Recipes',
            base: '/recipes/',
            collapsed: true,
            items: [
              { text: 'Testing', link: 'testing' },
              { text: 'Liquify', link: 'liquify' },
            ]
          },
          
          // {
          //   text: 'Plugins',
          //   base: '/plugins/',
          //   collapsed: true,
          //   items: [
          //     { text: 'Serve Static Files', link: 'serve_static' },
          //     { text: 'Liquify', link: 'serinus_liquify' },
          //     { 
          //       text: 'Swagger', 
          //       collapsed: true,
          //       base: '/plugins/swagger/',
          //       items: [
          //         { text: 'Introduction', link: '/' },
          //         { text: 'Document', link: 'document' },
          //         { text: 'Api Specification', link: 'api_spec' },
          //         { text: 'Components', link: 'components' },
          //       ],
          //     },
          //     { text: 'Frontier', link: 'frontier' },
          //     { text: 'Health Check [WIP]' },
          //     { text: 'Cron [WIP]' },
          //     { text: 'Socket.IO [WIP]', link: 'socketio' },
          //   ],
          //   link: '/'
          // },
          {
            text: 'Deployment',
            base: '/deployment/',
            collapsed: true,
            items: [
              { text: 'Docker', link: 'docker' },
              { text: 'Globe', link: 'globe' },
              { text: 'VPS', link: 'vps' },
              { text: 'Cloud Run', link: 'cloud_run' },
            ],
          },
          {
            'text': 'Breaking Changes in 2.x',
            'link': '/next/breaking-changes'
          },
          {
            text: 'Support Us',
            link: '/support'
          }
        ]
      },
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/francescovallone/serinus' },
      { icon: 'twitter', link: 'https://twitter.com/avesboxx'},
      { icon: 'discord', link: 'https://discord.gg/zydgnJ3ksJ' }
    ],
  },
  vite: {
    plugins: [
      Tailwind(),
      process.env.NODE_ENV ? llmstxt({
        ignoreFiles: [
          'blog/*',
          'index.md',
          'public/*',
          'plugins/*',
          'next/*'
        ],
        domain: 'https://serinus.app'
      }) : undefined
    ]
  }
})