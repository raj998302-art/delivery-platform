'use client';

import { useEffect, useState, useRef } from 'react';
import {
  Card, CardContent, CardHeader, CardTitle, CardDescription,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { RefreshCw, Bike, Package, MapPin, Radio } from 'lucide-react';
import { formatINR, timeAgo } from '@/lib/utils';

interface OnlinePartner {
  id: string; firstName: string; lastName: string; phone: string;
  currentLat: number | null; currentLng: number | null; lastLocationAt: string | null;
  rating: number; status: string;
  vehicles: { type: string; registrationNumber: string; isPrimary: boolean }[];
}
interface ActiveSession {
  id: string;
  order: {
    id: string; code: string; state: string;
    pickupLat: number; pickupLng: number; pickupAddress: string;
    dropLat: number; dropLng: number; dropAddress: string;
    user: { name: string | null; phone: string };
    partner: { id: string; firstName: string; lastName: string; phone: string; currentLat: number | null; currentLng: number | null; rating: number; vehicles: { type: string; registrationNumber: string }[] } | null;
  };
}

export default function LiveMapPage() {
  const [partners, setPartners] = useState<OnlinePartner[]>([]);
  const [sessions, setSessions] = useState<ActiveSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<string | null>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [dims, setDims] = useState({ w: 800, h: 500 });

  async function load() {
    setLoading(true);
    const res = await fetch('/api/tracking');
    if (res.ok) {
      const data = await res.json();
      setPartners(data.onlinePartners ?? []);
      setSessions(data.sessions ?? []);
    }
    setLoading(false);
  }

  useEffect(() => {
    load();
    const id = setInterval(load, 5000);
    return () => clearInterval(id);
  }, []);

  // Compute bounding box for the canvas map projection
  const allPoints = [
    ...partners.map((p) => ({ lat: p.currentLat, lng: p.currentLng })),
    ...sessions.flatMap((s) => [
      { lat: s.order.pickupLat, lng: s.order.pickupLng },
      { lat: s.order.dropLat, lng: s.order.dropLat },
      ...(s.order.partner?.currentLat ? [{ lat: s.order.partner.currentLat, lng: s.order.partner.currentLng }] : []),
    ]),
  ].filter((p) => p.lat != null && p.lng != null) as { lat: number; lng: number }[];

  // Bengaluru default center if no points
  const bbox = allPoints.length > 0
    ? {
        minLat: Math.min(...allPoints.map((p) => p.lat)) - 0.02,
        maxLat: Math.max(...allPoints.map((p) => p.lat)) + 0.02,
        minLng: Math.min(...allPoints.map((p) => p.lng)) - 0.02,
        maxLng: Math.max(...allPoints.map((p) => p.lng)) + 0.02,
      }
    : { minLat: 12.90, maxLat: 13.05, minLng: 77.50, maxLng: 77.75 };

  function project(lat: number, lng: number) {
    const x = ((lng - bbox.minLng) / (bbox.maxLng - bbox.minLng)) * dims.w;
    const y = ((bbox.maxLat - lat) / (bbox.maxLat - bbox.minLat)) * dims.h;
    return { x, y };
  }

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const parent = canvas.parentElement;
    if (!parent) return;
    const w = parent.clientWidth;
    const h = Math.max(400, Math.min(600, w * 0.55));
    setDims({ w, h });
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    canvas.width = dims.w * window.devicePixelRatio;
    canvas.height = dims.h * window.devicePixelRatio;
    canvas.style.width = `${dims.w}px`;
    canvas.style.height = `${dims.h}px`;
    ctx.scale(window.devicePixelRatio, window.devicePixelRatio);

    // Background
    ctx.fillStyle = '#f1f5f9';
    ctx.fillRect(0, 0, dims.w, dims.h);

    // Grid
    ctx.strokeStyle = '#e2e8f0';
    ctx.lineWidth = 1;
    for (let i = 0; i <= 10; i++) {
      const x = (i / 10) * dims.w;
      const y = (i / 10) * dims.h;
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, dims.h); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(dims.w, y); ctx.stroke();
    }

    // Draw routes for active sessions
    sessions.forEach((s) => {
      const pickup = project(s.order.pickupLat, s.order.pickupLng);
      const drop = project(s.order.dropLat, s.order.dropLng);

      // Route line
      ctx.strokeStyle = '#3b82f6';
      ctx.lineWidth = 2;
      ctx.setLineDash([4, 4]);
      ctx.beginPath();
      ctx.moveTo(pickup.x, pickup.y);
      ctx.lineTo(drop.x, drop.y);
      ctx.stroke();
      ctx.setLineDash([]);

      // Pickup marker (green)
      ctx.fillStyle = '#10b981';
      ctx.beginPath(); ctx.arc(pickup.x, pickup.y, 6, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#fff';
      ctx.beginPath(); ctx.arc(pickup.x, pickup.y, 2, 0, Math.PI * 2); ctx.fill();

      // Drop marker (red)
      ctx.fillStyle = '#ef4444';
      ctx.beginPath(); ctx.arc(drop.x, drop.y, 6, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#fff';
      ctx.beginPath(); ctx.arc(drop.x, drop.y, 2, 0, Math.PI * 2); ctx.fill();

      // Partner marker (blue pulse)
      if (s.order.partner?.currentLat) {
        const partner = project(s.order.partner.currentLat, s.order.partner.currentLng!);
        const isSelected = selected === s.id;
        ctx.fillStyle = isSelected ? '#f59e0b' : '#3b82f6';
        ctx.beginPath(); ctx.arc(partner.x, partner.y, 8, 0, Math.PI * 2); ctx.fill();
        ctx.strokeStyle = '#fff';
        ctx.lineWidth = 2;
        ctx.beginPath(); ctx.arc(partner.x, partner.y, 8, 0, Math.PI * 2); ctx.stroke();
      }
    });

    // Draw online partners (not on active delivery)
    const partnerIdsInSession = new Set(sessions.map((s) => s.order.partner?.id).filter(Boolean));
    partners
      .filter((p) => !partnerIdsInSession.has(p.id))
      .forEach((p) => {
        if (p.currentLat == null) return;
        const pt = project(p.currentLat, p.currentLng!);
        ctx.fillStyle = '#06b6d4';
        ctx.beginPath(); ctx.arc(pt.x, pt.y, 5, 0, Math.PI * 2); ctx.fill();
        ctx.strokeStyle = '#fff';
        ctx.lineWidth = 1.5;
        ctx.beginPath(); ctx.arc(pt.x, pt.y, 5, 0, Math.PI * 2); ctx.stroke();
      });
  }, [partners, sessions, dims, selected, bbox]);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold tracking-tight">Live Map</h2>
          <p className="text-sm text-muted-foreground">
            {partners.length} partners online · {sessions.length} active deliveries · refreshes every 5s
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={load} disabled={loading}>
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} /> Refresh
        </Button>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        {/* Map */}
        <Card className="lg:col-span-2 overflow-hidden">
          <CardContent className="p-0">
            <div className="relative">
              <canvas ref={canvasRef} className="block" />
              <div className="absolute top-3 left-3 flex items-center gap-3 rounded-md bg-background/90 backdrop-blur px-3 py-1.5 text-xs shadow">
                <span className="flex items-center gap-1"><span className="h-2 w-2 rounded-full bg-cyan-500" /> Partner idle</span>
                <span className="flex items-center gap-1"><span className="h-2 w-2 rounded-full bg-blue-500" /> On delivery</span>
                <span className="flex items-center gap-1"><span className="h-2 w-2 rounded-full bg-green-500" /> Pickup</span>
                <span className="flex items-center gap-1"><span className="h-2 w-2 rounded-full bg-red-500" /> Drop</span>
              </div>
              <div className="absolute bottom-3 right-3 text-[10px] text-muted-foreground bg-background/80 px-2 py-0.5 rounded">
                bbox: {bbox.minLat.toFixed(3)}→{bbox.maxLat.toFixed(3)}, {bbox.minLng.toFixed(3)}→{bbox.maxLng.toFixed(3)}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Side panel: active deliveries */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base"><Radio className="h-4 w-4 animate-pulse text-red-500" /> Active Deliveries</CardTitle>
            <CardDescription>{sessions.length} in progress</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2 max-h-[500px] overflow-y-auto scrollbar-thin">
            {sessions.length === 0 ? (
              <div className="text-center py-8 text-sm text-muted-foreground">
                No active deliveries right now.
                <br />Try seeding demo data and creating an order.
              </div>
            ) : (
              sessions.map((s) => (
                <button
                  key={s.id}
                  onClick={() => setSelected(selected === s.id ? null : s.id)}
                  className={`w-full text-left rounded-lg border p-3 transition-colors ${selected === s.id ? 'border-primary bg-primary/5' : 'hover:bg-accent'}`}
                >
                  <div className="flex items-center justify-between">
                    <div className="font-mono text-xs font-semibold">{s.order.code}</div>
                    <Badge variant="info" className="text-xs">{s.order.state.replace(/_/g, ' ')}</Badge>
                  </div>
                  <div className="mt-2 space-y-1 text-xs">
                    <div className="flex items-start gap-1.5">
                      <MapPin className="h-3 w-3 text-green-600 mt-0.5" />
                      <span className="line-clamp-1">{s.order.pickupAddress}</span>
                    </div>
                    <div className="flex items-start gap-1.5">
                      <MapPin className="h-3 w-3 text-red-600 mt-0.5" />
                      <span className="line-clamp-1">{s.order.dropAddress}</span>
                    </div>
                  </div>
                  {s.order.partner && (
                    <div className="mt-2 flex items-center gap-2 pt-2 border-t">
                      <div className="grid place-items-center h-6 w-6 rounded-full bg-blue-100 text-blue-700">
                        <Bike className="h-3 w-3" />
                      </div>
                      <div className="text-xs">
                        <div className="font-medium">{s.order.partner.firstName} {s.order.partner.lastName}</div>
                        <div className="text-muted-foreground">{s.order.partner.vehicles[0]?.registrationNumber ?? '—'} · ⭐ {s.order.partner.rating.toFixed(1)}</div>
                      </div>
                    </div>
                  )}
                </button>
              ))
            )}
          </CardContent>
        </Card>
      </div>

      {/* Online partners list */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Online Partners ({partners.length})</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-2 md:grid-cols-2 lg:grid-cols-3">
            {partners.map((p) => (
              <div key={p.id} className="flex items-center gap-3 rounded-lg border p-2.5">
                <div className="grid place-items-center h-9 w-9 rounded-full bg-cyan-100 text-cyan-700">
                  <Bike className="h-4 w-4" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-medium truncate">{p.firstName} {p.lastName}</div>
                  <div className="text-xs text-muted-foreground truncate">
                    {p.vehicles[0]?.registrationNumber ?? '—'} · ⭐ {p.rating.toFixed(1)}
                  </div>
                </div>
                <div className="text-[10px] text-muted-foreground">
                  {p.currentLat != null ? `${p.currentLat.toFixed(3)}, ${p.currentLng?.toFixed(3)}` : '—'}
                  <div>{p.lastLocationAt ? timeAgo(p.lastLocationAt) : ''}</div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
