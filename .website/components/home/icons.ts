import { defineComponent, h } from 'vue';

const CopyIcon = defineComponent({
	name: 'CopyIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M9 15c0-2.828 0-4.243.879-5.121C10.757 9 12.172 9 15 9h1c2.828 0 4.243 0 5.121.879C22 10.757 22 12.172 22 15v1c0 2.828 0 4.243-.879 5.121C20.243 22 18.828 22 16 22h-1c-2.828 0-4.243 0-5.121-.879C9 20.243 9 18.828 9 16z' }),
		h('path', { d: 'M17 9c-.003-2.957-.047-4.489-.908-5.538a4 4 0 0 0-.554-.554C14.43 2 12.788 2 9.5 2c-3.287 0-4.931 0-6.038.908a4 4 0 0 0-.554.554C2 4.57 2 6.212 2 9.5c0 3.287 0 4.931.908 6.038a4 4 0 0 0 .554.554c1.05.86 2.58.906 5.538.908' })
	])
});


const ShieldIcon = defineComponent({
	name: 'ShieldIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z' })
	])
});

const LightningIcon = defineComponent({
	name: 'LightningIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '4',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('polygon', { points: '13 2 3 14 12 14 11 22 21 10 12 10 13 2' })
	])
});

const SettingsIcon = defineComponent({
	name: 'SettingsIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M14 17H5M19 7h-9' }),
		h('circle', { cx: '17', cy: '17', r: '3' }),
		h('circle', { cx: '7', cy: '7', r: '3' })
	])
})

const RadioIcon = defineComponent({
	name: 'RadioIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M16.247 7.761a6 6 0 0 1 0 8.478m2.828-11.306a10 10 0 0 1 0 14.134m-14.15 0a10 10 0 0 1 0-14.134m2.828 11.306a6 6 0 0 1 0-8.478' }),
		h('circle', { cx: '12', cy: '12', r: '2' })
	])
});

const PuzzleIcon = defineComponent({
	name: 'TerminalIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M15.39 4.39a1 1 0 0 0 1.68-.474a2.5 2.5 0 1 1 3.014 3.015a1 1 0 0 0-.474 1.68l1.683 1.682a2.414 2.414 0 0 1 0 3.414L19.61 15.39a1 1 0 0 1-1.68-.474a2.5 2.5 0 1 0-3.014 3.015a1 1 0 0 1 .474 1.68l-1.683 1.682a2.414 2.414 0 0 1-3.414 0L8.61 19.61a1 1 0 0 0-1.68.474a2.5 2.5 0 1 1-3.014-3.015a1 1 0 0 0 .474-1.68l-1.683-1.682a2.414 2.414 0 0 1 0-3.414L4.39 8.61a1 1 0 0 1 1.68.474a2.5 2.5 0 1 0 3.014-3.015a1 1 0 0 1-.474-1.68l1.683-1.682a2.414 2.414 0 0 1 3.414 0z' }),
	])
});

const CodeFile = defineComponent({
	name: 'CodeFile',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M4 12.15V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.706.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2h-3.35' }),
		h('path', { d: 'M14 2v5a1 1 0 0 0 1 1h5M5 16l-3 3l3 3m4 0l3-3l-3-3' })
	])
});

const CogIcon = defineComponent({
	name: 'CogIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M9.671 4.136a2.34 2.34 0 0 1 4.659 0a2.34 2.34 0 0 0 3.319 1.915a2.34 2.34 0 0 1 2.33 4.033a2.34 2.34 0 0 0 0 3.831a2.34 2.34 0 0 1-2.33 4.033a2.34 2.34 0 0 0-3.319 1.915a2.34 2.34 0 0 1-4.659 0a2.34 2.34 0 0 0-3.32-1.915a2.34 2.34 0 0 1-2.33-4.033a2.34 2.34 0 0 0 0-3.831A2.34 2.34 0 0 1 6.35 6.051a2.34 2.34 0 0 0 3.319-1.915' }),
		h('circle', { cx: '12', cy: '12', r: '3' }),
	])
});

const BracesFile = defineComponent({
	name: 'BracesFile',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z' }),
		h('path', { d: 'M14 2v5a1 1 0 0 0 1 1h5m-10 4a1 1 0 0 0-1 1v1a1 1 0 0 1-1 1a1 1 0 0 1 1 1v1a1 1 0 0 0 1 1m4 0a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1a1 1 0 0 1-1-1v-1a1 1 0 0 0-1-1' })
	])
});

const TestTubeIcon = defineComponent({
	name: 'TestTubeIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M21 7L6.82 21.18a2.83 2.83 0 0 1-3.99-.01a2.83 2.83 0 0 1 0-4L17 3m-1-1l6 6m-10 8H4' })
	])
});

const ClockIcon = defineComponent({
	name: 'ClockIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M12 6v6l4 2' }),
		h('circle', { cx: '12', cy: '12', r: '10' })
	])
});

const ShieldCheckIcon = defineComponent({
	name: 'ShieldCheckIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z' }),
		h('path', { d: 'm9 12l2 2l4-4' })
	])
});

const XSocialIcon = defineComponent({
	name: 'XSocialIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 16 16',
		fill: 'currentColor',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'm9.237 7.004l4.84-5.505H12.93L8.727 6.28L5.371 1.5H1.5l5.075 7.228L1.5 14.499h1.147l4.437-5.047l3.545 5.047H14.5zM7.666 8.791l-.514-.72L3.06 2.344h1.762l3.302 4.622l.514.72l4.292 6.007h-1.761z' })
	])
});

const GithubIcon = defineComponent({
	name: 'GithubIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'currentColor',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M10 20.568c-3.429 1.157-6.286 0-8-3.568' }),
		h('path', { d: 'M10 22v-3.242c0-.598.184-1.118.48-1.588c.204-.322.064-.78-.303-.88C7.134 15.452 5 14.107 5 9.645c0-1.16.38-2.25 1.048-3.2c.166-.236.25-.354.27-.46c.02-.108-.015-.247-.085-.527c-.283-1.136-.264-2.343.16-3.43c0 0 .877-.287 2.874.96c.456.285.684.428.885.46s.469-.035 1.005-.169A9.5 9.5 0 0 1 13.5 3a9.6 9.6 0 0 1 2.343.28c.536.134.805.2 1.006.169c.2-.032.428-.175.884-.46c1.997-1.247 2.874-.96 2.874-.96c.424 1.087.443 2.294.16 3.43c-.07.28-.104.42-.084.526s.103.225.269.461c.668.95 1.048 2.04 1.048 3.2c0 4.462-2.134 5.807-5.177 6.643c-.367.101-.507.559-.303.88c.296.47.48.99.48 1.589V22' })
	])
});

const MessageIcon = defineComponent({
	name: 'MessageIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'm3 20l1.3-3.9C1.976 12.663 2.874 8.228 6.4 5.726c3.526-2.501 8.59-2.296 11.845.48c3.255 2.777 3.695 7.266 1.029 10.501S11.659 20.922 7.7 19z', strokeLinecap: 'round' }),
	])
});

const TerminalIcon = defineComponent({
	name: 'TerminalIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'm7 7l1.227 1.057C8.742 8.502 9 8.724 9 9s-.258.498-.773.943L7 11m4 0h3' }),
		h('path', { d: 'M12 21c3.75 0 5.625 0 6.939-.955a5 5 0 0 0 1.106-1.106C21 17.625 21 15.749 21 12s0-5.625-.955-6.939a5 5 0 0 0-1.106-1.106C17.625 3 15.749 3 12 3s-5.625 0-6.939.955A5 5 0 0 0 3.955 5.06C3 6.375 3 8.251 3 12s0 5.625.955 6.939a5 5 0 0 0 1.106 1.106C6.375 21 8.251 21 12 21' })
	])
});

const CalendarIcon = defineComponent({
	name: 'CalendarIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M4 7a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2zm12-4v4M8 3v4m-4 4h16' }),
		h('path', { d: 'M8 15h2v2H8z' })
	])
});

const ArrowUpRightIcon = defineComponent({
	name: 'ArrowUpRightIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		strokeWidth: '2',
		strokeLinecap: 'round',
		strokeLinejoin: 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M17 7L7 17M8 7h9v9' })
	])
});

export {
	ShieldIcon,
	LightningIcon,
	SettingsIcon,
	RadioIcon,
	PuzzleIcon,
	CodeFile,
	CogIcon,
	BracesFile,
	TestTubeIcon,
	ClockIcon,
	ShieldCheckIcon,
	XSocialIcon,
	GithubIcon,
	CopyIcon,
	MessageIcon,
	TerminalIcon,
	CalendarIcon,
	ArrowUpRightIcon
}