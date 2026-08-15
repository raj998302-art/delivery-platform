'use client';

import { useEffect, useState } from 'react';
import {
  Card, CardContent, CardDescription, CardHeader, CardTitle,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import {
  Tabs, TabsContent, TabsList, TabsTrigger,
} from '@/components/ui/tabs';
import { formatINR } from '@/lib/utils';
import { toast } from '@/components/ui/toaster';
import { Bike, Truck, Car, Zap, Tag, Flag } from 'lucide-react';

const VEHICLE_ICON: Record<string, any> = {
  BIKE: Bike, SCOOTER: Bike, AUTO: Car, MINI_TRUCK: Truck, TRUCK: Truck,
};

interface Service {
  id: string; type: string; name: string; isActive: boolean;
  baseFare: number; perKm: number; perMin: number; platformFee: number;
  taxPercent: number; minFare: number;
  vehicleTypes: { vehicleType: string; vehicleTypeConf: { name: string; multiplier: number; capacityKg: number } }[];
}
interface Coupon { id: string; code: string; description: string | null; type: string; value: number; maxDiscount: number | null; minOrderValue: number; isActive: boolean; }
interface Flag { id: string; key: string; name: string; description: string | null; enabled: boolean; }

export default function ServicesPage() {
  const [services, setServices] = useState<Service[]>([]);
  const [coupons, setCoupons] = useState<Coupon[]>([]);
  const [flags, setFlags] = useState<Flag[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const res = await fetch('/api/services');
    if (res.ok) {
      const data = await res.json();
      setServices(data.services);
      setCoupons(data.coupons);
      setFlags(data.flags);
    }
    setLoading(false);
  }

  useEffect(() => { load(); }, []);

  async function updateService(id: string, patch: Partial<Service>) {
    const res = await fetch('/api/services', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, ...patch }),
    });
    if (res.ok) {
      toast({ title: 'Saved', variant: 'success' });
      load();
    } else {
      toast({ title: 'Failed', variant: 'destructive' });
    }
  }

  if (loading) return <div className="grid gap-4 md:grid-cols-3">{Array.from({ length: 6 }).map((_, i) => <Card key={i}><CardContent className="h-40 animate-pulse bg-muted/30" /></Card>)}</div>;

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-bold tracking-tight">Services & Pricing</h2>
        <p className="text-sm text-muted-foreground">Configure services, fares, vehicle types, coupons, and feature flags.</p>
      </div>

      <Tabs defaultValue="services">
        <TabsList>
          <TabsTrigger value="services"><Zap className="h-4 w-4 mr-2" /> Services</TabsTrigger>
          <TabsTrigger value="coupons"><Tag className="h-4 w-4 mr-2" /> Coupons</TabsTrigger>
          <TabsTrigger value="flags"><Flag className="h-4 w-4 mr-2" /> Feature Flags</TabsTrigger>
        </TabsList>

        <TabsContent value="services" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {services.map((s) => (
              <Card key={s.id} className={s.isActive ? '' : 'opacity-60'}>
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <CardTitle className="text-base">{s.name}</CardTitle>
                      <CardDescription className="text-xs font-mono">{s.type}</CardDescription>
                    </div>
                    <Switch checked={s.isActive} onCheckedChange={(v) => updateService(s.id, { isActive: v })} />
                  </div>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <Field label="Base fare" value={formatINR(s.baseFare)} onChange={(v) => updateService(s.id, { baseFare: Number(v) })} />
                    <Field label="Per km" value={`₹${s.perKm}`} onChange={(v) => updateService(s.id, { perKm: Number(v) })} />
                    <Field label="Per min" value={`₹${s.perMin}`} onChange={(v) => updateService(s.id, { perMin: Number(v) })} />
                    <Field label="Platform fee" value={formatINR(s.platformFee)} onChange={(v) => updateService(s.id, { platformFee: Number(v) })} />
                    <Field label="Tax %" value={`${s.taxPercent}%`} onChange={(v) => updateService(s.id, { taxPercent: Number(v) })} />
                    <Field label="Min fare" value={formatINR(s.minFare)} onChange={(v) => updateService(s.id, { minFare: Number(v) })} />
                  </div>
                  <div className="flex flex-wrap gap-1 pt-2 border-t">
                    {s.vehicleTypes.map((vt) => {
                      const Icon = VEHICLE_ICON[vt.vehicleType] ?? Bike;
                      return (
                        <Badge key={vt.vehicleType} variant="secondary" className="text-xs">
                          <Icon className="h-3 w-3 mr-1" /> {vt.vehicleTypeConf.name} ×{vt.vehicleTypeConf.multiplier}
                        </Badge>
                      );
                    })}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="coupons">
          <Card>
            <CardHeader>
              <CardTitle>Coupons</CardTitle>
              <CardDescription>{coupons.length} coupons configured</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
                {coupons.map((c) => (
                  <div key={c.id} className="rounded-lg border p-4">
                    <div className="flex items-center justify-between">
                      <div className="font-mono font-semibold">{c.code}</div>
                      <Badge variant={c.isActive ? 'success' : 'secondary'}>{c.isActive ? 'Active' : 'Inactive'}</Badge>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">{c.description}</p>
                    <div className="mt-3 grid grid-cols-2 gap-1 text-xs">
                      <div>Type: <span className="font-medium">{c.type}</span></div>
                      <div>Value: <span className="font-medium">{c.type === 'FLAT' ? formatINR(c.value) : `${c.value}%`}</span></div>
                      <div>Min order: <span className="font-medium">{formatINR(c.minOrderValue)}</span></div>
                      {c.maxDiscount && <div>Max: <span className="font-medium">{formatINR(c.maxDiscount)}</span></div>}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="flags">
          <Card>
            <CardHeader>
              <CardTitle>Feature Flags</CardTitle>
              <CardDescription>Toggle platform features without redeploying.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-2">
              {flags.map((f) => (
                <div key={f.id} className="flex items-center justify-between rounded-lg border p-3">
                  <div>
                    <div className="text-sm font-medium">{f.name}</div>
                    <div className="text-xs text-muted-foreground font-mono">{f.key}{f.description && ` · ${f.description}`}</div>
                  </div>
                  <Badge variant={f.enabled ? 'success' : 'secondary'}>{f.enabled ? 'Enabled' : 'Disabled'}</Badge>
                </div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}

function Field({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <div>
      <Label className="text-[10px] text-muted-foreground">{label}</Label>
      <Input
        defaultValue={value}
        onBlur={(e) => onChange(e.target.value)}
        className="h-7 text-xs mt-0.5"
      />
    </div>
  );
}
