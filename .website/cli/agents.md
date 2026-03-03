# Agents

In the AI era, agents are autonomous programs that can perform tasks on behalf of users by leveraging large language models (LLMs) and other AI technologies. They can interact with various systems, process information, and make decisions to accomplish specific goals.

To provide a better experience when using Serinus documentation with AI agents, we have decided to include a special command in the Serinus CLI that generates an `AGENTS.md` file in the root of your Serinus project and downloads the documentation locally, allowing you to use your favorite LLM. This file contains a compressed index of all the documentation files available in the Serinus documentation, formatted in a way that is optimized for AI agents to understand and use.

## Generating the Agents File

To generate the `AGENTS.md` file and download the Serinus documentation locally, you can use the following command in your terminal:

```bash
serinus agents
```

This command will create an `AGENTS.md` file in the root of your Serinus project and download the documentation files into a `.serinus-docs` folder.

If you wish to create also the `CLAUDE.md` file for Anthropic Claude models, you can use the `--claude` flag:

```bash
serinus agents --claude
```
