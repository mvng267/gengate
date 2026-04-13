import Link from "next/link";

const seamCards = [
  {
    href: "/login",
    title: "1. Login / persisted session",
    summary: "Register or restore a persisted session before testing protected shells.",
    example: "/login",
  },
  {
    href: "/profile",
    title: "2. Friend graph shell",
    summary: "Launch one user context, inspect the friend graph, then pivot into nearby seams.",
    example: "/profile?user=<uuid>",
  },
  {
    href: "/feed",
    title: "3. Moments + private feed shell",
    summary: "Prefill author/viewer context, create a moment, then reload authored moments and private friend feed.",
    example: "/feed?author=<uuidA>&viewer=<uuidB>",
  },
  {
    href: "/inbox",
    title: "4. Direct messaging shell",
    summary: "Prefill a user pair, open or reuse a direct thread, then send and reload messages.",
    example: "/inbox?userA=<uuidA>&userB=<uuidB>&sender=<uuidA>",
  },
  {
    href: "/notifications",
    title: "5. Notification shell",
    summary: "Prefill one user context, then load, create, and toggle minimal notifications.",
    example: "/notifications?user=<uuid>",
  },
  {
    href: "/location",
    title: "6. Location sharing shell",
    summary: "Prefill owner/allowed/share context, then create shares, add audience, create snapshots, and reload counts.",
    example: "/location?owner=<uuidOwner>&allowed=<uuidFriend>&share=<uuidShare>",
  },
];

export default function HomePage() {
  return (
    <section>
      <h1>GenGate MVP Test Hub</h1>
      <p>
        Core MVP seams beyond auth are now wired on web. Use this page as the single guided entry point for human testing instead of
        remembering route conventions by hand.
      </p>
      <ol>
        <li>Start by creating or restoring a session in Login.</li>
        <li>Register/copy the user UUIDs you want to reuse across social, messaging, notification, and location seams.</li>
        <li>Use the launcher pages below to prefill context before operating the shell itself.</li>
      </ol>
      <ul>
        {seamCards.map((card) => (
          <li key={card.href}>
            <h2>
              <Link href={card.href}>{card.title}</Link>
            </h2>
            <p>{card.summary}</p>
            <p>
              Launcher route: <code>{card.href}</code>
            </p>
            <p>
              Prefill example: <code>{card.example}</code>
            </p>
          </li>
        ))}
      </ul>
      <p>
        Suggested browser smoke path: <Link href="/login">Login</Link> → <Link href="/profile">Profile</Link> → <Link href="/feed">Feed</Link>
        {" → "}
        <Link href="/inbox">Inbox</Link> → <Link href="/notifications">Notifications</Link> → <Link href="/location">Location</Link>
      </p>
      <p>
        Tip: after the recent hardening passes, <code>/profile</code>, <code>/feed</code>, <code>/inbox</code>, <code>/notifications</code>, and <code>/location</code>
        all expose a launcher form directly on the page, so query strings are optional unless you want shareable/repeatable test URLs.
      </p>
    </section>
  );
}
