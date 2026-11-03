# SamSkills

A collection of reusable skills for AI coding assistants and research agents. Each skill provides instructions for a specific task, with supporting scripts, examples, and reference material where available.

The collection covers scientific research and writing, machine learning, life sciences, software engineering, R and Shiny, data analysis, design, and document creation. It includes both model-agnostic workflows and skills tailored to particular agents.

## Explore the skills

**[Browse the SamSkills website →](https://samarthmathurphd.com/SamSkills/)**

Use the website to search by task or technology, filter by topic and agent compatibility, and read each skill's instructions. Listings include author credits and source links where available, along with installation guidance.

## Install a skill

### 1. Download the collection

Clone this repository:

```bash
git clone https://github.com/samarth8392/SamSkills.git
cd SamSkills
```

You can also choose **Code → Download ZIP** on GitHub and extract the archive.

### 2. Copy a skill into your project

Choose a skill on the [website](https://samarthmathurphd.com/SamSkills/), then copy its **entire folder**, including any scripts and references. The examples below install `pdf`; replace it with your chosen skill's folder name.

Run these commands from the downloaded `SamSkills` directory. Replace `/path/to/your-project` with the actual path to the project where you use your agent.

**Codex / Agent Skills project directory:**

```bash
mkdir -p /path/to/your-project/.agents/skills
cp -R skills/pdf /path/to/your-project/.agents/skills/
```

**Claude Code project directory:**

```bash
mkdir -p /path/to/your-project/.claude/skills
cp -R skills/pdf /path/to/your-project/.claude/skills/
```

For another agent, or to make a skill available across projects, copy the folder into that agent's configured skills directory.

### 3. Use the skill

Read the skill's `SKILL.md` for setup requirements, then open your agent in the target project and ask it to perform the task using that skill. If the skill does not appear, reload your agent session.

Some skills need additional packages, MCP servers, API credentials, model downloads, or your own data. Compatibility labels are guidance; check the instructions for the tools your agent needs. Where multiple folders share the same skill name, choose one variant to install.

## Authors and sources

SamSkills brings together skills from multiple authors and projects. Credits and source links appear on the [website](https://samarthmathurphd.com/SamSkills/) and in the skill files where provided. Original licenses and notices remain with their folders; follow those terms when using or redistributing a skill.
