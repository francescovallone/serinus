export type RoadmapStatus = "done" | "in-progress" | "planned";

export type RoadmapItem = {
  id: string;
  title: string;
  description?: string;
  githubIssueUrl?: string;
  status: RoadmapStatus;
  version?: string;
};

export type RoadmapTrack = {
  id: string;
  label: string;
  color: string; // HSL token name from design system or custom
  items: RoadmapItem[];
  wip?: boolean
};

export const roadmapTracks: RoadmapTrack[] = [
  {
    id: "core",
    label: "Serinus",
    color: "52 100% 50%",
    items: [
      { id: "c1", title: "Minimal Application", status: "in-progress", version: "v2.2" },
      { id: "c2", title: "Observability", status: "in-progress", version: "v2.2" },
      { id: "c3", title: "Injection Scopes", status: "planned", version: "v2.3" },
      { id: "c4", title: "CSRF", status: "done", version: "v2.1.2" },
    ],
  },
  {
    id: "openapi",
    label: "Serinus OpenAPI",
    color: "150 60% 45%",
    items: [
      { id: "s1", title: "Improve library robustness", status: "done", githubIssueUrl: "https://github.com/francescovallone/serinus/issues/222" },
    ],
  },
  {
    id: "frontier",
    label: "Serinus Frontier",
    color: "220 70% 55%",
    items: [
      { id: "f1", title: "Policies", status: "planned", version: "v1.1" },
    ],
  },
  {
    id: "cli",
    label: "Serinus CLI",
    color: "280 60% 55%",
    items: [
      { id: "cl1", title: "Client Generation", status: "planned" },
    ],
  },
  {
    id: "loxia",
    label: "Serinus Loxia",
    color: "15 80% 55%",
    items: [
      { id: "t1", title: "Seeding utilities", status: "planned", version: "v1.1" },
    ],
  },
  {
    id: 'queue',
    label: 'Serinus Stem',
    color: '200 30% 70%',
    items: [
      { id: 'q1', title: 'Initial implementation', 'status': 'planned' },
    ],
    wip: true
  }
];
