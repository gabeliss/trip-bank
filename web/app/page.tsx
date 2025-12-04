export default function Home() {
  return (
    <div className="min-h-screen flex flex-col">
      {/* Hero Section */}
      <main className="flex-1 flex items-center justify-center px-6 py-20">
        <div className="max-w-4xl mx-auto text-center">
          {/* Icon */}
          <div className="mb-8">
            <div className="inline-flex items-center justify-center w-24 h-24 rounded-[24px] bg-gradient-to-br from-ios-blue to-blue-600 mb-6">
              <svg className="w-14 h-14 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
          </div>

          {/* Headline */}
          <h1 className="text-5xl md:text-6xl font-bold mb-6 text-gray-900">
            Your travel memories,<br />
            <span className="text-ios-blue">beautifully organized</span>
          </h1>

          {/* Subheadline */}
          <p className="text-xl md:text-2xl text-ios-gray mb-12 max-w-2xl mx-auto">
            Turn your trips into stunning visual stories. Share moments with friends and relive your adventures.
          </p>

          {/* CTA */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <a
              href="#download"
              className="inline-flex items-center justify-center px-8 py-4 text-lg font-semibold text-white bg-gray-900 rounded-ios hover:bg-gray-800 transition-colors min-w-[200px]"
            >
              <svg className="w-6 h-6 mr-2" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              Download on iOS
            </a>

            <a
              href="#features"
              className="inline-flex items-center justify-center px-8 py-4 text-lg font-semibold text-ios-blue bg-ios-lightgray rounded-ios hover:bg-gray-200 transition-colors min-w-[200px]"
            >
              Learn More
            </a>
          </div>
        </div>
      </main>

      {/* Features Section */}
      <section id="features" className="py-20 bg-ios-lightgray">
        <div className="max-w-6xl mx-auto px-6">
          <h2 className="text-4xl font-bold text-center mb-16 text-gray-900">
            Everything you need for your trip memories
          </h2>

          <div className="grid md:grid-cols-3 gap-8">
            {/* Feature 1 */}
            <div className="bg-white p-8 rounded-ios-lg">
              <div className="w-14 h-14 bg-ios-blue bg-opacity-10 rounded-ios flex items-center justify-center mb-6">
                <svg className="w-8 h-8 text-ios-blue" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold mb-3">Organize Moments</h3>
              <p className="text-ios-gray">
                Create beautiful visual stories by organizing your photos into moments on an interactive canvas.
              </p>
            </div>

            {/* Feature 2 */}
            <div className="bg-white p-8 rounded-ios-lg">
              <div className="w-14 h-14 bg-ios-blue bg-opacity-10 rounded-ios flex items-center justify-center mb-6">
                <svg className="w-8 h-8 text-ios-blue" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold mb-3">Share with Friends</h3>
              <p className="text-ios-gray">
                Share your trips with a simple link. Friends can view and collaborate on your travel stories.
              </p>
            </div>

            {/* Feature 3 */}
            <div className="bg-white p-8 rounded-ios-lg">
              <div className="w-14 h-14 bg-ios-blue bg-opacity-10 rounded-ios flex items-center justify-center mb-6">
                <svg className="w-8 h-8 text-ios-blue" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold mb-3">Relive Adventures</h3>
              <p className="text-ios-gray">
                View your trips on a beautiful timeline. Each moment brings back the magic of your journey.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 bg-white border-t border-gray-200">
        <div className="max-w-6xl mx-auto px-6 text-center">
          <div className="flex justify-center gap-6 mb-4">
            <a href="/privacy" className="text-ios-gray hover:text-ios-blue text-sm">
              Privacy Policy
            </a>
            <a href="/terms" className="text-ios-gray hover:text-ios-blue text-sm">
              Terms of Service
            </a>
          </div>
          <p className="text-ios-gray text-sm">
            © 2025 Rewinded. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
