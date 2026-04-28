import { defineConfig } from 'vitepress'

const repo = 'https://github.com/VSoftTechnologies/VSoft.AnsiConsole'

export default defineConfig({
  title: 'VSoft.AnsiConsole',
  description: 'Rich, interactive console output for Delphi - tables, trees, live progress, prompts, syntax-coloured exceptions.',
  cleanUrls: true,
  lastUpdated: true,
  base: 'https://github.com/VSoftTechnologies/VSoft.AnsiConsole/docs/',

  head: [
    ['link', { rel: 'icon', href: '/images/favicon.png' }],
    ['meta', { name: 'theme-color', content: '#cc6633' }],
  ],

  themeConfig: {
    logo: '/images/readme-demo.png',
    siteTitle: 'VSoft.AnsiConsole',

    nav: [
      { text: 'Guide', link: '/getting-started/quick-start' },
      { text: 'Widgets', link: '/widgets/markup' },
      { text: 'Live', link: '/live/status' },
      { text: 'Prompts', link: '/prompts/text-prompt' },
      { text: 'Reference', link: '/reference/markup-syntax' },
    ],

    sidebar: {
      '/getting-started/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Installation', link: '/getting-started/installation' },
            { text: 'Quick start', link: '/getting-started/quick-start' },
            { text: 'Architecture', link: '/getting-started/architecture' },
          ],
        },
      ],
      '/widgets/': [
        {
          text: 'Primitives',
          items: [
            { text: 'Text', link: '/widgets/text' },
            { text: 'Markup', link: '/widgets/markup' },
            { text: 'Rule', link: '/widgets/rule' },
            { text: 'Paragraph', link: '/widgets/paragraph' },
            { text: 'Panel', link: '/widgets/panel' },
            { text: 'Padder', link: '/widgets/padder' },
          ],
        },
        {
          text: 'Layout',
          items: [
            { text: 'Align', link: '/widgets/align' },
            { text: 'Rows', link: '/widgets/rows' },
            { text: 'Columns', link: '/widgets/columns' },
            { text: 'Grid', link: '/widgets/grid' },
            { text: 'Layout', link: '/widgets/layout' },
          ],
        },
        {
          text: 'Data',
          items: [
            { text: 'Table', link: '/widgets/table' },
            { text: 'Tree', link: '/widgets/tree' },
          ],
        },
        {
          text: 'Charts',
          items: [
            { text: 'BarChart', link: '/widgets/barchart' },
            { text: 'BreakdownChart', link: '/widgets/breakdownchart' },
            { text: 'Calendar', link: '/widgets/calendar' },
            { text: 'Canvas', link: '/widgets/canvas' },
          ],
        },
        {
          text: 'Specialty',
          items: [
            { text: 'FigletText', link: '/widgets/figlet' },
            { text: 'JsonText', link: '/widgets/json' },
            { text: 'TextPath', link: '/widgets/textpath' },
            { text: 'ExceptionWidget', link: '/widgets/exception' },
          ],
        },
      ],
      '/live/': [
        {
          text: 'Live displays',
          items: [
            { text: 'Status', link: '/live/status' },
            { text: 'Progress', link: '/live/progress' },
            { text: 'Live display', link: '/live/live-display' },
          ],
        },
      ],
      '/prompts/': [
        {
          text: 'Prompts',
          items: [
            { text: 'Text prompt', link: '/prompts/text-prompt' },
            { text: 'Confirmation', link: '/prompts/confirmation-prompt' },
            { text: 'Selection', link: '/prompts/selection-prompt' },
            { text: 'Multi-selection', link: '/prompts/multi-selection-prompt' },
            { text: 'Hierarchical', link: '/prompts/hierarchical-selection' },
          ],
        },
      ],
      '/recording/': [
        {
          text: 'Recording',
          items: [
            { text: 'Recorder', link: '/recording/recorder' },
          ],
        },
      ],
      '/reference/': [
        {
          text: 'Reference',
          items: [
            { text: 'Markup syntax', link: '/reference/markup-syntax' },
            { text: 'Colors', link: '/reference/colors' },
            { text: 'Styles', link: '/reference/styles' },
            { text: 'Box borders', link: '/reference/box-borders' },
            { text: 'Table borders', link: '/reference/table-borders' },
            { text: 'Tree guides', link: '/reference/tree-guides' },
            { text: 'Spinners', link: '/reference/spinners' },
            { text: 'Emoji', link: '/reference/emoji' },
            { text: 'Capabilities', link: '/reference/capabilities' },
          ],
        },
      ],
    },

    socialLinks: [
      { icon: 'github', link: repo },
    ],

    editLink: {
      pattern: `${repo}/edit/main/docs/:path`,
      text: 'Edit this page on GitHub',
    },

    outline: {
      level: 'deep',
    },

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright (c) Vincent Parrett and contributors',
    },

    search: {
      provider: 'local',
    },
  },

  markdown: {
    lineNumbers: true,
    theme: {
      light: 'github-light',
      dark: 'github-dark',
    },
  },
})
