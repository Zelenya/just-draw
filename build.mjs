import esbuild from "esbuild";
import { execFile } from "node:child_process";
import { watch } from "node:fs";
import { promisify } from "node:util";
import pursPlugin from "esbuild-plugin-purescript";
import copyStaticFiles from "esbuild-copy-static-files";

const watchMode = process.argv.includes("--watch");
const basePath = watchMode ? "/" : "/just-draw";
const execFileAsync = promisify(execFile);

const buildCss = async () => {
  await execFileAsync(
    "npx",
    ["@tailwindcss/cli", "-i", "./styles/globals.css", "-o", "./dist/style.css"],
    { env: process.env }
  );
};

const renderStaticFiles = async () => {
  await execFileAsync(
    "node",
    ["./scripts/render-static.mjs", ...(watchMode ? ["--local"] : [])],
    { env: process.env }
  );
};

const writeStaticFilesPlugin = {
  name: "write-static-files",
  setup(build) {
    build.onEnd(async (result) => {
      if (result.errors.length > 0) {
        return;
      }

      await renderStaticFiles();
    });
  },
};

const makeSerialTask = (task) => {
  let running = false;
  let pending = false;

  return async () => {
    pending = true;

    if (running) {
      return;
    }

    running = true;

    while (pending) {
      pending = false;

      try {
        await task();
      } catch (error) {
        console.error(error);
      }
    }

    running = false;
  };
};

const ctx = await esbuild
  .context({
    entryPoints: ["index.js"],
    entryNames: "index",
    bundle: true,
    outdir: "dist",
    publicPath: basePath,
    define: {
      __BASE_PATH__: JSON.stringify(basePath),
    },
    plugins: [
      pursPlugin(),
      copyStaticFiles({ src: "./public", dest: "./dist" }),
      ...(watchMode ? [writeStaticFilesPlugin] : []),
    ],
    loader: {
      ".png": "file",
      ".svg": "file",
    },
    logLevel: "info",
    banner: watchMode
      ? {
          js: `(() => {
  new EventSource('/esbuild').addEventListener('change', () => location.reload());
})();`,
        }
      : {},
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

if (watchMode) {
  await ctx.watch();

  await ctx.serve({
    servedir: "./dist",
    port: 1234,
    fallback: "./dist/index.html",
  });

  const rebuildCss = makeSerialTask(async () => {
    await buildCss();
  });

  watch("styles", { recursive: true }, (_eventType, filename) => {
    if (filename?.endsWith(".css")) {
      rebuildCss();
    }
  });

  watch("src", { recursive: true }, (_eventType, filename) => {
    if (filename?.endsWith(".purs") || filename?.endsWith(".js")) {
      rebuildCss();
    }
  });

  console.log("Development server running at http://localhost:1234");
} else {
  await ctx.rebuild();
  await renderStaticFiles();
  await ctx.dispose();
}
