export type RoadmapStatus = "done" | "in-progress" | "planned";

export type RoadmapItem = {
  id: string;
  title: string;
  description?: string;
  status: RoadmapStatus;
  version?: string;
};

export type RoadmapTrack = {
  id: string;
  label: string;
  color: string; // HSL token name from design system or custom
  progress: number; // 0-100
  items: RoadmapItem[];
};

export const roadmapTracks: RoadmapTrack[] = [
  {
    id: "core",
    label: "Serinus",
    color: "52 100% 50%",
    progress: 0,
    items: [
      { id: "c1", title: "Minimal Application", status: "in-progress", version: "v2.2" },
      { id: "c2", title: "Observability", status: "in-progress", version: "v2.2" },
      { id: "c3", title: "Injection Scopes", status: "planned", version: "v2.3" },
      { id: "c4", title: "CSRF", status: "in-progress", version: "v2.2" },
    ],
  },
//   {
//     id: "swagger",
//     label: "Serinus OpenAPI",
//     color: "150 60% 45%",
//     progress: 50,
//     items: [
//       { id: "s1", title: "OpenAPI spec generation", status: "done", version: "v0.1" },
//       { id: "s2", title: "Swagger UI middleware", status: "done", version: "v0.1" },
//       { id: "s3", title: "Schema definitions", status: "in-progress", version: "v0.2" },
//       { id: "s4", title: "Auth decorators support", status: "planned", version: "v0.3" },
//       { id: "s5", title: "ReDoc support", status: "planned", version: "v0.4" },
//     ],
//   },
  {
    id: "frontier",
    label: "Serinus Frontier",
    color: "220 70% 55%",
    progress: 0,
    items: [
      { id: "f1", title: "Policies", status: "planned", version: "v1.1" },
    ],
  },
  {
    id: "cli",
    label: "Serinus CLI",
    color: "280 60% 55%",
    progress: 0,
    items: [
      { id: "cl1", title: "Client Generation", status: "planned" },
    ],
  },
  {
    id: "loxia",
    label: "Serinus Loxia",
    color: "15 80% 55%",
    progress: 0,
    items: [
      { id: "t4", title: "Seeding utilities", status: "planned", version: "v1.1" },
    ],
  },
];
