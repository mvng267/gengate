import { AuthenticatedRouteShell } from "@/components/authenticated-route-shell";

export default function ProfilePage() {
  return (
    <AuthenticatedRouteShell
      title="Profile"
      summary="Profile edit form, privacy settings, and recent moments are pending."
    />
  );
}
