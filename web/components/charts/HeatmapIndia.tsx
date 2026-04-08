'use client';

import { MapPin } from 'lucide-react';
import { Badge } from '@/components/ui/Badge';
import type { HeatmapPoint } from '@/types';

interface HeatmapIndiaProps {
  points: HeatmapPoint[];
}

// Simple list-based visualization since Google Maps embed is complex
export default function HeatmapIndia({ points }: HeatmapIndiaProps) {
  if (points.length === 0) {
    return (
      <div className="text-center py-10 text-muted text-sm">
        No geographic data available
      </div>
    );
  }

  const sorted = [...points].sort((a, b) => b.count - a.count);
  const maxCount = sorted[0]?.count ?? 1;

  return (
    <div className="space-y-3">
      {sorted.slice(0, 10).map((point, i) => (
        <div key={i} className="flex items-center gap-3">
          <MapPin className="h-4 w-4 text-accent shrink-0" />
          <div className="flex-1">
            <div className="flex items-center justify-between mb-1">
              <span className="text-sm text-white">
                {point.lat.toFixed(2)}°N, {point.lng.toFixed(2)}°E
              </span>
              <div className="flex items-center gap-2">
                <Badge risk={point.risk_level} />
                <span className="text-xs text-muted">{point.count} scans</span>
              </div>
            </div>
            <div className="h-1.5 bg-background-secondary rounded-full overflow-hidden">
              <div
                className="h-full bg-accent rounded-full transition-all duration-500"
                style={{ width: `${(point.count / maxCount) * 100}%` }}
              />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
