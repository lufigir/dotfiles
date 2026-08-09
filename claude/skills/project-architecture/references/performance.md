# Performance

Almost every slow page comes from one of three things: work that happened in sequence when it could have happened at once, JavaScript shipped to the browser that never needed to go there, or a route that lost its static rendering to a single line. None of them are exotic, and all of them are architectural rather than micro-optimizations.

Measure before you touch anything. The production build prints the JavaScript shipped per route and marks each route static or dynamic. That output is the map: it tells you which route is heavy and whether it is being rendered ahead of time at all. Guessing from a dev server tells you nothing, since dev is unoptimized by design.

## Waterfalls

A waterfall is a request that could not start until an unrelated one finished. The classic:

```ts
const user = await getUser()          // 200ms
const posts = await getPosts()        // 200ms, and it waited for no reason
const tags = await getTags()          // 200ms, same
```

600ms of latency where 200ms was available. `getPosts` never needed `user`.

Two fixes, and the second is usually better:

```ts
// independent data, one round of waiting
const [user, posts, tags] = await Promise.all([getUser(), getPosts(), getTags()])
```

```tsx
// or: let each piece fetch its own data and stream in when ready
<Suspense fallback={<PostsSkeleton />}><Posts /></Suspense>
<Suspense fallback={<TagsSkeleton />}><Tags /></Suspense>
```

`Promise.all` makes the page wait for the slowest of the three. Separate suspended components make the page wait for none of them, and the user sees the fast ones immediately.

A genuine dependency is not a waterfall. `getPosts(user.id)` has to wait. Look for the awaits where nothing downstream uses the value above.

## Streaming and Suspense

Streaming sends HTML in pieces as it becomes ready, instead of holding the whole response until the slowest query returns.

The unit of control is the Suspense boundary, and placing it is the whole skill:

- **Keep the shell outside.** Navigation, headings, static copy: these are ready immediately and should render immediately.
- **Wrap only what is slow**, and wrap each slow thing separately so one query cannot hold another hostage.
- **The fallback should match the layout it replaces.** A skeleton with the same dimensions keeps the page from jumping when real content arrives.

```tsx
<header>Nav</header>
<h1>Dashboard</h1>
<Suspense fallback={<ChartSkeleton />}>
  <RevenueChart />        {/* the slow query lives inside this component */}
</Suspense>
```

The framework's route-level loading file is the blunt version of this: it suspends the **entire** route, so a static navbar that could have painted in 50ms waits for the slowest query on the page. Use it as a starting point, then replace it with real boundaries as soon as one part of the route is meaningfully slower than the rest. See `routing.md` for the rest of the route's special files.

For streaming to work, the fetch has to happen **inside** the suspended component. Fetching in the page and passing the result down as a prop means the page awaited it, and the boundary never suspends.

## Server and client components

Server components are the default, and the default is right. They run only on the server, ship no JavaScript for themselves, and skip hydration entirely.

A client component ships its code to the browser and pays for hydration: the framework re-runs the component client-side to attach event handlers. That cost is worth paying for interactivity and nothing else.

The rule: **`"use client"` belongs on the leaves.** When a page needs one interactive button, extract the button, not the page. Marking a component as client marks everything it imports as client too, which is how one `useState` drags an entire route into the bundle.

When a client component needs to wrap server-rendered content, pass it as `children` rather than importing it:

```tsx
// accordion.tsx: "use client", owns the open/closed state
<Accordion>
  <ExpensiveServerComponent />    {/* stays on the server, arrives as rendered output */}
</Accordion>
```

The client component receives already-rendered children and never needs to know what produced them.

## Static, dynamic, and the line between them

Static rendering happens at build time and serves from a CDN. It is the fastest thing available and it is the default until you take it away.

A route becomes dynamic the moment it reads request-time information: cookies, headers, search params. That is correct behavior, and the cost is the whole point of watching for it.

The mistake worth naming: reading cookies in the **root layout**. Every route is inside the root layout, so one session lookup for an avatar turns the entire application dynamic, marketing pages included. The build output is where you catch this, because every route flips from static to dynamic at once.

`data-layer.md` covers the ways out when the dynamic read is a session check. The general form is the same: push the request-time read as deep into the tree as it will go, and isolate it behind a Suspense boundary so the rest of the route keeps its static shell.

## Partial prerendering

Partial prerendering is the resolution of "static or dynamic" into "both, on the same route". The static shell is generated at build time and served from the CDN; the dynamic islands stream in from the server on the same request.

It is exactly right for the shape most real pages have: a product page that is static except for stock and personalized recommendations, a dashboard whose chrome never changes, a marketing page with a logged-in header.

The islands are the Suspense boundaries you already placed. That is the payoff of getting boundaries right: enabling this is a config change rather than a rewrite.

> **VERIFY:** whether partial prerendering is stable or still behind a flag, what the flag is called, whether it is opt-in per route, and whether opting in is still an exported route constant. This has moved on nearly every release.

## Caching

The framework caches; the question is only whether you control it or discover it. Three concerns, and mixing them up is what makes caching feel unpredictable:

- **What to cache.** Mark the data-fetching function, not the page. A directive at the top of the function opts its result into the data cache.
- **How long.** A named profile ("minutes", "hours", "days") beats a raw number, because the intent survives being read six months later.
- **When to throw it away.** Tag the cached data, and invalidate by tag in the mutation that changed it. Time-based expiry alone means a user edits a record and then stares at the old value until the window elapses.

The invalidation belongs in the action that performed the write. A mutation that does not revalidate is a bug that only shows up on someone else's screen.

> **VERIFY:** the current caching directives and their exact names, the profile names available, the tagging and revalidation functions, and which of them are stable. Caching is the single most volatile area of the framework and has been reworked repeatedly. Look it up every time.

## Images

Images are usually the largest thing on the page and the framework's image component handles four problems at once:

- **Format and size.** Serves modern formats and generates the sizes actually needed, instead of sending a 4000px original to a 400px slot.
- **Layout shift.** Explicit `width` and `height` reserve the space before the file arrives, so nothing jumps. Unreserved images are the most common cause of a bad CLS score.
- **Lazy loading.** Off-screen images do not load until they are approached.
- **Priority.** The one image above the fold is usually the largest contentful paint. Marking it `priority` loads it eagerly instead of behind everything else. Marking every image priority is the same as marking none.

Provide `sizes` when the image is responsive, or the browser downloads for the widest case on every screen.

> **VERIFY:** the current image component API, whether `sizes` is required for fill layouts, and the config needed to allow remote image hosts.

## Bundle

Read the per-route JavaScript from the build output and look at the largest ones first. Two moves cover most of what you find:

- **Replace heavy dependencies with platform APIs.** Date formatting and number formatting are the usual offenders: a formatting library can cost tens of kilobytes where the built-in `Intl` costs nothing and is already in the browser.

  ```ts
  new Intl.DateTimeFormat("es-CO", { dateStyle: "long" }).format(date)
  ```

- **Load rarely-used heavy components on demand.** A chart library or a rich text editor behind a tab does not belong in the initial bundle.

Before adding any dependency, check its bundle cost and whether the platform already does the job. This is the cheapest performance decision available and it is made at install time.

## Common mistakes

| Mistake | Consequence |
|---|---|
| Sequential awaits on independent data | Latency adds up instead of overlapping |
| Fetching in the page, passing down as props | The page awaits, so the Suspense boundary never suspends |
| Route-level loading file for the whole page | Static content waits on the slowest query |
| `"use client"` at the top of a page | Everything the page imports ships to the browser |
| Reading cookies in the root layout | The entire application becomes dynamic |
| Time-based cache with no tag invalidation | Users see stale data after their own writes |
| Plain `<img>` | No resizing, no modern formats, layout shift |
| `priority` on every image | Equivalent to prioritizing nothing |
| Judging performance from the dev server | Dev is unoptimized; only the production build is informative |
