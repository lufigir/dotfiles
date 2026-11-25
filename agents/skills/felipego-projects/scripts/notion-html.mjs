#!/usr/bin/env node
/**
 * Create/replace/inspect Notion "HTML blocks" (embed blocks backed by an
 * uploaded .html file) — the one thing the Notion MCP write tools cannot do.
 * felipego.com renders these in a sandboxed, theme-aware iframe; see
 * ../references/html-diagrams.md for the full workflow this script is part of.
 *
 * Requires @notionhq/client to be resolvable and NOTION_API_KEY to be set (or
 * present in a .env.local in the current directory) — in practice, run this
 * from the felipego.com site repo checkout, which already has both.
 *
 * Usage:
 *   node notion-html.mjs list <pageId>
 *     List a page's direct children with index, type, id, and a short
 *     preview — use this to find the block id to anchor a new diagram after
 *     (e.g. right below an existing image block).
 *
 *   node notion-html.mjs add <pageId> <htmlFile> [--after <blockId>]
 *     Upload htmlFile and append it as a new HTML block. Without --after,
 *     appends at the end of the page.
 *
 *   node notion-html.mjs replace <blockId> <htmlFile>
 *     Replace an existing HTML block's content in place (same position):
 *     uploads htmlFile, deletes the old block, and inserts the new one after
 *     the same previous sibling (or at the start if it was first).
 *
 *   node notion-html.mjs delete <blockId>
 *     Delete an HTML block.
 */
import fs from "node:fs"
import { createRequire } from "node:module"
import path from "node:path"

function loadDotEnvLocal() {
  if (process.env.NOTION_API_KEY) return
  try {
    const env = fs.readFileSync(".env.local", "utf8")
    for (const line of env.split("\n")) {
      const m = /^([A-Z_]+)=(.*)$/.exec(line.trim())
      if (m) process.env[m[1]] ??= m[2].replace(/^["']|["']$/g, "")
    }
  } catch {
    // no .env.local in cwd — fine if NOTION_API_KEY is already set
  }
}

loadDotEnvLocal()

if (!process.env.NOTION_API_KEY) {
  console.error(
    "NOTION_API_KEY is not set and no .env.local was found in the current " +
      "directory. Run this from the felipego.com site repo checkout, or set " +
      "NOTION_API_KEY yourself.",
  )
  process.exit(1)
}

// Resolve @notionhq/client relative to the CURRENT DIRECTORY, not this
// script's own location — `import()` of a bare specifier resolves relative to
// the importing module, which would look in ~/.claude/skills/.../node_modules
// instead of the site repo's. `createRequire` anchored at cwd fixes that.
let Client
try {
  const cwdRequire = createRequire(path.join(process.cwd(), "package.json"))
  ;({ Client } = cwdRequire("@notionhq/client"))
} catch {
  console.error(
    "@notionhq/client is not resolvable from this directory. Run this " +
      "script from the felipego.com site repo checkout (it depends on " +
      "@notionhq/client already).",
  )
  process.exit(1)
}

const notion = new Client({ auth: process.env.NOTION_API_KEY })

async function listChildren(blockId) {
  const all = []
  let cursor
  do {
    const res = await notion.blocks.children.list({
      block_id: blockId,
      page_size: 100,
      start_cursor: cursor,
    })
    all.push(...res.results)
    cursor = res.has_more ? (res.next_cursor ?? undefined) : undefined
  } while (cursor)
  return all
}

function preview(block) {
  const data = block[block.type]
  if (!data) return ""
  if (block.type === "embed") return data.url ?? ""
  if (block.type === "image") {
    const img = data
    return img.type === "external" ? (img.external?.url ?? "") : (img.file?.url ?? "")
  }
  const rt = data.rich_text
  if (Array.isArray(rt)) return rt.map((t) => t.plain_text).join("").slice(0, 80)
  return ""
}

async function uploadHtml(htmlFile) {
  const html = fs.readFileSync(htmlFile, "utf8")
  const filename = htmlFile.split(/[\\/]/).pop() || "diagram.html"
  const fu = await notion.fileUploads.create({
    mode: "single_part",
    filename,
    content_type: "text/html",
  })
  await notion.fileUploads.send({
    file_upload_id: fu.id,
    file: { data: new Blob([html], { type: "text/html" }), filename },
  })
  return fu.id
}

async function cmdList(pageId) {
  const children = await listChildren(pageId)
  children.forEach((b, i) => {
    console.log(`${i}\t${b.type}\t${b.id}\t${preview(b)}`)
  })
}

async function cmdAdd(pageId, htmlFile, after) {
  const fileId = await uploadHtml(htmlFile)
  const res = await notion.blocks.children.append({
    block_id: pageId,
    ...(after ? { after } : {}),
    children: [
      { type: "embed", embed: { type: "file_upload", file_upload: { id: fileId } } },
    ],
  })
  console.log(`created block ${res.results[0].id}`)
}

async function cmdReplace(blockId, htmlFile) {
  const block = await notion.blocks.retrieve({ block_id: blockId })
  const parentId =
    block.parent.type === "page_id" ? block.parent.page_id : block.parent.block_id
  const siblings = await listChildren(parentId)
  const idx = siblings.findIndex((b) => b.id === blockId)
  const after = idx > 0 ? siblings[idx - 1].id : undefined

  const fileId = await uploadHtml(htmlFile)
  await notion.blocks.delete({ block_id: blockId })
  const res = await notion.blocks.children.append({
    block_id: parentId,
    ...(after ? { after } : {}),
    children: [
      { type: "embed", embed: { type: "file_upload", file_upload: { id: fileId } } },
    ],
  })
  console.log(`replaced with block ${res.results[0].id}`)
}

async function cmdDelete(blockId) {
  await notion.blocks.delete({ block_id: blockId })
  console.log(`deleted ${blockId}`)
}

const [cmd, ...rest] = process.argv.slice(2)
const flags = {}
const pos = []
for (let i = 0; i < rest.length; i++) {
  if (rest[i] === "--after") flags.after = rest[++i]
  else pos.push(rest[i])
}

try {
  if (cmd === "list") await cmdList(pos[0])
  else if (cmd === "add") await cmdAdd(pos[0], pos[1], flags.after)
  else if (cmd === "replace") await cmdReplace(pos[0], pos[1])
  else if (cmd === "delete") await cmdDelete(pos[0])
  else {
    console.error(
      "Usage:\n" +
        "  node notion-html.mjs list <pageId>\n" +
        "  node notion-html.mjs add <pageId> <htmlFile> [--after <blockId>]\n" +
        "  node notion-html.mjs replace <blockId> <htmlFile>\n" +
        "  node notion-html.mjs delete <blockId>",
    )
    process.exit(1)
  }
} catch (err) {
  console.error("Error:", err.message ?? err)
  process.exit(1)
}
