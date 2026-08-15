'use client';

import { useEffect, useState } from 'react';
import {
  Card, CardContent, CardHeader, CardTitle,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select';
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from '@/components/ui/table';
import { formatINR, formatDistance, timeAgo } from '@/lib/utils';
import { ORDER_STATE_COLORS, ORDER_STATE_LABELS } from '@/lib/order-state';
import { Search, RefreshCw, ChevronLeft, ChevronRight, MapPin, Package as PackageIcon } from 'lucide-react';
import type { OrderState } from '@prisma/client';

interface Order {
  id: string; code: string; state: OrderState;
  pickupAddress: string; dropAddress: string;
  distanceKm: number; totalAmount: number; paymentStatus: string;
  createdAt: string;
  user: { id: string; name: string | null; phone: string };
  partner: { id: string; firstName: string; lastName: string; phone: string } | null;
  service: { id: string; name: string; type: string };
}

const STATES: OrderState[] = [
  'DRAFT', 'QUOTE_CREATED', 'PAYMENT_PENDING', 'CONFIRMED', 'SEARCHING_PARTNER',
  'PARTNER_ASSIGNED', 'PARTNER_ACCEPTED', 'PARTNER_ARRIVING', 'PARTNER_ARRIVED',
  'PICKUP_VERIFICATION', 'PICKED_UP', 'IN_TRANSIT', 'ARRIVING',
  'DELIVERY_VERIFICATION', 'DELIVERED', 'COMPLETED', 'CANCELLED', 'FAILED', 'REFUNDED',
];

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize] = useState(15);
  const [state, setState] = useState<string>('ALL');
  const [q, setQ] = useState('');
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const params = new URLSearchParams({ page: String(page), pageSize: String(pageSize), state, q });
    const res = await fetch(`/api/orders?${params}`);
    if (res.ok) {
      const data = await res.json();
      setOrders(data.orders);
      setTotal(data.total);
    }
    setLoading(false);
  }

  useEffect(() => { load(); /* eslint-disable-next-line */ }, [page, state]);

  const pageCount = Math.ceil(total / pageSize);

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-bold tracking-tight">Orders</h2>
          <p className="text-sm text-muted-foreground">{total} total orders</p>
        </div>
        <div className="flex gap-2">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search by code, address…"
              value={q}
              onChange={(e) => setQ(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && (setPage(1), load())}
              className="pl-9 w-64"
            />
          </div>
          <Select value={state} onValueChange={(v) => { setState(v); setPage(1); }}>
            <SelectTrigger className="w-48"><SelectValue placeholder="Filter state" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">All states</SelectItem>
              {STATES.map((s) => (
                <SelectItem key={s} value={s}>{ORDER_STATE_LABELS[s]}</SelectItem>
              ))}
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
                <TableHead>Code</TableHead>
                <TableHead>Customer</TableHead>
                <TableHead>Partner</TableHead>
                <TableHead>Route</TableHead>
                <TableHead>Distance</TableHead>
                <TableHead>Fare</TableHead>
                <TableHead>State</TableHead>
                <TableHead>Payment</TableHead>
                <TableHead>Created</TableHead>
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
              ) : orders.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={9} className="text-center text-sm text-muted-foreground py-12">
                    No orders found. Try adjusting filters or seed demo data from the dashboard.
                  </TableCell>
                </TableRow>
              ) : (
                orders.map((o) => (
                  <TableRow key={o.id}>
                    <TableCell className="font-mono text-xs font-medium">{o.code}</TableCell>
                    <TableCell>
                      <div className="text-sm font-medium">{o.user.name ?? o.user.phone}</div>
                      <div className="text-xs text-muted-foreground">{o.user.phone}</div>
                    </TableCell>
                    <TableCell>
                      {o.partner ? (
                        <div>
                          <div className="text-sm">{o.partner.firstName} {o.partner.lastName}</div>
                          <div className="text-xs text-muted-foreground">{o.partner.phone}</div>
                        </div>
                      ) : <span className="text-xs text-muted-foreground">—</span>}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-start gap-1 text-xs">
                        <MapPin className="h-3 w-3 text-green-600 mt-0.5" />
                        <span className="line-clamp-1 max-w-[140px]">{o.pickupAddress}</span>
                      </div>
                      <div className="flex items-start gap-1 text-xs mt-0.5">
                        <MapPin className="h-3 w-3 text-red-600 mt-0.5" />
                        <span className="line-clamp-1 max-w-[140px]">{o.dropAddress}</span>
                      </div>
                    </TableCell>
                    <TableCell className="text-xs">{formatDistance(o.distanceKm)}</TableCell>
                    <TableCell className="font-mono text-sm font-medium">{formatINR(o.totalAmount)}</TableCell>
                    <TableCell>
                      <span className={`inline-flex items-center rounded-md px-2 py-0.5 text-xs font-medium ${ORDER_STATE_COLORS[o.state]}`}>
                        {ORDER_STATE_LABELS[o.state]}
                      </span>
                    </TableCell>
                    <TableCell>
                      <Badge variant={o.paymentStatus === 'PAID' ? 'success' : o.paymentStatus === 'FAILED' ? 'destructive' : 'warning'}>
                        {o.paymentStatus}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">{timeAgo(o.createdAt)}</TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {pageCount > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-xs text-muted-foreground">
            Page {page} of {pageCount} · {total} orders
          </p>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage(p => Math.max(1, p - 1))}>
              <ChevronLeft className="h-4 w-4" /> Prev
            </Button>
            <Button variant="outline" size="sm" disabled={page >= pageCount} onClick={() => setPage(p => p + 1)}>
              Next <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
