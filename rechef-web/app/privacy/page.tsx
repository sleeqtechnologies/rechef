import Link from "next/link";

export const metadata = {
  title: "Privacy Policy | Rechef",
  description:
    "Privacy Policy for Rechef – a cooking companion app for managing recipes, pantry items, and your Rechef Pro subscription.",
};

export default function PrivacyPage() {
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
          Privacy Policy
        </h1>
        <p className="mb-12 text-sm text-zinc-600 dark:text-zinc-400">
          Last updated:{" "}
          {new Date().toLocaleDateString("en-US", {
            year: "numeric",
            month: "long",
            day: "numeric",
          })}
        </p>

        <div className="prose prose-zinc dark:prose-invert max-w-none space-y-8">
          <section>
            <p className="text-zinc-700 dark:text-zinc-300">
              At Rechef (&quot;we,&quot; &quot;us,&quot; or &quot;our&quot;), we
              are committed to protecting your privacy. This Privacy Policy
              explains how we collect, use, disclose, and safeguard your
              information when you use the Rechef mobile and web applications
              (the &quot;Service&quot;), including features like recipe
              management, pantry tracking, grocery list creation, and the
              Rechef Pro subscription.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              1. Information We Collect
            </h2>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              1.1 Account Information
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              When you create or use an account with Rechef, we may collect:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Email address or other sign-in identifiers (for example via Firebase or the app store)</li>
              <li>Authentication tokens and identifiers used to keep you signed in securely</li>
              <li>Profile information you choose to provide (such as name or initials)</li>
            </ul>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              1.2 Subscription and Purchase Information
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              If you subscribe to Rechef Pro, we may receive limited information
              about your purchases and subscription status from the relevant app
              store and our subscription provider (for example, RevenueCat),
              such as:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Active or expired subscription status</li>
              <li>Product identifiers (for example, monthly or yearly plans)</li>
              <li>Renewal status and subscription period</li>
              <li>Non-personal transaction metadata provided by the app store</li>
            </ul>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We do not store your full payment card details; payments are
              processed by the app stores or their payment processors.
            </p>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              1.3 Recipe, Pantry, and Content Data
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              To provide the core functionality of Rechef, we process content
              you choose to add to the Service, which may include:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Recipes you create or save (titles, ingredients, instructions, notes, and images)</li>
              <li>Pantry items, quantities, and related notes</li>
              <li>Grocery lists or shopping-related information generated from your pantry or recipes</li>
              <li>Recipe import data when you submit a URL or content to be parsed</li>
            </ul>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              1.4 Usage and Device Information
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We automatically collect certain usage and technical information
              when you use the Service, such as:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Device information (device model, operating system version, language)</li>
              <li>Unique identifiers associated with your device or account</li>
              <li>Log data (IP address, access times, app version, and pages or screens viewed)</li>
              <li>Feature usage statistics (for example, number of recipe imports per month)</li>
              <li>Error and performance logs to help us diagnose issues</li>
            </ul>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              2. How We Use Your Information
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We use the information we collect for the following purposes:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>To operate, maintain, and improve the Rechef app and related services</li>
              <li>To sync your recipes, pantry items, and preferences across your devices where supported</li>
              <li>To manage your Rechef Pro subscription, including entitlement checks and feature access</li>
              <li>To process recipe imports from URLs or other supported sources</li>
              <li>To communicate with you about updates, changes to the Service, and important notices</li>
              <li>To provide customer support and respond to your inquiries</li>
              <li>To monitor usage, protect against misuse or abuse, and detect and prevent fraud or security incidents</li>
              <li>To comply with legal obligations and enforce our Terms and Conditions</li>
            </ul>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              3. How We Share Your Information
            </h2>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              3.1 Service Providers and Partners
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We may share your information with trusted third-party service
              providers that help us operate and improve Rechef, such as:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Cloud hosting and storage providers</li>
              <li>Authentication and user account providers (for example, Firebase)</li>
              <li>Subscription and billing infrastructure (for example, RevenueCat and app stores)</li>
              <li>Analytics, crash reporting, and error monitoring tools</li>
            </ul>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              These providers are permitted to use your information only as
              necessary to provide services to us and are expected to protect
              it appropriately.
            </p>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              3.2 Legal Requirements
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We may disclose your information if required to do so by law or
              in response to valid legal requests, such as subpoenas, court
              orders, or requests from public authorities.
            </p>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              3.3 Business Transfers
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              In connection with a merger, acquisition, financing, or sale of
              all or a portion of our business, your information may be
              transferred as part of that transaction. We will take reasonable
              steps to ensure the confidentiality of your personal information
              in such circumstances.
            </p>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              3.4 With Your Consent
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We may share your information with third parties when you ask us
              to do so or otherwise give your explicit consent.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              4. Data Storage and Security
            </h2>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              4.1 Storage Locations
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              Your information may be stored on servers located in different
              regions to provide a reliable and performant Service. Regardless
              of where your information is stored, we take reasonable steps to
              ensure it is handled in accordance with this Privacy Policy.
            </p>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              4.2 Security Measures
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We implement appropriate technical and organizational measures
              designed to protect your information, which may include:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Encryption of data in transit using TLS/SSL</li>
              <li>Access controls and authentication safeguards</li>
              <li>Regular updates to systems and dependencies</li>
              <li>Monitoring for suspicious activity where appropriate</li>
            </ul>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              However, no method of transmission over the internet or method of
              electronic storage is completely secure, and we cannot guarantee
              absolute security.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              5. Data Retention
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We retain your information for as long as necessary to provide
              the Service and fulfill the purposes described in this Privacy
              Policy, including:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Account information for as long as your account remains active</li>
              <li>Recipes, pantry items, and related content while you choose to keep them in your account</li>
              <li>Subscription and billing-related records for a period required for tax, accounting, or legal purposes</li>
              <li>Log and analytics data for a reasonable period to improve and secure the Service</li>
            </ul>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              If you request that we delete your account, we will delete or
              anonymize your personal information, except where we are required
              to retain certain data to comply with law or to protect our legal
              rights.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              6. Your Rights and Choices
            </h2>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              6.1 Access and Correction
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              Where applicable under local law, you may have the right to
              access the personal information we hold about you and to request
              corrections to inaccurate or incomplete information.
            </p>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              6.2 Deletion
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              You may be able to delete certain content directly within the
              app, such as recipes or pantry items. You can also request
              deletion of your account and associated personal information,
              subject to any legal obligations we may have to retain some data.
            </p>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              6.3 Communication Preferences
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              You may opt out of certain non-essential communications (such as
              marketing emails) by using the unsubscribe link in those
              messages or by adjusting your preferences in the app where
              available.
            </p>

            <h3 className="mt-4 text-xl font-semibold text-black dark:text-zinc-50">
              6.4 Additional Rights (for example, GDPR/CCPA)
            </h3>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              Depending on your location, you may have additional rights under
              data protection laws such as the GDPR or CCPA, including rights
              to:
            </p>
            <ul className="ml-6 mt-2 list-disc space-y-2 text-zinc-700 dark:text-zinc-300">
              <li>Request access to and a copy of your personal information</li>
              <li>Request correction or deletion of your personal information</li>
              <li>Request restriction of or object to certain processing activities</li>
              <li>Request data portability</li>
              <li>Withdraw consent where processing is based on consent</li>
            </ul>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              To exercise these rights, please contact us using the details in
              the &quot;Contact Us&quot; section below. We may need to verify
              your identity before responding to your request.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              7. Children&apos;s Privacy
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              Rechef is not intended for use by children under the age of 13
              (or the equivalent minimum age in your jurisdiction). We do not
              knowingly collect personal information from children under that
              age. If we become aware that we have collected personal
              information from a child under the applicable age, we will take
              steps to delete such information. If you believe we may have
              collected information from a child, please contact us.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              8. Cookies and Similar Technologies
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We may use cookies or similar technologies in our web
              experiences to help remember your preferences, keep you signed
              in, and understand how the Service is used. You can usually
              control cookies through your browser settings. Disabling cookies
              may affect certain features of the Service.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              9. International Data Transfers
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              Your information may be transferred to and processed in
              countries other than your country of residence. These countries
              may have different data protection laws than your own. Where
              required by law, we will take appropriate steps to ensure that
              your personal information receives an adequate level of
              protection in the countries where it is processed.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              10. Changes to This Privacy Policy
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              We may update this Privacy Policy from time to time. When we do,
              we will revise the &quot;Last updated&quot; date at the top of
              this page. If we make material changes, we may provide additional
              notice (such as a notice in the app). Your continued use of the
              Service after any changes signifies your acceptance of the
              updated policy.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-black dark:text-zinc-50">
              11. Contact Us
            </h2>
            <p className="mt-2 text-zinc-700 dark:text-zinc-300">
              If you have any questions, concerns, or requests regarding this
              Privacy Policy or our data practices, please contact us at:{" "}
              <a
                href="mailto:oyelowopelumi@gmail.com"
                className="text-blue-600 hover:underline dark:text-blue-400"
              >
                oyelowopelumi@gmail.com
              </a>
              .
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
