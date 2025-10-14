# Troubleshooting: Persistent Blank Display on Netlify (Vite + Stacks.js)

## Problem
After deploying a Vite + React app using @stacks/connect to Netlify, the site displayed a blank page in production, even though it worked perfectly locally. The browser console showed a module resolution error:

```
Failed to resolve module specifier '@stacks/connect'
```

## Cause
Vite's production build and Netlify's environment handle module resolution differently than the local dev server. Some npm packages (like @stacks/connect) use CommonJS or mixed ESM/CJS, which Vite may not bundle correctly for production unless explicitly handled. This leads to missing or broken modules in the deployed app.

## Solution
**Add the Vite CommonJS plugin and update Vite config:**

1. Install the plugin:
   ```sh
   npm install @originjs/vite-plugin-commonjs --save-dev
   ```
2. Update `vite.config.ts`:
   ```ts
   import { defineConfig } from 'vite';
   import react from '@vitejs/plugin-react';
   import { viteCommonjs } from '@originjs/vite-plugin-commonjs';

   export default defineConfig({
     plugins: [react(), viteCommonjs()],
   });
   ```
3. Clean and rebuild:
   ```sh
   # PowerShell
   Remove-Item -Recurse -Force node_modules
   Remove-Item -Force package-lock.json
   Remove-Item -Recurse -Force dist
   npm install
   npm run build
   ```
4. Commit and push changes, then redeploy to Netlify.

## Why This Works
- The CommonJS plugin tells Vite to properly transform and bundle CommonJS dependencies (like @stacks/connect) for production.
- Removing `external: ['@stacks/connect']` from `rollupOptions` ensures the package is bundled, not excluded.
- This resolves module resolution errors that only appear in production builds on Netlify.

## References
- [Vite Plugin CommonJS](https://github.com/originjs/vite-plugins/tree/main/packages/vite-plugin-commonjs)
- [Vite Docs: CommonJS](https://vitejs.dev/guide/features.html#commonjs)
- [Stacks.js GitHub](https://github.com/hirosystems/stacks.js)

---
**Tip:** For future bugs, document the error message, cause, and solution in this file for your team!
