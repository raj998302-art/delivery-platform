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
  Crown,
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
    <aside className="hidden md:flex w-64 shrink-0 flex-col bg-sidebar text-sidebar-foreground relative">
      {/* Gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-b from-blue-600/10 via-transparent to-purple-600/10 pointer-events-none" />

      {/* Logo */}
      <div className="relative flex h-16 items-center gap-3 px-6 border-b border-white/5">
        <div className="grid place-items-center h-10 w-10 rounded-xl gradient-bg shadow-lg shadow-blue-500/30">
          <Truck className="h-5 w-5 text-white" />
        </div>
        <div className="leading-tight">
          <div className="text-sm font-bold text-white">Delivery</div>
          <div className="text-[10px] text-blue-300/70 uppercase tracking-wider">Admin Console</div>
        </div>
      </div>

      {/* Nav */}
      <nav className="relative flex-1 overflow-y-auto scrollbar-thin px-3 py-4 space-y-1">
        {NAV.map((item, i) => {
          const active =
            pathname === item.href ||
            (item.href !== '/dashboard' && pathname.startsWith(item.href));
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'group flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200 animate-slide-in',
                active
                  ? 'gradient-bg text-white shadow-lg shadow-blue-500/20'
                  : 'text-blue-100/60 hover:bg-white/5 hover:text-white'
              )}
              style={{ animationDelay: `${i * 40}ms` }}
            >
              <Icon className={cn('h-4 w-4 transition-transform group-hover:scale-110', active && 'drop-shadow')} />
              <span className="flex-1">{item.label}</span>
              {active && <ChevronRight className="h-4 w-4 animate-in" />}
            </Link>
          );
        })}
      </nav>

      {/* Owner badge */}
      <div className="relative p-3">
        <div className="rounded-xl bg-gradient-to-br from-amber-500/10 to-orange-500/5 border border-amber-500/20 p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="grid place-items-center h-7 w-7 rounded-lg bg-amber-500/20">
              <Crown className="h-3.5 w-3.5 text-amber-400" />
            </div>
            <div className="text-xs font-bold text-amber-400 uppercase tracking-wide">Owner</div>
          </div>
          <div className="text-[11px] leading-relaxed text-blue-100/60">
            Full access · Manage admins · Configure platform
          </div>
        </div>
      </div>

      {/* Version */}
      <div className="relative px-6 py-3 border-t border-white/5">
        <div className="text-[10px] text-blue-300/50">Platform v0.3.0 · MongoDB</div>
      </div>
    </aside>
  );
}
