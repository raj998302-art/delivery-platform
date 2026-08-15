'use client';

import { usePathname } from 'next/navigation';
import { Sidebar } from '@/components/layout/sidebar';
import { Topbar } from '@/components/layout/topbar';
import { AuthGuard } from '@/components/layout/auth-guard';

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  // Login page is rendered without the shell
  if (pathname === '/login' || pathname === '/') {
    return <>{children}</>;
  }

  return (
    <div className="flex h-screen overflow-hidden bg-muted/20">
      <Sidebar />
      <div className="flex flex-1 flex-col overflow-hidden">
        <Topbar />
        <main className="flex-1 overflow-y-auto scrollbar-thin">
          <AuthGuard>
            <div className="container mx-auto max-w-[1600px] p-4 md:p-6 lg:p-8 animate-fade-in">
              {children}
            </div>
          </AuthGuard>
        </main>
      </div>
    </div>
  );
}
