'use client';

import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { Bell, Search, Menu, LogOut, User as UserIcon, Crown, Settings, ChevronDown } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

interface SessionUser { name: string; email: string; role: string }

export function Topbar() {
  const router = useRouter();
  const pathname = usePathname();
  const [session, setSession] = useState<SessionUser | null>(null);

  useEffect(() => {
    fetch('/api/auth/me')
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => d?.user && setSession(d.user))
      .catch(() => {});
  }, [pathname]);

  const title = (() => {
    if (pathname.startsWith('/dashboard')) return 'Dashboard';
    if (pathname.startsWith('/orders')) return 'Orders';
    if (pathname.startsWith('/partners')) return 'Partners';
    if (pathname.startsWith('/users')) return 'Users';
    if (pathname.startsWith('/services')) return 'Services & Pricing';
    if (pathname.startsWith('/live-map')) return 'Live Map';
    if (pathname.startsWith('/support')) return 'Support';
    if (pathname.startsWith('/settings')) return 'Settings';
    return 'Admin';
  })();

  const isOwner = session?.role === 'OWNER';
  const initials = session?.name?.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase() ?? 'A';

  async function logout() {
    await fetch('/api/auth/logout', { method: 'POST' });
    router.push('/login');
    router.refresh();
  }

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center gap-3 border-b bg-background/70 px-4 backdrop-blur-xl md:px-6">
      <Button variant="ghost" size="icon" className="md:hidden">
        <Menu className="h-5 w-5" />
      </Button>

      <div className="flex-1 flex items-center gap-3">
        <h1 className="text-base font-bold tracking-tight md:text-lg">{title}</h1>
        {isOwner && (
          <span className="hidden sm:inline-flex items-center gap-1 rounded-full bg-gradient-to-r from-amber-500 to-orange-500 px-2.5 py-0.5 text-[10px] font-bold text-white shadow-sm">
            <Crown className="h-3 w-3" />
            OWNER
          </span>
        )}
      </div>

      <div className="hidden md:flex relative w-72">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Search orders, users, partners…"
          className="pl-9 h-9 bg-muted/50 border-transparent focus-visible:bg-background"
        />
      </div>

      <Button variant="ghost" size="icon" className="relative hover-lift">
        <Bell className="h-5 w-5" />
        <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-destructive ring-2 ring-background pulse-dot" />
      </Button>

      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button className="flex items-center gap-2 rounded-full pl-1 pr-3 py-1 hover:bg-accent transition-colors group">
            <Avatar className="h-8 w-8 ring-2 ring-primary/20 group-hover:ring-primary/40 transition-all">
              <AvatarFallback className={isOwner ? 'bg-gradient-to-br from-amber-500 to-orange-500 text-white' : 'bg-primary/10 text-primary'}>
                {initials}
              </AvatarFallback>
            </Avatar>
            <div className="hidden md:block text-left leading-tight">
              <div className="text-xs font-semibold">{session?.name ?? 'Admin'}</div>
              <div className="text-[10px] text-muted-foreground">{session?.role ?? 'ADMIN'}</div>
            </div>
            <ChevronDown className="h-3.5 w-3.5 text-muted-foreground hidden md:block" />
          </button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-56 animate-scale-in">
          <DropdownMenuLabel>
            <div className="text-sm font-semibold">{session?.name ?? 'Admin'}</div>
            <div className="text-xs text-muted-foreground font-normal">{session?.email}</div>
            {isOwner && (
              <div className="mt-2 inline-flex items-center gap-1 rounded-full bg-gradient-to-r from-amber-500 to-orange-500 px-2 py-0.5 text-[10px] font-bold text-white">
                <Crown className="h-2.5 w-2.5" /> OWNER
              </div>
            )}
          </DropdownMenuLabel>
          <DropdownMenuSeparator />
          <DropdownMenuItem asChild>
            <Link href="/settings" className="cursor-pointer"><UserIcon className="mr-2 h-4 w-4" /> Profile</Link>
          </DropdownMenuItem>
          <DropdownMenuItem asChild>
            <Link href="/settings" className="cursor-pointer"><Settings className="mr-2 h-4 w-4" /> Settings</Link>
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={logout} className="text-destructive focus:text-destructive cursor-pointer">
            <LogOut className="mr-2 h-4 w-4" /> Sign out
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </header>
  );
}
