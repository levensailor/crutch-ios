import Link from "next/link";

export default function NotFound() {
  return (
    <main className="page-shell">
      <section className="panel">
        <div className="eyebrow">Not found</div>
        <h1>Song not found</h1>
        <p className="muted">That song may have been deleted from the public lyrics manager.</p>
        <Link className="button" href="/">
          Back to songs
        </Link>
      </section>
    </main>
  );
}
