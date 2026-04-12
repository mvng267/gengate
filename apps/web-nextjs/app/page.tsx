import Link from "next/link";

export default function HomePage() {
  return (
    <section>
      <h1>GenGate Web Foundation</h1>
      <p>
        Batch 31 đã có persisted session shell tối thiểu. Login flow hiện có thể giữ
        session cục bộ và dùng lại để mở route shell cần auth.
      </p>
      <p>
        Start with <Link href="/login">Login</Link> or open <Link href="/feed">Feed</Link>.
      </p>
    </section>
  );
}
