import { AuthenticatedRouteShell } from "@/components/authenticated-route-shell";

export default function InboxPage() {
  return (
    <AuthenticatedRouteShell
      title="Inbox"
      summary="1:1 encrypted messaging thread list and composer are pending."
    />
  );
}
