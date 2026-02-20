/**
 * DesignerDashboard.tsx — Production Focus for Floral Designers.
 *
 * 2 stat cards + task lists (production, wedding, custom) with status toggle.
 * No financial data.
 */
import { useState, useCallback } from 'react';
import TaskItem from '../components/TaskItem';
import SectionHeading from '../components/SectionHeading';
import StatCard from '../components/StatCard';
import type { DesignerDashboardData, ProductionTask } from '../api/dashboardApi';

const ic = 'w-5 h-5';

const Icons = {
  wrench: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M11.42 15.17l-5.384 5.384a2.025 2.025 0 01-2.862-2.862l5.384-5.384m2.862 2.862a3 3 0 104.243-4.243 3 3 0 00-4.243 4.243zm0 0L9.258 7.757a2.003 2.003 0 00-.468-.375l-3.758-2.128a.5.5 0 00-.606.088l-.84.84a.5.5 0 00-.088.606l2.128 3.758c.1.178.233.335.375.468l7.857 7.857" />
    </svg>
  ),
  clock: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ),
};

interface DesignerDashboardProps {
  data: DesignerDashboardData;
}

export default function DesignerDashboard({ data }: DesignerDashboardProps) {
  const [tasks, setTasks] = useState<ProductionTask[]>(data.productionTasks);
  const [weddingTasks, setWeddingTasks] = useState<ProductionTask[]>(data.weddingPrepTasks);
  const [customOrders, setCustomOrders] = useState<ProductionTask[]>(data.customOrders);

  const cycleStatus = useCallback((list: ProductionTask[], id: string): ProductionTask[] => {
    return list.map((t) => {
      if (t.id !== id) return t;
      const next = t.status === 'pending' ? 'in_progress' : t.status === 'in_progress' ? 'completed' : 'pending';
      return { ...t, status: next };
    });
  }, []);

  return (
    <div>
      {/* Quick stat cards — 4-col grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-10">
        <StatCard
          label="Maintenance Required"
          value={data.maintenanceRequired}
          icon={Icons.wrench}
          iconBg="bg-amber-50"
          iconColor="text-amber-600"
          href="/production/finished-goods"
        />
        <StatCard
          label="Expiring Bouquets"
          value={data.expiringBouquets}
          icon={Icons.clock}
          iconBg="bg-rose-50"
          iconColor="text-rose-500"
          href="/expiry-alerts"
        />
      </div>

      {/* Subtle divider */}
      <div className="border-t border-gray-100 my-8" />

      {/* Today's production tasks */}
      <div className="mb-10">
        <div className="mb-4">
          <SectionHeading title="Today's Production" count={tasks.length} />
        </div>
        {tasks.length === 0 ? (
          <div className="text-center py-12 text-gray-400">
            <p className="text-sm">No production tasks today</p>
          </div>
        ) : (
          <div className="space-y-3">
            {tasks.map((t) => (
              <TaskItem key={t.id} task={t} onToggle={(id) => setTasks((p) => cycleStatus(p, id))} />
            ))}
          </div>
        )}
      </div>

      {/* Wedding prep */}
      {weddingTasks.length > 0 && (
        <>
          {/* Subtle divider */}
          <div className="border-t border-gray-100 my-8" />
          <div className="mb-10">
            <div className="mb-4">
              <SectionHeading title="Wedding Prep" count={weddingTasks.length} />
            </div>
            <div className="space-y-3">
              {weddingTasks.map((t) => (
                <TaskItem key={t.id} task={t} onToggle={(id) => setWeddingTasks((p) => cycleStatus(p, id))} />
              ))}
            </div>
          </div>
        </>
      )}

      {/* Custom orders */}
      {customOrders.length > 0 && (
        <>
          {/* Subtle divider */}
          <div className="border-t border-gray-100 my-8" />
          <div>
            <div className="mb-4">
              <SectionHeading title="Custom Orders" count={customOrders.length} />
            </div>
            <div className="space-y-3">
              {customOrders.map((t) => (
                <TaskItem key={t.id} task={t} onToggle={(id) => setCustomOrders((p) => cycleStatus(p, id))} />
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
