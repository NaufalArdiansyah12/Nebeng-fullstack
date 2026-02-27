import { useState } from "react";
import DashboardLayout from "@/components/DashboardLayout";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import MotorConfig from "@/components/ui/pricing/MotorConfig";
import MobilConfig from "@/components/ui/pricing/MobilConfig";
import BarangConfig from "@/components/ui/pricing/BarangConfig";
import TitipBarangConfig from "@/components/ui/pricing/TitipBarangConfig";

const Pricing = () => {
  const [activeTab, setActiveTab] = useState("motor");

  return (
    <DashboardLayout title="Konfigurasi Tarif">
      <div className="py-6 space-y-6">
        <div>
          <h2 className="text-2xl font-bold mb-2">Pengaturan Tarif Tebengan</h2>
          <p className="text-gray-600">
            Kelola harga untuk setiap jenis layanan tebengan
          </p>
        </div>



        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="motor">Motor</TabsTrigger>
            <TabsTrigger value="mobil">Mobil</TabsTrigger>
            <TabsTrigger value="barang">Barang</TabsTrigger>
            <TabsTrigger value="titip-barang">Titip Barang</TabsTrigger>
          </TabsList>

          <TabsContent value="motor">
            <MotorConfig />
          </TabsContent>

          <TabsContent value="mobil">
            <MobilConfig />
          </TabsContent>

          <TabsContent value="barang">
            <BarangConfig />
          </TabsContent>

          <TabsContent value="titip-barang">
            <TitipBarangConfig />
          </TabsContent>
        </Tabs>
      </div>
    </DashboardLayout>
  );
};

export default Pricing;
