import Navbar from '@/components/shared/Navbar';
import Footer from '@/components/shared/Footer';
import { Activity, Phone, Users, Brain, Smartphone, MessageSquare } from 'lucide-react';

const stats = [
  { value: '77,000', label: 'New oral cancer cases/year in India', source: 'GLOBOCAN 2021' },
  { value: '74.9%', label: 'Cases from rural areas', source: 'ICMR NCRP' },
  { value: '80%', label: 'Diagnosed at Stage 3 or 4', source: 'ICMR NCRP' },
  { value: '30%', label: 'Share of all cancers in India', source: 'ICMR NCRP' },
];

const team = [
  { role: 'Team Lead / ML Engineer', desc: 'EfficientNetB3 model training, TFLite optimization, project architecture' },
  { role: 'Flutter Developer', desc: 'Android app, on-device inference, multilingual UI' },
  { role: 'Backend Developer', desc: 'FastAPI, Gemini integration, WhatsApp webhook, PDF generation' },
  { role: 'Research & Outreach', desc: 'ASHA worker research, dataset curation, impact validation' },
];

const tech = [
  { name: 'Gemini 2.5 Flash', desc: '4-language AI analysis and report generation' },
  { name: 'TFLite / EfficientNetB3', desc: 'On-device cancer risk classification' },
  { name: 'Firebase', desc: 'Firestore database and Cloud Storage' },
  { name: 'Google Maps', desc: 'Nearest cancer screening centre lookup' },
  { name: 'Flutter', desc: 'Cross-platform Android app with offline support' },
  { name: 'Cloud Run', desc: 'Scalable serverless backend deployment' },
  { name: 'WhatsApp Cloud API', desc: 'Zero-friction screening for basic phone users' },
];

export default function AboutPage() {
  return (
    <div className="min-h-screen bg-background-primary">
      <Navbar />
      <main>
        {/* Hero */}
        <section className="pt-28 pb-16 px-4">
          <div className="max-w-4xl mx-auto text-center">
            <div className="inline-flex items-center gap-2 bg-accent/10 border border-accent/20 rounded-full px-4 py-1.5 text-accent text-sm font-medium mb-6">
              <Activity className="h-4 w-4" />
              Google Solution Challenge 2025
            </div>
            <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
              Building Healthcare Equity<br className="hidden md:block" /> for Rural India
            </h1>
            <p className="text-muted text-lg max-w-2xl mx-auto">
              JanArogya (जनआरोग्य) — meaning &ldquo;People&apos;s Health&rdquo; — is a free AI-powered cancer screening
              platform designed for the 600 million rural Indians who lack access to specialist care.
            </p>
          </div>
        </section>

        {/* Problem */}
        <section className="py-16 px-4 bg-background-secondary border-y border-border">
          <div className="max-w-6xl mx-auto">
            <h2 className="text-2xl font-bold text-white text-center mb-10">The Scale of the Problem</h2>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-6">
              {stats.map(({ value, label, source }) => (
                <div key={value} className="bg-background-card rounded-2xl border border-border p-6 text-center">
                  <div className="text-3xl font-bold text-accent mb-2">{value}</div>
                  <p className="text-white text-sm font-medium mb-1">{label}</p>
                  <p className="text-muted text-xs">{source}</p>
                </div>
              ))}
            </div>
            <p className="text-center text-muted text-sm mt-6">
              Late-stage diagnosis has a <strong className="text-white">5-year survival rate of &lt;30%</strong>,
              vs. <strong className="text-white">&gt;80%</strong> if caught at Stage 1.
              Rural areas face a 1:500,000 oncologist ratio.
            </p>
          </div>
        </section>

        {/* Solution */}
        <section className="py-16 px-4">
          <div className="max-w-6xl mx-auto">
            <h2 className="text-2xl font-bold text-white text-center mb-10">Our Solution</h2>
            <div className="grid md:grid-cols-3 gap-6">
              {[
                { icon: MessageSquare, title: 'WhatsApp Bot', color: 'text-green-400', desc: 'Send a photo on WhatsApp. Get risk assessment in Hindi in 10 seconds. No app download. No data plan. Works on a basic Android.' },
                { icon: Smartphone, title: 'Android App', color: 'text-accent', desc: 'Full screening experience with PDF reports, nearest clinic finder, multilingual TTS, and offline-capable on-device AI.' },
                { icon: Brain, title: 'AI Engine', color: 'text-purple-400', desc: 'EfficientNetB3 TFLite model (95%+ accuracy) + Gemini Vision for personalised 4-language analysis in plain everyday language.' },
              ].map(({ icon: Icon, title, color, desc }) => (
                <div key={title} className="bg-background-card rounded-2xl border border-border p-6">
                  <Icon className={`h-8 w-8 ${color} mb-4`} />
                  <h3 className="text-white font-bold text-lg mb-2">{title}</h3>
                  <p className="text-muted text-sm leading-relaxed">{desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Team */}
        <section className="py-16 px-4 bg-background-secondary border-y border-border">
          <div className="max-w-6xl mx-auto">
            <h2 className="text-2xl font-bold text-white text-center mb-10">
              <Users className="inline h-6 w-6 mr-2 text-accent" />
              The Team
            </h2>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              {team.map(({ role, desc }) => (
                <div key={role} className="bg-background-card rounded-2xl border border-border p-5 text-center">
                  <div className="w-12 h-12 rounded-full bg-accent/10 border border-accent/20 flex items-center justify-center mx-auto mb-3">
                    <Users className="h-6 w-6 text-accent" />
                  </div>
                  <p className="text-white font-semibold text-sm mb-2">{role}</p>
                  <p className="text-muted text-xs leading-relaxed">{desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Tech */}
        <section className="py-16 px-4">
          <div className="max-w-6xl mx-auto">
            <h2 className="text-2xl font-bold text-white text-center mb-2">Built on Google Technologies</h2>
            <p className="text-muted text-center mb-10">7 Google products powering every screening</p>
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {tech.map(({ name, desc }) => (
                <div key={name} className="bg-background-card rounded-xl border border-border p-4">
                  <div className="w-8 h-8 rounded-lg bg-accent flex items-center justify-center mb-3 text-white font-bold text-sm">
                    {name[0]}
                  </div>
                  <p className="text-white font-semibold text-sm mb-1">{name}</p>
                  <p className="text-muted text-xs leading-relaxed">{desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Helpline */}
        <section className="py-12 px-4">
          <div className="max-w-2xl mx-auto bg-danger/10 border border-danger/30 rounded-2xl p-8 text-center">
            <Phone className="h-10 w-10 text-danger mx-auto mb-3" />
            <h3 className="text-white font-bold text-xl mb-1">Cancer Helpline</h3>
            <p className="text-3xl font-bold text-danger font-mono mb-2">1800-11-2345</p>
            <p className="text-muted text-sm">Toll-Free · 24/7 · National Cancer Grid India</p>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
