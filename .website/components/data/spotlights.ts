import { posts } from './blog'

export interface Spotlight {
    title: string
    subtitle: string
    src?: string
    alt?: string
    color: string
    featherColor?: string
    textColor: string
    href: string,
    cta: string
}

export const spotlights: Spotlight[] = [
    {
        title: 'Last Post',
        subtitle: posts[0].title,
        color: '#E65100',
        textColor: 'white',
        href: posts[0].href,
        cta: 'Read more'
    },
    {
        title: 'Our community',
        subtitle: 'Join our Discord server to get in touch with the community and the team',
        color: 'rgb(23,23,23)',
        textColor: 'white',
        href: 'https://discord.gg/zydgnJ3ksJ',
        cta: 'Join now'
    }
]

export interface OpenInOption {
  name: string;
  icon: any;
  href: string;
}
