import { BracesFile, ClockIcon, CodeFile, CogIcon, RadioIcon, ShieldCheckIcon, TestTubeIcon } from "../home/icons";

export const plugins = [
	{
		title: 'OpenAPI',
		pub: 'https://pub.dev/packages/serinus_openapi',
		desc: 'Generate complete API documentation automatically.',
		link: '/openapi/',
		slot: 'openapi',
		icon: BracesFile
	},
	{
		title: 'Database',
		pub: 'https://pub.dev/packages/serinus_loxia',
		desc: 'Use your database as a source of truth with an intuitive ORM.',
		link: '/techniques/database',
		slot: 'database',
		icon: CodeFile
	},
	{
		title: 'Auth',
		pub: 'https://pub.dev/packages/serinus_frontier',
		desc: 'Flexible authentication with hooks and middlewares.',
		link: '/security/authentication',
		slot: 'authentication',
		icon: ShieldCheckIcon
	},
	{
		title: 'Cron',
		pub: 'https://pub.dev/packages/serinus_schedule',
		desc: 'Schedule background tasks with cron expressions.',
		link: '/techniques/task_scheduling',
		slot: 'cron_jobs',
		icon: ClockIcon
	},
	{
		title: 'WebSockets',
		pub: 'https://pub.dev/packages/serinus',
		desc: 'Real-time bidirectional communication',
		link: '/websockets/gateways',
		slot: 'websockets',
		icon: RadioIcon
	},
	{
		title: 'Testing',
		pub: 'https://pub.dev/packages/serinus_test',
		desc: 'Built-in utilities for testing your applications.',
		link: '/recipes/testing',
		slot: 'testing',
		icon: TestTubeIcon
	},
	{
		title: 'Config',
		pub: 'https://pub.dev/packages/serinus_config',
		desc: 'Environment-based configuration.',
		link: '/techniques/configuration',
		slot: 'configuration',
		icon: CogIcon
	},
]