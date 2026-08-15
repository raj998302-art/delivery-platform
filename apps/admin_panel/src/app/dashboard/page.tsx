'use client';

import { useEffect, useState } from 'react';
import {
  Card, CardContent, CardDescription, CardHeader, CardTitle,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Package, Users, Bike, IndianRupee, TrendingUp, TrendingDown,
  Activity, Star, Zap, RefreshCw, AlertCircle,
} from 'lucide-react';
import {
  Area, AreaChart, Bar, BarChart, CartesianGrid, Cell,
  Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis,
} from 'recharts';
import { formatINR, timeAgo } from '@/lib/utils';
import { toast } from '@/components/ui/toaster';
import Link from 'next/link';

interface Analytics {
  kpis: {
    totalOrders: number; orders24h: number; completedOrders: number; cancelledOrders: number;
    cancellationRate: number; totalRevenue: number; revenue30d: number;
    totalUsers: number; users24h: number; totalPartners: number; onlinePartners: number;
    activeOrders: number; avgRating: number;
  };
  hourly: { hour: string; count: number; revenue: number }[];
  daily: { day: string; count: number; revenue: number }[];
  byService: { service: string; type: string; count: number; revenue: number }[];
  byState: { state: string; count: number }[];
}

const SERVICE_COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#14b8a6'];

export default function DashboardPage() {
  const [data, setData] = useState<Analytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [seeding, setSeeding] = useState(false);

  async function load() {
    setLoading(true);
    try {
      const res = await fetch('/api/analytics');
      if (res.ok) setData(await res.json());
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function seed() {
    setSeeding(true);
    try {
      const res = await fetch('/api/seed');
      const json = await res.json();
      if (res.ok) {
        toast({ title: 'Seed complete', description: `${json.results?.length ?? 0} steps`, variant: 'success' });
        await load();
      } else {
        toast({ title: 'Seed failed', description: json.error, variant: 'destructive' });
      }
    } finally {
      setSeeding(false);
    }
  }

  if (loading) {
    return (
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 8 }).map((_, i) => (
          <Card key={i}><CardContent className="h-32 animate-pulse bg-muted/30" /></Card>
        ))}
      </div>
    );
  }

  const k = data?.kpis;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Welcome back, Admin 👋</h2>
          <p className="text-sm text-muted-foreground">
            Real-time overview of your delivery platform.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={seed} disabled={seeding}>
            {seeding ? <RefreshCw className="h-4 w-4 animate-spin" /> : <Zap className="h-4 w-4" />}
            Seed demo data
          </Button>
          <Button variant="outline" size="sm" onClick={load}>
            <RefreshCw className="h-4 w-4" /> Refresh
          </Button>
        </div>
      </div>

      {/* KPI cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <KpiCard
          title="Total Orders"
          value={k?.totalOrders ?? 0}
          delta={k?.orders24h ?? 0}
          deltaLabel="last 24h"
          icon={Package}
          accent="text-blue-600"
        />
        <KpiCard
          title="Revenue (paid)"
          value={formatINR(k?.totalRevenue ?? 0)}
          delta={formatINR(k?.revenue30d ?? 0)}
          deltaLabel="last 30d"
          icon={IndianRupee}
          accent="text-green-600"
        />
        <KpiCard
          title="Active Orders"
          value={k?.activeOrders ?? 0}
          icon={Activity}
          accent="text-purple-600"
          delta={`${k?.onlinePartners ?? 0} partners online`}
          deltaLabel="live"
        />
        <KpiCard
          title="Total Users"
          value={k?.totalUsers ?? 0}
          delta={k?.users24h ?? 0}
          deltaLabel="last 24h"
          icon={Users}
          accent="text-orange-600"
        />
      </div>

      {/* Secondary KPIs */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <MiniStat label="Completed" value={k?.completedOrders ?? 0} icon={TrendingUp} tone="success" />
        <MiniStat label="Cancelled" value={k?.cancelledOrders ?? 0} sub={`${(k?.cancellationRate ?? 0).toFixed(1)}% rate`} icon={TrendingDown} tone="destructive" />
        <MiniStat label="Partners (online)" value={`${k?.onlinePartners ?? 0}/${k?.totalPartners ?? 0}`} icon={Bike} tone="info" />
        <MiniStat label="Avg Rating" value={(k?.avgRating ?? 0).toFixed(2)} icon={Star} tone="warning" />
      </div>

      {/* Charts */}
      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Orders — Last 24 hours</CardTitle>
            <CardDescription>Hourly order volume</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <AreaChart data={data?.hourly ?? []}>
                <defs>
                  <linearGradient id="ordersGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="hour" tick={{ fontSize: 10 }} tickFormatter={(v) => v.slice(11, 16)} />
                <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
                <Tooltip
                  contentStyle={{ borderRadius: 8, border: '1px solid #e5e7eb', fontSize: 12 }}
                  labelFormatter={(v) => `Hour: ${String(v).slice(11, 16)}`}
                />
                <Area type="monotone" dataKey="count" stroke="#3b82f6" strokeWidth={2} fill="url(#ordersGrad)" />
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Revenue — Last 7 days</CardTitle>
            <CardDescription>Daily paid revenue (₹)</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={data?.daily ?? []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="day" tick={{ fontSize: 10 }} tickFormatter={(v) => v.slice(5)} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip
                  contentStyle={{ borderRadius: 8, border: '1px solid #e5e7eb', fontSize: 12 }}
                  formatter={(v: any) => formatINR(v)}
                />
                <Bar dataKey="revenue" fill="#10b981" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Orders by Service</CardTitle>
            <CardDescription>Volume per service type</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={data?.byService ?? []} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis type="number" tick={{ fontSize: 11 }} allowDecimals={false} />
                <YAxis type="category" dataKey="service" tick={{ fontSize: 11 }} width={90} />
                <Tooltip contentStyle={{ borderRadius: 8, border: '1px solid #e5e7eb', fontSize: 12 }} />
                <Bar dataKey="count" radius={[0, 6, 6, 0]}>
                  {(data?.byService ?? []).map((_, i) => (
                    <Cell key={i} fill={SERVICE_COLORS[i % SERVICE_COLORS.length]} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Orders by State</CardTitle>
            <CardDescription>Current distribution</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {(data?.byState ?? [])
                .sort((a, b) => b.count - a.count)
                .map((s) => {
                  const total = (data?.byState ?? []).reduce((sum, x) => sum + x.count, 0);
                  const pct = total > 0 ? (s.count / total) * 100 : 0;
                  return (
                    <div key={s.state} className="flex items-center gap-3">
                      <div className="w-32 text-xs font-medium capitalize">{s.state.replace(/_/g, ' ').toLowerCase()}</div>
                      <div className="flex-1 h-2.5 bg-muted rounded-full overflow-hidden">
                        <div className="h-full bg-primary rounded-full" style={{ width: `${pct}%` }} />
                      </div>
                      <div className="w-12 text-right text-xs font-mono text-muted-foreground">{s.count}</div>
                    </div>
                  );
                })}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick actions */}
      <Card>
        <CardHeader>
          <CardTitle>Quick actions</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-wrap gap-2">
          <Button asChild variant="outline"><Link href="/orders"><Package className="h-4 w-4" /> View Orders</Link></Button>
          <Button asChild variant="outline"><Link href="/partners"><Bike className="h-4 w-4" /> Manage Partners</Link></Button>
          <Button asChild variant="outline"><Link href="/live-map"><Activity className="h-4 w-4" /> Live Map</Link></Button>
          <Button asChild variant="outline"><Link href="/services"><Zap className="h-4 w-4" /> Pricing Config</Link></Button>
        </CardContent>
      </Card>

      {(k?.totalOrders ?? 0) === 0 && (
        <Card className="border-amber-200 bg-amber-50">
          <CardContent className="flex items-center gap-3 p-4">
            <AlertCircle className="h-5 w-5 text-amber-600" />
            <div className="flex-1">
              <div className="text-sm font-medium text-amber-900">No data yet</div>
              <div className="text-xs text-amber-700">Click <span className="font-semibold">&quot;Seed demo data&quot;</span> above to populate services, partners, users, and orders for testing.</div>
            </div>
            <Button size="sm" onClick={seed} disabled={seeding}>Seed now</Button>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function KpiCard({
  title, value, delta, deltaLabel, icon: Icon, accent,
}: {
  title: string; value: string | number; delta?: string | number;
  deltaLabel?: string; icon: any; accent: string;
}) {
  return (
    <Card className="overflow-hidden">
      <CardContent className="p-5">
        <div className="flex items-start justify-between">
          <div>
            <div className="text-xs font-medium text-muted-foreground">{title}</div>
            <div className="mt-2 text-2xl font-bold tracking-tight">{value}</div>
            {delta !== undefined && (
              <div className="mt-1 text-xs text-muted-foreground">
                <span className="font-semibold text-foreground">{delta}</span> {deltaLabel}
              </div>
            )}
          </div>
          <div className={`grid place-items-center h-11 w-11 rounded-lg bg-muted ${accent}`}>
            <Icon className="h-5 w-5" />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function MiniStat({
  label, value, sub, icon: Icon, tone,
}: {
  label: string; value: string | number; sub?: string; icon: any;
  tone: 'success' | 'destructive' | 'info' | 'warning';
}) {
  const tones = {
    success: 'bg-green-100 text-green-700',
    destructive: 'bg-red-100 text-red-700',
    info: 'bg-blue-100 text-blue-700',
    warning: 'bg-amber-100 text-amber-700',
  };
  return (
    <Card>
      <CardContent className="p-4 flex items-center gap-3">
        <div className={`grid place-items-center h-9 w-9 rounded-md ${tones[tone]}`}>
          <Icon className="h-4 w-4" />
        </div>
        <div className="flex-1">
          <div className="text-xs text-muted-foreground">{label}</div>
          <div className="text-sm font-semibold">{value}{sub && <span className="ml-2 text-xs text-muted-foreground">{sub}</span>}</div>
        </div>
      </CardContent>
    </Card>
  );
}
