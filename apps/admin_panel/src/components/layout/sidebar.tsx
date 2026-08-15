'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Package,
  Users,
  Bike,
  Map,
  Settings,
  LifeBuoy,
  Truck,
  ChevronRight,
  Zap,
} from 'lucide-react';
import { cn } from '@/lib/utils';

const NAV = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/orders', label: 'Orders', icon: Package },
  { href: '/partners', label: 'Partners', icon: Bike },
  { href: '/users', label: 'Users', icon: Users },
  { href: '/services', label: 'Services & Pricing', icon: Zap },
  { href: '/live-map', label: 'Live Map', icon: Map },
  { href: '/support', label: 'Support', icon: LifeBuoy },
  { href: '/settings', label: 'Settings', icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="hidden md:flex w-64 shrink-0 flex-col border-r bg-card">
      <div className="flex h-16 items-center gap-2 px-6 border-b">
        <div className="grid place-items-center h-9 w-9 rounded-lg bg-primary text-primary-foreground shadow-sm">
          <Truck className="h-5 w-5" />
        </div>
        <div className="leading-tight">
          <div className="text-sm font-semibold">Delivery</div>
          <div className="text-[11px] text-muted-foreground">Admin Console</div>
        </div>
      </div>

      <nav className="flex-1 overflow-y-auto scrollbar-thin p-3 space-y-1">
        {NAV.map((item) => {
          const active =
            pathname === item.href ||
            (item.href !== '/dashboard' && pathname.startsWith(item.href));
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'group flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors',
                active
                  ? 'bg-primary text-primary-foreground shadow-sm'
                  : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
              )}
            >
              <Icon className="h-4 w-4" />
              <span className="flex-1">{item.label}</span>
              {active && <ChevronRight className="h-4 w-4" />}
            </Link>
          );
        })}
      </nav>

      <div className="border-t p-3">
        <div className="rounded-lg bg-gradient-to-br from-primary/10 via-primary/5 to-transparent p-3">
          <div className="text-xs font-semibold text-foreground">Platform v0.1.0</div>
          <p className="mt-1 text-[11px] leading-relaxed text-muted-foreground">
            MVP — modular monolith on Vercel. APK builds via GitHub Actions.
          </p>
        </div>
      </div>
    </aside>
  );
}
