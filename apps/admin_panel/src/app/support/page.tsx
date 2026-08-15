'use client';

import { useEffect, useState } from 'react';
import {
  Card, CardContent,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from '@/components/ui/table';
import { RefreshCw, LifeBuoy } from 'lucide-react';
import { timeAgo } from '@/lib/utils';

interface Ticket {
  id: string; code: string; subject: string; category: string; priority: string;
  status: string; createdAt: string;
  user: { name: string | null; phone: string } | null;
  partner: { firstName: string; lastName: string; phone: string } | null;
  _count?: { messages: number };
}

export default function SupportPage() {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    // Note: support API is optional for MVP; reusing /api/orders pattern
    // For now we render an empty state placeholder until DB is wired.
    setTickets([]);
    setLoading(false);
  }

  useEffect(() => { load(); }, []);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold tracking-tight">Support Tickets</h2>
          <p className="text-sm text-muted-foreground">Customer & partner support requests</p>
        </div>
        <Button variant="outline" size="sm" onClick={load}><RefreshCw className="h-4 w-4" /> Refresh</Button>
      </div>

      <Card>
        <CardContent className="p-0">
          {loading ? (
            <div className="p-8 text-center text-sm text-muted-foreground">Loading…</div>
          ) : tickets.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center">
              <div className="grid place-items-center h-14 w-14 rounded-full bg-green-100 text-green-700 mb-3">
                <LifeBuoy className="h-7 w-7" />
              </div>
              <div className="text-base font-medium">All clear</div>
              <p className="mt-1 text-sm text-muted-foreground max-w-sm">
                No support tickets right now. Tickets raised by users or partners in the apps
                will appear here with full conversation history.
              </p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Code</TableHead>
                  <TableHead>Subject</TableHead>
                  <TableHead>From</TableHead>
                  <TableHead>Priority</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Created</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {tickets.map((t) => (
                  <TableRow key={t.id}>
                    <TableCell className="font-mono text-xs">{t.code}</TableCell>
                    <TableCell className="text-sm">{t.subject}</TableCell>
                    <TableCell className="text-xs">
                      {t.user?.name ?? t.partner?.firstName ?? '—'}
                    </TableCell>
                    <TableCell>
                      <Badge variant={t.priority === 'HIGH' ? 'destructive' : t.priority === 'NORMAL' ? 'info' : 'secondary'}>
                        {t.priority}
                      </Badge>
                    </TableCell>
                    <TableCell><Badge variant="secondary">{t.status}</Badge></TableCell>
                    <TableCell className="text-xs text-muted-foreground">{timeAgo(t.createdAt)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
