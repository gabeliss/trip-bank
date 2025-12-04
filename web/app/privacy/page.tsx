import Link from "next/link";

export const metadata = {
  title: "Privacy Policy - Rewinded",
  description: "Privacy Policy for Rewinded - Your travel memories app",
};

export default function PrivacyPolicy() {
  return (
    <div className="min-h-screen flex flex-col bg-white">
      <header className="py-6 border-b border-gray-200">
        <div className="max-w-4xl mx-auto px-6">
          <Link href="/" className="text-ios-blue hover:underline">
            ← Back to Home
          </Link>
        </div>
      </header>

      <main className="flex-1 py-12">
        <div className="max-w-4xl mx-auto px-6">
          <h1 className="text-4xl font-bold mb-8 text-gray-900">Privacy Policy</h1>
          <p className="text-ios-gray mb-8">Last updated: January 2025</p>

          <div className="prose prose-gray max-w-none space-y-8">
            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">1. Introduction</h2>
              <p className="text-gray-700 leading-relaxed">
                Welcome to Rewinded. We respect your privacy and are committed to protecting your personal data.
                This privacy policy explains how we collect, use, and safeguard your information when you use our
                mobile application and related services.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">2. Information We Collect</h2>
              <p className="text-gray-700 leading-relaxed mb-4">We collect the following types of information:</p>
              <ul className="list-disc pl-6 text-gray-700 space-y-2">
                <li><strong>Account Information:</strong> Email address, name, and profile information when you create an account.</li>
                <li><strong>Photos and Media:</strong> Photos, videos, and other media you upload to create your trip memories.</li>
                <li><strong>Trip Data:</strong> Trip names, dates, locations, and moments you create within the app.</li>
                <li><strong>Usage Data:</strong> Information about how you interact with the app to help us improve our services.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">3. How We Use Your Information</h2>
              <p className="text-gray-700 leading-relaxed mb-4">We use your information to:</p>
              <ul className="list-disc pl-6 text-gray-700 space-y-2">
                <li>Provide, maintain, and improve our services</li>
                <li>Store and organize your trip memories</li>
                <li>Enable sharing features with people you choose</li>
                <li>Send you important updates about the service</li>
                <li>Ensure the security and integrity of our platform</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">4. Data Storage and Security</h2>
              <p className="text-gray-700 leading-relaxed">
                Your data is stored securely using industry-standard encryption and security practices.
                We use trusted third-party services for authentication and data storage, all of which
                maintain strict security standards and compliance certifications.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">5. Sharing Your Information</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                We do not sell your personal information. We may share your information only in the following circumstances:
              </p>
              <ul className="list-disc pl-6 text-gray-700 space-y-2">
                <li><strong>With Your Consent:</strong> When you choose to share trips with other users.</li>
                <li><strong>Service Providers:</strong> With trusted partners who help us operate our services.</li>
                <li><strong>Legal Requirements:</strong> When required by law or to protect our rights.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">6. Your Rights</h2>
              <p className="text-gray-700 leading-relaxed mb-4">You have the right to:</p>
              <ul className="list-disc pl-6 text-gray-700 space-y-2">
                <li>Access your personal data</li>
                <li>Correct inaccurate data</li>
                <li>Delete your account and associated data</li>
                <li>Export your data</li>
                <li>Opt out of marketing communications</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">7. Children&apos;s Privacy</h2>
              <p className="text-gray-700 leading-relaxed">
                Our service is not intended for children under 13. We do not knowingly collect personal
                information from children under 13. If you believe we have collected such information,
                please contact us immediately.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">8. Changes to This Policy</h2>
              <p className="text-gray-700 leading-relaxed">
                We may update this privacy policy from time to time. We will notify you of any changes
                by posting the new policy on this page and updating the &quot;Last updated&quot; date.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">9. Contact Us</h2>
              <p className="text-gray-700 leading-relaxed">
                If you have any questions about this Privacy Policy, please contact us at{" "}
                <a href="mailto:support@rewinded.app" className="text-ios-blue hover:underline">
                  support@rewinded.app
                </a>
              </p>
            </section>
          </div>
        </div>
      </main>

      <footer className="py-12 bg-white border-t border-gray-200">
        <div className="max-w-6xl mx-auto px-6 text-center">
          <div className="flex justify-center gap-6 mb-4">
            <Link href="/privacy" className="text-ios-gray hover:text-ios-blue text-sm">
              Privacy Policy
            </Link>
            <Link href="/terms" className="text-ios-gray hover:text-ios-blue text-sm">
              Terms of Service
            </Link>
          </div>
          <p className="text-ios-gray text-sm">
            © 2025 Rewinded. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
