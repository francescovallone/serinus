import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Serinus",
  titleTemplate: ':title - Serinus | The Flutter modular Backend Framework',
  description: "Serinus is a framework written in Dart for building efficient and scalable server-side applications.",
  head: [
    ['link', { rel: "icon", type: "image/png", sizes: "32x32", href: "/serinus-icon-32x32.png"}],
    ['link', { rel: "icon", type: "image/png", sizes: "16x16", href: "/serinus-icon-16x16.png"}],
    [
      'script', 
      {},
      `
        (function(c,l,a,r,i,t,y){
            c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
            t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
            y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
        })(window, document, "clarity", "script", "qsba56yrau");
      `
  ]
  ],
  markdown: {
    image: {
      lazyLoading: true
    },
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
        text: 'Documentation',
        link: '/introduction'
      },
      {
        text: 'Blog',
        link: '/blog/'
      },
      // {
      //   text: 'Next Version',
      //   link: '/next/in_a_nutshell'
      // },
      {
        text: 'Pub.dev',
        link: 'https://pub.dev/packages/serinus'
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
              // { text: 'WebSockets', link: 'websockets' },
              { text: 'Hooks', link: 'hooks' },
              // { text: 'Exceptions', link: 'exceptions' },
              // { text: 'Tracer', link: 'tracer' },
            ]
          },
          {
            text: 'Foundations',
            base: '/foundations/',
            collapsed: true,
            items: [
              { text: 'Body', link: 'body' },
              { text: 'Request Lifecycle', link: 'request_lifecycle' },
            ]
          },
          {
            text: 'Techniques',
            base: '/techniques/',
            collapsed: true,
            items: [
              { text: 'Logging', link: 'logging' },
              { text: 'Validation', link: 'validation' },
              { text: 'Model Provider', link: 'model_provider' },
              { text: 'Model View Controller', link: 'mvc' },
              { text: 'Request Events', link: 'request_events' },
              { text: 'Versioning', link: 'versioning' },
              { text: 'Global Prefix', link: 'global_prefix' },
              { text: 'Session', link: 'session' },
              { text: 'Exceptions', link: 'exceptions' },
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
            text: 'Plugins',
            base: '/plugins/',
            collapsed: true,
            items: [
              { text: 'Configuration', link: 'configuration' },
              { text: 'Serve Static Files', link: 'serve_static' },
              { text: 'Liquify', link: 'liquify' },
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
    socialLinks: [
      { icon: 'github', link: 'https://github.com/francescovallone/serinus' },
      { icon: 'twitter', link: 'https://twitter.com/avesboxx'},
      { icon: 'discord', link: '/discord.html' }
    ],
  },
})