import { FriendGraphShell } from "@/components/friend-graph-shell";

type ProfilePageProps = {
  searchParams?: Promise<{
    user?: string;
  }>;
};

export default async function ProfilePage({ searchParams }: ProfilePageProps) {
  const params = searchParams ? await searchParams : undefined;
  const selectedUserId = params?.user?.trim() ?? "";

  return (
    <section>
      <h1>Profile</h1>
      <p>Friend graph shell is now the first product seam beyond auth for MVP testing.</p>
      {selectedUserId ? (
        <FriendGraphShell userId={selectedUserId} />
      ) : (
        <p>
          Provide <code>?user=&lt;uuid&gt;</code> on this route after creating users and friend requests in backend to inspect the
          friend graph shell.
        </p>
      )}
    </section>
  );
}
