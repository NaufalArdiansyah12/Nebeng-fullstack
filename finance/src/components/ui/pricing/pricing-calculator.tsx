import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import api from "@/lib/api";
import { toast } from "sonner";

const PricingCalculator = () => {
  const [transport, setTransport] = useState('motor');
  const [weight, setWeight] = useState<string>('');
  const [serviceType, setServiceType] = useState<string>('');
  const [distance, setDistance] = useState<string>('');
  const [result, setResult] = useState<any | null>(null);
  const [loading, setLoading] = useState(false);

  const handleCalculate = async () => {
    if (!weight) {
      toast.error('Masukkan berat');
      return;
    }
    try {
      setLoading(true);
      const params: any = { 
        transport_mode: transport, 
        weight: Number(weight)
      };
      if (serviceType) params.service_type = serviceType;
      if (distance) params.distance = Number(distance);

      const res = await api.get('/finance/price/calculate', { params });
      setResult(res.data.data || null);
      toast.success('Tarif berhasil dihitung');
    } catch (err: any) {
      console.error(err);
      toast.error(err.response?.data?.message || 'Gagal menghitung tarif');
      setResult(null);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Kalkulator Tarif</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
          <div>
            <Label htmlFor="transport">Jenis Transportasi</Label>
            <Input 
              id="transport"
              value={transport} 
              onChange={(e) => setTransport(e.target.value)} 
              placeholder="motor, mobil, barang"
            />
          </div>
          <div>
            <Label htmlFor="weight">Berat (KG) *</Label>
            <Input 
              id="weight"
              type="number" 
              value={weight} 
              onChange={(e) => setWeight(e.target.value)} 
              placeholder="0"
            />
          </div>
          <div>
            <Label htmlFor="distance">Jarak (KM)</Label>
            <Input 
              id="distance"
              type="number" 
              value={distance} 
              onChange={(e) => setDistance(e.target.value)} 
              placeholder="0"
            />
          </div>
          <div>
            <Label htmlFor="serviceType">Tipe Layanan</Label>
            <Input 
              id="serviceType"
              value={serviceType} 
              onChange={(e) => setServiceType(e.target.value)} 
              placeholder="Opsional"
            />
          </div>
        </div>
        
        <div className="flex justify-end">
          <Button onClick={handleCalculate} disabled={loading}>
            {loading ? 'Menghitung...' : 'Hitung Tarif'}
          </Button>
        </div>

        {result && (
          <div className="mt-6 p-4 bg-gray-50 rounded-lg">
            <h4 className="font-semibold mb-3">Hasil Perhitungan:</h4>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-gray-600">Profil:</span>
                <span className="font-medium">{result.profile_name || '-'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Harga per unit:</span>
                <span className="font-medium">Rp {Number(result.unit_price || 0).toLocaleString('id-ID')}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Harga dasar:</span>
                <span className="font-medium">Rp {Number(result.base_price || 0).toLocaleString('id-ID')}</span>
              </div>
              {result.distance_charge !== undefined && (
                <div className="flex justify-between">
                  <span className="text-gray-600">Biaya jarak ({result.distance || 0} km):</span>
                  <span className="font-medium">Rp {Number(result.distance_charge || 0).toLocaleString('id-ID')}</span>
                </div>
              )}
              {result.weight_charge !== undefined && (
                <div className="flex justify-between">
                  <span className="text-gray-600">Biaya berat ({result.weight || 0} kg):</span>
                  <span className="font-medium">Rp {Number(result.weight_charge || 0).toLocaleString('id-ID')}</span>
                </div>
              )}
              <div className="flex justify-between text-lg font-bold pt-2 border-t">
                <span>Total:</span>
                <span className="text-primary">Rp {Number(result.total || 0).toLocaleString('id-ID')}</span>
              </div>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default PricingCalculator;
