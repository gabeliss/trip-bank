import { Metadata } from 'next';
import { convex } from '@/lib/convex';
import { OpenInAppButton } from './OpenInAppButton';

interface PageProps {
  params: Promise<{ slug: string }>;
}

interface GridPosition {
  column: number; // 0 = left, 1 = right
  row: number; // 0, 0.5, 1, 1.5, 2, 2.5, 3, etc.
  width: number; // 1 or 2 (columns)
  height: number; // 1, 1.5, 2, 2.5, 3, etc. (rows)
}

interface TripPreview {
  trip: {
    tripId: string;
    title: string;
    startDate: number;
    endDate: number;
    shareSlug?: string;
    shareCode?: string;
    coverImageUrl?: string | null;
  };
  moments: Array<{
    momentId: string;
    title: string;
    gridPosition?: GridPosition;
    mediaCount: number;
    media: Array<{ url: string | null; type: "photo" | "video" }>;
  }>;
  totalMoments: number;
  collaborators: Array<{
    userId: string;
    role: string;
    name: string | null;
    email: string | null;
    imageUrl: string | null;
  }>;
}

async function getTripData(slug: string): Promise<TripPreview | null> {
  try {
    const data = await convex.query('trips:getPublicPreview' as any, {
      shareSlug: slug,
    });
    console.log('📊 Trip data:', JSON.stringify(data, null, 2));
    return data as TripPreview | null;
  } catch (error) {
    console.error('Error fetching trip:', error);
    return null;
  }
}

function formatDate(timestamp: number) {
  return new Date(timestamp).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  });
}

function MediaItem({ url, type, alt, className }: { url: string; type: "photo" | "video"; alt: string; className: string }) {
  if (type === "video") {
    return (
      <video
        src={url}
        className={className}
        controls={false}
        muted
        playsInline
        loop
        autoPlay
      />
    );
  }
  return <img src={url} alt={alt} className={className} />;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const data = await getTripData(slug);

  if (!data) {
    return {
      title: 'Trip Not Found - Rewinded',
    };
  }

  return {
    title: `${data.trip.title} - Rewinded`,
    description: `Join me on my ${data.trip.title} trip! ${data.totalMoments} moments from ${formatDate(data.trip.startDate)} to ${formatDate(data.trip.endDate)}`,
    openGraph: {
      title: data.trip.title,
      description: `${data.totalMoments} moments • ${formatDate(data.trip.startDate)} - ${formatDate(data.trip.endDate)}`,
      type: 'website',
      url: `https://rewinded.app/trip/${slug}`,
      images: data.trip.coverImageUrl ? [
        {
          url: data.trip.coverImageUrl,
          width: 1200,
          height: 630,
          alt: data.trip.title,
        }
      ] : [],
    },
    twitter: {
      card: 'summary_large_image',
      title: data.trip.title,
      description: `${data.totalMoments} moments from this amazing trip`,
      images: data.trip.coverImageUrl ? [data.trip.coverImageUrl] : [],
    },
  };
}

export default async function TripPreviewPage({ params }: PageProps) {
  const { slug } = await params;
  const data = await getTripData(slug);
  const appUrl = process.env.NEXT_PUBLIC_APP_URL || 'https://rewinded.app';

  if (!data) {
    return (
      <div className="min-h-screen flex items-center justify-center px-6">
        <div className="max-w-md text-center">
          <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <svg className="w-10 h-10 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M12 12h.01M12 12h.01M12 12h.01M12 12h.01" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold mb-3">Trip Not Found</h1>
          <p className="text-ios-gray mb-8">
            This trip link is invalid or has been disabled.
          </p>
          <a
            href="/"
            className="inline-block px-6 py-3 bg-ios-blue text-white rounded-ios font-semibold hover:bg-blue-600 transition-colors"
          >
            Go Home
          </a>
        </div>
      </div>
    );
  }

  const { trip, moments, totalMoments, collaborators } = data;

  return (
    <div className="min-h-screen bg-ios-lightgray">
      {/* Header */}
      <div className="absolute top-0 left-0 right-0 z-10">
        <div className="max-w-6xl mx-auto px-6 py-6">
          <a href="/" className="inline-flex items-center text-white text-sm font-medium hover:underline drop-shadow-lg">
            <svg className="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            Home
          </a>
        </div>
      </div>

      {/* Hero Section with Cover Image */}
      <div className="relative h-[500px] bg-gradient-to-br from-blue-400 to-blue-600">
        {trip.coverImageUrl ? (
          <>
            <img
              src={trip.coverImageUrl}
              alt={trip.title}
              className="absolute inset-0 w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/30 to-black/20" />
          </>
        ) : (
          <div className="absolute inset-0 flex items-center justify-center">
            <svg className="w-24 h-24 text-white opacity-30" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
            </svg>
          </div>
        )}

        {/* Hero Content */}
        <div className="relative h-full flex flex-col justify-end">
          <div className="max-w-6xl mx-auto px-6 pb-8 md:pb-12 w-full">
            <h1 className="text-4xl md:text-6xl font-bold mb-3 md:mb-4 text-white drop-shadow-lg">
              {trip.title}
            </h1>
            <div className="flex flex-col sm:flex-row sm:items-center gap-3 sm:gap-6 text-white/90 text-base md:text-lg">
              <div className="flex items-center gap-2">
                <svg className="w-5 h-5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                <span className="leading-tight">{formatDate(trip.startDate)} - {formatDate(trip.endDate)}</span>
              </div>
              <div className="flex items-center gap-2">
                <svg className="w-5 h-5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
                </svg>
                <span className="leading-tight">{totalMoments} {totalMoments === 1 ? 'moment' : 'moments'}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="bg-white">
        <div className="max-w-6xl mx-auto px-6 py-8">
          {/* Collaborators */}
          {(() => {
            const activeCollaborators = collaborators.filter(c => c.role === 'owner' || c.role === 'collaborator');

            return (
              <div className="max-w-md mx-auto mb-8">
                <h3 className="text-sm font-semibold text-gray-700 mb-3 text-center">
                  Collaborators
                </h3>
                <div className="flex items-center justify-center gap-3 flex-wrap">
                  {activeCollaborators.map((collab) => (
                  <div key={collab.userId} className="flex flex-col items-center gap-1">
                    {collab.imageUrl ? (
                      <img
                        src={collab.imageUrl}
                        alt={collab.name || 'User'}
                        className="w-12 h-12 rounded-full border-2 border-white shadow-md"
                      />
                    ) : (
                      <div className="w-12 h-12 rounded-full bg-gradient-to-br from-ios-blue to-blue-600 flex items-center justify-center border-2 border-white shadow-md">
                        <span className="text-white font-semibold text-lg">
                          {collab.name?.[0]?.toUpperCase() || collab.email?.[0]?.toUpperCase() || '?'}
                        </span>
                      </div>
                    )}
                    <span className="text-xs text-gray-600 max-w-[80px] truncate">
                      {collab.name || collab.email?.split('@')[0] || 'User'}
                    </span>
                    {collab.role === 'owner' && (
                      <span className="text-[10px] text-ios-blue font-semibold">Owner</span>
                    )}
                  </div>
                  ))}
                </div>
              </div>
            );
          })()}

          {/* Masonry Canvas */}
          {moments.length > 0 && (() => {
            // Calculate canvas height based on moments
            const ROW_HEIGHT_PX = 150;
            const PADDING = 16;

            const maxBottom = moments
              .filter((m) => m.gridPosition)
              .reduce((max, moment) => {
                const { row, height } = moment.gridPosition!;
                const bottom = (row + height) * ROW_HEIGHT_PX + PADDING;
                return Math.max(max, bottom);
              }, 0);

            const canvasHeight = maxBottom + PADDING;

            return (
              <div className="mb-8">
                <div className="relative w-full border-2 border-gray-200 shadow-lg rounded-lg overflow-hidden" style={{ height: `${canvasHeight}px` }}>
                  <div className="absolute inset-0 bg-white p-4">
                    {moments
                      .filter((m) => m.gridPosition)
                      .map((moment) => {
                        const { column, row, width, height } = moment.gridPosition!;

                        // Grid: 2 columns, each 50% wide
                        // Rows: each row unit = 150px (adjust based on your iOS grid)
                        const COLUMN_WIDTH_PERCENT = 50;
                        const ROW_HEIGHT_PX = 150;

                      return (
                        <div
                          key={moment.momentId}
                          className="absolute rounded-[20px] overflow-hidden shadow-lg hover:shadow-2xl transition-shadow"
                          style={{
                            left: `calc(${column * COLUMN_WIDTH_PERCENT}% + 8px)`,
                            top: `${row * ROW_HEIGHT_PX + 8}px`,
                            width: `calc(${width * COLUMN_WIDTH_PERCENT}% - 16px)`,
                            height: `${height * ROW_HEIGHT_PX - 16}px`,
                          }}
                        >
                          {/* Collage layout matching iOS */}
                          {moment.media.length === 0 ? (
                            <div className="w-full h-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center">
                              <svg className="w-1/3 h-1/3 text-white opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                              </svg>
                            </div>
                          ) : moment.media.length === 1 ? (
                            // Single media - full size
                            moment.media[0].url && (
                              <MediaItem
                                url={moment.media[0].url}
                                type={moment.media[0].type}
                                alt={moment.title}
                                className="w-full h-full object-cover"
                              />
                            )
                          ) : moment.media.length === 2 ? (
                            // 2 media - split vertically 50/50
                            <div className="flex w-full h-full gap-[2px]">
                              {moment.media[0].url && (
                                <MediaItem url={moment.media[0].url} type={moment.media[0].type} alt="" className="w-1/2 h-full object-cover" />
                              )}
                              {moment.media[1].url && (
                                <MediaItem url={moment.media[1].url} type={moment.media[1].type} alt="" className="w-1/2 h-full object-cover" />
                              )}
                            </div>
                          ) : moment.media.length === 3 ? (
                            // 3 media - 60% left, 40% right (2 stacked)
                            <div className="flex w-full h-full gap-[2px]">
                              {moment.media[0].url && (
                                <MediaItem url={moment.media[0].url} type={moment.media[0].type} alt="" className="w-[60%] h-full object-cover" />
                              )}
                              <div className="flex flex-col w-[40%] h-full gap-[2px]">
                                {moment.media[1].url && (
                                  <MediaItem url={moment.media[1].url} type={moment.media[1].type} alt="" className="w-full h-1/2 object-cover" />
                                )}
                                {moment.media[2].url && (
                                  <MediaItem url={moment.media[2].url} type={moment.media[2].type} alt="" className="w-full h-1/2 object-cover" />
                                )}
                              </div>
                            </div>
                          ) : (
                            // 4+ media - 2x2 grid (first 4)
                            <div className="grid grid-cols-2 grid-rows-2 w-full h-full gap-[2px]">
                              {moment.media.slice(0, 4).map((item, idx) => (
                                item.url && (
                                  <MediaItem
                                    key={idx}
                                    url={item.url}
                                    type={item.type}
                                    alt=""
                                    className="w-full h-full object-cover"
                                  />
                                )
                              ))}
                            </div>
                          )}
                          <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/70 to-transparent p-3">
                            <p className="text-white font-semibold text-sm line-clamp-1">
                              {moment.title}
                            </p>
                            <p className="text-white/80 text-xs">
                              {moment.mediaCount} {moment.mediaCount === 1 ? 'photo' : 'photos'}
                            </p>
                          </div>
                        </div>
                      );
                      })}
                  </div>
                </div>
              </div>
            );
          })()}

          {/* Join Trip Section */}
          <div className="max-w-md mx-auto text-center">
            <div className="bg-ios-lightgray rounded-ios-lg p-6 mb-6">
              <p className="text-xs text-ios-gray uppercase tracking-wide mb-2">Trip Code</p>
              <p className="text-3xl font-bold tracking-[0.2em] text-ios-blue mb-2">
                {trip.shareCode}
              </p>
              <p className="text-xs text-ios-gray">
                Use this code in the app to join
              </p>
            </div>

            <OpenInAppButton slug={slug} />

            <p className="text-sm text-ios-gray">
              Don't have the app?{' '}
              <a
                href="https://apps.apple.com/app/rewinded"
                className="text-ios-blue font-medium hover:underline"
              >
                Download it here
              </a>
            </p>
          </div>
        </div>
      </div>

      {/* About Section */}
      <div className="bg-ios-lightgray py-12 border-t border-gray-200">
        <div className="max-w-2xl mx-auto px-6 text-center">
          <h2 className="text-2xl font-bold mb-3 text-gray-900">
            Create your own travel stories
          </h2>
          <p className="text-base text-ios-gray mb-6">
            Rewinded lets you capture and share your adventures in an interactive canvas. Download now to get started.
          </p>
          <a
            href="https://apps.apple.com/app/rewinded"
            className="inline-flex items-center justify-center px-6 py-3 text-base font-semibold text-white bg-ios-blue rounded-ios hover:bg-blue-600 transition-colors"
          >
            <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 24 24">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
            </svg>
            Download on the App Store
          </a>
        </div>
      </div>

      {/* Footer */}
      <footer className="py-6 bg-white border-t border-gray-200">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <p className="text-ios-gray text-xs">
            © 2025 Rewinded. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
