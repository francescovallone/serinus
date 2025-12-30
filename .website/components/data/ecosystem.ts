import { BracesFile, ClockIcon, CodeFile, CogIcon, RadioIcon, ShieldCheckIcon, TestTubeIcon } from "../home/icons";

export const plugins = [
	{
		title: 'OpenAPI',
		pub: 'https://pub.dev/packages/serinus_openapi',
		desc: 'Generate complete API documentation automatically.',
		link: '/plugins/swagger/',
		slot: 'openapi',
		icon: BracesFile
	},
	{
		title: 'Auth',
		pub: 'https://pub.dev/packages/serinus_frontier',
		desc: 'Flexible authentication with hooks and middlewares.',
		link: '/plugins/frontier',
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
		link: '/plugins/configuration',
		slot: 'configuration',
		icon: CogIcon
	},
]