import Link from "next/link";

export const metadata = {
  title: "Terms and Conditions | Rechef",
  description:
    "Terms and Conditions for Rechef – a cooking companion app for managing recipes, pantry items, grocery lists, and your Rechef Pro subscription.",
};

export default function TermsPage() {
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
          Terms and Conditions
        </h1>
        <p className="mb-12 text-sm text-zinc-600 dark:text-zinc-400">
          Last updated: {new Date().toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}
        </p>

        <div className="prose prose-zinc dark:prose-invert max-w-none space-y-8">
          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              1. Agreement to Terms
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              By accessing or using Rechef (the &quot;Service&quot;), you agree
              to be bound by these Terms and Conditions (the &quot;Terms&quot;).
              If you do not agree to these Terms, you may not access or use the
              Service.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              2. Description of Service
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              Rechef is a cooking companion application that helps you manage
              your recipes and pantry and make grocery planning easier. The
              Service may include features such as:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Creating, viewing, and organizing recipes</li>
              <li>Tracking pantry items and ingredients you have on hand</li>
              <li>Generating or managing grocery lists based on your pantry or recipes</li>
              <li>Importing recipes from supported URLs or content sources</li>
              <li>Access to additional functionality as part of a paid Rechef Pro subscription</li>
            </ul>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              3. User Accounts
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              To use certain features of the Service, you may need to create an
              account. You are responsible for:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Maintaining the confidentiality of your account credentials</li>
              <li>All activities that occur under your account</li>
              <li>Providing accurate and complete information when creating your account</li>
              <li>Notifying us immediately of any unauthorized use of your account</li>
            </ul>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              4. Acceptable Use
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              You agree not to use the Service to:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Create, upload, or share content that is illegal, harmful, threatening, abusive, or otherwise violates any applicable law</li>
              <li>Impersonate any person or entity or misrepresent your affiliation with any person or entity</li>
              <li>Upload or share content that infringes on intellectual property, privacy, or other rights of third parties</li>
              <li>Upload or share content that promotes violence, hate speech, discrimination, or harassment</li>
              <li>Upload or share content featuring minors without proper consent and authorization where required</li>
              <li>Attempt to circumvent technical protections, reverse engineer, decompile, or otherwise tamper with the Service</li>
              <li>Use automated systems, bots, or scraping methods to access or interact with the Service without authorization</li>
              <li>Interfere with or disrupt the Service or servers or networks connected to the Service</li>
            </ul>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              5. Content and Intellectual Property
            </h2>
            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              5.1 User Content
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              You retain ownership of the content you add to Rechef
              (&quot;User Content&quot;), such as your recipes, pantry items,
              notes, and related data. By uploading or otherwise providing User
              Content to the Service, you grant us a worldwide, non-exclusive,
              royalty-free license to use, store, process, and display your User
              Content as reasonably necessary to operate, maintain, and improve
              the Service.
            </p>
            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              5.2 Generated Content
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              The Service may generate certain outputs or derived data from your
              User Content (for example, grocery lists or structured recipe
              information). Subject to these Terms, you may use this generated
              content for your own personal, non-commercial purposes. You may
              not use the Service or generated content to:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Violate any law or regulation</li>
              <li>Infringe the rights of others</li>
              <li>Misrepresent information in a way that could reasonably cause harm</li>
            </ul>
            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              5.3 Service Intellectual Property
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              The Service, including its software, design, logos, trademarks,
              and all related intellectual property rights (excluding your User
              Content), is owned by us or our licensors and is protected by
              applicable intellectual property laws. You may not copy, modify,
              distribute, sell, or create derivative works of the Service
              without our prior written consent.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              6. Subscriptions and Payment
            </h2>
            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              6.1 Subscription Tiers
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              Rechef may offer both a free tier and one or more paid
              subscription options, such as Rechef Pro. Features and limits may
              differ between tiers, for example:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>
                <strong>Free:</strong> A limited set of features intended to let
                you try the Service.
              </li>
              <li>
                <strong>Rechef Pro:</strong> Additional or enhanced features,
                such as higher recipe import limits or advanced tools.
              </li>
            </ul>
            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              6.2 Payment Terms
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              Subscriptions are billed by the applicable app store (for
              example, Apple App Store or Google Play Store) on a monthly or
              yearly basis, or as otherwise specified at the time of purchase.
              All fees are charged in advance and are generally non-refundable
              except as required by law or by the policies of the app store
              where you made the purchase. Prices may change at any time, but
              price changes will not affect your current billing period.
            </p>
            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              6.3 Auto-Renewal
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              Unless you disable auto-renewal in your app store account
              settings, your subscription will automatically renew at the end of
              each billing period and your chosen payment method will be charged
              again. You can manage or cancel your subscription at any time
              through the app store settings for your device. Cancelling a
              subscription will take effect at the end of the current billing
              period.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              7. Service Availability and Modifications
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We reserve the right to modify, suspend, or discontinue the
              Service (in whole or in part) at any time, with or without
              notice. We do not guarantee that the Service will be available at
              all times or that it will be error-free. We may perform
              maintenance, updates, or other work that may temporarily interrupt
              access to the Service.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              8. Disclaimers and Limitations of Liability
            </h2>
            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              8.1 Service Provided "As Is"
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              The Service is provided &quot;as is&quot; and &quot;as
              available&quot; without warranties of any kind, whether express or
              implied. We do not warrant that the Service will meet your
              requirements or that it will be uninterrupted, timely, secure, or
              error-free.
            </p>
            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              8.2 Limitation of Liability
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              To the maximum extent permitted by law, we shall not be liable for
              any indirect, incidental, special, consequential, or punitive
              damages, or any loss of profits or revenues, whether incurred
              directly or indirectly, or any loss of data, use, goodwill, or
              other intangible losses resulting from (a) your access to or use
              of or inability to access or use the Service; (b) any conduct or
              content of any third party on the Service; or (c) unauthorized
              access, use, or alteration of your transmissions or content.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              9. Indemnification
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              You agree to indemnify, defend, and hold harmless Rechef and its
              officers, directors, employees, and agents from any claims,
              damages, losses, liabilities, and expenses (including reasonable
              legal fees) arising out of or related to your use of the Service,
              your violation of these Terms, or your violation of any rights of
              another party.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              10. Termination
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We may terminate or suspend your account and access to the Service
              immediately, without prior notice, if we believe that you have
              violated these Terms or if your conduct is harmful to other
              users, us, or third parties, or for any other reason at our
              discretion. Upon termination, your right to use the Service will
              cease immediately, and we may delete or disable access to your
              account and User Content, subject to any legal obligations to
              retain certain data.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              11. Governing Law
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              These Terms and your use of the Service shall be governed by and
              construed in accordance with the laws of Canada, without regard
              to its conflict of law principles. Subject to any applicable
              consumer protection laws that provide you with additional rights,
              you agree that any disputes arising out of or relating to these
              Terms or the Service will be brought in the courts of a competent
              jurisdiction in Canada.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              12. Changes to Terms
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We may update or modify these Terms from time to time. When we do,
              we will update the &quot;Last updated&quot; date at the top of
              this page. If we make material changes, we may provide additional
              notice (for example, within the app or by email). Your continued
              use of the Service after the effective date of any changes
              constitutes your acceptance of the revised Terms.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              13. Contact Information
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              If you have any questions about these Terms, please contact us at:{" "}
              <a
                href="mailto:oyelowopelumi@gmail.com"
                className="text-blue-600 hover:underline dark:text-blue-400"
              >
                oyelowopelumi@gmail.com
              </a>
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
