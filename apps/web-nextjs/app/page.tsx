import Link from "next/link";

export default function HomePage() {
  return (
    <section>
      <h1>GenGate Web Foundation</h1>
      <p>
        This is a Phase 1 starter shell. Core features are intentionally stubbed and
        will be implemented in later batches.
      </p>
      <p>
        Start with <Link href="/login">Login</Link> or jump to <Link href="/feed">Feed</Link>.
      </p>
    </section>
  );
}
