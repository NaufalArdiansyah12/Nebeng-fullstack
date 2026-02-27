
interface PriceRate {
  id: number;
  service_type: string;
  ride_type: string;
  bagasi_capacity?: number | null;
  rate_per_kg: number;
  min_charge: number;
  is_active: boolean;
  effective_from: string;
}

interface PriceTableProps {
  data: PriceRate[];
  onEdit: (rate: PriceRate) => void;
  onDelete: (id: number) => void;
  onToggleStatus: (id: number, isActive: boolean) => void;
}

// price table moved to finance/src/deprecated/removed_price_system/
export function PriceTable() {
  return null;
}
