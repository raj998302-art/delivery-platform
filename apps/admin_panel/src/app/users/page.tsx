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
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from '@/components/ui/table';
import { Search, RefreshCw, Ban, CheckCircle2, Phone } from 'lucide-react';
import { timeAgo } from '@/lib/utils';
import { toast } from '@/components/ui/toaster';

interface User {
  id: string; name: string | null; phone: string; email: string | null;
  role: string; isBlocked: boolean; phoneVerified: string | null;
  createdAt: string; lastLoginAt: string | null;
  _count: { orders: number };
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [q, setQ] = useState('');
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const params = new URLSearchParams({ page: String(page), pageSize: '20', q });
    const res = await fetch(`/api/users?${params}`);
    if (res.ok) {
      const data = await res.json();
      setUsers(data.users);
      setTotal(data.total);
    }
    setLoading(false);
  }

  useEffect(() => { load(); /* eslint-disable-next-line */ }, [page]);

  async function toggleBlock(u: User) {
    const res = await fetch('/api/users', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: u.id, isBlocked: !u.isBlocked }),
    });
    if (res.ok) {
      toast({ title: u.isBlocked ? 'User unblocked' : 'User blocked', description: u.name ?? u.phone, variant: 'success' });
      load();
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-bold tracking-tight">Users</h2>
          <p className="text-sm text-muted-foreground">{total} customers</p>
        </div>
        <div className="flex gap-2">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input placeholder="Search users…" value={q} onChange={(e) => setQ(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && (setPage(1), load())} className="pl-9 w-56" />
          </div>
          <Button variant="outline" size="icon" onClick={load}><RefreshCw className="h-4 w-4" /></Button>
        </div>
      </div>

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User</TableHead>
                <TableHead>Phone</TableHead>
                <TableHead>Role</TableHead>
                <TableHead>Orders</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Joined</TableHead>
                <TableHead>Last login</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    {Array.from({ length: 8 }).map((_, j) => (
                      <TableCell key={j}><div className="h-4 bg-muted animate-pulse rounded" /></TableCell>
                    ))}
                  </TableRow>
                ))
              ) : users.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center text-sm text-muted-foreground py-12">No users found.</TableCell>
                </TableRow>
              ) : (
                users.map((u) => (
                  <TableRow key={u.id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <Avatar><AvatarFallback>{(u.name ?? u.phone).charAt(0)}</AvatarFallback></Avatar>
                        <div>
                          <div className="text-sm font-medium">{u.name ?? 'Unknown'}</div>
                          {u.email && <div className="text-xs text-muted-foreground">{u.email}</div>}
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-xs"><span className="flex items-center gap-1"><Phone className="h-3 w-3" />{u.phone}</span></TableCell>
                    <TableCell><Badge variant={u.role === 'CUSTOMER' ? 'secondary' : 'default'}>{u.role}</Badge></TableCell>
                    <TableCell className="text-sm">{u._count.orders}</TableCell>
                    <TableCell>
                      {u.isBlocked ? <Badge variant="destructive">Blocked</Badge> : <Badge variant="success">Active</Badge>}
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">{timeAgo(u.createdAt)}</TableCell>
                    <TableCell className="text-xs text-muted-foreground">{u.lastLoginAt ? timeAgo(u.lastLoginAt) : '—'}</TableCell>
                    <TableCell>
                      <Button variant="ghost" size="sm" onClick={() => toggleBlock(u)} className={u.isBlocked ? 'text-green-600' : 'text-destructive'}>
                        {u.isBlocked ? <><CheckCircle2 className="h-4 w-4" /> Unblock</> : <><Ban className="h-4 w-4" /> Block</>}
                      </Button>
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
