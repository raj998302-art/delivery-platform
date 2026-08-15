'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Truck, Mail, Lock, ArrowRight, Loader2, Crown, Sparkles } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { toast } from '@/components/ui/toaster';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('raj998302@gmail.com');
  const [password, setPassword] = useState('RAJ998302');
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Login failed');
      toast({ title: 'Welcome back', description: data.user?.name, variant: 'success' });
      router.push('/dashboard');
      router.refresh();
    } catch (err: any) {
      toast({
        title: 'Login failed',
        description: err.message,
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen relative flex items-center justify-center p-4 overflow-hidden">
      {/* Animated gradient background */}
      <div className="absolute inset-0 bg-gradient-to-br from-blue-600 via-indigo-600 to-purple-700" />
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,_rgba(255,255,255,0.15),transparent_50%)]" />
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_left,_rgba(168,85,247,0.2),transparent_50%)]" />

      {/* Floating orbs */}
      <div className="absolute top-20 left-20 w-72 h-72 bg-blue-400/20 rounded-full blur-3xl animate-pulse" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-purple-400/20 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />

      {/* Grid pattern overlay */}
      <div
        className="absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage: `linear-gradient(white 1px, transparent 1px), linear-gradient(90deg, white 1px, transparent 1px)`,
          backgroundSize: '40px 40px',
        }}
      />

      <div className="relative w-full max-w-md animate-in">
        {/* Logo */}
        <div className="flex flex-col items-center mb-8">
          <div className="grid place-items-center h-16 w-16 rounded-2xl bg-white/10 backdrop-blur-md border border-white/20 shadow-2xl mb-4">
            <Truck className="h-8 w-8 text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white tracking-tight">Delivery Platform</h1>
          <p className="text-blue-200/80 text-sm mt-1">Admin Console · Owner Access</p>
        </div>

        <Card className="shadow-2xl border-white/10 bg-white/95 backdrop-blur-xl">
          <CardHeader className="space-y-1">
            <div className="flex items-center gap-2">
              <CardTitle className="text-2xl">Sign in</CardTitle>
              <span className="inline-flex items-center gap-1 rounded-full bg-gradient-to-r from-amber-500 to-orange-500 px-2 py-0.5 text-[10px] font-bold text-white">
                <Crown className="h-2.5 w-2.5" /> OWNER
              </span>
            </div>
            <CardDescription className="flex items-center gap-1.5">
              <Sparkles className="h-3 w-3" />
              Owner credentials are pre-filled
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={onSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <Label htmlFor="email">Email</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="pl-9"
                    required
                  />
                </div>
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="password">Password</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="pl-9"
                    required
                  />
                </div>
              </div>
              <Button type="submit" disabled={loading} className="w-full gradient-bg shadow-lg shadow-blue-500/30 hover:shadow-blue-500/50 transition-shadow">
                {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <>Sign in <ArrowRight className="h-4 w-4" /></>}
              </Button>
            </form>
          </CardContent>
        </Card>

        <p className="mt-6 text-center text-xs text-blue-200/60">
          Protected by JWT session cookie · bcrypt password hashing
        </p>
      </div>
    </div>
  );
}
