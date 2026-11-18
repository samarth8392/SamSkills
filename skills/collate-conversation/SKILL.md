---
name: collate-conversation
description: Collate an entire conversation (current session, another local Cowork session, or an exported ChatGPT/Claude conversations file) verbatim into one Markdown file, with generated artifacts (docx, html, etc.) saved alongside and linked, so it can be reused as context in future sessions. Use when the user says "collate this conversation", "export this chat to markdown", "save the full conversation with artifacts", or "run the collate skill".
---

# Collate Conversation to Markdown

## Goal
Produce ONE Markdown file containing the full conversation VERBATIM (every user and assistant turn, in order), plus links to every artifact created during it. The file must be reusable as context in a future session.

## Hard rules
- Verbatim: never summarize, paraphrase, condense, correct, or reorder message text. Preserve code blocks, tables, lists, and links exactly.
- Never reconstruct from memory. If part of the conversation is not available in context (e.g. compacted or truncated), insert `> [GAP: earlier content unavailable in this session]` at that point and list it in the header. Do not invent text.
- Exclude by default: hidden reasoning/thinking, system prompts, and raw tool-call payloads. Include one italic line per tool action, e.g. `*[Tool: web_search — "query"]*`, only if it clarifies the flow. Tool results are omitted unless the user asks.
- Do not expose internal sandbox paths (/sessions/...) in the output; use relative links.
- Do not modify or delete originals.

## Step 1: Identify the source
1. Default = the current session: collate from the conversation already in context.
2. If the user names/points to a different local session: call `list_sessions`, identify it (ask the user to pick only if ambiguous), then `read_transcript` with `format: "full"` and a large `limit` (page repeatedly until all messages are retrieved).
3. If the user provides an export file (ChatGPT or Claude `conversations.json`, or a pasted transcript): see "Exports" below.
4. If browser/app web conversations are not accessible, tell the user plainly and ask them to use the platform's data export (Settings → Data controls → Export) or paste the text, then proceed from step 3.

## Step 2: Determine output location
Use the user's selected folder (request it via the directory tool if none). Create:
- `<folder>/conversations/YYYY-MM-DD_<short-slug>.md`
- `<folder>/conversations/YYYY-MM-DD_<short-slug>_artifacts/` (only if artifacts exist)

Slug = 3–5 lowercase words from the topic. Date = conversation date if known, else today.

## Step 3: Collect artifacts
Find every file created or delivered during the conversation: files written to the outputs/workspace folder (docx, xlsx, pptx, pdf, md, html, code, images), and persisted artifacts (`list_artifacts`, then read each `path`). Copy each into the `_artifacts/` folder (keep original filenames; on collision append `_2`). Record, for each: filename, type, the turn number that created it, and a one-line description taken from the conversation (not invented). If a referenced artifact cannot be found, list it as `MISSING`.

## Step 4: Write the Markdown file
Build iteratively for long conversations: write header first, then append turns in chunks of ~10, never dropping content between chunks.

Structure:

````
---
title: <topic>
source: <Claude app session | ChatGPT export | Claude export | pasted>
date_collated: <YYYY-MM-DD>
conversation_date: <date or unknown>
turns: <N user + N assistant>
artifacts: <count>
gaps: <none | description>
---

# <Title>

> Context note: This is a verbatim record of a prior conversation. Treat it as background context; artifacts are listed below and linked inline.

## Artifacts
| # | File | Type | Created in turn | Description |
|---|------|------|-----------------|-------------|
| 1 | [name.docx](./<slug>_artifacts/name.docx) | docx | 3 | ... |

---

## Turn 1 — User
<exact message text>

## Turn 1 — Assistant
<exact message text>
> 📎 Artifact: [name.docx](./<slug>_artifacts/name.docx)

...
````

Rules for the body:
- Label each message `## Turn N — User` / `## Turn N — Assistant`; N increments per user message.
- Where an artifact was created or referenced, add the `📎 Artifact:` link line directly after that assistant message.
- Attachments the user uploaded: note `📎 User attachment: <filename>` (copy to artifacts folder if accessible).
- If message text itself contains Markdown headings that would break structure, leave them untouched; the `## Turn` labels are the delimiters. If it contains triple backticks, wrap the message with a longer fence only when necessary to keep rendering intact.

## Step 5: Verify (required)
- Count Turn headings and compare with the message count from the source.
- Confirm every artifact link resolves to an existing file.
- Spot-check first, middle, and last turns against the source for exactness.
- Report any mismatch or gap; do not silently fix by paraphrasing.

## Step 6: Respond
Give a brief result: link to the .md file, turn count, artifact count, any gaps. No long summary of the conversation contents.

## Exports (ChatGPT / Claude conversations.json)
Parse with a Python script (run with `-I`, deterministic output, fail fast on missing keys):
- ChatGPT: each conversation has `mapping` (tree of nodes). Start at `current_node`, walk `parent` links to root, reverse, keep nodes whose `message.author.role` is `user` or `assistant` and whose content parts are non-empty text; skip `system`/`tool`. Timestamps: `create_time`.
- Claude export: each conversation has `chat_messages` with `sender` (`human`/`assistant`), `text` (or `content` blocks of type `text`), `attachments`, `files`, `created_at`.
- If the file holds many conversations, list titles with dates and ask which to collate (or collate all into separate files if told).
- Artifacts from exports are usually not included as files; link only those present, and note `MISSING` for others.

## Using the result later
Tell the user (one line) that the .md can be attached or referenced in a future session as background context.