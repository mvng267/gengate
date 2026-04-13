import Link from "next/link";

import { LocationShell } from "@/components/location-shell";

type LocationPageProps = {
  searchParams?: Promise<{
    owner?: string;
    allowed?: string;
    share?: string;
  }>;
};

export default async function LocationPage({ searchParams }: LocationPageProps) {
  const params = searchParams ? await searchParams : undefined;
  const ownerUserId = params?.owner?.trim() ?? "";
  const allowedUserId = params?.allowed?.trim() ?? "";
  const shareId = params?.share?.trim() ?? "";

  const profileHref = ownerUserId ? `/profile?user=${encodeURIComponent(ownerUserId)}` : allowedUserId ? `/profile?user=${encodeURIComponent(allowedUserId)}` : "/profile";
  const feedHref = ownerUserId || allowedUserId
    ? `/feed?author=${encodeURIComponent(ownerUserId || allowedUserId)}&viewer=${encodeURIComponent(allowedUserId || ownerUserId)}`
    : "/feed";
  const inboxHref = ownerUserId || allowedUserId
    ? `/inbox?userA=${encodeURIComponent(ownerUserId || allowedUserId)}&userB=${encodeURIComponent(allowedUserId || ownerUserId)}&sender=${encodeURIComponent(ownerUserId || allowedUserId)}`
    : "/inbox";
  const notificationsHref = ownerUserId ? `/notifications?user=${encodeURIComponent(ownerUserId)}` : allowedUserId ? `/notifications?user=${encodeURIComponent(allowedUserId)}` : "/notifications";

  return (
    <section>
      <h1>Location</h1>
      <p>Optional location sharing state shell is now wired for MVP testing.</p>
      <p>Use the launcher form below to prefill owner/audience/share context before exercising the location shell.</p>

      <form method="GET" action="/location" style={{ display: "grid", gap: 12, maxWidth: 720, marginBottom: 20 }}>
        <label htmlFor="location-owner-user-id">
          Owner user UUID
          <input
            id="location-owner-user-id"
            name="owner"
            type="text"
            defaultValue={ownerUserId}
            placeholder="Paste owner user UUID"
            style={{ display: "block", width: "100%", marginTop: 8, padding: 10 }}
          />
        </label>
        <label htmlFor="location-allowed-user-id">
          Allowed user UUID (optional)
          <input
            id="location-allowed-user-id"
            name="allowed"
            type="text"
            defaultValue={allowedUserId}
            placeholder="Paste optional allowed user UUID"
            style={{ display: "block", width: "100%", marginTop: 8, padding: 10 }}
          />
        </label>
        <label htmlFor="location-share-id">
          Existing share UUID (optional)
          <input
            id="location-share-id"
            name="share"
            type="text"
            defaultValue={shareId}
            placeholder="Paste existing share UUID if you want to reload counts directly"
            style={{ display: "block", width: "100%", marginTop: 8, padding: 10 }}
          />
        </label>
        <button type="submit" style={{ width: "fit-content", padding: "10px 14px" }}>
          Prefill location shell
        </button>
      </form>

      {ownerUserId || allowedUserId || shareId ? (
        <>
          <p>
            Active location context: owner <code>{ownerUserId || "(not set)"}</code> · allowed <code>{allowedUserId || "(not set)"}</code>
            {" · share "}
            <code>{shareId || "(not set)"}</code>
          </p>
          <p>
            Suggested pivots after validating location state: <Link href={profileHref}>Profile</Link> · <Link href={feedHref}>Feed</Link> ·{" "}
            <Link href={inboxHref}>Inbox</Link> · <Link href={notificationsHref}>Notifications</Link>
          </p>
          <p>
            Tip: these pivots now carry the current owner/allowed context forward, so you can continue cross-seam testing without retyping the same IDs.
          </p>
        </>
      ) : (
        <p>
          Provide owner/share-related UUIDs here before using the shell below, instead of manually retyping them for every location test pass.
        </p>
      )}

      <LocationShell initialOwnerUserId={ownerUserId} initialAllowedUserId={allowedUserId} initialShareId={shareId} />
    </section>
  );
}
