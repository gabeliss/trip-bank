'use client';

export function OpenInAppButton({ slug }: { slug: string }) {
  const handleClick = (e: React.MouseEvent<HTMLAnchorElement>) => {
    e.preventDefault();

    const appLink = `https://rewinded.app/trip/${slug}`;
    const appStoreLink = 'https://apps.apple.com/app/rewinded';
    const now = Date.now();

    // Track if user left the page (app opened)
    let hasFocus = true;
    const onBlur = () => { hasFocus = false; };

    window.addEventListener('blur', onBlur);

    // Try to open the app using an iframe (won't navigate current page)
    const iframe = document.createElement('iframe');
    iframe.style.display = 'none';
    iframe.src = appLink;
    document.body.appendChild(iframe);

    // After 2 seconds, check if app opened
    setTimeout(() => {
      window.removeEventListener('blur', onBlur);
      document.body.removeChild(iframe);

      // If page kept focus and user didn't switch away, app didn't open
      const timeElapsed = Date.now() - now;
      if (hasFocus && timeElapsed < 2500) {
        // App didn't open - redirect to App Store
        window.location.href = appStoreLink;
      }
    }, 2000);
  };

  return (
    <a
      href="https://rewinded.app"
      onClick={handleClick}
      className="inline-flex items-center justify-center w-full px-8 py-4 text-lg font-semibold text-white bg-gray-900 rounded-ios hover:bg-gray-800 transition-colors mb-3"
    >
      <svg className="w-6 h-6 mr-2" fill="currentColor" viewBox="0 0 24 24">
        <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
      </svg>
      Open in Rewinded
    </a>
  );
}
