import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Serinus",
  titleTemplate: 'Serinus - Dart Backend Framework',
  description: "Serinus is a framework written in Dart for building efficient and scalable server-side applications.",
  head: [
    ['link', { rel: "icon", type: "image/png", sizes: "32x32", href: "/serinus-icon-32x32.png"}],
    ['link', { rel: "icon", type: "image/png", sizes: "16x16", href: "/serinus-icon-16x16.png"}],
  ],
  lastUpdated: true,
  themeConfig: {
    footer: {
      copyright: 'Copyright © 2024 Francesco Vallone',
      message: 'Built with 💙 and Dart 🎯 | One of the 🐤 of <a href="https://github.com/serinus-nest">Serinus Nest</a>'
    },
    // https://vitepress.dev/reference/default-theme-config
    logo: '/serinus-logo.png',
    nav: [
      {
        text: 'pub.dev',
        link: 'https://pub.dev/packages/serinus'
      },
    ],
    sidebar: [
      {
        items: [
          { text: 'Introduction', link: '/introduction' },
          {
            text: 'Overview',
            items: [
              { text: 'Getting Started', link: '/overview/getting_started' },
              { text: 'Modules', link: '/overview/modules' },
              { text: 'Controllers', link: '/overview/controllers' },
              { text: 'Routes', link: '/overview/routes' },
              { text: 'Providers', link: '/overview/providers' },
              { text: 'Middlewares', link: '/overview/middlewares' },
              { text: 'Guards', link: '/overview/guards' },
              { text: 'Pipes', link: '/overview/pipes' },
              { text: 'WebSockets', link: '/overview/websockets' },
            ]
          },
          {
            text: 'Techniques',
            items: [
              { text: 'Model View Controller', link: '/techniques/mvc' },
              { text: 'Versioning', link: '/techniques/versioning' },
            ]
          },
          {
            text: 'Plugins',
            items: [
              { text: 'Configuration', link: '/plugins/configuration' },
              { text: 'Serve Static Files', link: '/plugins/serve_static' },
              { text: 'Swagger [WIP]' }
            ],
            link: '/plugins/'
          }
        ]
      },
      // {
      //   text: 'Roadmap',
      //   link: '/roadmap',
      // },
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/francescovallone/serinus' },
      { icon: 'twitter', link: 'https://twitter.com/serinus_nest'},
      { icon: 'discord', link: 'https://discord.gg/zydgnJ3ksJ' }
    ]
  }
})