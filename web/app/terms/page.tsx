import Link from "next/link";

export const metadata = {
  title: "Terms of Service - Rewinded",
  description: "Terms of Service for Rewinded - Your travel memories app",
};

export default function TermsOfService() {
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
          <h1 className="text-4xl font-bold mb-8 text-gray-900">Terms of Service</h1>
          <p className="text-ios-gray mb-8">Last updated: January 2025</p>

          <div className="prose prose-gray max-w-none space-y-8">
            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">1. Acceptance of Terms</h2>
              <p className="text-gray-700 leading-relaxed">
                By accessing or using Rewinded, you agree to be bound by these Terms of Service.
                If you do not agree to these terms, please do not use our service.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">2. Description of Service</h2>
              <p className="text-gray-700 leading-relaxed">
                Rewinded is a mobile application that allows you to organize, store, and share your
                travel memories through photos, videos, and moments. We provide tools to create
                beautiful visual stories of your trips and share them with friends and family.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">3. User Accounts</h2>
              <p className="text-gray-700 leading-relaxed mb-4">To use Rewinded, you must:</p>
              <ul className="list-disc pl-6 text-gray-700 space-y-2">
                <li>Be at least 13 years old</li>
                <li>Create an account with accurate information</li>
                <li>Keep your account credentials secure</li>
                <li>Be responsible for all activity under your account</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">4. User Content</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                You retain ownership of the content you upload to Rewinded. By uploading content, you grant us
                a license to store, display, and share your content as necessary to provide our services. You agree that:
              </p>
              <ul className="list-disc pl-6 text-gray-700 space-y-2">
                <li>You own or have the right to share the content you upload</li>
                <li>Your content does not violate any laws or third-party rights</li>
                <li>Your content is not harmful, offensive, or inappropriate</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">5. Prohibited Uses</h2>
              <p className="text-gray-700 leading-relaxed mb-4">You may not use Rewinded to:</p>
              <ul className="list-disc pl-6 text-gray-700 space-y-2">
                <li>Upload illegal, harmful, or offensive content</li>
                <li>Violate the rights of others</li>
                <li>Attempt to gain unauthorized access to our systems</li>
                <li>Use the service for commercial purposes without permission</li>
                <li>Interfere with or disrupt the service</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">6. Subscriptions and Payments</h2>
              <p className="text-gray-700 leading-relaxed">
                Some features of Rewinded may require a paid subscription. Subscription terms, pricing,
                and billing cycles will be clearly presented before purchase. Subscriptions are managed
                through the Apple App Store and are subject to Apple&apos;s terms and conditions.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">7. Intellectual Property</h2>
              <p className="text-gray-700 leading-relaxed">
                The Rewinded app, including its design, features, and branding, is owned by us and
                protected by intellectual property laws. You may not copy, modify, or distribute our
                app or its components without permission.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">8. Disclaimer of Warranties</h2>
              <p className="text-gray-700 leading-relaxed">
                Rewinded is provided &quot;as is&quot; without warranties of any kind. We do not guarantee that
                the service will be uninterrupted, error-free, or completely secure. We are not responsible
                for any loss of data or content.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">9. Limitation of Liability</h2>
              <p className="text-gray-700 leading-relaxed">
                To the maximum extent permitted by law, we shall not be liable for any indirect,
                incidental, special, or consequential damages arising from your use of Rewinded.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">10. Termination</h2>
              <p className="text-gray-700 leading-relaxed">
                We may suspend or terminate your account if you violate these terms. You may delete
                your account at any time. Upon termination, your right to use the service will cease,
                but certain provisions of these terms will survive.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">11. Changes to Terms</h2>
              <p className="text-gray-700 leading-relaxed">
                We may update these terms from time to time. Continued use of Rewinded after changes
                constitutes acceptance of the new terms. We will notify you of any significant changes.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4 text-gray-900">12. Contact Us</h2>
              <p className="text-gray-700 leading-relaxed">
                If you have any questions about these Terms of Service, please contact us at{" "}
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
