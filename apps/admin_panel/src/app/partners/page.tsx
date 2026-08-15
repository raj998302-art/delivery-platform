'use client';

import { useEffect, useState } from 'react';
import {
  Card, CardContent,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select';
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from '@/components/ui/table';
import { formatINR, timeAgo } from '@/lib/utils';
import { Search, RefreshCw, Bike, Star, Phone, Mail } from 'lucide-react';
import { toast } from '@/components/ui/toaster';
import type { PartnerStatus } from '@prisma/client';

interface Partner {
  id: string; firstName: string; lastName: string; phone: string; email: string | null;
  status: PartnerStatus; isOnline: boolean; rating: number; totalDeliveries: number;
  totalEarnings: number; currentLat: number | null; currentLng: number | null;
  lastLocationAt: string | null; createdAt: string;
  vehicles: { id: string; type: string; registrationNumber: string; isPrimary: boolean }[];
}

const STATUS_VARIANT: Record<PartnerStatus, 'success' | 'warning' | 'destructive' | 'secondary' | 'info' | 'default'> = {
  ONLINE: 'success',
  ON_DELIVERY: 'info',
  OFFLINE: 'secondary',
  APPROVED: 'default',
  PENDING: 'warning',
  REJECTED: 'destructive',
  SUSPENDED: 'destructive',
};

export default function PartnersPage() {
  const [partners, setPartners] = useState<Partner[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [status, setStatus] = useState('ALL');
  const [q, setQ] = useState('');
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const params = new URLSearchParams({ page: String(page), pageSize: '20', status, q });
    const res = await fetch(`/api/partners?${params}`);
    if (res.ok) {
      const data = await res.json();
      setPartners(data.partners);
      setTotal(data.total);
    }
    setLoading(false);
  }

  useEffect(() => { load(); /* eslint-disable-next-line */ }, [page, status]);

  async function updateStatus(id: string, newStatus: PartnerStatus) {
    const res = await fetch('/api/partners', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, status: newStatus }),
    });
    if (res.ok) {
      toast({ title: 'Partner updated', description: `Status: ${newStatus}`, variant: 'success' });
      load();
    } else {
      toast({ title: 'Update failed', variant: 'destructive' });
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-bold tracking-tight">Partners</h2>
          <p className="text-sm text-muted-foreground">{total} delivery partners</p>
        </div>
        <div className="flex gap-2">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input placeholder="Search partners…" value={q} onChange={(e) => setQ(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && (setPage(1), load())} className="pl-9 w-56" />
          </div>
          <Select value={status} onValueChange={(v) => { setStatus(v); setPage(1); }}>
            <SelectTrigger className="w-40"><SelectValue placeholder="Filter" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">All</SelectItem>
              <SelectItem value="ONLINE">Online</SelectItem>
              <SelectItem value="OFFLINE">Offline</SelectItem>
              <SelectItem value="ON_DELIVERY">On Delivery</SelectItem>
              <SelectItem value="PENDING">Pending KYC</SelectItem>
              <SelectItem value="APPROVED">Approved</SelectItem>
              <SelectItem value="SUSPENDED">Suspended</SelectItem>
            </SelectContent>
          </Select>
          <Button variant="outline" size="icon" onClick={load}><RefreshCw className="h-4 w-4" /></Button>
        </div>
      </div>

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Partner</TableHead>
                <TableHead>Contact</TableHead>
                <TableHead>Vehicle</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Rating</TableHead>
                <TableHead>Deliveries</TableHead>
                <TableHead>Earnings</TableHead>
                <TableHead>Last seen</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    {Array.from({ length: 9 }).map((_, j) => (
                      <TableCell key={j}><div className="h-4 bg-muted animate-pulse rounded" /></TableCell>
                    ))}
                  </TableRow>
                ))
              ) : partners.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={9} className="text-center text-sm text-muted-foreground py-12">
                    No partners found.
                  </TableCell>
                </TableRow>
              ) : (
                partners.map((p) => (
                  <TableRow key={p.id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <Avatar>
                          <AvatarFallback>{p.firstName.charAt(0)}{p.lastName.charAt(0)}</AvatarFallback>
                        </Avatar>
                        <div>
                          <div className="text-sm font-medium">{p.firstName} {p.lastName}</div>
                          <div className="text-xs text-muted-foreground">Joined {timeAgo(p.createdAt)}</div>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="text-xs flex items-center gap-1"><Phone className="h-3 w-3" />{p.phone}</div>
                      {p.email && <div className="text-xs text-muted-foreground flex items-center gap-1 mt-0.5"><Mail className="h-3 w-3" />{p.email}</div>}
                    </TableCell>
                    <TableCell>
                      {p.vehicles[0] ? (
                        <div className="flex items-center gap-2">
                          <Bike className="h-4 w-4 text-muted-foreground" />
                          <div>
                            <div className="text-xs font-medium">{p.vehicles[0].type.replace(/_/g, ' ')}</div>
                            <div className="text-xs text-muted-foreground">{p.vehicles[0].registrationNumber}</div>
                          </div>
                        </div>
                      ) : <span className="text-xs text-muted-foreground">No vehicle</span>}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Badge variant={STATUS_VARIANT[p.status]}>{p.status.replace(/_/g, ' ')}</Badge>
                        {p.isOnline && <span className="h-2 w-2 rounded-full bg-green-500 animate-pulse" />}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                        <span className="text-sm font-medium">{p.rating.toFixed(1)}</span>
                      </div>
                    </TableCell>
                    <TableCell className="text-sm">{p.totalDeliveries}</TableCell>
                    <TableCell className="font-mono text-sm">{formatINR(Number(p.totalEarnings))}</TableCell>
                    <TableCell className="text-xs text-muted-foreground">{p.lastLocationAt ? timeAgo(p.lastLocationAt) : '—'}</TableCell>
                    <TableCell>
                      <Select onValueChange={(v) => updateStatus(p.id, v as PartnerStatus)}>
                        <SelectTrigger className="h-8 w-28 text-xs"><SelectValue placeholder="Manage" /></SelectTrigger>
                        <SelectContent>
                          <SelectItem value="APPROVED">Approve</SelectItem>
                          <SelectItem value="SUSPENDED">Suspend</SelectItem>
                          <SelectItem value="REJECTED">Reject</SelectItem>
                          <SelectItem value="OFFLINE">Force Offline</SelectItem>
                        </SelectContent>
                      </Select>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
