const { description } = require('../../package')
const {gitDescribe, gitDescribeSync} = require('git-describe');
process.env.BUILDBOX_VERSION = gitDescribeSync({match: '*'}).tag

BASE_URL = process.env.BASE_URL

module.exports = {
  title: 'BuildBox',
  description: 'version ' + process.env.BUILDBOX_VERSION,

  base: BASE_URL !== 'undefined' ? BASE_URL : '/',

  head: [
    ['meta', { name: 'theme-color', content: '#3eaf7c' }],
    ['meta', { name: 'apple-mobile-web-app-capable', content: 'yes' }],
    ['meta', { name: 'apple-mobile-web-app-status-bar-style', content: 'black' }]
  ],

  themeConfig: {
    logo: '/buildbox.png',
    repo: 'https://github.com/TrustedObjects/BuildBox',
    repoLabel: 'GitHub',
    editLinks: false,
    docsDir: '',
    editLinkText: '',
    lastUpdated: false,
    nav: [
      {
        text: 'Getting started',
        link: '/getting-started/',
      },
      {
        text: 'User manual',
        link: '/user/',
      },
      {
        text: 'Developer manual',
        link: '/dev/'
      },
    ],
    sidebar: {
      '/getting-started/': [
        {
          title: 'Getting started',
          collapsable: false,
          children: [
            '',
            'install',
            'further_reading',
          ]
        }
      ],
      '/user/': [
        {
          title: 'User manual',
          collapsable: false,
          children: [
            '',
            'project',
            'target',
            'package',
            'tool',
            'container',
            'utils',
            'advanced',
          ]
        }
      ],
      '/dev/': [
        {
          title: 'Developer manual',
          collapsable: false,
          children: [
            '',
            'api',
            'envvars',
            'container',
            'shell',
            'scripting',
            'developing',
            'build_modes',
          ]
        }
      ],
    }
  },

  plugins: [
    '@vuepress/plugin-back-to-top',
    '@vuepress/plugin-medium-zoom',
  ]
}
