import Link from "next/link";

const seamCards = [
  {
    href: "/login",
    title: "1. Login / persisted session",
    summary: "Register or restore a persisted session before testing protected shells.",
  },
  {
    href: "/profile",
    title: "2. Friend graph shell",
    summary: "Use real user UUIDs to inspect profile and friend graph flows.",
  },
  {
    href: "/feed",
    title: "3. Moments + private feed shell",
    summary: "Create a moment with image metadata, then reload authored moments and private friend feed.",
  },
  {
    href: "/inbox",
    title: "4. Direct messaging shell",
    summary: "Open or reuse a direct thread by two user UUIDs, then send and reload messages.",
  },
  {
    href: "/notifications",
    title: "5. Notification shell",
    summary: "Create minimal notifications by user UUID, then toggle read/unread state.",
  },
  {
    href: "/location",
    title: "6. Location sharing shell",
    summary: "Create a share, add audience, create snapshots, and toggle sharing state.",
  },
];

export default function HomePage() {
  return (
    <section>
      <h1>GenGate MVP Test Hub</h1>
      <p>
        Core MVP seams beyond auth are now wired on web. Use this page as the single guided
        entry point for human testing instead of remembering individual routes.
      </p>
      <ol>
        <li>Start by creating or restoring a session in Login.</li>
        <li>Register/copy user UUIDs you want to reuse across the shells.</li>
        <li>Walk the seams below in order or jump directly to the one you want to test.</li>
      </ol>
      <ul>
        {seamCards.map((card) => (
          <li key={card.href}>
            <h2>
              <Link href={card.href}>{card.title}</Link>
            </h2>
            <p>{card.summary}</p>
            <p>
              Route: <code>{card.href}</code>
            </p>
          </li>
        ))}
      </ul>
      <p>
        Suggested smoke path: <Link href="/login">Login</Link> → <Link href="/profile">Profile</Link> →{" "}
        <Link href="/feed">Feed</Link> → <Link href="/inbox">Inbox</Link> →{" "}
        <Link href="/notifications">Notifications</Link> → <Link href="/location">Location</Link>
      </p>
    </section>
  );
}
