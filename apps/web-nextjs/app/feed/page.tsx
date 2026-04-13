import Link from "next/link";

import { MomentComposeShell } from "@/components/moment-compose-shell";

type FeedPageProps = {
  searchParams?: Promise<{
    author?: string;
    viewer?: string;
  }>;
};

export default async function FeedPage({ searchParams }: FeedPageProps) {
  const params = searchParams ? await searchParams : undefined;
  const authorUserId = params?.author?.trim() ?? "";
  const viewerUserId = params?.viewer?.trim() ?? "";

  const profileHref = authorUserId ? `/profile?user=${encodeURIComponent(authorUserId)}` : viewerUserId ? `/profile?user=${encodeURIComponent(viewerUserId)}` : "/profile";
  const inboxHref = authorUserId || viewerUserId
    ? `/inbox?userA=${encodeURIComponent(authorUserId || viewerUserId)}&userB=${encodeURIComponent(viewerUserId || authorUserId)}&sender=${encodeURIComponent(authorUserId || viewerUserId)}`
    : "/inbox";
  const notificationsHref = viewerUserId ? `/notifications?user=${encodeURIComponent(viewerUserId)}` : authorUserId ? `/notifications?user=${encodeURIComponent(authorUserId)}` : "/notifications";
  const locationHref = authorUserId ? `/location?owner=${encodeURIComponent(authorUserId)}&allowed=${encodeURIComponent(viewerUserId)}` : viewerUserId ? `/location?owner=${encodeURIComponent(viewerUserId)}` : "/location";

  return (
    <section>
      <h1>Feed</h1>
      <p>Moment posting with image + caption shell is now wired for MVP testing.</p>
      <p>Use the launcher form below to prefill author/viewer UUIDs before creating moments or checking the private friend feed.</p>

      <form method="GET" action="/feed" style={{ display: "grid", gap: 12, maxWidth: 720, marginBottom: 20 }}>
        <label htmlFor="feed-author-user-id">
          Author user UUID
          <input
            id="feed-author-user-id"
            name="author"
            type="text"
            defaultValue={authorUserId}
            placeholder="Paste author user UUID"
            style={{ display: "block", width: "100%", marginTop: 8, padding: 10 }}
          />
        </label>
        <label htmlFor="feed-viewer-user-id">
          Feed viewer UUID
          <input
            id="feed-viewer-user-id"
            name="viewer"
            type="text"
            defaultValue={viewerUserId}
            placeholder="Paste viewer UUID"
            style={{ display: "block", width: "100%", marginTop: 8, padding: 10 }}
          />
        </label>
        <button type="submit" style={{ width: "fit-content", padding: "10px 14px" }}>
          Prefill feed shell
        </button>
      </form>

      {authorUserId || viewerUserId ? (
        <>
          <p>
            Active feed context: author <code>{authorUserId || "(not set)"}</code> · viewer <code>{viewerUserId || "(not set)"}</code>
          </p>
          <p>
            Suggested pivots after validating moments/feed: <Link href={profileHref}>Profile</Link> · <Link href={inboxHref}>Inbox</Link> ·{" "}
            <Link href={notificationsHref}>Notifications</Link> · <Link href={locationHref}>Location</Link>
          </p>
          <p>
            Tip: these pivots now carry the current author/viewer context forward, so you can continue cross-seam testing without re-entering the same UUID pair.
          </p>
        </>
      ) : (
        <p>
          Provide author/viewer UUIDs here before using the shell below, instead of manually retyping them for every feed test pass.
        </p>
      )}

      <MomentComposeShell initialAuthorUserId={authorUserId} initialViewerUserId={viewerUserId} />
    </section>
  );
}
