type RoutePlaceholderProps = {
  title: string;
  summary: string;
};

export function RoutePlaceholder({ title, summary }: RoutePlaceholderProps) {
  return (
    <section>
      <h1>{title}</h1>
      <p>{summary}</p>
      <p>
        <strong>Status:</strong> route shell only (MVP foundation).
      </p>
    </section>
  );
}
