# API design

This is the transport layer: the thin band between the UI and the domain whose only jobs are validating what came in, confirming who is asking, delegating the decision downward, and validating what goes back out. It makes no business decisions of its own. A transport function that knows Stripe price IDs has absorbed the domain layer and the boundary is gone.

The failure mode is familiar because most APIs have it: no validation, a 500 for every problem, and documentation in a document nobody has updated since last year. Every part of that is fixed by the same move, which is putting the **contract** first.

## Server actions or route handlers

Both run on the server. The question is who calls them.

**Server actions** for mutations from inside your own app. They abstract the network boundary away: no endpoint to define, no fetch to write, no response type to keep in sync. The framework generates the endpoint and wires the call. For "this form creates a post", nothing else competes.

**Route handlers** when something outside your app needs a URL:

- **Webhooks.** Stripe, a CMS, any provider posting an event to you.
- **Public or third-party APIs**, where consumers need documented methods and paths.
- **Full control of the HTTP surface**: status codes, custom headers, streaming responses.
- **Parallel invocation.** Server actions execute one at a time per request; if several must run concurrently, they cannot.

Default to actions inside the app, and reach for handlers at the edges. Both are covered by the same rule from `security.md`: they are public entry points, so validation and authorization happen inside them regardless of who you expect to be calling.

## Contract first

The contract is a schema that defines input and output before any implementation exists. Both sides of the app build against it, and it produces the runtime validation, the TypeScript types, and the documentation from one definition. Change the contract and all three follow. Nothing can drift, because there is nothing separate to drift from.

Two schemas per operation, and the output one is the one people skip:

```ts
// shared/contracts/tutorial.ts
export const createTutorialInput = z.object({
  title: z.string().min(2).max(100),
  slug: z.string().regex(/^[a-z0-9-]+$/),
  content: z.string().min(1),
})

export const tutorialOutput = z.object({
  id: z.uuid(),
  title: z.string(),
  slug: z.string(),
  content: z.string(),
  createdAt: z.date(),
})

// list responses carry their own cursor
export const tutorialListOutput = z.object({
  items: z.array(tutorialOutput),
  nextCursor: z.string().nullable(),
})
```

Input validation stops garbage from reaching the domain. Output validation stops the database from reaching the client, which is the same guarantee the DTO gives in `data-layer.md`, expressed at the transport boundary instead of the data one.

**Contracts live in the shared foundations layer**, never inside the transport package. Both the API and the UI import them, which is what lets the client know the response type without a single hand-written interface. A schema defined inside transport forces the UI to depend on transport internals and the dependency rule is broken.

Cursor pagination on every list endpoint, from the beginning. Retrofitting pagination means changing the response shape, which means changing every consumer.

> **VERIFY:** the current major of the schema library and its API. Zod in particular has moved validators between majors (`z.string().uuid()` became `z.uuid()`, `z.string().email()` became `z.email()`). Check before writing schemas from memory.

## Typed RPC

A typed RPC layer implements the contract as **procedures** and gives the client end-to-end type safety with no generated client and no manually maintained types. Call the procedure, get the return type, done. If the contract changes and a call site no longer matches, type checking fails at build time instead of a user finding it.

The shape:

- **The contract** declares input, output, possible errors, and the HTTP metadata (method, path, summary, tags).
- **The procedure** implements one contract entry. It cannot return a shape the contract does not describe.
- **Middleware** composes onto procedures for the cross-cutting concerns: session checks, rate limiting, bot protection. Written once, chained onto every procedure that needs it, and it puts the authenticated user into the handler's context.

```ts
export const createTutorial = os.tutorial.create
  .use(requireAuth)                              // context.user now exists and is valid
  .handler(async ({ input, context, errors }) => {
    const existing = await tutorialDal.findBySlug(input.slug)
    if (existing) throw errors.CONFLICT({ message: "That slug is taken" })
    return tutorialDal.create(input, context.user.id)
  })
```

Notice what the handler does **not** do: no session parsing, no manual input checking, no shaping of the response. The middleware handled identity, the contract handled validation in both directions, and the DAL owns the database. The handler is left with the orchestration, which is all transport should ever hold.

> **VERIFY:** the current setup of the typed-RPC library, its builder and middleware API, and how it mounts into the framework's route handlers. Also check whether the framework's own typed server functions now cover the use case without the extra library.

## OpenAPI

When contracts carry HTTP metadata, the OpenAPI specification generates from them, and an interactive documentation page generates from that. Endpoints, request bodies, response schemas, error codes and a live client, all derived rather than written.

The value is that it cannot go stale. Manually maintained API documentation is wrong the day after it is written, and everyone knows it, which is why nobody trusts it and everybody reads the source instead.

Add the route metadata to each contract entry as you write it: HTTP method, path, success status, a one-line summary, a description that says what authentication is required, and tags to group related endpoints in the docs. It is a few lines per endpoint and it is what turns procedures into a documented API.

> **VERIFY:** the current handler for serving the generated specification and the documentation UI, and where it mounts. This is a catch-all route and the framework's conventions for those have changed.

## Errors

A production API does not answer every problem with a 500. Errors are part of the contract, declared once on a base and reused everywhere, so the same failure always produces the same status and the same shape.

Every error carries a status and a human-readable message, plus structured data when the client needs to act on it:

```ts
{ status: 404, message: "Tutorial not found", data: { resourceType: "tutorial", id } }
```

| Status | Meaning | Typical cause |
|---|---|---|
| **400** | Bad request | Input failed schema validation |
| **401** | Unauthenticated | No session, or an invalid token |
| **403** | Forbidden | Authenticated, but the policy said no |
| **404** | Not found | The resource does not exist, or the caller may not know it does |
| **409** | Conflict | A business rule was violated: slug taken, email registered, already cancelled |
| **422** | Unprocessable | Syntactically valid, semantically impossible. 400 is acceptable if you would rather not draw this line |
| **500** | Internal error | A bug. Never a rule you chose not to express |

Separate the two kinds cleanly. **Expected errors** are outcomes the product has rules about, and they are thrown deliberately with the right code. **Unexpected errors** are exceptions: log them with enough context to debug, return a generic 500, and never leak a stack trace or a database message to the caller.

The distinction between 401 and 403 is worth getting right because it drives client behavior. 401 means "log in", and the client can act on it. 403 means "you are logged in and it still will not happen", and retrying with a fresh session changes nothing.

## Webhooks

Incoming webhooks are route handlers with two extra obligations:

**Verify the signature before anything else.** The URL is public and anyone can post to it. Every serious provider signs its payloads; validate with the raw request body, since parsing to JSON first usually invalidates the signature.

**Assume duplicate delivery.** Providers retry, and at-least-once delivery means the same event arrives twice. Record processed event ids and skip repeats, or make the handler naturally idempotent by writing state rather than incrementing it. Charging a customer twice because a retry succeeded is the canonical version of this bug.

Webhooks are also how asynchronous flows finish, and the shape recurs across payments, uploads, and background jobs:

1. The user acts. Transport delegates to the domain, which calls the capability, which calls the vendor.
2. The vendor takes over. Seconds, minutes, sometimes a day.
3. The webhook handler receives the completion event, verifies it, and syncs the result into your database.
4. The UI reads the updated state.

State lives in your database, not in the vendor. The webhook's job is to keep the two in agreement.

> **VERIFY:** the current way to read a raw request body in a route handler, since signature verification depends on it and the API has changed.

## Common mistakes

| Mistake | Consequence |
|---|---|
| Business logic in a procedure or action | Transport absorbed the domain; the rule is now unreusable and untestable |
| Contracts defined inside the transport package | The UI must depend on transport internals to know its own types |
| Input validated, output not | Internal columns reach the client and the response shape is unenforced |
| Hand-written client types | They drift from the server the first time someone forgets |
| Everything returns 500 | Clients cannot distinguish "log in" from "not allowed" from "already exists" |
| Stack traces in error responses | Free internal reconnaissance for an attacker |
| Manually maintained API docs | Wrong within a week and trusted by nobody |
| Webhook processed without signature verification | Anyone who finds the URL can forge events |
| Webhook handler that is not idempotent | Retries double-charge, double-send, double-write |
| Pagination added later | A breaking change to every consumer |
