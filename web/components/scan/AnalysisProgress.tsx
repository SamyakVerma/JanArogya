'use client';

import { useEffect, useState } from 'react';
import { Loader2, CheckCircle } from 'lucide-react';
import { cn } from '@/lib/utils';

const steps = [
  { label: 'Checking image quality...', duration: 1000 },
  { label: 'Running AI model (TFLite + Gemini)...', duration: 1500 },
  { label: 'Generating explanation...', duration: 1000 },
  { label: 'Finalizing results...', duration: 500 },
];

export default function AnalysisProgress() {
  const [activeStep, setActiveStep] = useState(0);

  useEffect(() => {
    const timers: ReturnType<typeof setTimeout>[] = [];
    let elapsed = 0;

    steps.forEach((step, i) => {
      if (i === 0) return;
      elapsed += steps[i - 1].duration;
      const t = setTimeout(() => setActiveStep(i), elapsed);
      timers.push(t);
    });

    return () => timers.forEach(clearTimeout);
  }, []);

  return (
    <div className="flex flex-col items-center justify-center py-16 gap-8">
      {/* Animated ring */}
      <div className="relative w-20 h-20">
        <div className="absolute inset-0 rounded-full border-4 border-border" />
        <div className="absolute inset-0 rounded-full border-4 border-accent border-t-transparent animate-spin" />
        <div className="absolute inset-0 flex items-center justify-center">
          <Loader2 className="h-8 w-8 text-accent animate-spin" />
        </div>
      </div>

      {/* Steps */}
      <div className="w-full max-w-sm space-y-3">
        {steps.map((step, i) => (
          <div
            key={i}
            className={cn(
              'flex items-center gap-3 text-sm transition-all duration-300',
              i < activeStep && 'text-muted',
              i === activeStep && 'text-white',
              i > activeStep && 'text-muted/40'
            )}
          >
            <div className="shrink-0">
              {i < activeStep ? (
                <CheckCircle className="h-4 w-4 text-success" />
              ) : i === activeStep ? (
                <div className="h-4 w-4 rounded-full border-2 border-accent border-t-transparent animate-spin" />
              ) : (
                <div className="h-4 w-4 rounded-full border-2 border-border" />
              )}
            </div>
            <span>{step.label}</span>
          </div>
        ))}
      </div>

      <p className="text-muted text-sm">This usually takes 3–5 seconds</p>
    </div>
  );
}
