import { defineConfig } from 'vitepress'
import { execSync } from 'child_process'
import { writeFileSync } from 'fs'
import { join } from 'path'

let version = 'dev'
try {
  version = execSync('git describe --tags --match "*"', { encoding: 'utf8' }).trim()
} catch (_) {}

const BASE_URL = process.env.BASE_URL
const SITE_URL = process.env.SITE_URL

export default defineConfig({
  title: 'BuildBox',
  description: 'version ' + version,

  base: BASE_URL && BASE_URL !== 'undefined' ? BASE_URL : '/',

  sitemap: SITE_URL ? { hostname: SITE_URL } : undefined,

  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#ee7214' }],
    ['meta', { name: 'apple-mobile-web-app-capable', content: 'yes' }],
    ['meta', { name: 'apple-mobile-web-app-status-bar-style', content: 'black' }],
  ],

  buildEnd(siteConfig) {
    const lines = [
      'User-agent: *',
      'Allow: /',
      '',
      'User-agent: GPTBot',
      'Allow: /',
      '',
      'User-agent: OAI-SearchBot',
      'Allow: /',
      '',
      'User-agent: Claude-Web',
      'Allow: /',
      '',
      'User-agent: Google-Extended',
      'Allow: /',
      '',
      'Content-Signal: search=yes, ai-train=yes, ai-input=yes',
    ]
    if (SITE_URL) {
      lines.push('')
      lines.push(`Sitemap: ${SITE_URL}/sitemap.xml`)
    }
    writeFileSync(join(siteConfig.outDir, 'robots.txt'), lines.join('\n') + '\n')
  },

  themeConfig: {
    logo: '/buildbox.png',

    nav: [
      { text: 'Getting started', link: '/getting-started/' },
      { text: 'User manual', link: '/user/' },
      { text: 'Developer manual', link: '/dev/' },
    ],

    sidebar: {
      '/getting-started/': [
        {
          text: 'Getting started',
          collapsed: false,
          items: [
            { text: 'Introduction', link: '/getting-started/' },
            { text: 'Installation', link: '/getting-started/install' },
            { text: 'Further reading', link: '/getting-started/further_reading' },
          ],
        },
      ],
      '/user/': [
        {
          text: 'User manual',
          collapsed: false,
          items: [
            { text: 'Introduction', link: '/user/' },
            { text: 'Projects', link: '/user/project' },
            { text: 'Targets', link: '/user/target' },
            { text: 'Packages', link: '/user/package' },
            { text: 'Tools', link: '/user/tool' },
            { text: 'Container', link: '/user/container' },
            { text: 'Shell plugin', link: '/user/shell_plugin' },
            { text: 'Utilities', link: '/user/utils' },
            { text: 'Advanced features', link: '/user/advanced' },
          ],
        },
      ],
      '/dev/': [
        {
          text: 'Developer manual',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/dev/' },
            { text: 'BuildBox API', link: '/dev/api' },
            { text: 'Environment variables', link: '/dev/envvars' },
            { text: 'Container', link: '/dev/container' },
            { text: 'Shell', link: '/dev/shell' },
            { text: 'Scripting', link: '/dev/scripting' },
            { text: 'Developing BuildBox', link: '/dev/developing' },
            { text: 'Build modes', link: '/dev/build_modes' },
          ],
        },
      ],
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/TrustedObjects/BuildBox' },
    ],

    footer: {
      copyright: '© <a href="https://trusted-objects.com" target="_blank" rel="noopener noreferrer">Trusted Objects</a>',
    },
  },
})
