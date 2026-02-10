import Link from "next/link";

export const metadata = {
  title: "Support | Rechef",
  description:
    "Get support for Rechef – your smart recipe and pantry companion app.",
};

export default function SupportPage() {
  return (
    <div className="min-h-screen bg-white dark:bg-black">
      <div className="mx-auto max-w-4xl px-6 py-16 sm:px-8">
        <Link
          href="/"
          className="mb-8 inline-flex items-center text-sm text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-100"
        >
          ← Back to Home
        </Link>

        <h1 className="mb-4 text-4xl font-bold text-black dark:text-zinc-50">
          Support
        </h1>

        <div className="prose prose-zinc dark:prose-invert max-w-none space-y-8">
          <section>
            <p className="text-zinc-700 dark:text-zinc-300">
              Need help with Rechef? We are here to assist you!
            </p>
            <p className="mt-4 text-zinc-700 dark:text-zinc-300">
              If you have any questions, issues, or feedback, please reach out to us by sending an email to:
            </p>
            <p className="mt-6 text-center">
              <a
                href="mailto:lumi@notableai.ca"
                className="text-xl font-semibold text-blue-600 hover:underline dark:text-blue-400"
              >
                lumi@notableai.ca
              </a>
            </p>
            <p className="mt-6 text-zinc-700 dark:text-zinc-300">
              We will do our best to respond to your inquiry as soon as possible.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
