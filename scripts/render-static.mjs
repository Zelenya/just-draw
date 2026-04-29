import fs from "node:fs/promises"
import path from "node:path"
import { pathToFileURL } from "node:url"

// Loads the compiled PureScript static renderer
const loadStaticFilesRenderer = async () => {
  const moduleUrl = pathToFileURL(
    path.resolve("output/Build.Static/index.js"),
  ).href
  const { renderStaticFiles } = await import(`${moduleUrl}?t=${Date.now()}`)
  return renderStaticFiles
}

export const writeStaticFiles = async ({ basePath, distDir }) => {
  const renderStaticFiles = await loadStaticFilesRenderer()
  const files = renderStaticFiles({ basePath })

  await Promise.all(
    // Returns records like { outputPath: string, html: string }
    files.map(async file => {
      const outputPath = path.join(distDir, file.outputPath)
      await fs.mkdir(path.dirname(outputPath), { recursive: true })
      await fs.writeFile(outputPath, file.html)
    }),
  )
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  await writeStaticFiles({
    basePath: process.argv.includes("--local") ? "/" : "/just-draw",
    distDir: "dist",
  })

  console.log("Rendered static route files.")
}
