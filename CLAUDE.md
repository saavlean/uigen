# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UIGen is an AI-powered React component generator with live preview. It uses Claude AI to generate React components based on natural language descriptions, renders them in real-time using a virtual file system, and allows users to iterate on designs through conversation.

## Development Commands

```bash
# Initial setup (install, generate Prisma client, run migrations)
npm run setup

# Start development server with Turbopack
npm run dev

# Run tests with Vitest
npm run test

# Build for production
npm run build

# Database operations
npm run db:reset              # Reset database (force)
npx prisma migrate dev        # Create and apply migrations
npx prisma studio             # Open Prisma Studio GUI
```

## Technology Stack

- **Framework:** Next.js 15.3.3 with App Router, React 19
- **Language:** TypeScript (strict mode)
- **Styling:** Tailwind CSS v4, shadcn/ui (New York style)
- **Database:** Prisma ORM with SQLite
- **AI:** Anthropic Claude Haiku 4.5 via Vercel AI SDK
- **Testing:** Vitest with jsdom and React Testing Library
- **Code Editor:** Monaco Editor
- **Mock Mode:** Project runs without ANTHROPIC_API_KEY (returns static code)

## Core Architecture

### Virtual File System

The heart of the application is an in-memory virtual file system (`src/lib/file-system.ts`):

- **VirtualFileSystem class** maintains a tree structure using `Map<string, FileNode>`
- Supports full CRUD operations: create, read, update, delete, rename
- **Never writes to disk** - exists only in memory and database
- Serializes to/from JSON for Prisma storage
- Used by both AI tools and UI components
- Changes propagate through `FileSystemContext` to trigger re-renders

### AI Agent System

AI generation uses Vercel AI SDK's `streamText` with function calling (`src/app/api/chat/route.ts`):

- **Two AI tools available to Claude:**
  - `str_replace_editor` (from `src/lib/tools/str-replace.ts`): View file contents, create new files, edit files via string replacement
  - `file_manager` (from `src/lib/tools/file-manager.ts`): Rename and delete files
- Supports up to 40 generation steps per request
- System prompt in `src/lib/prompts/generation.tsx` instructs Claude on component generation patterns
- **Mock provider** (`src/lib/provider.ts`): Returns static code when API key not present

### Client-Side JSX Transformation

Components are transformed and rendered entirely in the browser (`src/lib/transform/jsx-transformer.ts`):

1. **Babel transformation:** Uses `@babel/standalone` to transform JSX/TSX to JavaScript
2. **Module system:** Creates blob URLs for each transformed module
3. **Import maps:** Generates ES module import maps for module resolution
4. **Path aliases:** Handles `@/` paths by mapping to virtual file system
5. **Missing imports:** Creates placeholder modules for undefined imports to prevent runtime errors
6. **Tailwind integration:** Injects Tailwind CSS v4 via CDN

Result is rendered in `PreviewFrame.tsx` inside a sandboxed iframe with:
- React 19 from esm.sh CDN
- Error boundaries for graceful error handling
- Full import map for module resolution
- Real-time updates when files change

### Authentication & State

**JWT-based authentication** (`src/lib/auth.ts`, `src/middleware.ts`):
- Uses `jose` library for JWT operations
- Password hashing with bcrypt
- Middleware protects API routes
- Supports both authenticated and anonymous users
- Anonymous: ephemeral virtual file system (lost on refresh)
- Authenticated: projects persisted to SQLite via Prisma

**Database schema** (`prisma/schema.prisma`):
```prisma
User {
  id, email, password (bcrypt), projects[]
}

Project {
  id, name, userId (optional), messages (JSON), data (JSON), user
}
```

**State management via React Context:**
- `ChatContext` (`src/lib/contexts/chat-context.tsx`): Manages chat messages, streaming state
- `FileSystemContext` (`src/lib/contexts/file-system-context.tsx`): Manages virtual file system state and operations

### Server Actions

Data operations use Next.js server actions (`src/actions/`):
- `createProject(name)`: Create new project for current user
- `getProject(id)`: Fetch project by ID with authorization check
- `getProjects()`: List all projects for current user
- `getUser()`: Get current authenticated user from JWT

## Key Files and Their Roles

- `src/app/api/chat/route.ts`: AI chat endpoint, orchestrates Claude streaming and tool execution
- `src/lib/file-system.ts`: Virtual file system implementation (518 lines)
- `src/lib/transform/jsx-transformer.ts`: Babel-based JSX transformation and module bundling
- `src/components/preview/PreviewFrame.tsx`: Sandboxed iframe component renderer
- `src/components/editor/CodeEditor.tsx`: Monaco editor wrapper
- `src/components/chat/ChatInterface.tsx`: Main chat UI with message list and input
- `src/app/main-content.tsx`: Primary app layout (resizable split-pane)
- `src/middleware.ts`: Auth middleware for protected routes

## Component Development Patterns

**shadcn/ui components** are in `src/components/ui/`:
- Built on Radix UI primitives
- New York style configuration
- Use `cn()` utility from `src/lib/utils.ts` for class merging
- Import from `@/components/ui/*`

**AI-generated components**:
- Should use Tailwind CSS for styling
- Import from `@/components/ui/*` for shadcn components
- Use `@/` path alias for local imports
- Export default for main component
- Support hot reload in preview

## Testing

- Test files use Vitest with React Testing Library
- Located in `__tests__` directories alongside source
- Path aliases (`@/*`) supported via `vite-tsconfig-paths`
- Run with `npm test`

## Important Notes

- **No disk writes:** All code generation happens in virtual file system
- **Import resolution:** Uses custom import map generation in jsx-transformer
- **Preview updates:** Automatic when file system changes via context
- **Anonymous mode:** Full functionality without signup, but no persistence
- **Export feature:** Generates ZIP of all files in virtual file system
- use comments sparingly. Only comment complex code.