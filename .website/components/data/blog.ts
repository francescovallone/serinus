export const authors = {
    "Francesco Vallone": {
        src: 'francesco_vallone.webp',
        twitter: 'francescovll'
    }
}

export type Authors = typeof authors

export interface Post {
    title: string
    src?: string
    alt?: string
    author: keyof Authors
    desc?: string
    date: string
    lastUpdated?: string
    shadow?: boolean
    tags: string[],
    href: string
}

export const posts: Post[] = [
    // {
    //     title: 'Why Dart Backends Need Architecture, Not Just Scaffolding',
    //     src: '/blog/architecture_over_scaffolding/architecture_over_scaffolding.webp',
    //     alt: 'Why Dart Backends Need Architecture, Not Just Scaffolding',
    //     desc: 'Over the last years, Dart has proven over and over again to be a great language for building frontend applications, Flutter being the prime example of this. On the server, however, Dart is still treated like a shortcut language, something you use to avoid context switching, not something you design systems with.',
    //     author: 'Francesco Vallone',
    //     date: '01 Jan 2025',
    //     href: '/blog/architecture_over_scaffolding',
    //     tags: ['general'],
    // },
    {
        title: 'Serinus 2.1 - Morning Song',
        src: '/blog/serinus_2_1/serinus_2_1.webp',
        alt: 'Serinus 2.1 - Morning Song',
        desc: 'Introducing new router, Class and Value Providers and Loxia integration',
        author: 'Francesco Vallone',
        date: '03 Feb 2026',
        href: '/blog/serinus_2_1',
        tags: ['releases'],
    },
    {
        title: 'Serinus 2.0 - Dawn Chorus',
        src: '/blog/serinus_2_0/serinus_2_0.webp',
        alt: 'Serinus 2.0 - Dawn Chorus',
        desc: 'Major improvements to performances, new features and a refined developer experience.',
        author: 'Francesco Vallone',
        date: '05 Nov 2025',
        href: '/blog/serinus_2_0',
        tags: ['releases'],
    },
    {
        title: 'Serinus VS Dart Frog - A Comparison',
        src: '/blog/serinus_vs_dartfrog/serinus_vs_dartfrog.webp',
        alt: 'Serinus VS Dart Frog - A Comparison',
        desc: 'A detailed comparison between Serinus and Dart Frog frameworks.',
        author: 'Francesco Vallone',
        date: '27 Feb 2025',
        href: '/blog/serinus_vs_dartfrog.html',
        tags: ['general'],
    },
    {
        title: 'How Hooks and Metadata can improve your Serinus application',
        src: '/blog/hooks_and_metadata/hooks_and_metadata.webp',
        alt: 'How Hooks and Metadata can improve your Serinus application',
        desc: 'Learn how to leverage Hooks and Metadata in Serinus to create more dynamic and flexible applications.',
        author: 'Francesco Vallone',
        date: '28 Jan 2025',
        href: '/blog/hooks_and_metadata',
        tags: ['tutorial'],
    },
    {
        title: 'Serinus 1.0 - Primavera',
        src: '/blog/serinus_1_0/serinus_1_0.webp',
        alt: 'Serinus 1.0 - Primavera',
        desc: 'The first major release of Serinus, introducing stability and new features.',
        author: 'Francesco Vallone',
        date: '26 Nov 2024',
        href: '/blog/serinus_1_0',
        tags: ['releases'],
    },
    {
        title: 'The goal of Serinus',
        src: '/blog/the_goal_of_serinus/the_goal_of_serinus.webp',
        alt: 'The goal of Serinus',
        desc: 'Why Serinus was created and what are its main objectives.',
        author: 'Francesco Vallone',
        date: '04 Nov 2024',
        href: '/blog/the_goal_of_serinus',
        tags: ['general'],
    },
    {
        title: 'Serinus 0.6 - Welcome to the Meta-World',
        src: '/blog/serinus_0_6/serinus_0_6.webp',
        alt: 'Serinus 0.6 - Welcome to the Meta-World',
        desc: 'Introducing Metadata and Hooks to enhance your Serinus applications.',
        author: 'Francesco Vallone',
        date: '1 Aug 2024',
        href: '/blog/serinus_0_6',
        tags: ['releases'],
    },
]