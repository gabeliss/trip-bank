import Image from "next/image";

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col bg-gradient-to-b from-slate-50 via-white to-blue-50">
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-xl border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Image
              src="/app-icon.jpeg"
              alt="Rewinded"
              width={40}
              height={40}
              className="rounded-xl shadow-sm"
            />
            <span className="text-xl font-bold text-gray-900">Rewinded</span>
          </div>
          <a
            href="https://apps.apple.com/app/rewinded"
            className="inline-flex items-center gap-2 px-5 py-2.5 text-sm font-semibold text-white bg-gray-900 rounded-full hover:bg-gray-800 transition-all hover:scale-105"
          >
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
            </svg>
            Get the App
          </a>
        </div>
      </nav>

      {/* Hero Section */}
      <main className="flex-1 pt-24">
        {/* Hero */}
        <section className="relative overflow-hidden px-6 py-16 md:py-24">
          {/* Background decorations */}
          <div className="absolute top-20 left-10 w-72 h-72 bg-blue-200 rounded-full mix-blend-multiply filter blur-3xl opacity-30 animate-blob" />
          <div className="absolute top-40 right-10 w-72 h-72 bg-cyan-200 rounded-full mix-blend-multiply filter blur-3xl opacity-30 animate-blob animation-delay-2000" />
          <div className="absolute bottom-20 left-1/2 w-72 h-72 bg-indigo-200 rounded-full mix-blend-multiply filter blur-3xl opacity-30 animate-blob animation-delay-4000" />

          <div className="max-w-7xl mx-auto">
            <div className="grid lg:grid-cols-2 gap-12 items-center">
              {/* Left - Text Content */}
              <div className="text-center lg:text-left">
                <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-50 rounded-full text-ios-blue text-sm font-medium mb-6">
                  <span className="relative flex h-2 w-2">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-ios-blue opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-2 w-2 bg-ios-blue"></span>
                  </span>
                  Now available on the App Store
                </div>

                <h1 className="text-4xl sm:text-5xl md:text-6xl font-bold text-gray-900 leading-tight mb-6">
                  Your travel memories,{" "}
                  <span className="text-transparent bg-clip-text bg-gradient-to-r from-ios-blue to-cyan-500">
                    beautifully organized
                  </span>
                </h1>

                <p className="text-lg md:text-xl text-gray-600 mb-8 max-w-xl mx-auto lg:mx-0">
                  Turn your trips into stunning visual stories. Organize photos into moments,
                  share with friends, and relive your adventures anytime.
                </p>

                <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
                  <a
                    href="https://apps.apple.com/app/rewinded"
                    className="group inline-flex items-center justify-center gap-3 px-8 py-4 bg-gray-900 text-white rounded-2xl font-semibold text-lg hover:bg-gray-800 transition-all hover:scale-105 shadow-lg shadow-gray-900/25"
                  >
                    <svg className="w-7 h-7" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                    </svg>
                    <div className="text-left">
                      <div className="text-xs opacity-80">Download on the</div>
                      <div className="text-base font-bold -mt-0.5">App Store</div>
                    </div>
                  </a>
                </div>

                {/* Social proof */}
                <div className="mt-10 flex items-center gap-6 justify-center lg:justify-start">
                  <div className="flex -space-x-2">
                    {[1, 2, 3, 4].map((i) => (
                      <div
                        key={i}
                        className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-400 to-cyan-400 border-2 border-white"
                      />
                    ))}
                  </div>
                  <div className="text-left">
                    <div className="flex items-center gap-1 text-amber-500">
                      {[1, 2, 3, 4, 5].map((i) => (
                        <svg key={i} className="w-4 h-4 fill-current" viewBox="0 0 20 20">
                          <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                        </svg>
                      ))}
                    </div>
                    <p className="text-sm text-gray-600">Loved by travelers</p>
                  </div>
                </div>
              </div>

              {/* Right - Phone Mockups */}
              <div className="relative">
                <div className="relative flex justify-center items-center">
                  {/* Back phone - Trip detail */}
                  <div className="absolute -left-4 md:left-8 top-8 transform -rotate-6 hover:rotate-0 transition-transform duration-500">
                    <Image
                      src="/mockups/ss1-portrait.png"
                      alt="Trip moments view"
                      width={280}
                      height={600}
                      className="w-56 md:w-64 drop-shadow-2xl"
                      priority
                    />
                  </div>

                  {/* Front phone - Main view */}
                  <div className="relative z-10 transform hover:scale-105 transition-transform duration-500">
                    <Image
                      src="/mockups/ss0-portrait.png"
                      alt="Rewinded app main screen"
                      width={320}
                      height={680}
                      className="w-64 md:w-72 drop-shadow-2xl"
                      priority
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section id="features" className="py-20 md:py-32 bg-white">
          <div className="max-w-7xl mx-auto px-6">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-5xl font-bold text-gray-900 mb-4">
                Everything you need to preserve your memories
              </h2>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                Rewinded makes it easy to organize, share, and relive your travel adventures
              </p>
            </div>

            <div className="grid md:grid-cols-3 gap-8">
              {/* Feature 1 */}
              <div className="group relative bg-gradient-to-br from-blue-50 to-cyan-50 p-8 rounded-3xl hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
                <div className="w-16 h-16 bg-gradient-to-br from-ios-blue to-cyan-500 rounded-2xl flex items-center justify-center mb-6 shadow-lg shadow-ios-blue/30 group-hover:scale-110 transition-transform">
                  <svg className="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">Organize Moments</h3>
                <p className="text-gray-600 leading-relaxed">
                  Create beautiful visual stories by organizing your photos and videos into moments on an interactive canvas.
                </p>
              </div>

              {/* Feature 2 */}
              <div className="group relative bg-gradient-to-br from-purple-50 to-pink-50 p-8 rounded-3xl hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
                <div className="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-500 rounded-2xl flex items-center justify-center mb-6 shadow-lg shadow-purple-500/30 group-hover:scale-110 transition-transform">
                  <svg className="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">Share with Friends</h3>
                <p className="text-gray-600 leading-relaxed">
                  Share your trips with a simple link or code. Invite friends to view or collaborate on your travel stories.
                </p>
              </div>

              {/* Feature 3 */}
              <div className="group relative bg-gradient-to-br from-amber-50 to-orange-50 p-8 rounded-3xl hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
                <div className="w-16 h-16 bg-gradient-to-br from-amber-500 to-orange-500 rounded-2xl flex items-center justify-center mb-6 shadow-lg shadow-amber-500/30 group-hover:scale-110 transition-transform">
                  <svg className="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">Relive Adventures</h3>
                <p className="text-gray-600 leading-relaxed">
                  View your trips on a beautiful timeline. Each moment brings back the magic of your journey.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* App Showcase Section */}
        <section className="py-20 md:py-32 bg-gradient-to-b from-gray-900 to-gray-950 overflow-hidden">
          <div className="max-w-7xl mx-auto px-6">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-5xl font-bold text-white mb-4">
                See it in action
              </h2>
              <p className="text-lg text-gray-400 max-w-2xl mx-auto">
                From organizing moments to sharing with friends
              </p>
            </div>

            {/* Scrolling mockups */}
            <div className="relative">
              <div className="flex justify-center items-end gap-4 md:gap-8">
                {/* Screen 1 - Trip list */}
                <div className="transform hover:scale-105 transition-all duration-500 opacity-80 hover:opacity-100">
                  <Image
                    src="/mockups/ss0-portrait.png"
                    alt="Trip list"
                    width={220}
                    height={470}
                    className="w-40 md:w-52 drop-shadow-2xl"
                  />
                  <p className="text-center text-gray-500 mt-4 text-sm font-medium">Your Trips</p>
                </div>

                {/* Screen 2 - Moments canvas */}
                <div className="transform scale-110 hover:scale-115 transition-all duration-500 z-10">
                  <Image
                    src="/mockups/ss1-portrait.png"
                    alt="Moments canvas"
                    width={260}
                    height={560}
                    className="w-48 md:w-60 drop-shadow-2xl"
                  />
                  <p className="text-center text-white mt-4 text-sm font-medium">Organize Moments</p>
                </div>

                {/* Screen 3 - Expanded moment */}
                <div className="transform hover:scale-105 transition-all duration-500 opacity-80 hover:opacity-100">
                  <Image
                    src="/mockups/ss2-portrait.png"
                    alt="Expanded moment"
                    width={220}
                    height={470}
                    className="w-40 md:w-52 drop-shadow-2xl"
                  />
                  <p className="text-center text-gray-500 mt-4 text-sm font-medium">Relive Memories</p>
                </div>

                {/* Screen 4 - Sharing */}
                <div className="hidden lg:block transform hover:scale-105 transition-all duration-500 opacity-80 hover:opacity-100">
                  <Image
                    src="/mockups/ss3-portrait.png"
                    alt="Share trip"
                    width={220}
                    height={470}
                    className="w-40 md:w-52 drop-shadow-2xl"
                  />
                  <p className="text-center text-gray-500 mt-4 text-sm font-medium">Share Easily</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* How It Works */}
        <section className="py-20 md:py-32 bg-white">
          <div className="max-w-7xl mx-auto px-6">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-5xl font-bold text-gray-900 mb-4">
                How it works
              </h2>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                Three simple steps to preserve your travel memories forever
              </p>
            </div>

            <div className="grid md:grid-cols-3 gap-12">
              {/* Step 1 */}
              <div className="text-center">
                <div className="w-16 h-16 bg-ios-blue text-white rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6 shadow-lg shadow-ios-blue/30">
                  1
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">Create a Trip</h3>
                <p className="text-gray-600">
                  Start by creating a new trip and adding your photos and videos from your camera roll.
                </p>
              </div>

              {/* Step 2 */}
              <div className="text-center">
                <div className="w-16 h-16 bg-ios-blue text-white rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6 shadow-lg shadow-ios-blue/30">
                  2
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">Organize Moments</h3>
                <p className="text-gray-600">
                  Group your media into meaningful moments. Add titles and notes to capture the story.
                </p>
              </div>

              {/* Step 3 */}
              <div className="text-center">
                <div className="w-16 h-16 bg-ios-blue text-white rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6 shadow-lg shadow-ios-blue/30">
                  3
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">Share & Relive</h3>
                <p className="text-gray-600">
                  Share with friends using a simple link and revisit your memories anytime.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* CTA Section */}
        <section className="py-20 md:py-32 bg-gradient-to-br from-ios-blue via-blue-600 to-cyan-600 relative overflow-hidden">
          {/* Background decoration */}
          <div className="absolute inset-0 opacity-30">
            <div className="absolute top-0 left-0 w-96 h-96 bg-white rounded-full filter blur-3xl -translate-x-1/2 -translate-y-1/2" />
            <div className="absolute bottom-0 right-0 w-96 h-96 bg-cyan-300 rounded-full filter blur-3xl translate-x-1/2 translate-y-1/2" />
          </div>

          <div className="max-w-4xl mx-auto px-6 text-center relative z-10">
            <div className="mb-8">
              <Image
                src="/app-icon.jpeg"
                alt="Rewinded"
                width={100}
                height={100}
                className="rounded-3xl shadow-2xl mx-auto border-4 border-white/20"
              />
            </div>
            <h2 className="text-3xl md:text-5xl font-bold text-white mb-6">
              Start preserving your memories today
            </h2>
            <p className="text-xl text-white/80 mb-10 max-w-2xl mx-auto">
              Download Rewinded and turn your travel photos into beautiful, shareable stories.
            </p>
            <a
              href="https://apps.apple.com/app/rewinded"
              className="group inline-flex items-center justify-center gap-3 px-10 py-5 bg-white text-gray-900 rounded-2xl font-semibold text-lg hover:bg-gray-100 transition-all hover:scale-105 shadow-2xl"
            >
              <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              <div className="text-left">
                <div className="text-xs opacity-70">Download on the</div>
                <div className="text-lg font-bold -mt-0.5">App Store</div>
              </div>
            </a>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="py-12 bg-gray-900 text-white">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="flex items-center gap-3">
              <Image
                src="/app-icon.jpeg"
                alt="Rewinded"
                width={36}
                height={36}
                className="rounded-xl"
              />
              <span className="font-semibold">Rewinded</span>
            </div>
            <div className="flex items-center gap-6">
              <a href="/privacy" className="text-gray-400 hover:text-white text-sm transition-colors">
                Privacy Policy
              </a>
              <a href="/terms" className="text-gray-400 hover:text-white text-sm transition-colors">
                Terms of Service
              </a>
            </div>
            <p className="text-gray-500 text-sm">
              © 2025 Rewinded. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
