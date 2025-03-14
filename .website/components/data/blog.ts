export const authors = {
    "Francesco Vallone": {
        src: 'francesco_vallone.webp',
        twitter: 'francescovll'
    }
}

type Authors = typeof authors

export interface Post {
    title: string
    src: string
    alt: string
    author: keyof Authors
    date: string
    shadow?: boolean
    tags: string[],
    href: string
}

export const posts: Post[] = [
    {
        title: 'Serinus VS Dart Frog - A Comparison',
        src: '/blog/serinus_vs_dartfrog/serinus_vs_dartfrog.webp',
        alt: 'Serinus VS Dart Frog - A Comparison',
        author: 'Francesco Vallone',
        date: '27 Feb 2025',
        href: '/blog/serinus_vs_dartfrog.html',
        tags: ['general'],
    },
    {
        title: 'How Hooks and Metadata can improve your Serinus application',
        src: '/blog/hooks_and_metadata/hooks_and_metadata.webp',
        alt: 'How Hooks and Metadata can improve your Serinus application',
        author: 'Francesco Vallone',
        date: '28 Jan 2025',
        href: '/blog/hooks_and_metadata',
        tags: ['tutorial'],
    },
    {
        title: 'Serinus 1.0 - Primavera',
        src: '/blog/serinus_1_0/serinus_1_0.webp',
        alt: 'Serinus 1.0 - Primavera',
        author: 'Francesco Vallone',
        date: '26 Nov 2024',
        href: '/blog/serinus_1_0',
        tags: ['releases'],
    },
    {
        title: 'The goal of Serinus',
        src: '/blog/the_goal_of_serinus/the_goal_of_serinus.webp',
        alt: 'The goal of Serinus',
        author: 'Francesco Vallone',
        date: '04 Nov 2024',
        href: '/blog/the_goal_of_serinus',
        tags: ['general'],
    },
    {
        title: 'Serinus 0.6 - Welcome to the Meta-World',
        src: '/blog/serinus_0_6/serinus_0_6.webp',
        alt: 'Serinus 0.6 - Welcome to the Meta-World',
        author: 'Francesco Vallone',
        date: '1 Aug 2024',
        href: '/blog/serinus_0_6',
        tags: ['releases'],
    },
]