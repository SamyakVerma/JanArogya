'use client';

import { Smile, Sun, HelpCircle } from 'lucide-react';
import { cn } from '@/lib/utils';
import type { ScanType } from '@/types';

const types: { value: ScanType; label: string; desc: string; icon: React.ReactNode }[] = [
  {
    value: 'oral',
    label: 'Oral Cavity',
    desc: 'Inside mouth, tongue, gums',
    icon: <Smile className="h-6 w-6" />,
  },
  {
    value: 'skin',
    label: 'Skin Lesion',
    desc: 'Moles, spots, discoloration',
    icon: <Sun className="h-6 w-6" />,
  },
  {
    value: 'other',
    label: 'Other',
    desc: 'General screening',
    icon: <HelpCircle className="h-6 w-6" />,
  },
];

interface ScanTypeSelectorProps {
  value: ScanType | null;
  onChange: (t: ScanType) => void;
}

export default function ScanTypeSelector({ value, onChange }: ScanTypeSelectorProps) {
  return (
    <div>
      <label className="block text-sm font-medium text-gray-300 mb-2">Scan Type</label>
      <div className="grid grid-cols-3 gap-3">
        {types.map((t) => (
          <button
            key={t.value}
            type="button"
            onClick={() => onChange(t.value)}
            className={cn(
              'flex flex-col items-center gap-2 p-4 rounded-xl border transition-all duration-200 text-center',
              value === t.value
                ? 'border-accent bg-accent/10 text-accent'
                : 'border-border bg-background-card text-muted hover:border-border-light hover:text-white'
            )}
          >
            {t.icon}
            <div>
              <div className="text-xs font-semibold">{t.label}</div>
              <div className="text-xs opacity-70 mt-0.5">{t.desc}</div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}
