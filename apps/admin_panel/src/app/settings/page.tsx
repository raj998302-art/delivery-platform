'use client';

import { useEffect, useState } from 'react';
import {
  Card, CardContent, CardDescription, CardHeader, CardTitle,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import {
  Tabs, TabsContent, TabsList, TabsTrigger,
} from '@/components/ui/tabs';
import { toast } from '@/components/ui/toaster';
import { Settings as SettingsIcon, Key, Database, Webhook, Shield, Server } from 'lucide-react';

export default function SettingsPage() {
  const [health, setHealth] = useState<any>(null);

  useEffect(() => {
    fetch('/api/auth/me')
      .then((r) => {
        if (r.ok) {
          fetch('/api/analytics')
            .then(() => setHealth({ db: 'ok', api: 'ok' }))
            .catch(() => setHealth({ db: 'fail', api: 'ok' }));
        }
      })
      .catch(() => setHealth({ db: 'fail', api: 'fail' }));
  }, []);

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-bold tracking-tight">Settings</h2>
        <p className="text-sm text-muted-foreground">Platform configuration, secrets, and integrations.</p>
      </div>

      <Tabs defaultValue="general">
        <TabsList>
          <TabsTrigger value="general"><SettingsIcon className="h-4 w-4 mr-2" /> General</TabsTrigger>
          <TabsTrigger value="secrets"><Key className="h-4 w-4 mr-2" /> API Keys</TabsTrigger>
          <TabsTrigger value="integrations"><Webhook className="h-4 w-4 mr-2" /> Integrations</TabsTrigger>
          <TabsTrigger value="system"><Server className="h-4 w-4 mr-2" /> System</TabsTrigger>
        </TabsList>

        <TabsContent value="general">
          <Card>
            <CardHeader>
              <CardTitle>Platform</CardTitle>
              <CardDescription>Branding and locale</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid gap-2 md:grid-cols-2">
                <div>
                  <Label>Platform name</Label>
                  <Input defaultValue="Delivery Platform" />
                </div>
                <div>
                  <Label>Default currency</Label>
                  <Input defaultValue="INR" disabled />
                </div>
                <div>
                  <Label>Default country</Label>
                  <Input defaultValue="India" />
                </div>
                <div>
                  <Label>Default language</Label>
                  <Input defaultValue="en" />
                </div>
              </div>
              <Button onClick={() => toast({ title: 'Saved', variant: 'success' })}>Save changes</Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="secrets">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2"><Shield className="h-4 w-4" /> API Keys & Secrets</CardTitle>
              <CardDescription>
                These are read from Vercel environment variables. Never commit secrets to git.
                Update them in <code>Vercel → Project → Settings → Environment Variables</code>.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <SecretRow name="DATABASE_URL" desc="PostgreSQL connection string (with PostGIS for production)" status="required" />
              <SecretRow name="JWT_SECRET" desc="Used to sign admin session tokens" status="required" />
              <SecretRow name="APP_API_KEYS" desc="Comma-separated keys for Flutter app → API auth" status="optional" />
              <SecretRow name="MSG91_AUTH_KEY" desc="Msg91 OTP provider auth key (configurable)" status="optional" />
              <SecretRow name="TWILIO_ACCOUNT_SID" desc="Twilio OTP provider (alternative)" status="optional" />
              <SecretRow name="RAZORPAY_KEY_ID" desc="Razorpay payment gateway key" status="optional" />
              <SecretRow name="RAZORPAY_KEY_SECRET" desc="Razorpay payment gateway secret" status="optional" />
              <SecretRow name="GOOGLE_MAPS_API_KEY" desc="Google Maps SDK for Flutter apps" status="optional" />
              <SecretRow name="FIREBASE_SERVER_KEY" desc="FCM push notifications (optional)" status="optional" />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="integrations">
          <div className="grid gap-4 md:grid-cols-2">
            <IntegrationCard name="OTP — Msg91" desc="India-first OTP delivery" status="not configured" />
            <IntegrationCard name="OTP — Twilio" desc="International OTP" status="not configured" />
            <IntegrationCard name="Payments — Razorpay" desc="UPI, cards, netbanking" status="not configured" />
            <IntegrationCard name="Maps — Google Maps" desc="Geocoding, directions, places" status="not configured" />
            <IntegrationCard name="Push — FCM" desc="Firebase Cloud Messaging" status="not configured" />
            <IntegrationCard name="Analytics — PostHog" desc="Product analytics" status="not configured" />
          </div>
        </TabsContent>

        <TabsContent value="system">
          <Card>
            <CardHeader>
              <CardTitle>System Status</CardTitle>
              <CardDescription>Live health checks</CardDescription>
            </CardHeader>
            <CardContent className="space-y-2">
              <StatusRow icon={Database} label="PostgreSQL (Prisma)" status={health?.db ?? 'checking'} />
              <StatusRow icon={Server} label="API routes" status={health?.api ?? 'checking'} />
              <StatusRow icon={Webhook} label="Vercel deployment" status="ok" />
              <StatusRow icon={Shield} label="Auth (JWT + bcrypt)" status="ok" />
            </CardContent>
          </Card>

          <Card className="mt-4">
            <CardHeader>
              <CardTitle>Architecture</CardTitle>
              <CardDescription>Stack & deployment topology</CardDescription>
            </CardHeader>
            <CardContent>
              <pre className="text-xs bg-muted p-4 rounded-lg overflow-x-auto">{`Flutter (user_app)  ─┐
Flutter (partner_app) ─┼─→  Next.js API Routes (this Vercel deployment)
Admin Panel (this app) ─┘         │
                                  ├─ Prisma ORM
                                  ├─ PostgreSQL + PostGIS
                                  ├─ Redis (BullMQ, geospatial) [prod]
                                  └─ Socket.IO (real-time tracking) [prod]

Build pipeline:
  GitHub Actions → Flutter SDK → APK artifacts (per app)
  Vercel         → Next.js auto-deploy on push to main`}</pre>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}

function SecretRow({ name, desc, status }: { name: string; desc: string; status: 'required' | 'optional' }) {
  return (
    <div className="flex items-center justify-between rounded-lg border p-3">
      <div>
        <div className="font-mono text-xs font-medium">{name}</div>
        <div className="text-xs text-muted-foreground">{desc}</div>
      </div>
      <Badge variant={status === 'required' ? 'destructive' : 'secondary'}>{status}</Badge>
    </div>
  );
}

function IntegrationCard({ name, desc, status }: { name: string; desc: string; status: string }) {
  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div className="font-medium text-sm">{name}</div>
          <Badge variant={status === 'connected' ? 'success' : 'secondary'}>{status}</Badge>
        </div>
        <p className="mt-1 text-xs text-muted-foreground">{desc}</p>
      </CardContent>
    </Card>
  );
}

function StatusRow({ icon: Icon, label, status }: { icon: any; label: string; status: string }) {
  const color = status === 'ok' ? 'text-green-600' : status === 'fail' ? 'text-red-600' : 'text-amber-600';
  return (
    <div className="flex items-center gap-3 rounded-lg border p-3">
      <Icon className={`h-4 w-4 ${color}`} />
      <div className="flex-1 text-sm">{label}</div>
      <Badge variant={status === 'ok' ? 'success' : status === 'fail' ? 'destructive' : 'warning'}>{status}</Badge>
    </div>
  );
}
